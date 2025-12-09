const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn part1(ctx: *Context) ![]const u8 {
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
            if (area > max_area) {
                max_area = area;
            }
        }
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{max_area});
}

pub const Context = struct {
    allocator: Allocator,
    red_tiles: []const [2]u64,

    pub fn deinit(self: *Context) void {
        self.allocator.free(self.red_tiles);
    }
};

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;
    var red_tiles = try std.ArrayList([2]u64).initCapacity(allocator, 0);
    defer red_tiles.deinit(allocator);

    var lines = std.mem.tokenizeScalar(u8, in, '\n');
    while (lines.next()) |line| {
        var toks = std.mem.tokenizeScalar(u8, line, ',');
        const row = try std.fmt.parseInt(usize, toks.next().?, 10);
        const col = try std.fmt.parseInt(usize, toks.next().?, 10);
        try red_tiles.append(allocator, .{ row, col });
    }

    ctx.red_tiles = try red_tiles.toOwnedSlice(allocator);

    return ctx;
}
