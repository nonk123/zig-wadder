const std = @import("std");

const wad = @import("wad.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    var testWad = try wad.Wad.readFromFile("test.wad", arena.allocator());
    defer testWad.deinit(arena.allocator());

    std.debug.print("{s} lumps:\n\n", .{testWad.identification});

    var sumMb: f32 = 0.0;

    for (testWad.lumps) |lump| {
        const b = lump.data.len;
        const k = @as(f32, @floatFromInt(b)) / 1024.0;
        const m = k / 1024.0;

        sumMb += m;

        std.debug.print("Lump {s}: {}B {d:.2}K {d:.2}M\n", .{ lump.name, b, k, m });
    }

    std.debug.print("\n{d:.2}M total\n", .{sumMb});
}
