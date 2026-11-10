// Regression coverage for bounded helper process groups and setup failure gating.
const assert = require("assert")
const fs = require("fs")
const os = require("os")
const path = require("path")
const { spawn } = require("child_process")

const travel = fs.readFileSync(path.join(__dirname, "../qml/core/TravelModel.qml"), "utf8")
const settings = fs.readFileSync(path.join(__dirname, "../qml/core/SettingsStore.qml"), "utf8")
assert.doesNotMatch(travel + settings, /\.kill\(\)/)
assert.match(travel, /root\.storeFailed = !ok[\s\S]*root\.storeReady = ok/)
assert.match(travel, /path: root\.storeReady && !root\.storeFailed \? root\.storePath : ""/)
assert.match(travel, /function _write\(obj\) \{\s*if \(!storeReady \|\| storeFailed\) return/)
assert.match(travel, /function exportData\(kind\) \{\s*if \(!storeReady \|\| storeFailed\)/)
assert.match(travel, /then cp .* \|\| exit \$\?/ )
assert.match(travel, /root\._bounded\(\["sh", "-c", \[/)
assert.match(travel, /proc\.command = root\._bounded/)
assert.match(travel, /command: root\._bounded\(\["chmod", "600", root\.storePath\]\)[\s\S]*permFixerDeadline\.start\(\)/)
assert.match(travel, /onTriggered: if \(permFixer\.running\) permFixer\.signal\(15\)/)
assert.match(settings, /root\.dirFailed = !ok[\s\S]*root\.dirReady = ok/)
assert.match(settings, /if \(dirFailed \|\| !dirReady\) return/)
assert.match(settings, /path: root\.dirReady && !root\.dirFailed \? root\.path : ""/)

const pidFile = path.join(os.tmpdir(), `omatravel-timeout-${process.pid}`)
const runnerLiteral = travel.match(/_groupRunner: ("(?:\\.|[^"\\])*")/)[1]
const runner = JSON.parse(runnerLiteral)
const processAlive = pid => {
  try {
    process.kill(pid, 0)
    return fs.readFileSync(`/proc/${pid}/stat`, "utf8").split(" ")[2] !== "Z"
  } catch (_) { return false }
}
const delay = ms => new Promise(resolve => setTimeout(resolve, ms))

;(async () => {
  let stalled
  try {
    stalled = spawn("setsid", ["sh", "-c", runner, "sh", "sh", "-c", 'echo $$ > "$1"; exec sleep 30', "sh", pidFile], { stdio: "ignore" })
    for (let i = 0; i < 100 && !fs.existsSync(pidFile); i++) await delay(10)
    assert.ok(fs.existsSync(pidFile), "stalled child started")
    const childPid = Number(fs.readFileSync(pidFile, "utf8"))
    process.kill(-stalled.pid, "SIGTERM")
    await new Promise(resolve => stalled.once("exit", resolve))
    for (let i = 0; i < 100 && processAlive(childPid); i++) await delay(10)
    assert.ok(!processAlive(childPid), "timeout terminated descendant")

    const failed = spawn("setsid", ["sh", "-c", runner, "sh", "sh", "-c", "exit 23"], { stdio: "ignore" })
    const result = await new Promise(resolve => failed.once("exit", (code, signal) => resolve({ code, signal })))
    assert.strictEqual(result.code, 23, "failing setup preserves its failure exit")
    console.log("  ok   timeout cleans up stalled descendants and failure is preserved")
  } finally {
    try { fs.unlinkSync(pidFile) } catch (_) { }
    if (stalled && stalled.exitCode === null) try { process.kill(-stalled.pid, "SIGKILL") } catch (_) { }
  }
})().catch(error => { console.error(error); process.exitCode = 1 })
