const std = @import("std");

const map = @import("map.zig");
pub const rl = @cImport(@cInclude("raylib.h"));

pub fn vec2(x: anytype, y: anytype) rl.Vector2 {
    return rl.Vector2{
        .x = @floatFromInt(x),
        .y = @floatFromInt(y),
    };
}

pub const Renderer = struct {
    pub fn init() Renderer {
        return Renderer{};
    }

    pub fn run(self: *Renderer, level: *const map.Map) void {
        _ = self;

        var center = vec2(0, 0);

        rl.InitWindow(800, 600, "zig-wadder");
        defer rl.CloseWindow();

        rl.InitAudioDevice();
        defer rl.CloseAudioDevice();

        while (!rl.WindowShouldClose()) {
            rl.BeginDrawing();
            defer rl.EndDrawing();

            rl.BeginMode2D(.{
                .offset = vec2(
                    @divTrunc(rl.GetScreenWidth(), 2),
                    @divTrunc(rl.GetScreenHeight(), 2),
                ),
                .target = center,
                .rotation = 0.0,
                .zoom = 1.0 / 4.0,
            });
            defer rl.EndMode2D();

            rl.ClearBackground(rl.BLACK);

            for (level.lines) |line| {
                const start = level.vertices[line.startIdx];
                const end = level.vertices[line.endIdx];

                rl.DrawLineEx(vec2(start.x, start.y), vec2(end.x, end.y), 5.0, rl.RED);
            }
        }
    }

    pub fn deinit(self: *Renderer) void {
        _ = self;
    }
};
