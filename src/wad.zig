const std = @import("std");

pub const Lump = struct {
    name: []u8,
    data: []u8,
};

pub const Wad = struct {
    identification: []u8,
    lumps: []Lump,

    /// Read a WAD file. Requires an allocator to store the lumps.
    ///
    /// The returned object owns the allocated memory. Make sure to call `deinit` on it afterwards!
    pub fn readFromFile(relativePath: []const u8, allocator: std.mem.Allocator) !Wad {
        var file = try std.fs.cwd().openFile(relativePath, .{});
        defer file.close();

        var identification = try allocator.alloc(u8, 4);
        _ = try file.reader().read(identification);

        const lumpCount = try file.reader().readIntLittle(u32);
        var lumpsBuf = try allocator.alloc(Lump, lumpCount);

        const dirAddr = try file.reader().readIntLittle(u32);

        for (0..lumpCount) |lumpIdx| {
            const entryAddr = dirAddr + lumpIdx * 16;
            try file.seekTo(entryAddr);

            const lumpDataStart = try file.reader().readIntLittle(u32);
            const lumpSize = try file.reader().readIntLittle(u32);

            var lumpName = try allocator.alloc(u8, 8);
            _ = try file.reader().read(lumpName);

            // Virtual lumps don't need to be read for data apparently.
            if (lumpSize == 0) {
                lumpsBuf[lumpIdx] = Lump{
                    .name = lumpName,
                    .data = &[0]u8{},
                };

                continue;
            }

            try file.seekTo(lumpDataStart);

            var data = try allocator.alloc(u8, lumpSize);
            _ = try file.reader().read(data);

            lumpsBuf[lumpIdx] = Lump{
                .name = lumpName,
                .data = data,
            };
        }

        return Wad{
            .identification = identification,
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
};
