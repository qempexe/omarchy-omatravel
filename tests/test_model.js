// Run: node tests/test_model.js   (pure logic in Model.js, no Qt needed)
const fs = require("fs"), path = require("path"), assert = require("assert");
const src = fs.readFileSync(path.join(__dirname, "..", "Model.js"), "utf8").replace(".pragma library", "");
const M = new Function(src + `;return {parseStore,sanitize,normalizeDate,countryCode,canonicalCountry,
  continentOf,isSovereign,WORLD_COUNTRIES,haversineKm,pathDistanceKm,visitYears,filterByYear,computeStats,
  formatKm,csvCell,toCsv,toJson,fileSafe,_COUNTRY_TABLE,visitsOf,countryCount,cityCount}`)();

let n = 0;
function t(name, fn) { fn(); n++; console.log("ok -", name); }

const store = M.parseStore(JSON.stringify({
  activeProfile: "default",
  profiles: { default: {
    countries: {
      "Spain":   { cities: ["Barcelona", "Madrid"], city_meta: { Barcelona: { visits: ["2019-05", "2023-08-02"] }, Madrid: { visits: ["2021"] } } },
      "Japan":   { cities: ["Tokyo"], city_meta: { Tokyo: { visits: ["2022-04"] } } },
      "Canada":  { cities: ["Toronto"], city_meta: {} },
      "Hong Kong": { cities: [], city_meta: {} }
    },
    wishlist: { Peru: ["Cusco"] }
  } }
}));

t("every country has a continent, 195 sovereign", () => {
  let sov = 0;
  for (const r of M._COUNTRY_TABLE) {
    const name = r.split("|")[1];
    assert.ok(M.continentOf(name), name + " has no continent");
    if (M.isSovereign(name)) sov++;
  }
  assert.strictEqual(sov, M.WORLD_COUNTRIES);
  assert.strictEqual(M.continentOf("uk"), "Europe");
  assert.strictEqual(M.continentOf("Tuvalu"), "Oceania");
  assert.strictEqual(M.isSovereign("Hong Kong"), false);
  assert.strictEqual(M.isSovereign("Tuvalu"), true);
});

t("haversine: Brussels -> New York ~ 5,880 km", () => {
  const d = M.haversineKm(50.85, 4.35, 40.71, -74.0);
  assert.ok(d > 5800 && d < 5950, d);
  assert.strictEqual(M.haversineKm(10, 10, 10, 10), 0);
  const half = M.haversineKm(0, 0, 0, 180);
  assert.ok(Math.abs(half - Math.PI * 6371.0088) < 1);
});

t("path distance adds up the hops", () => {
  const p = [{ lat: 0, lng: 0 }, { lat: 0, lng: 90 }, { lat: 0, lng: 180 }];
  assert.ok(Math.abs(M.pathDistanceKm(p) - Math.PI * 6371.0088) < 1);
  assert.strictEqual(M.pathDistanceKm([]), 0);
  assert.strictEqual(M.pathDistanceKm([{ lat: 1, lng: 1 }]), 0);
});

t("visit years are unique and sorted", () => {
  assert.deepStrictEqual(M.visitYears(store), [2019, 2021, 2022, 2023]);
});

const pts = [
  { lat: 41.4, lng: 2.2, name: "Barcelona", country: "Spain", kind: "visited", visits: ["2019-05", "2023-08-02"], visitCount: 2, date: "2023-08-02" },
  { lat: 40.4, lng: -3.7, name: "Madrid", country: "Spain", kind: "visited", visits: ["2021"], visitCount: 1, date: "2021" },
  { lat: 35.7, lng: 139.7, name: "Tokyo", country: "Japan", kind: "visited", visits: ["2022-04"], visitCount: 1, date: "2022-04" },
  { lat: 43.7, lng: -79.4, name: "Toronto", country: "Canada", kind: "visited", visits: [], visitCount: 1, date: "" },
  { lat: -13.5, lng: -72.0, name: "Cusco", country: "Peru", kind: "wishlist", visits: [], visitCount: 0, date: "" }
];

