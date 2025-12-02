const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn part1(ctx: *Context) ![]const u8 {
    var sum: u64 = 0;
    for (ctx.ranges) |r| {
        var v = r.start;
        while (v <= r.end) : (v += 1) {
            if (isDouble(v)) sum += v;
            if (v == std.math.maxInt(u64)) break; // safety against overflow
        }
    }
    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

pub const Context = struct {
    allocator: Allocator,
    ranges: []const Range,

    pub fn deinit(self: Context) void {
        self.allocator.free(self.ranges);
    }
};

const Range = struct { start: u64, end: u64 };

fn isDouble(n: u64) bool {
    // A number qualifies if its decimal representation length is even and
    // consists of some sequence repeated exactly twice (e.g. 55, 6464, 123123).
    var buf: [32]u8 = undefined; // enough for u64
    const s = std.fmt.bufPrint(&buf, "{d}", .{n}) catch return false;
    const len = s.len;
    if (len < 2 or (len & 1) == 1) return false; // need even length >= 2
    const half = len / 2;
    return std.mem.eql(u8, s[0..half], s[half..]);
}

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);

    var list = try std.ArrayList(Range).initCapacity(allocator, 0);
    defer list.deinit(allocator);

    var it = std.mem.tokenizeAny(u8, in, ",\n");
    while (it.next()) |tok| {
        const dash_idx = std.mem.indexOfScalar(u8, tok, '-').?;
        const lhs = tok[0..dash_idx];
        const rhs = tok[(dash_idx + 1)..];

        const start = try std.fmt.parseInt(u64, lhs, 10);
        const end = try std.fmt.parseInt(u64, rhs, 10);
        try list.append(allocator, .{ .start = start, .end = end });
    }

    ctx.allocator = allocator;
    ctx.ranges = try list.toOwnedSlice(allocator);

    return ctx;
}
