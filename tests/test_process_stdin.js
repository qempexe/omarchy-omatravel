// The write helper gets its content on stdin, through the same runner the plugin uses:
// what arrives in the file is exactly what was sent, and nothing empty replaces a file.
const assert = require("assert")
const fs = require("fs")
const os = require("os")
const path = require("path")
const { spawnSync } = require("child_process")

const travel = fs.readFileSync(path.join(__dirname, "../qml/core/TravelModel.qml"), "utf8")
const runner = JSON.parse(travel.match(/_groupRunner: ("(?:\\.|[^"\\])*")/)[1])
const block = travel.match(/_privateWriteScript: \[([\s\S]*?)\]\.join\("\\n"\)/)[1]
const script = block.split("\n").map(l => l.trim()).filter(l => l.startsWith("'"))
  .map(l => l.replace(/^'/, "").replace(/',?$/, "")).join("\n")
assert.match(script, /cat > "\$tmp"/, "the write script was read from TravelModel.qml")
assert.match(travel, /function _bounded\(command\) \{ return \["setsid", "sh", "-c", _groupRunner, "sh"\]\.concat\(command\) \}/)
assert.match(travel, /proc\.command = root\._bounded\(\["sh", "-c", root\._privateWriteScript, "sh", dir, file\]\)/)

const has = name => spawnSync("sh", ["-c", "command -v " + name], { stdio: "ignore" }).status === 0
const shells = ["sh", "bash", "dash"].filter(has)
if (has("busybox")) shells.push("busybox")
const dir = fs.mkdtempSync(path.join(os.tmpdir(), "omatravel-stdin-"))
let failed = 0
const ok = (cond, what) => { console.log((cond ? "  ok   " : "  FAIL ") + what); if (!cond) failed++ }
const read = file => { try { return fs.readFileSync(file, "utf8") } catch (_) { return null } }

try {
  for (const shell of shells) {
    const sh = shell === "busybox" ? ["busybox", "sh"] : [shell]
    const write = (target, input) => spawnSync("setsid", [...sh, "-c", runner, "sh", ...sh, "-c", script, "sh", path.dirname(target), target],
      { input, timeout: 10000 })
    const fresh = path.join(dir, shell, "exports", "travel.json")
    const payload = JSON.stringify({ places: ["Brugge", "Bucureşti"], note: "line one\nline two" }, null, 2) + "\n"
    let run = write(fresh, payload)
    ok(run.status === 0 && read(fresh) === payload, shell + ": a new file holds exactly what was sent (" + Buffer.byteLength(payload) + " bytes)")
    ok(read(fresh) !== null && (fs.statSync(fresh).mode & 0o777) === 0o600 && (fs.statSync(path.dirname(fresh)).mode & 0o777) === 0o700,
      shell + ": the file is 600 in a 700 folder")

    const big = "x".repeat(300000) + "\nend"
    run = write(fresh, big)
    ok(run.status === 0 && read(fresh) === big, shell + ": an existing file is replaced by the new content, whole")

    run = write(fresh, "")
    ok(run.status !== 0 && read(fresh) === big, shell + ": nothing sent fails and leaves the file as it was")
    ok(fs.readdirSync(path.dirname(fresh)).length === 1, shell + ": no temporary file is left behind")
  }
} finally {
  fs.rmSync(dir, { recursive: true, force: true })
}
if (failed) { console.error(failed + " failed"); process.exitCode = 1 } else console.log("  ok   stdin reaches the write helper in " + shells.join(", "))
