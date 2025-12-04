const std = @import("std");
const Context = @import("part1.zig").Context;
const isAccessible = @import("part1.zig").isAccessible;
const Allocator = std.mem.Allocator;

pub fn part2(ctx: *Context) ![]const u8 {
    var sum: u64 = 0;

    var last_sum: u64 = undefined;
    while (true) {
        for (0..ctx.dims[0]) |r| {
            for (0..ctx.dims[1]) |c| {
                if (try isAccessible(.{ @intCast(r), @intCast(c) }, ctx.grid)) {
                    try ctx.grid.put(.{ @intCast(r), @intCast(c) }, false);
                    sum += 1;
                }
            }
        }

        if (sum == last_sum) break;
        last_sum = sum;
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}
