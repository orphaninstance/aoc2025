const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn part1(ctx: *Context) ![]const u8 {
    var sum: u64 = 0;
    for (ctx.problems) |p| {
        var x = p.operands[0];
        for (p.operands[1..]) |n| {
            try switch (p.operation) {
                '+' => x += n,
                '*' => x *= n,
                else => error.InvalidOperand,
            };
        }
        sum += x;
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

pub const Context = struct {
    allocator: Allocator,
    problems: []const Problem,
    in: []const u8,

    pub fn deinit(self: *Context) void {
        for (self.problems) |p| {
            // Free operands for each problem, then the problems slice itself
            self.allocator.free(p.operands);
        }
        self.allocator.free(self.problems);
        self.allocator.free(self.in);
    }
};

pub const Problem = struct {
    operation: u8,
    operands: []const u64,

    pub fn debugPrint(self: Problem) void {
        std.debug.print("op='{c}' operands:", .{self.operation});
        for (self.operands) |v| {
            std.debug.print(" {d}", .{v});
        }
        std.debug.print("\n", .{});
    }
};

pub const Range = struct { start: u64, end: u64 };

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;
    ctx.problems = try parseProblems(allocator, in);

    const in2 = try allocator.alloc(u8, in.len);
    @memcpy(in2, in);
    ctx.in = in2;

    return ctx;
}

fn parseProblems(allocator: std.mem.Allocator, in: []const u8) ![]const Problem {
    // 1) Tokenize rows
    var rows = try std.ArrayList([]const []const u8).initCapacity(allocator, 0);
    defer rows.deinit(allocator);

    var lines = std.mem.tokenizeScalar(u8, in, '\n');
    while (lines.next()) |line| {
        var toks = try std.ArrayList([]const u8).initCapacity(allocator, 0);
        defer toks.deinit(allocator);
        var it = std.mem.tokenizeAny(u8, line, " \t");
        while (it.next()) |tok| {
            try toks.append(allocator, tok);
        }
        const owned = try toks.toOwnedSlice(allocator);
        try rows.append(allocator, owned);
    }

    const row_slices = try rows.toOwnedSlice(allocator); // [][]slice
    const rows_len = row_slices.len;
    if (rows_len == 0) return allocator.alloc(Problem, 0);

    // 2) Find max columns
    var cols: usize = 0;
    for (row_slices) |r| cols = @max(cols, r.len);

    // 3) Build problems column-wise
    var problems = try std.ArrayList(Problem).initCapacity(allocator, cols);
    defer problems.deinit(allocator);

    var col: usize = 0;
    while (col < cols) : (col += 1) {
        // Collect operands from all rows except last
        var ops = try std.ArrayList(u64).initCapacity(allocator, rows_len - 1);
        defer ops.deinit(allocator);

        var r: usize = 0;
        while (r + 1 < rows_len) : (r += 1) {
            if (col < row_slices[r].len) {
                const tok = row_slices[r][col];
                const val = try std.fmt.parseInt(u64, tok, 10);
                try ops.append(allocator, val);
            }
        }

        // Operator from last row (single char like '+' or '*')
        var op_char: u8 = '+';
        if (col < row_slices[rows_len - 1].len) {
            const tok = row_slices[rows_len - 1][col];
            if (tok.len >= 1) op_char = tok[0];
        }

        const ops_owned = try ops.toOwnedSlice(allocator);
        try problems.append(allocator, .{ .operation = op_char, .operands = ops_owned });
    }

    const result = try problems.toOwnedSlice(allocator);
    // Free the per-line token arrays we owned
    for (row_slices) |r| allocator.free(r);
    allocator.free(row_slices);

    return result;
}
