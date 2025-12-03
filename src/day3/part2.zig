const std = @import("std");
const Context = @import("part1.zig").Context;
const Allocator = std.mem.Allocator;

pub fn part2(ctx: *Context) ![]const u8 {
    var total: u64 = 0;
    for (ctx.banks) |b| {
        if (b.len < 12) continue;
        var pos: usize = 0;
        var remaining: usize = 12;
        var val: u64 = 0;
        while (remaining > 0) : (remaining -= 1) {
            const last_idx = b.len - remaining;
            var best_digit: u64 = 0;
            var best_idx: usize = pos;
            var i = pos;
            while (i <= last_idx) : (i += 1) {
                const d = b[i];
                if (d > best_digit) {
                    best_digit = d;
                    best_idx = i;
                    if (best_digit == 9) break;
                }
            }
            val = val * 10 + best_digit;
            pos = best_idx + 1;
        }
        total += val;
    }
    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{total});
}
