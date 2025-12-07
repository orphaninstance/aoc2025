const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn part1(ctx: *Context) ![]const u8 {
    var manifold = try ctx.manifold.clone();
    defer manifold.deinit();
    try traverse(&manifold, ctx.start);
    const sum = countSplits(manifold, ctx.dims);

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

pub const Context = struct {
    allocator: Allocator,
    manifold: std.AutoArrayHashMap([2]isize, u8),
    dims: [2]isize,
    start: [2]isize,

    pub fn deinit(self: *Context) void {
        self.manifold.deinit();
    }
};

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;
    var manifold = std.AutoArrayHashMap([2]isize, u8).init(allocator);
    var start: [2]isize = undefined;

    var lines = std.mem.tokenizeScalar(u8, in, '\n');

    var row: isize = 0;
    var line_len: isize = undefined;
    while (lines.next()) |line| {
        line_len = @intCast(line.len);
        for (line, 0..) |c, col| {
            try manifold.put(.{ row, @intCast(col) }, c);
            if (c == 'S') start = .{ row, @intCast(col) };
        }
        row += 1;
    }

    ctx.manifold = manifold;
    ctx.dims = .{ row, line_len };
    ctx.start = start;

    return ctx;
}

fn traverse(manifold: *std.AutoArrayHashMap([2]isize, u8), start: [2]isize) !void {
    const m_curr = manifold.get(start);
    if (m_curr == null) {
        return;
    }

    const curr = m_curr.?;
    if (curr == '|') {
        return;
    } else if (curr == '^') {
        try traverse(manifold, .{ start[0], start[1] - 1 });
        try traverse(manifold, .{ start[0], start[1] + 1 });
    } else {
        try manifold.put(start, '|');
        try traverse(manifold, .{ start[0] + 1, start[1] });
    }
}

fn countSplits(manifold: std.AutoArrayHashMap([2]isize, u8), dims: [2]isize) u64 {
    var sum: u64 = 0;
    for (0..@intCast(dims[0])) |row| {
        for (0..@intCast(dims[1])) |col| {
            if (manifold.get(.{ @intCast(row), @intCast(col) }) == '^' and
                manifold.get(.{ @intCast(row - 1), @intCast(col) }) == '|')
            {
                sum += 1;
            }
        }
    }

    return sum;
}

pub fn printManifold(manifold: std.AutoArrayHashMap([2]isize, u8), dims: [2]isize) void {
    for (0..@intCast(dims[0])) |row| {
        for (0..@intCast(dims[1])) |col| {
            const ch_opt = manifold.get(.{ @intCast(row), @intCast(col) });
            const ch: u8 = ch_opt orelse ' ';
            std.debug.print("{c}", .{ch});
        }
        std.debug.print("\n", .{});
    }
}
