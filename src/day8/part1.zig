const std = @import("std");
const Allocator = std.mem.Allocator;
const graph = @import("graph.zig");

pub fn part1(ctx: *Context) ![]const u8 {
    const conns = try shortestConnections(ctx.allocator, ctx.all_jbs, 1000);
    defer ctx.allocator.free(conns);
    var g = Graph.init(ctx.allocator);
    defer g.deinit();
    for (conns) |c| {
        try g.add(ctx.all_jbs[c.a]);
        try g.add(ctx.all_jbs[c.b]);
        try g.addEdge(ctx.all_jbs[c.a], ctx.all_jbs[c.b], 1);
        try g.addEdge(ctx.all_jbs[c.b], ctx.all_jbs[c.a], 1);
    }

    const n_list = try largestThreeConnectedSizes(ctx.allocator, g);
    const product = n_list[0] * n_list[1] * n_list[2];
    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{product});
}

pub const Context = struct {
    allocator: Allocator,
    all_jbs: []const JunctionBox,

    pub fn deinit(self: *Context) void {
        self.allocator.free(self.all_jbs);
    }
};

pub const JunctionBox = struct {
    x: i64,
    y: i64,
    z: i64,
};

// Hash/equality context for JunctionBox to use with DirectedGraph
const JunctionContext = struct {
    pub fn hash(_: JunctionContext, jb: JunctionBox) u64 {
        // Combine coordinates into a 64-bit hash using std.hash
        var h = std.hash.Wyhash.init(0);
        h.update(std.mem.asBytes(&jb.x));
        h.update(std.mem.asBytes(&jb.y));
        h.update(std.mem.asBytes(&jb.z));
        return h.final();
    }

    pub fn eql(_: JunctionContext, a: JunctionBox, b: JunctionBox) bool {
        return a.x == b.x and a.y == b.y and a.z == b.z;
    }
};

pub const Graph = graph.DirectedGraph(JunctionBox, JunctionContext);

const Connection = struct { a: usize, b: usize, len: f64 };

fn dist(a: JunctionBox, b: JunctionBox) f64 {
    const dx = @as(f64, @floatFromInt(a.x - b.x));
    const dy = @as(f64, @floatFromInt(a.y - b.y));
    const dz = @as(f64, @floatFromInt(a.z - b.z));
    return std.math.sqrt(dx * dx + dy * dy + dz * dz);
}

pub fn shortestConnections(allocator: Allocator, jbs: []const JunctionBox, k: usize) ![]const Connection {
    var list = try std.ArrayList(Connection).initCapacity(allocator, 0);
    defer list.deinit(allocator);
    for (jbs, 0..) |ja, i| {
        var j: usize = i + 1;
        while (j < jbs.len) : (j += 1) {
            const d = dist(ja, jbs[j]);
            try list.append(allocator, .{ .a = i, .b = j, .len = d });
        }
    }
    std.mem.sort(Connection, list.items, {}, struct {
        fn less(_: void, a: Connection, b: Connection) bool { return a.len < b.len; }
    }.less);
    const n = if (list.items.len < k) list.items.len else k;
    const out = try allocator.alloc(Connection, n);
    std.mem.copyForwards(Connection, out, list.items[0..n]);
    return out;
}

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;
    var all_jbs = try std.ArrayList(JunctionBox).initCapacity(allocator, 0);
    defer all_jbs.deinit(allocator);

    var lines = std.mem.tokenizeScalar(u8, in, '\n');
    while (lines.next()) |line| {
        var toks = std.mem.tokenizeScalar(u8, line, ',');
        const x = try std.fmt.parseInt(i64, toks.next().?, 10);
        const y = try std.fmt.parseInt(i64, toks.next().?, 10);
        const z = try std.fmt.parseInt(i64, toks.next().?, 10);
        try all_jbs.append(allocator, JunctionBox{ .x = x, .y = y, .z = z });
    }

    ctx.all_jbs = try all_jbs.toOwnedSlice(allocator);

    return ctx;
}

fn largestThreeConnectedSizes(allocator: std.mem.Allocator, g: Graph) ![3]usize {
    var visited = std.AutoHashMap(u64, void).init(allocator);
    defer visited.deinit();

    var it = g.values.iterator(); // iterate all vertices by hash
    var sizes = try std.ArrayList(usize).initCapacity(allocator, g.countVertices());
    defer sizes.deinit(allocator);

    // DFS stack
    var stack = try std.ArrayList(u64).initCapacity(allocator, 0);
    defer stack.deinit(allocator);

    while (it.next()) |kv| {
        const h = kv.key_ptr.*;
        if (visited.contains(h)) continue;

        var comp_size: usize = 0;
        try stack.append(allocator, h);
        try visited.put(h, {});

        while (stack.pop()) |cur| {
            comp_size += 1;
            var neigh = try neighborsUnion(g, cur, allocator);
            defer neigh.deinit(allocator);
            for (neigh.items) |nh| {
                if (!visited.contains(nh)) {
                    try visited.put(nh, {});
                    try stack.append(allocator, nh);
                }
            }
        }

        try sizes.append(allocator, comp_size);
    }

    // Sort descending and pick top 3
    std.mem.sort(usize, sizes.items, {}, struct {
        fn less(_: void, a: usize, b: usize) bool { return a > b; }
    }.less);

    var out: [3]usize = .{0, 0, 0};
    const n = if (sizes.items.len < 3) sizes.items.len else 3;
    for (0..n) |i| out[i] = sizes.items[i];
    return out;
}

// Helper to get undirected neighbors (union of out and in)
fn neighborsUnion(g: Graph, h: u64, alloc: std.mem.Allocator) !std.ArrayList(u64) {
    var neigh = try std.ArrayList(u64).initCapacity(alloc, 0);
    // add out-neighbors
    if (g.adjOut.getPtr(h)) |mout| {
        var ki = mout.keyIterator();
        while (ki.next()) |k| try neigh.append(alloc, k.*);
    }
    // add in-neighbors
    if (g.adjIn.getPtr(h)) |min| {
        var ki = min.keyIterator();
        while (ki.next()) |k| try neigh.append(alloc, k.*);
    }
    // optional: dedup by sorting or hash set if needed; usually fine if graph doesn't have parallel edges
    return neigh;
}
