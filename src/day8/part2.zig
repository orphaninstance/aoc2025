const std = @import("std");
const Context = @import("part1.zig").Context;
const shortestConnections = @import("part1.zig").shortestConnections;
const Graph = @import("part1.zig").Graph;
const JunctionBox = @import("part1.zig").JunctionBox;
const Allocator = std.mem.Allocator;

pub fn part2(ctx: *Context) ![]const u8 {
    var g = Graph.init(ctx.allocator);
    defer g.deinit();
    for (ctx.all_jbs) |jb| try g.add(jb);

    const last = try connectByShortest(ctx.allocator, &g, ctx.all_jbs);
    defer ctx.allocator.free(last);
    const a = last[0];
    const b = last[1];
    const p = a.x * b.x;
    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{ p });
}

const Edge = struct { i: usize, j: usize, d: f64 };

fn dist(a: JunctionBox, b:JunctionBox) f64 {
    const dx = @as(f64, @floatFromInt(a.x - b.x));
    const dy = @as(f64, @floatFromInt(a.y - b.y));
    const dz = @as(f64, @floatFromInt(a.z - b.z));
    return std.math.sqrt(dx * dx + dy * dy + dz * dz);
}

fn connectByShortest(allocator: Allocator, g: *Graph, jbs: []const JunctionBox) ![]const JunctionBox {
    const n = jbs.len;
    // Union-Find (DSU)
    const uf_parent = try allocator.alloc(usize, n);
    defer allocator.free(uf_parent);
    for (uf_parent, 0..) |*p, i| p.* = i;

    // Build all edges
    var edges = try std.ArrayList(Edge).initCapacity(allocator, 0);
    defer edges.deinit(allocator);
    for (jbs, 0..) |ja, i| {
        var j: usize = i + 1;
        while (j < n) : (j += 1) {
            try edges.append(allocator, .{ .i = i, .j = j, .d = dist(ja, jbs[j]) });
        }
    }
    std.mem.sort(Edge, edges.items, {}, struct {
        fn less(_: void, a: Edge, b: Edge) bool {
            return a.d < b.d;
        }
    }.less);

    var components: usize = n;
    var last_a: JunctionBox = jbs[0];
    var last_b: JunctionBox = jbs[0];
    for (edges.items) |e| {
        const ra = ufFind(uf_parent, e.i);
        const rb = ufFind(uf_parent, e.j);
        if (ra == rb) continue;
        // add undirected edge (both directions)
        try g.addEdge(jbs[e.i], jbs[e.j], @intFromFloat(e.d));
        try g.addEdge(jbs[e.j], jbs[e.i], @intFromFloat(e.d));
        ufUnite(uf_parent, ra, rb);
        components -= 1;
        last_a = jbs[e.i];
        last_b = jbs[e.j];
        if (components == 1) break;
    }

    const out = try allocator.alloc(JunctionBox, 2);
    out[0] = last_a;
    out[1] = last_b;
    return out;
}

fn ufFind(par: []usize, x: usize) usize {
    var v = x;
    while (par[v] != v) : (v = par[v]) {}
    return v;
}

fn ufUnite(par: []usize, a: usize, b: usize) void {
    const ra = ufFind(par, a);
    const rb = ufFind(par, b);
    if (ra != rb) par[ra] = rb;
}