t("year filter: 0 keeps everything, same array", () => {
  assert.strictEqual(M.filterByYear(pts, 0), pts);
});
t("year filter: 2020 keeps Barcelona (1 visit), undated Toronto and the wishlist", () => {
  const f = M.filterByYear(pts, 2020);
  assert.deepStrictEqual(f.map(p => p.name), ["Barcelona", "Toronto", "Cusco"]);
  const b = f[0];
  assert.deepStrictEqual(b.visits, ["2019-05"]);
  assert.strictEqual(b.visitCount, 1);
  assert.strictEqual(b.date, "2019-05");
  assert.strictEqual(pts[0].visits.length, 2, "input must not be mutated");
});
t("year filter: 2022 includes the 2021 and 2022 visits", () => {
  assert.deepStrictEqual(M.filterByYear(pts, 2022).map(p => p.name), ["Barcelona", "Madrid", "Tokyo", "Toronto", "Cusco"]);
  assert.strictEqual(M.filterByYear(pts, 1990).filter(p => p.kind === "visited" && p.visits.length).length, 0);
});

t("stats", () => {
  const path = [pts[0], pts[1], pts[2], pts[0]];
  const s = M.computeStats(store, path);
  assert.strictEqual(s.countries, 4);
  assert.strictEqual(s.sovereign, 3);                       // Hong Kong is not
  assert.strictEqual(s.worldPercent, 1.5);
  assert.deepStrictEqual(s.continents, ["Asia", "Europe", "North America"]);
  assert.strictEqual(s.cities, 4);
  assert.strictEqual(s.visits, 4);
  assert.strictEqual(s.datedCities, 3);
  assert.strictEqual(s.first, "2019-05");
  assert.strictEqual(s.last, "2023-08-02");
  assert.deepStrictEqual(s.topCity, { name: "Barcelona", country: "Spain", count: 2 });
  assert.deepStrictEqual(s.years.map(y => y.year), [2019, 2021, 2022, 2023]);
  assert.strictEqual(s.busiestYear.trips, 1);
  assert.ok(s.distanceKm > 20000 && s.laps > 0.5);
});
t("stats on an empty store don't crash", () => {
  const s = M.computeStats(M.parseStore(""), []);
  assert.strictEqual(s.countries, 0);
  assert.strictEqual(s.distanceKm, 0);
  assert.strictEqual(s.topCity, null);
  assert.strictEqual(s.busiestYear, null);
  assert.deepStrictEqual(s.continents, []);
});

t("formatKm", () => {
  assert.strictEqual(M.formatKm(0), "0 km");
  assert.strictEqual(M.formatKm(999.6), "1,000 km");
  assert.strictEqual(M.formatKm(1234567), "1,234,567 km");
});

t("csv cells are quoted and formula-safe", () => {
  assert.strictEqual(M.csvCell("plain"), "plain");
  assert.strictEqual(M.csvCell("a,b"), '"a,b"');
  assert.strictEqual(M.csvCell('say "hi"'), '"say ""hi"""');
  assert.strictEqual(M.csvCell("=SUM(A1)"), "'=SUM(A1)");
  assert.strictEqual(M.csvCell(null), "");
  assert.strictEqual(M.csvCell(41.4), "41.4");
});
t("csv export", () => {
  const csv = M.toCsv(store, pts).trim().split("\n");
  assert.strictEqual(csv[0], "country,city,status,visits,lat,lng");
  assert.ok(csv.includes("Spain,Barcelona,visited,2019-05;2023-08-02,41.4,2.2"));
  assert.ok(csv.includes("Canada,Toronto,visited,,43.7,-79.4"));
  assert.ok(csv.includes("Hong Kong,,visited,,,"));
  assert.ok(csv.includes("Peru,Cusco,wishlist,,-13.5,-72"));
  assert.strictEqual(csv.length, 1 + 4 + 1 + 1);
  // a city without a pin still exports, with empty coordinates
  assert.ok(M.toCsv(store, []).includes("Japan,Tokyo,visited,2022-04,,\n"));
});
t("json export", () => {
  const j = JSON.parse(M.toJson(store, "2026-10-07"));
  assert.strictEqual(j.app, "omatravel");
  assert.strictEqual(j.profile, "default");
  assert.strictEqual(j.exportedAt, "2026-10-07");
  assert.deepStrictEqual(j.wishlist, { Peru: ["Cusco"] });
  assert.ok(j.countries.Spain.city_meta.Barcelona.visits.length === 2);
});
t("file-safe names", () => {
  assert.strictEqual(M.fileSafe("My trips!"), "My_trips_");
  assert.strictEqual(M.fileSafe("../../etc"), "_etc");
  assert.strictEqual(M.fileSafe(""), "profile");
});

t("existing behaviour: dates and counts", () => {
  assert.strictEqual(M.normalizeDate("2019-5"), "2019-05");
  assert.strictEqual(M.normalizeDate("nope"), null);
  assert.strictEqual(M.countryCount(store), 4);
  assert.strictEqual(M.cityCount(store), 4);
});

console.log("\n" + n + " tests passed");
