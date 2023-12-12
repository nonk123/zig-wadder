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

pub const Map = struct {
    vertices: []Vertex,
    lines: []Line,
    sectors: []Sector,

    pub const LoadError = std.mem.Allocator.Error || error{
        MapStartLumpNotFound,
        InvalidLumpOrder,
        InvalidLumpLength,
    };

    pub fn loadByName(containingWad: *const wad.Wad, mapName: [:0]const u8, allocator: std.mem.Allocator) LoadError!Map {
        const startIdx = containingWad.findLump(mapName) orelse {
            return LoadError.MapStartLumpNotFound;
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
                return LoadError.InvalidLumpOrder;
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

    fn expect(self: *Map, dataLump: *const wad.Lump, allocator: std.mem.Allocator) LoadError!void {
        _ = dataLump;
        _ = allocator;
        _ = self;
    }

    fn loadPacked(self: *Map, dataLump: *const wad.Lump, allocator: std.mem.Allocator, comptime elementSize: usize, comptime destType: type, comptime destField: []const u8, comptime fields: anytype) LoadError!void {
        if (@mod(dataLump.data.len, elementSize) != 0) {
            return LoadError.InvalidLumpLength;
        }

        @field(self, destField) = try allocator.alloc(destType, dataLump.data.len / elementSize);
        var dest = @field(self, destField);
        errdefer allocator.free(dest);

        for (0..dest.len) |idx| {
            const offset = idx * elementSize;
            var slice = dataLump.data[offset .. offset + elementSize];

            inline for (fields) |field| {
                const size = @sizeOf(field[1]);
                @field(dest[idx], field[0]) = std.mem.readIntLittle(field[1], slice[0..size]);
                slice = slice[size..];
            }
        }
    }

    fn loadLinedefs(self: *Map, dataLump: *const wad.Lump, allocator: std.mem.Allocator) LoadError!void {
        return self.loadPacked(dataLump, allocator, 14, Line, "lines", .{
            .{ "startIdx", u16 },
            .{ "endIdx", u16 },
            // TODO: read etc.
        });
    }

    // TODO.
    fn loadSidedefs(self: *Map, dataLump: *const wad.Lump, allocator: std.mem.Allocator) LoadError!void {
        _ = dataLump;
        _ = allocator;
        _ = self;
    }

    fn loadVertices(self: *Map, dataLump: *const wad.Lump, allocator: std.mem.Allocator) LoadError!void {
        return self.loadPacked(dataLump, allocator, 4, Vertex, "vertices", .{
            .{ "x", i16 },
            .{ "y", i16 },
        });
    }

    fn loadSectors(self: *Map, dataLump: *const wad.Lump, allocator: std.mem.Allocator) LoadError!void {
        _ = dataLump;
        _ = allocator;
        _ = self;
    }
};
