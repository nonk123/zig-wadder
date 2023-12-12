const std = @import("std");

pub fn normalizeDoomStr(input: []u8) [:0]u8 {
    var idx = input.len;

    while (idx > 0 and input[idx - 1] == 0) {
        idx -= 1;
    }

    return input[0..idx :0];
}

pub const Lump = struct {
    name: [:0]u8,
    data: []u8,

    pub fn nameEql(self: *const Lump, arg: [:0]const u8) bool {
        return std.mem.orderZ(u8, self.name, arg) == std.math.Order.eq;
    }
};

pub const Wad = struct {
    identification: [:0]u8,
    lumps: []Lump,

    /// Read a WAD file. Requires an allocator to store the lumps.
    ///
    /// The returned object owns the allocated memory. Make sure to call `deinit` on it afterwards!
    pub fn readFromFile(relativePath: []const u8, allocator: std.mem.Allocator) !Wad {
        var file = try std.fs.cwd().openFile(relativePath, .{});
        defer file.close();

        var identificationBuf: [4]u8 = undefined;
        _ = try file.reader().read(&identificationBuf);

        var identification = try allocator.alloc(u8, 5);
        std.mem.copy(u8, identification, &identificationBuf);
        identification[4] = 0;

        const lumpCount = try file.reader().readIntLittle(u32);
        var lumpsBuf = try allocator.alloc(Lump, lumpCount);

        const dirAddr = try file.reader().readIntLittle(u32);

        for (0..lumpCount) |lumpIdx| {
            const entryAddr = dirAddr + lumpIdx * 16;
            try file.seekTo(entryAddr);

            const lumpDataStart = try file.reader().readIntLittle(u32);
            const lumpSize = try file.reader().readIntLittle(u32);

            var lumpNameBuf: [8]u8 = undefined;
            _ = try file.reader().read(&lumpNameBuf);

            var lumpName = try allocator.alloc(u8, 9);
            std.mem.copy(u8, lumpName, &lumpNameBuf);
            lumpName[8] = 0;

            // Virtual lumps don't need to be read for data apparently.
            if (lumpSize == 0) {
                lumpsBuf[lumpIdx] = Lump{
                    .name = normalizeDoomStr(lumpName),
                    .data = &[0]u8{},
                };

                continue;
            }

            try file.seekTo(lumpDataStart);

            var data = try allocator.alloc(u8, lumpSize);
            _ = try file.reader().read(data);

            lumpsBuf[lumpIdx] = Lump{
                .name = normalizeDoomStr(lumpName),
                .data = data,
            };
        }

        return Wad{
            .identification = normalizeDoomStr(identification),
            .lumps = lumpsBuf,
        };
    }

    /// Free the previously allocated memory.
    pub fn deinit(self: *Wad, allocator: std.mem.Allocator) void {
        allocator.free(self.identification);

        for (self.lumps) |lump| {
            allocator.free(lump.name);

            if (lump.data.len != 0) {
                allocator.free(lump.data);
            }
        }

        allocator.free(self.lumps);
    }

    pub fn debugPrintContents(self: *const Wad) void {
        std.debug.print("Loaded {s}. Lumps:\n\n", .{self.identification});

        var sumMb: f32 = 0.0;

        for (self.lumps) |lump| {
            const b = lump.data.len;
            const k = @as(f32, @floatFromInt(b)) / 1024.0;
            const m = k / 1024.0;

            sumMb += m;

            std.debug.print("Lump {s}: {}B {d:.2}K {d:.2}M\n", .{ lump.name, b, k, m });
        }

        std.debug.print("\n{d:.2}M total\n", .{sumMb});
    }

    /// Find a lump index by the lump's name.
    pub fn findLump(self: *const Wad, name: [:0]const u8) ?usize {
        for (0..self.lumps.len) |idx| {
            const lump = self.lumps[idx];

            if (lump.nameEql(name)) {
                return idx;
            }
        }

        return null;
    }
};
