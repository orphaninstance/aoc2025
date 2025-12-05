const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn part1(ctx: *Context) ![]const u8 {
    var sum: u64 = 0;

    for (ctx.ingredients) |i| {
        for (ctx.ranges) |r| {
            if (i >= r.start and i <= r.end) {
                sum += 1;
                break;
            }
        }
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

pub const Context = struct {
    allocator: Allocator,
    ranges: []const Range,
    ingredients: []const u64,

    pub fn deinit(self: *Context) void {
        self.allocator.free(self.ranges);
        self.allocator.free(self.ingredients);
    }
};

pub const Range = struct { start: u64, end: u64 };

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;
    var ranges = try std.ArrayList(Range).initCapacity(allocator, 0);
    defer ranges.deinit(allocator);
    var ingredients = try std.ArrayList(u64).initCapacity(allocator, 0);
    defer ingredients.deinit(allocator);

    var parts = std.mem.tokenizeSequence(u8, in, "\n\n");

    const p1 = parts.next().?;
    var range_iter = std.mem.tokenizeScalar(u8, p1, '\n');
    while (range_iter.next()) |r| {
        var xs = std.mem.tokenizeScalar(u8, r, '-');
        const start = try std.fmt.parseInt(u64, xs.next().?, 10);
        const end = try std.fmt.parseInt(u64, xs.next().?, 10);
        const range = Range{ .start = start, .end = end };
        try ranges.append(allocator, range);
    }

    const p2 = parts.next().?;
    var ingred_iter = std.mem.tokenizeScalar(u8, p2, '\n');
    while (ingred_iter.next()) |i| {
        const n = try std.fmt.parseInt(u64, i, 10);
        try ingredients.append(allocator, n);
    }

    ctx.ranges = try ranges.toOwnedSlice(allocator);
    ctx.ingredients = try ingredients.toOwnedSlice(allocator);

    return ctx;
}
