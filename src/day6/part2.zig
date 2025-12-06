const std = @import("std");
const Context = @import("part1.zig").Context;
const Problem = @import("part1.zig").Problem;
const Allocator = std.mem.Allocator;

pub fn part2(ctx: *Context) ![]const u8 {
    const ps = try parse(ctx.allocator, ctx.in);
    defer {
        for (ps) |p| ctx.allocator.free(p.operands);
        ctx.allocator.free(ps);
    }

    var sum: u64 = 0;
    for (ps) |p| {
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

pub fn parse(allocator: Allocator, in: []const u8) ![]const Problem {
    // Returns a slice of rows, where each row is an owned slice of u8 tokens
    // exactly as they appear between whitespace on that line.
    var rows = try std.ArrayList([]const u8).initCapacity(allocator, 0);
    defer rows.deinit(allocator);

    var lines = std.mem.tokenizeScalar(u8, in, '\n');
    while (lines.next()) |line| {
        // Collect the entire raw line as one row (without splitting tokens)
        // If you want per-token splitting, use tokenizeAny and store tokens instead.
        const owned = try allocator.alloc(u8, line.len);
        std.mem.copyForwards(u8, owned, line);
        try rows.append(allocator, owned);
    }

    const foo = try rows.toOwnedSlice(allocator);
    defer {
        for (foo) |f| {
            allocator.free(f);
        }
        allocator.free(foo);
    }

    const fooT = try transposeRows(allocator, foo);
    defer {
        for (fooT) |f| allocator.free(f);
        allocator.free(fooT);
    }

    var problems = try std.ArrayList(Problem).initCapacity(allocator, 0);
    defer problems.deinit(allocator);

    // If needed, use parseTransposedProblems on fooT
    const parsed = try parseTransposedProblems(allocator, fooT);
    // defer {
    //     for (parsed) |p| allocator.free(p.operands);
    //     allocator.free(parsed);
    // }

    return parsed;
}

// Transpose an array of rows (each a []u8) into columns.
// Column j contains the j-th byte of each row that has it, in top-to-bottom order.
pub fn transposeRows(allocator: Allocator, rows: []const []const u8) ![]const []const u8 {
    // Find max row length
    var max_len: usize = 0;
    for (rows) |r| {
        if (r.len > max_len) max_len = r.len;
    }

    var cols = try std.ArrayList([]const u8).initCapacity(allocator, max_len);
    defer cols.deinit(allocator);

    var j: usize = 0;
    while (j < max_len) : (j += 1) {
        // Collect bytes present at column j for all rows
        var col_items = try std.ArrayList(u8).initCapacity(allocator, rows.len);
        defer col_items.deinit(allocator);
        for (rows) |r| {
            if (j < r.len) {
                try col_items.append(allocator, r[j]);
            }
        }
        const owned = try col_items.toOwnedSlice(allocator);
        try cols.append(allocator, owned);
    }

    return cols.toOwnedSlice(allocator);
}

// pub const Problem = struct {
//     operation: u8,
//     operands: []const u64,
// };

// Parse a transposed text (fooT) into problems. Groups are separated by blank lines.
// Rule: The operation is the last non-space char of the first line in a group.
//       Each non-empty subsequent line in the group is an operand composed of all digits in that line.
pub fn parseTransposedProblems(allocator: Allocator, fooT: []const []const u8) ![]const Problem {
    var problems = try std.ArrayList(Problem).initCapacity(allocator, 0);
    defer problems.deinit(allocator);

    var i: usize = 0;
    while (i < fooT.len) {
        // Skip leading empty lines between groups
        while (i < fooT.len and isBlank(fooT[i])) : (i += 1) {}
        if (i >= fooT.len) break;

        // First line of group: may contain an operand and ends with operation.
        const first = fooT[i];
        i += 1;
        var op: u8 = '+'; // default
        if (first.len > 0) {
            var j: isize = @as(isize, @intCast(first.len)) - 1;
            while (j >= 0) : (j -= 1) {
                const ch = first[@as(usize, @intCast(j))];
                if (ch != ' ' and ch != '\t') {
                    op = ch;
                    break;
                }
            }
        }

        // Collect operand lines until a blank line or end (including first line's digits)
        var ops_builder = try std.ArrayList(u64).initCapacity(allocator, 0);
        defer ops_builder.deinit(allocator);
        if (!isBlank(first)) {
            const head_val = try parseDigitsAsU64(first);
            // Append if the line contained any digits
            if (head_val != 0 or std.mem.indexOfScalar(u8, first, '0') != null) {
                try ops_builder.append(allocator, head_val);
            }
        }
        while (i < fooT.len and !isBlank(fooT[i])) : (i += 1) {
            const line = fooT[i];
            const val = try parseDigitsAsU64(line);
            try ops_builder.append(allocator, val);
        }

        const ops_owned = try ops_builder.toOwnedSlice(allocator);
        try problems.append(allocator, .{ .operation = op, .operands = ops_owned });
        // Loop continues; i currently at blank line (if any), will skip it next iteration
    }

    return problems.toOwnedSlice(allocator);
}

fn isBlank(s: []const u8) bool {
    for (s) |ch| {
        if (ch != ' ' and ch != '\t') return false;
    }
    return true;
}

fn parseDigitsAsU64(s: []const u8) !u64 {
    // Build a number from all ASCII digits in the slice
    var n: u64 = 0;
    for (s) |ch| {
        if (ch >= '0' and ch <= '9') {
            n = n * 10 + @as(u64, @intCast(ch - '0'));
        }
    }
    return n;
}
