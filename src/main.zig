const std = @import("std");

const wad = @import("wad.zig");
const map = @import("map.zig");

pub const Texture = struct {};

pub const Resources = struct {
    currentLevel: map.Map,
    textures: std.AutoHashMap([]u8, Texture),
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var wadArena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer wadArena.deinit();

    const wadAlloc = wadArena.allocator();

    var testWad = try wad.Wad.readFromFile("test.wad", wadAlloc);
    defer testWad.deinit(wadAlloc);

    var iwad = try wad.Wad.readFromFile("DOOM2.WAD", wadAlloc);
    defer iwad.deinit(wadAlloc);

    var mapArena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer mapArena.deinit();

    const mapAlloc = mapArena.allocator();

    var level = try map.Map.loadByName(&iwad, "MAP01", mapAlloc);
    defer level.deinit(mapAlloc);

    level.debugAsciiArt(64, 64, 32, 0, 32);
}
