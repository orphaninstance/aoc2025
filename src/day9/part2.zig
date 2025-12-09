const std = @import("std");
const Context = @import("part1.zig").Context;
const Allocator = std.mem.Allocator;

fn Seg(comptime T: type) type {
    return struct { a: T, b: T };
}

fn buildEdges(allocator: Allocator, reds: []const [2]u64) !std.ArrayList(Seg([2]u64)) {
    var edges = try std.ArrayList(Seg([2]u64)).initCapacity(allocator, reds.len);
    var i: usize = 0;
    while (i < reds.len) : (i += 1) {
        const a = reds[i];
        const b = reds[(i + 1) % reds.len];
        try edges.append(allocator, .{ .a = a, .b = b });
    }
    return edges;
}

fn onSegment(p: [2]u64, s: Seg([2]u64)) bool {
    const r1 = s.a[0];
    const c1 = s.a[1];
    const r2 = s.b[0];
    const c2 = s.b[1];
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

fn pointInside(p: [2]u64, edges: []const Seg([2]u64)) bool {
    // Treat boundary as inside
    var e: usize = 0;
    while (e < edges.len) : (e += 1) {
        if (onSegment(p, edges[e])) return true;
    }

    var crossings: usize = 0;
    e = 0;
    while (e < edges.len) : (e += 1) {
        const s = edges[e];
        // Count intersections of a ray to the right with vertical segments
        if (s.a[1] == s.b[1]) continue; // horizontal edge
        const col = s.a[1]; // vertical: same col
        const minr = if (s.a[0] <= s.b[0]) s.a[0] else s.b[0];
        const maxr = if (s.a[0] >= s.b[0]) s.a[0] else s.b[0];
        if (p[0] >= minr and p[0] < maxr and col > p[1]) {
            crossings += 1;
        }
    }
    return (crossings % 2) == 1;
}

pub fn part2(ctx: *Context) ![]const u8 {
    const reds = ctx.red_tiles;
    if (reds.len < 2) return try std.fmt.allocPrint(ctx.allocator, "{d}", .{0});

    // Build edges once
    var edges = try buildEdges(ctx.allocator, reds);
    defer edges.deinit(ctx.allocator);

    var max_area: u64 = 0;
    var best_a: [2]u64 = undefined;
    var best_b: [2]u64 = undefined;

    var i: usize = 0;
    while (i < reds.len) : (i += 1) {
        var j: usize = i + 1;
        while (j < reds.len) : (j += 1) {
            const a = reds[i];
            const b = reds[j];
            if (a[0] == b[0] or a[1] == b[1]) continue; // need opposite corners
            const rmin: u64 = if (a[0] <= b[0]) a[0] else b[0];
            const rmax: u64 = if (a[0] >= b[0]) a[0] else b[0];
            const cmin: u64 = if (a[1] <= b[1]) a[1] else b[1];
            const cmax: u64 = if (a[1] >= b[1]) a[1] else b[1];

            // Quick corner checks: treat boundary as inside
            const c1: [2]u64 = .{ rmin, cmin };
            const c2: [2]u64 = .{ rmin, cmax };
            const c3: [2]u64 = .{ rmax, cmin };
            const c4: [2]u64 = .{ rmax, cmax };
            if (!pointInside(c1, edges.items) or !pointInside(c2, edges.items) or !pointInside(c3, edges.items) or !pointInside(c4, edges.items)) {
                continue;
            }

            // Verify the entire rectangle cells are inside or on boundary
            var ok = true;
            var r: u64 = rmin;
            while (r <= rmax and ok) : (r += 1) {
                var c: u64 = cmin;
                while (c <= cmax) : (c += 1) {
                    if (!pointInside(.{ r, c }, edges.items)) {
                        ok = false;
                        break;
                    }
                }
            }
            if (!ok) continue;

            const area: u64 =
                @as(u64, @intCast(rmax - rmin + 1)) *
                @as(u64, @intCast(cmax - cmin + 1));
            if (area > max_area) {
                max_area = area;
                best_a = a;
                best_b = b;
            }
        }
    }

    // Return just the area as required
    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{max_area});
}
