const std = @import("std");

pub const Trigger = enum { P1, PR, S1, SR, W1, WR, G1, GR };
pub const Lock = enum { YELLOW, RED, BLUE };

pub const Door = struct {
    trigger: ?Trigger,
    lock: ?Lock,
};

pub const Floor = struct {
    trigger: ?Trigger,
};

pub const Special = union(enum) {
    Wall,
    Door: Door,
};

// TODO: redo for completeness.
fn decode(comptime desc: []const u8) Special {
    if (desc.len >= 5 and std.mem.eql(u8, desc[0..5], "DOOR ")) {
        return Special{ .Door = .{
            .trigger = null,
            .lock = null,
        } };
    }

    return Special.Wall;
}

pub const list = blk: {
    @setEvalBranchQuota(100000);

    var ls: [270]Special = undefined;

    const defs = @embedFile("stolen.py");
    var iter = std.mem.splitScalar(u8, defs, '\n');

    while (iter.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var lineSplit = std.mem.splitScalar(u8, line, ':');

        const def = lineSplit.first();

        const numRaw = lineSplit.next() orelse @compileError("FUCK");
        const numParsable = numRaw[0 .. numRaw.len - 1];

        const num = std.fmt.parseInt(usize, numParsable, 10) catch @compileError("SHIT");

        ls[num] = decode(def);
    }

    break :blk ls;
};
