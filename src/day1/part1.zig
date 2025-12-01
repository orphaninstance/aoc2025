const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn part1(ctx: *Context) ![]const u8 {
    var sum: u64 = 0;
    var dial = Dial.init(50);
    for (ctx.instructions) |i| {
        dial.apply(i);
        if (dial.pos == 0) {
            sum = sum + 1;
        }
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

pub const Context = struct {
    allocator: Allocator,
    instructions: []const Instruction,

    pub fn deinit(self: Context) void {
        self.allocator.free(self.instructions);
    }
};

const Turn = enum { Left, Right };
pub const Instruction = struct {
    turn: Turn,
    distance: u32,
};

pub const Dial = struct {
    // Current dial position in range [0, 99]
    pos: u8,

    pub fn init(start: u8) Dial {
        // Normalize any start to [0,99]
        return .{ .pos = start % 100 };
    }

    pub fn apply(self: *Dial, instr: Instruction) void {
        const dist_u8: u8 = @intCast(instr.distance % 100);
        switch (instr.turn) {
            .Right => {
                const tmp: u16 = @as(u16, self.pos) + @as(u16, dist_u8);
                self.pos = @intCast(tmp % 100);
            },
            .Left => {
                // Add 100 before modulo to avoid underflow
                const tmp: u16 = (100 + @as(u16, self.pos) - @as(u16, dist_u8));
                self.pos = @intCast(tmp % 100);
            },
        }
    }
};

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);

    var instructions = try std.ArrayList(Instruction).initCapacity(allocator, 0);
    defer instructions.deinit(allocator);

    var lines = std.mem.tokenizeScalar(u8, in, '\n');
    while (lines.next()) |line| {
        const instruction = try parseInstruction(line);
        try instructions.append(allocator, instruction);
    }

    ctx.allocator = allocator;
    ctx.instructions = try instructions.toOwnedSlice(allocator);

    return ctx;
}

fn parseInstruction(line: []const u8) !Instruction {
    const trimmed = std.mem.trim(u8, line, " \t\r\n,");
    if (trimmed.len < 2) return error.BadLine;
    const dir_char = trimmed[0];
    const num_slice = trimmed[1..];
    const dist = try std.fmt.parseInt(u32, num_slice, 10);
    const turn: Turn = switch (dir_char) {
        'L' => .Left,
        'R' => .Right,
        else => return error.BadDirection,
    };

    return .{ .turn = turn, .distance = dist };
}
