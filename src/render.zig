const std = @import("std");

const root = @import("root");
const map = @import("map.zig");
pub const rl = @cImport(@cInclude("raylib.h"));

pub fn vec2(x: anytype, y: anytype) rl.Vector2 {
    return rl.Vector2{
        .x = @floatFromInt(x),
        .y = @floatFromInt(y),
    };
}

pub const Renderer = struct {
    curLevel: usize,
    center: rl.Vector2,

    pub fn init() Renderer {
        return .{
            .curLevel = 0,
            .center = vec2(0, 0),
        };
    }

    pub fn run(self: *Renderer, res: *const root.Resources) void {
        rl.InitWindow(800, 600, "zig-wadder");
        defer rl.CloseWindow();

        rl.InitAudioDevice();
        defer rl.CloseAudioDevice();

        rl.SetTargetFPS(60);

        while (!rl.WindowShouldClose()) {
            const scrollSpeed = 5120.0 * rl.GetFrameTime();

            if (rl.IsKeyDown(rl.KEY_A)) {
                self.center.x -= scrollSpeed;
            }

            if (rl.IsKeyDown(rl.KEY_D)) {
                self.center.x += scrollSpeed;
            }

            if (rl.IsKeyDown(rl.KEY_W)) {
                self.center.y -= scrollSpeed;
            }

            if (rl.IsKeyDown(rl.KEY_S)) {
                self.center.y += scrollSpeed;
            }

            if (rl.IsKeyPressed(rl.KEY_R)) {
                if (self.curLevel < res.levels.items.len - 1) {
                    self.curLevel += 1;
                }
            }

            if (rl.IsKeyPressed(rl.KEY_F)) {
                if (self.curLevel > 0) {
                    self.curLevel -= 1;
                }
            }

            rl.BeginDrawing();
            defer rl.EndDrawing();

            rl.BeginMode2D(.{
                .offset = vec2(
                    @divTrunc(rl.GetScreenWidth(), 2),
                    @divTrunc(rl.GetScreenHeight(), 2),
                ),
                .target = self.center,
                .rotation = 0.0,
                .zoom = 1.0 / 4.0,
            });
            defer rl.EndMode2D();

            rl.ClearBackground(rl.BLACK);

            const level = res.levels.items[self.curLevel];

            for (level.lines) |line| {
                const start = level.vertices[line.startIdx];
                const end = level.vertices[line.endIdx];

                rl.DrawLineEx(vec2(start.x, -start.y), vec2(end.x, -end.y), 5.0, rl.RED);
            }
        }
    }

    pub fn deinit(self: *Renderer) void {
        _ = self;
    }
};
