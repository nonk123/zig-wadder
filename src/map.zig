const std = @import("std");

const wad = @import("wad.zig");
const specials = @import("specials.zig");

pub const LineFlags = struct {
    const BLOCK_PLAYERS_MONSTERS = 1 << 0;
    const BLOCK_MONSTERS = 1 << 1;
    const TWO_SIDED = 1 << 2;
    // TODO: add more flags.
};

pub const Vertex = struct {
    x: i16,
    y: i16,
};

pub const Line = struct {
    startIdx: u16,
    endIdx: u16,
    flags: u16,
    special: u16,
    sectorIdx: u16,
    frontSidedefIdx: u16,
    backSidedefIdx: u16,

    pub fn getSpecial(self: *const Line) specials.Special {
        return specials.list[self.special];
    }
};

pub const Sector = struct {
    tmp: u8,
};

pub const Map = struct {
    name: [:0]u8,
    vertices: []Vertex,
    lines: []Line,
    sectors: []Sector,

    allocator: std.mem.Allocator,

    pub const LoadError = std.mem.Allocator.Error || error{
        MapStartLumpNotFound,
        InvalidLumpOrder,
        InvalidLumpLength,
    };

    /// Load a map given its initial lump index.
    ///
    /// The returned object owns the allocated memory. Make sure to call `deinit` when done using it!
    ///
    /// `allocator` is cached and must be available up until `deinit` is called.
    pub fn loadByLumpIdx(containingWad: *const wad.Wad, startIdx: usize, allocator: std.mem.Allocator) LoadError!Map {
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

        const mapName = containingWad.lumps[startIdx].name;

        var name = try allocator.allocSentinel(u8, mapName.len, 0);
        std.mem.copy(u8, name, mapName);

        var map = Map{
            .name = name,
            .vertices = undefined,
            .lines = undefined,
            .sectors = &[0]Sector{},
            .allocator = allocator,
        };

        var idx = startIdx + 1;

        inline for (lumpOrder) |order| {
            const dataLump = containingWad.lumps[idx];

            if (!dataLump.nameEql(order[0])) {
                return LoadError.InvalidLumpOrder;
            }

            order[1](&map, &dataLump) catch |err| {
                return err;
            };

            idx += 1;
        }

        return map;
    }

    /// Load a named map from a WAD.
    ///
    /// See `loadByLumpIndex` for details.
    pub fn loadByName(containingWad: *const wad.Wad, mapName: [:0]const u8, allocator: std.mem.Allocator) LoadError!Map {
        const startIdx = containingWad.findLump(mapName) orelse {
            return LoadError.MapStartLumpNotFound;
        };

        return loadByLumpIdx(containingWad, startIdx, allocator);
    }

    pub fn deinit(self: *Map) void {
        self.allocator.free(self.name);

        if (self.vertices.len != 0) {
            self.allocator.free(self.vertices);
        }

        if (self.lines.len != 0) {
            self.allocator.free(self.lines);
        }

        if (self.sectors.len != 0) {
            self.allocator.free(self.sectors);
        }
    }

    fn expect(self: *Map, dataLump: *const wad.Lump) LoadError!void {
        _ = dataLump;
        _ = self;
    }

    fn loadPacked(self: *Map, dataLump: *const wad.Lump, comptime elementSize: usize, comptime destType: type, comptime destField: []const u8, comptime fields: anytype) LoadError!void {
        if (@mod(dataLump.data.len, elementSize) != 0) {
            return LoadError.InvalidLumpLength;
        }

        @field(self, destField) = try self.allocator.alloc(destType, dataLump.data.len / elementSize);
        var dest = @field(self, destField);
        errdefer self.allocator.free(dest);

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

    fn loadLinedefs(self: *Map, dataLump: *const wad.Lump) LoadError!void {
        return self.loadPacked(dataLump, 14, Line, "lines", .{
            .{ "startIdx", u16 },
            .{ "endIdx", u16 },
            .{ "flags", u16 },
            .{ "special", u16 },
            .{ "sectorIdx", u16 },
            .{ "frontSidedefIdx", u16 },
            .{ "backSidedefIdx", u16 },
            // TODO: read etc.
        });
    }

    // TODO.
    fn loadSidedefs(self: *Map, dataLump: *const wad.Lump) LoadError!void {
        _ = dataLump;
        _ = self;
    }

    fn loadVertices(self: *Map, dataLump: *const wad.Lump) LoadError!void {
        return self.loadPacked(dataLump, 4, Vertex, "vertices", .{
            .{ "x", i16 },
            .{ "y", i16 },
        });
    }

    fn loadSectors(self: *Map, dataLump: *const wad.Lump) LoadError!void {
        _ = dataLump;
        _ = self;
    }
};
