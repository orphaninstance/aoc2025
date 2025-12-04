const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn part1(ctx: *Context) ![]const u8 {
    var sum: u64 = 0;

    var iter = ctx.grid.iterator();
    while (iter.next()) |entry| {
        if (try isAccessible(entry.key_ptr.*, ctx.grid)) sum += 1;
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

pub fn isAccessible(rc: [2]isize, grid: std.AutoArrayHashMap([2]isize, bool)) !bool {
    const r, const c = rc;
    const is_true = grid.get(rc).?;
    if (!is_true) return false;

    var neighbors_true: u8 = 0;
    // Check 8 directions
    const drc = [_][2]isize{
        .{ -1, -1 }, .{ -1, 0 }, .{ -1, 1 },
        .{ 0, -1 },  .{ 0, 1 },  .{ 1, -1 },
        .{ 1, 0 },   .{ 1, 1 },
    };
    for (drc) |d| {
        const r2 = r + d[0];
        const c2 = c + d[1];
        if (grid.get(.{ r2, c2 })) |val| {
            if (val) neighbors_true += 1;
        }
    }
    return neighbors_true < 4;
}

pub const Context = struct {
    allocator: Allocator,
    grid: std.AutoArrayHashMap([2]isize, bool),
    dims: [2]usize,

    pub fn deinit(self: *Context) void {
        self.grid.deinit();
    }
};

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;
    ctx.grid = std.AutoArrayHashMap([2]isize, bool).init(allocator);

    var lines = std.mem.tokenizeScalar(u8, in, '\n');
    var row: isize = 0;
    var line_len: usize = undefined;
    while (lines.next()) |line| {
        line_len = line.len;
        for (line, 0..) |char, col| {
            var roll: bool = undefined;
            if (char == '@') {
                roll = true;
            } else {
                roll = false;
            }
            try ctx.grid.put(.{ row, @intCast(col) }, roll);
        }
        row += 1;
    }

    ctx.dims = .{ @intCast(row), line_len };

    return ctx;
}
