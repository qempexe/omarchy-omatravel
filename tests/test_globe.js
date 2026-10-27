// The globe only looks at the places in the cells around the middle of the view
// (js/GlobeProjection.js visibleRows). Checked against every place in the biggest band,
// for views all over the world and at every zoom: whatever is on screen is never left
// out, only places beyond what a cell can hold at that size.
// run: node tests/test_globe.js
const fs = require("fs"), path = require("path"), vm = require("vm"), assert = require("assert");
const root = path.join(__dirname, "..");
const ctx = {};
vm.createContext(ctx);
vm.runInContext(fs.readFileSync(path.join(root, "qml/js/GlobeProjection.js"), "utf8").replace(".pragma library", ""), ctx);
const band = JSON.parse(fs.readFileSync(path.join(root, "data/layers/z3.json"), "utf8"));
const cells = ctx.buildCells(band);
const n = band.lat.length;

// each place's rank in its cell, busiest first
const rank = new Int32Array(n);
for (let c = 0; c < cells.start.length - 1; c++)
    for (let k = cells.start[c]; k < cells.start[c + 1]; k++) rank[cells.rows[k]] = k - cells.start[c];

let seed = 7;
const rnd = () => (seed = (seed * 1103515245 + 12345) % 2147483648) / 2147483648;
const w = 700, h = 600, cx = w / 2, cy = h / 2;
let views = 0;
for (const zoom of [1, 1.5, 3, 6, 12, 25, 40]) {
    for (let v = 0; v < 12; v++) {
        const yaw = (rnd() * 2 - 1) * Math.PI, pitch = (rnd() * 2 - 1) * 1.5;
        const R = Math.min(w, h) * 0.46 * zoom;
        const got = new Set(ctx.visibleRows(cells, yaw, pitch, cx, cy, R));
        const perCell = Math.max(2, Math.ceil((R * Math.PI / 180) ** 2 / 400) + 1);
        const P = ctx.makeProjector(yaw, pitch, cx, cy, R);
        for (let i = 0; i < n; i++) {
            const z = P(band.lat[i], band.lng[i]);
            if (z < 0.12 || P.x < 4 || P.x > w - 4 || P.y < 8 || P.y > h - 4) continue;
            if (rank[i] >= perCell) continue;
            assert.ok(got.has(i), `zoom ${zoom}, view ${v}: ${band.name[i]} is on screen but was left out`);
        }
        const list = ctx.visibleRows(cells, yaw, pitch, cx, cy, R);
        for (let k = 1; k < list.length; k++) assert.ok(list[k - 1] < list[k], "not busiest first");
        views++;
    }
}
// every place is in exactly one cell
assert.strictEqual(cells.rows.length, n);
assert.strictEqual(new Set(cells.rows).size, n);
console.log("globe tests: ok (" + views + " views)");
