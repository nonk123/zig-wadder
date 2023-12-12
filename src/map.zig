const std = @import("std");

const wad = @import("wad.zig");

pub const Vertex = struct {
    x: i16,
    y: i16,
};

pub const Line = struct {
    startIdx: u16,
    endIdx: u16,
    flags: u16,
    special: u16,
    sector: u16,
    frontSidedef: u16,
    backSidedef: u16,
};

pub const Sector = struct {
    tmp: u8,
};

pub const MapLoadError = std.mem.Allocator.Error || error{
    MapStartLumpNotFound,
    InvalidLumpOrder,
    InvalidLumpLength,
};

pub const Map = struct {
    vertices: []Vertex,
    lines: []Line,
    sectors: []Sector,

    pub fn loadByName(containingWad: *const wad.Wad, mapName: [:0]const u8, allocator: std.mem.Allocator) MapLoadError!Map {
        const startIdx = containingWad.findLump(mapName) orelse {
            return MapLoadError.MapStartLumpNotFound;
        };

        var idx = startIdx + 1;

        const lumpOrder = comptime .{
            .{ "THINGS", expect },
            .{ "LINEDEFS", loadLinedefs },
            .{ "SIDEDEFS", loadSidedefs },
            .{ "VERTEXES", loadVertices },
            .{ "SEGS", expect },
            .{ "SSECTORS", expect },
            .{ "NODES", expect },
            .{ "SECTORS", loadSectors },
            .{ "REJECT", expect },
            .{ "BLOCKMAP", expect },
            // .{ "BEHAVIOR", expect },
            //     ^ Hexen only; not interested.
        };

        var map = Map{
            .vertices = undefined,
            .lines = undefined,
            .sectors = undefined,
        };

        inline for (lumpOrder) |order| {
            const dataLump = containingWad.lumps[idx];

            if (!dataLump.nameEql(order[0])) {
                return MapLoadError.InvalidLumpOrder;
            }

            order[1](&map, &dataLump, allocator) catch |err| {
                return err;
            };

            idx += 1;
        }

        return map;
    }

    pub fn deinit(self: *Map, allocator: std.mem.Allocator) void {
        if (self.vertices.len != 0) {
            allocator.free(self.vertices);
        }

        if (self.lines.len != 0) {
            allocator.free(self.lines);
        }

        if (self.sectors.len != 0) {
            allocator.free(self.sectors);
        }
    }

    fn expect(self: *Map, dataLump: *const wad.Lump, allocator: std.mem.Allocator) MapLoadError!void {
        _ = dataLump;
        _ = allocator;
        _ = self;
    }

    fn loadLinedefs(self: *Map, dataLump: *const wad.Lump, allocator: std.mem.Allocator) MapLoadError!void {
        if (@mod(dataLump.data.len, 14) != 0) {
            return MapLoadError.InvalidLumpLength;
        }

        self.lines = try allocator.alloc(Line, dataLump.data.len / 14);
        errdefer allocator.free(self.lines);

        for (0..self.lines.len) |idx| {
            const offset = idx * 14;
            const slice = dataLump.data[offset .. offset + 14];

            self.lines[idx].startIdx = std.mem.readIntLittle(u16, slice[0..2]);
            self.lines[idx].endIdx = std.mem.readIntLittle(u16, slice[2..4]);
            // TODO: read etc.
        }
    }

    // TODO.
    fn loadSidedefs(self: *Map, dataLump: *const wad.Lump, allocator: std.mem.Allocator) MapLoadError!void {
        _ = dataLump;
        _ = allocator;
        _ = self;
    }

    fn loadVertices(self: *Map, dataLump: *const wad.Lump, allocator: std.mem.Allocator) MapLoadError!void {
        if (@mod(dataLump.data.len, 4) != 0) {
            return MapLoadError.InvalidLumpLength;
        }

        self.vertices = try allocator.alloc(Vertex, dataLump.data.len / 4);
        errdefer allocator.free(self.vertices);

        for (0..self.vertices.len) |idx| {
            const offset = idx * 4;
            const slice = dataLump.data[offset .. offset + 4];

            self.vertices[idx].x = std.mem.readIntLittle(i16, slice[0..2]);
            self.vertices[idx].y = std.mem.readIntLittle(i16, slice[2..4]);
        }
    }

    fn loadSectors(self: *Map, dataLump: *const wad.Lump, allocator: std.mem.Allocator) MapLoadError!void {
        _ = dataLump;
        _ = allocator;
        _ = self;
    }
};
