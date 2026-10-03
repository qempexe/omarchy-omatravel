.pragma library

// Orthographic globe maths. Conventions (shared with shaders/globe.frag):
//   world vec : x = cos(lat)·sin(lng), y = sin(lat), z = cos(lat)·cos(lng)
//   view      : yaw about Y, then pitch about X;  centre of screen = (lat = pitch, lng = −yaw)
//   screen    : x right, y up; visible when z > 0

var PI = Math.PI;
var D2R = PI / 180.0;

function latLngToVec(lat, lng) {
    var la = lat * D2R, lo = lng * D2R;
    return { x: Math.cos(la) * Math.sin(lo), y: Math.sin(la), z: Math.cos(la) * Math.cos(lo) };
}

function rotate(v, yaw, pitch) {
    var cy = Math.cos(yaw), sy = Math.sin(yaw);
    var cp = Math.cos(pitch), sp = Math.sin(pitch);
    var x1 = cy * v.x + sy * v.z;
    var z1 = -sy * v.x + cy * v.z;
    return { x: x1, y: cp * v.y - sp * z1, z: sp * v.y + cp * z1 };
}

function project(lat, lng, yaw, pitch, cx, cy, radius) {
    var r = rotate(latLngToVec(lat, lng), yaw, pitch);
    if (r.z <= 0.0) return { visible: false, x: 0, y: 0, scale: 0 };
    return { visible: true, x: cx + r.x * radius, y: cy - r.y * radius, scale: r.z };
}

// Allocation-free projector for hot loops. Call p(lat, lng) → z (depth; > 0 is
// visible) and read p.x / p.y (screen px).
function makeProjector(yaw, pitch, cx, cy, radius) {
    var cy_ = Math.cos(yaw), sy = Math.sin(yaw), cp = Math.cos(pitch), sp = Math.sin(pitch);
    var f = function(lat, lng) {
        var la = lat * D2R, lo = lng * D2R, cl = Math.cos(la);
        var x = cl * Math.sin(lo), y = Math.sin(la), z = cl * Math.cos(lo);
        var x1 = cy_ * x + sy * z, z1 = -sy * x + cy_ * z;
        var y2 = cp * y - sp * z1, z2 = sp * y + cp * z1;
        f.x = cx + x1 * radius;
        f.y = cy - y2 * radius;
        return z2;
    };
    f.x = 0; f.y = 0;
    return f;
}

// Angular distance (radians) between two lat/lng points.
function angleBetween(lat1, lng1, lat2, lng2) {
    var a = latLngToVec(lat1, lng1), b = latLngToVec(lat2, lng2);
    var d = a.x * b.x + a.y * b.y + a.z * b.z;
    return Math.acos(Math.max(-1, Math.min(1, d)));
}

// Points along the great circle from A to B (inclusive), at most `maxStepDeg` apart.
function greatCircle(lat1, lng1, lat2, lng2, maxStepDeg) {
    var a = latLngToVec(lat1, lng1), b = latLngToVec(lat2, lng2);
    var dot = Math.max(-1, Math.min(1, a.x * b.x + a.y * b.y + a.z * b.z));
    var om = Math.acos(dot);
    var n = Math.max(1, Math.min(96, Math.ceil(om / (maxStepDeg * D2R))));
    var out = [];
    var so = Math.sin(om);
    for (var i = 0; i <= n; i++) {
        var t = i / n, k1, k2;
        if (so < 1e-6) { k1 = 1 - t; k2 = t; }
        else { k1 = Math.sin((1 - t) * om) / so; k2 = Math.sin(t * om) / so; }
        var x = k1 * a.x + k2 * b.x, y = k1 * a.y + k2 * b.y, z = k1 * a.z + k2 * b.z;
        out.push({ lat: Math.asin(Math.max(-1, Math.min(1, y))) / D2R, lng: Math.atan2(x, z) / D2R });
    }
    return out;
}
