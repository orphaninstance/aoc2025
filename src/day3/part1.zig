const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn part1(ctx: *Context) ![]const u8 {
    var total: u64 = 0;
    for (ctx.banks) |b| {
            if (b.len < 2) continue;
            var pos: usize = 0;
            var remaining: usize = 2;
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

pub const Context = struct {
    allocator: Allocator,
    banks: []const []const u64,

    pub fn deinit(self: Context) void {
        for (self.banks) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.banks);
    }
};

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);

    var list = try std.ArrayList([]u64).initCapacity(allocator, 0);
    defer list.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, in, '\n');
    while (it.next()) |tok| {
        var line = try std.ArrayList(u64).initCapacity(allocator, 0);
        defer line.deinit(allocator);
        for (tok) |byte| {
            // Parse each single-digit char into a u64
            const s = &[_]u8{byte};
            const i = try std.fmt.parseInt(u64, s, 10);
            try line.append(allocator, i);
        }
        const owned = try line.toOwnedSlice(allocator);
        try list.append(allocator, owned);
    }

    ctx.allocator = allocator;
    ctx.banks = try list.toOwnedSlice(allocator);

    return ctx;
}
