const std = @import("std");
const Context = @import("part1.zig").Context;
const Range = @import("part1.zig").Range;
const isAccessible = @import("part1.zig").isAccessible;
const Allocator = std.mem.Allocator;

pub fn part2(ctx: *Context) ![]const u8 {
    if (ctx.ranges.len == 0) {
        return try std.fmt.allocPrint(ctx.allocator, "{d}", .{0});
    }

    // Copy and sort ranges by start, then end
    var ranges = try ctx.allocator.alloc(Range, ctx.ranges.len);
    defer ctx.allocator.free(ranges);
    @memcpy(ranges, ctx.ranges);
    std.mem.sort(Range, ranges, {}, struct {
        fn less(_: void, a: Range, b: Range) bool {
            if (a.start == b.start) return a.end < b.end;
            return a.start < b.start;
        }
    }.less);

    // Merge and count unique values (inclusive)
    var total: u64 = 0;
    var cur_start = ranges[0].start;
    var cur_end = ranges[0].end;
    for (ranges[1..]) |r| {
        if (r.start <= cur_end + 1) {
            // Overlapping or adjacent: extend
            if (r.end > cur_end) cur_end = r.end;
        } else {
            // Disjoint: add previous length and start new
            total += (cur_end - cur_start + 1);
            cur_start = r.start;
            cur_end = r.end;
        }
    }
    // Add last merged interval
    total += (cur_end - cur_start + 1);

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{total});
}
