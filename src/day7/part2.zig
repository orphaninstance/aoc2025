const std = @import("std");
const Context = @import("part1.zig").Context;
const printManifold = @import("part1.zig").printManifold;
const Allocator = std.mem.Allocator;

pub fn part2(ctx: *Context) ![]const u8 {
    const sum = try countPaths(ctx.manifold, ctx.dims, ctx.start);
    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

fn countPaths(manifold: std.AutoArrayHashMap([2]isize, u8), dims: [2]isize, start: [2]isize) !u64 {
    const rows: usize = @intCast(dims[0]);
    const cols: usize = @intCast(dims[1]);

    var cur = try std.heap.page_allocator.alloc(u64, cols);
    var next = try std.heap.page_allocator.alloc(u64, cols);
    defer {
        std.heap.page_allocator.free(cur);
        std.heap.page_allocator.free(next);
    }

    for (0..cols) |c| cur[c] = 0;
    cur[@intCast(start[1])] = 1;

    var r: usize = @intCast(start[0]);
    while (r + 1 < rows) : (r += 1) {
        for (0..cols) |c| next[c] = 0;

        for (0..cols) |c| {
            const ways = cur[c];
            if (ways == 0) continue;

            const ch_opt = manifold.get(.{ @intCast(r + 1), @intCast(c) });
            const ch: u8 = ch_opt orelse '.';

            if (ch == '^') {
                if (c > 0) next[c - 1] += ways;
                if (c + 1 < cols) next[c + 1] += ways;
            } else {
                next[c] += ways;
            }
        }

        const tmp = cur;
        cur = next;
        next = tmp;
    }

    var total: u64 = 0;
    for (0..cols) |c| total += cur[c];
    return total;
}
