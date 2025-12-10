const std = @import("std");
const Context = @import("part1.zig").Context;
const Allocator = std.mem.Allocator;

// fn Seg(comptime T: type) type {
//     return struct { a: T, b: T };
// }

// fn buildEdges(allocator: Allocator, reds: []const [2]u64) !std.ArrayList(Seg([2]u64)) {
//     var edges = try std.ArrayList(Seg([2]u64)).initCapacity(allocator, reds.len);
//     var i: usize = 0;
//     while (i < reds.len) : (i += 1) {
//         const a = reds[i];
//         const b = reds[(i + 1) % reds.len];
//         try edges.append(allocator, .{ .a = a, .b = b });
//     }
//     return edges;
// }

// fn onSegment(p: [2]u64, s: Seg([2]u64)) bool {
//     const r1 = s.a[0];
//     const c1 = s.a[1];
//     const r2 = s.b[0];
//     const c2 = s.b[1];
//     if (r1 == r2) {
//         if (p[0] != r1) return false;
//         const minc = if (c1 <= c2) c1 else c2;
//         const maxc = if (c1 >= c2) c1 else c2;
//         return p[1] >= minc and p[1] <= maxc;
//     } else if (c1 == c2) {
//         if (p[1] != c1) return false;
//         const minr = if (r1 <= r2) r1 else r2;
//         const maxr = if (r1 >= r2) r1 else r2;
//         return p[0] >= minr and p[0] <= maxr;
//     }
//     return false;
// }

// fn pointInside(p: [2]u64, edges: []const Seg([2]u64)) bool {
//     // Treat boundary as inside
//     var e: usize = 0;
//     while (e < edges.len) : (e += 1) {
//         if (onSegment(p, edges[e])) return true;
//     }

//     var crossings: usize = 0;
//     e = 0;
//     while (e < edges.len) : (e += 1) {
//         const s = edges[e];
//         // Count intersections of a ray to the right with vertical segments
//         if (s.a[1] == s.b[1]) continue; // horizontal edge
//         const col = s.a[1]; // vertical: same col
//         const minr = if (s.a[0] <= s.b[0]) s.a[0] else s.b[0];
//         const maxr = if (s.a[0] >= s.b[0]) s.a[0] else s.b[0];
//         if (p[0] >= minr and p[0] < maxr and col > p[1]) {
//             crossings += 1;
//         }
//     }
//     return (crossings % 2) == 1;
// }

// Helper: check if point p lies on segment (x1,y1)-(x2,y2) assuming axis-aligned edges
fn onSegment(p: [2]u64, pa: [2]u64, pb: [2]u64) bool {
    const r1 = pa[0];
    const c1 = pa[1];
    const r2 = pb[0];
    const c2 = pb[1];
    if (r1 == r2) {
        if (p[0] != r1) return false;
        const minc = if (c1 <= c2) c1 else c2;
        const maxc = if (c1 >= c2) c1 else c2;
        return p[1] >= minc and p[1] <= maxc;
    } else if (c1 == c2) {
        if (p[1] != c1) return false;
        const minr = if (r1 <= r2) r1 else r2;
        const maxr = if (r1 >= r2) r1 else r2;
        return p[0] >= minr and p[0] <= maxr;
    }
    return false;
}

// Ray casting: treat boundary as inside
fn pointInside(p: [2]u64, verts: []const [2]u64) bool {
    // Boundary check
    var i: usize = 0;
    while (i < verts.len) : (i += 1) {
        if (verts[i][0] == p[0] and verts[i][1] == p[1]) return true; // exact vertex
        const va = verts[i];
        const vb = verts[(i + 1) % verts.len];
        if (onSegment(p, va, vb)) return true;
    }

    var crossings: usize = 0;
    i = 0;
    while (i < verts.len) : (i += 1) {
        const va = verts[i];
        const vb = verts[(i + 1) % verts.len];
        // Standard ray casting to the right using integer-safe math
        const ri: i64 = @intCast(va[0]);
        const rj: i64 = @intCast(vb[0]);
        const ci: i64 = @intCast(va[1]);
        const cj: i64 = @intCast(vb[1]);
        const ry: i64 = @intCast(p[0]);
        const px: i64 = @intCast(p[1]);

        const dy = rj - ri;
        if (dy == 0) continue; // horizontal edge

        // Check if the ray at row 'ry' intersects the segment (ri,ci)-(rj,cj)
        if (((ry >= ri) != (ry >= rj))) {
            const num = (cj - ci) * (ry - ri);
            const x_int = ci + @divFloor(num, dy);
            if (px < x_int) crossings += 1;
        }
    }
    return (crossings % 2) == 1;
}

fn isInsidePolygon(a: [2]u64, b: [2]u64, reds: []const [2]u64) bool {
    // Opposite corners define rectangle bounds
    const rmin: u64 = if (a[0] <= b[0]) a[0] else b[0];
    const rmax: u64 = if (a[0] >= b[0]) a[0] else b[0];
    const cmin: u64 = if (a[1] <= b[1]) a[1] else b[1];
    const cmax: u64 = if (a[1] >= b[1]) a[1] else b[1];

    // Corner-only check for orthogonal polygons: sufficient for filled interior
    return pointInside(.{ rmin, cmin }, reds) and
        pointInside(.{ rmin, cmax }, reds) and
        pointInside(.{ rmax, cmin }, reds) and
        pointInside(.{ rmax, cmax }, reds);
}

pub fn part2(ctx: *Context) ![]const u8 {
    var max_area: u64 = 0;
    const n = ctx.red_tiles.len;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        var j: usize = i + 1;
        while (j < n) : (j += 1) {
            const a = ctx.red_tiles[i];
            const b = ctx.red_tiles[j];
            const dr = if (a[0] >= b[0]) a[0] - b[0] + 1 else b[0] - a[0] + 1;
            const dc = if (a[1] >= b[1]) a[1] - b[1] + 1 else b[1] - a[1] + 1;
            const area = dr * dc;
            if (area > max_area and isInsidePolygon(a, b, ctx.red_tiles)) {
                max_area = area;
            }
        }
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{max_area});
}

test "isInsidePolygon example rectangle inside" {
    const reds: []const [2]u64 = &[_][2]u64{
        .{ 7, 1 },
        .{ 11, 1 },
        .{ 11, 7 },
        .{ 9, 7 },
        .{ 9, 5 },
        .{ 2, 5 },
        .{ 2, 3 },
        .{ 7, 3 },
    };
    const a: [2]u64 = .{ 9, 5 };
    const b: [2]u64 = .{ 2, 3 };
    // Check corners individually to ensure boundary handling
    try std.testing.expect(pointInside(.{ 2, 3 }, reds));
    try std.testing.expect(pointInside(.{ 2, 5 }, reds));
    try std.testing.expect(pointInside(.{ 9, 3 }, reds));
    try std.testing.expect(pointInside(.{ 9, 5 }, reds));
    try std.testing.expect(isInsidePolygon(a, b, reds));
}

test "isInsidePolygon rectangle partially outside returns false" {
    const reds: []const [2]u64 = &[_][2]u64{
        .{ 7, 1 },
        .{ 11, 1 },
        .{ 11, 7 },
        .{ 9, 7 },
        .{ 9, 5 },
        .{ 2, 5 },
        .{ 2, 3 },
        .{ 7, 3 },
    };
    const a: [2]u64 = .{ 12, 6 };
    const b: [2]u64 = .{ 10, 4 };
    try std.testing.expect(!isInsidePolygon(a, b, reds));
}
