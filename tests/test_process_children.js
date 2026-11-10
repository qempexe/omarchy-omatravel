// Process has no default property, so a child object declared inside a Process block
// (a Timer, say) makes the whole file fail to load, and with it the bar widget.
const assert = require("assert")
const fs = require("fs")
const path = require("path")

const files = []
;(function walk(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name)
    if (e.isDirectory()) walk(p)
    else if (p.endsWith(".qml")) files.push(p)
  }
})(path.join(__dirname, "../qml"))

const bad = []
for (const file of files) {
  const lines = fs.readFileSync(file, "utf8").split("\n")
  const stack = []
  lines.forEach((line, i) => {
    const code = line.replace(/"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'/g, '""').replace(/\/\/.*/, "")
    let m = code.match(/^\s*(?:component\s+\w+\s*:\s*)?([A-Z][\w.]*)\s*\{/)
    const top = stack[stack.length - 1]
    if (m && top && top.process && top.depth === stack.length - 1 && !/^\s*[\w.]+\s*:\s*[A-Z]/.test(code))
      bad.push(path.relative(path.join(__dirname, ".."), file) + ":" + (i + 1) + ": " + line.trim())
    for (const ch of code) {
      if (ch === "{") { stack.push({ process: !!m && m[1].split(".").pop() === "Process", depth: stack.length }); m = null }
      else if (ch === "}") stack.pop()
    }
  })
}
assert.deepStrictEqual(bad, [], "child objects inside a Process block:\n" + bad.join("\n"))
console.log("  ok   no Process block declares a child object (" + files.length + " files)")
