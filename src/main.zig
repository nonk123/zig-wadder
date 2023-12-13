const std = @import("std");

const wad = @import("wad.zig");
const map = @import("map.zig");
const render = @import("render.zig");

const rl = render.rl;

const TextureMap = std.AutoHashMap([]u8, rl.Texture);

pub const Resources = struct {
    levels: std.ArrayList(map.Map),
    textures: TextureMap,

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Resources {
        return .{
            .levels = std.ArrayList(map.Map).init(allocator),
            .textures = TextureMap.init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Resources) void {
        self.textures.deinit();
        self.deinitLevels();
    }

    pub fn loadFromWad(self: *Resources, srcWad: *const wad.Wad) !void {
        try self.loadLevels(srcWad);
        errdefer self.deinitLevels();

        try self.loadTextures(srcWad);
    }

    fn deinitLevels(self: *Resources) void {
        for (self.levels.items) |*level| {
            level.deinit();
        }

        self.levels.deinit();
    }

    fn loadLevels(self: *Resources, srcWad: *const wad.Wad) !void {
        var lumpIdx: usize = 0;

        while (lumpIdx + 1 < srcWad.lumps.len) {
            if (srcWad.lumps[lumpIdx + 1].nameEql("THINGS")) {
                var level = try map.Map.loadByLumpIdx(srcWad, lumpIdx, self.allocator);
                var slot = try self.levels.addOne();
                slot.* = level;

                lumpIdx += 10;
            } else {
                lumpIdx += 1;
            }
        }
    }

    fn loadTextures(self: *Resources, srcWad: *const wad.Wad) !void {
        // TODO TODO TODO.
        _ = srcWad;
        _ = self;
    }
};

const Error = error{
    UnrecognizedParameter,
    NoLevelsLoaded,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const gpaAlloc = gpa.allocator();

    var mapArena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer mapArena.deinit();

    var texArena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer texArena.deinit();

    var res = Resources.init(gpaAlloc);
    defer res.deinit();

    var args = try std.process.argsAlloc(gpaAlloc);
    defer std.process.argsFree(gpaAlloc, args);

    var argIdx: usize = 0;

    while (argIdx < args.len) {
        const arg = args[argIdx];

        if (std.mem.startsWith(u8, arg, "-")) {
            const name = arg[1..];

            if (std.mem.eql(u8, name, "file") or std.mem.eql(u8, name, "iwad")) {
                var wadArena = std.heap.ArenaAllocator.init(gpa.allocator());
                defer wadArena.deinit();

                const wadAlloc = wadArena.allocator();

                var curWad = try wad.Wad.readFromFile(args[argIdx + 1], wadAlloc);
                defer curWad.deinit();

                try res.loadFromWad(&curWad);

                argIdx += 2;
            } else {
                return Error.UnrecognizedParameter;
            }
        }

        argIdx += 1;
    }

    if (res.levels.items.len == 0) {
        return Error.NoLevelsLoaded;
    }

    var renderer = render.Renderer.init();
    defer renderer.deinit();

    return renderer.run(&res);
}
