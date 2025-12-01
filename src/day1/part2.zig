const std = @import("std");
const Context = @import("part1.zig").Context;
const Instruction = @import("part1.zig").Instruction;
const Allocator = std.mem.Allocator;

pub fn part2(ctx: *Context) ![]const u8 {
    var sum: u64 = 0;
    var dial = Dial.init(50);

    for (ctx.instructions) |i| {
        dial.apply(i);
    }
    sum = dial.crossings;

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

pub const Dial = struct {
    // Current dial position in range [0, 99]
    pos: u8,
    // Number of times we wrapped past 0
    crossings: u64,

    pub fn init(start: u8) Dial {
        // Normalize any start to [0,99]
        return .{ .pos = start % 100, .crossings = 0 };
    }

    pub fn apply(self: *Dial, instr: Instruction) void {
        // Use full distance to count multiple crossings; compute final pos with modulo.
        const d = instr.distance; // u32
        switch (instr.turn) {
            .Right => {
                const start = self.pos; // u8
                const total: u32 = @as(u32, start) + d;
                // Number of times we cross past 0 when moving right
                self.crossings += total / 100;
                self.pos = @intCast(total % 100);
            },
            .Left => {
                const start = self.pos; // u8
                // Crossings when moving left are how many times we go below 0.
                // Each 100 steps left guarantees one wrap. Additionally, if the remainder exceeds start, we cross once more.
                const wraps = d / 100;
                const rem: u32 = d % 100;
                self.crossings += wraps;
                if (rem > start) self.crossings += 1;
                // Final position after moving left by d
                const dec: u32 = (rem % 100);
                const widened: u32 = (100 + @as(u32, start) - dec) % 100;
                self.pos = @intCast(widened);
            },
        }
    }
};
