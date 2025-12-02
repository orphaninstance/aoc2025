const std = @import("std");
const Context = @import("part1.zig").Context;
const Range = @import("part1.zig").Range;
const Allocator = std.mem.Allocator;

pub fn part2(ctx: *Context) ![]const u8 {
    var sum: u64 = 0;
    for (ctx.ranges) |r| {
        var v = r.start;
        while (v <= r.end) : (v += 1) {
            if (isAtLeastDouble(v)) sum += v;
            if (v == std.math.maxInt(u64)) break; // safety against overflow
        }
    }
    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

fn isAtLeastDouble(n: u64) bool {
    // True if decimal representation consists of a shorter substring
    // repeated at least twice (k >= 2). Example: 55, 6464, 123123, 777777.
    var buf: [32]u8 = undefined;
    const s = std.fmt.bufPrint(&buf, "{d}", .{n}) catch return false;
    const len = s.len;
    if (len < 2) return false; // Need at least two digits

    // Try every possible pattern length up to half of total length.
    // Pattern length must divide the total length.
    var pattern_len: usize = 1;
    while (pattern_len <= len / 2) : (pattern_len += 1) {
        if (len % pattern_len != 0) continue;
        const repeats = len / pattern_len;
        if (repeats < 2) continue; // Need at least two repeats
        const pattern = s[0..pattern_len];
        var i: usize = pattern_len;
        while (i < len) : (i += pattern_len) {
            if (!std.mem.eql(u8, pattern, s[i .. i + pattern_len])) break;
        }
        if (i == len) return true; // All blocks matched
    }
    return false;
}
