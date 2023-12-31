const std = @import("std");

const root = @import("root");
const map = @import("map.zig");

pub const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

pub fn vec2(x: f32, y: f32) rl.Vector2 {
    return .{ .x = x, .y = y };
}

pub fn vec3(x: f32, y: f32, z: f32) rl.Vector3 {
    return .{ .x = x, .y = y, .z = z };
}

pub const Renderer = struct {
    curLevel: usize,

    cameraPos: rl.Vector3,
    angle: f32,

    pub fn init() Renderer {
        return .{
            .curLevel = 0,
            .cameraPos = vec3(0.0, 0.0, 0.0),
            .angle = rl.PI * 0.5,
        };
    }

    pub fn run(self: *Renderer, res: *const root.Resources) void {
        rl.InitWindow(800, 600, "zig-wadder");
        defer rl.CloseWindow();

        const shader =
            rl.LoadShaderFromMemory(@embedFile("vertex.glsl"), @embedFile("fragment.glsl"));
        defer rl.UnloadShader(shader);

        rl.InitAudioDevice();
        defer rl.CloseAudioDevice();

        rl.SetTargetFPS(60);

        while (!rl.WindowShouldClose()) {
            const rotSpeed = rl.PI * rl.GetFrameTime();
            const scrollSpeed = 12.0 * rl.GetFrameTime();

            if (rl.IsKeyDown(rl.KEY_Q)) {
                self.angle += rotSpeed;
            }

            if (rl.IsKeyDown(rl.KEY_E)) {
                self.angle -= rotSpeed;
            }

            var delta = vec2(0.0, 0.0);

            if (rl.IsKeyDown(rl.KEY_A)) {
                delta.x -= scrollSpeed;
            }

            if (rl.IsKeyDown(rl.KEY_D)) {
                delta.x += scrollSpeed;
            }

            if (rl.IsKeyDown(rl.KEY_W)) {
                delta.y += scrollSpeed;
            }

            if (rl.IsKeyDown(rl.KEY_S)) {
                delta.y -= scrollSpeed;
            }

            const deltaRot = rl.Vector2Rotate(delta, self.angle);
            self.cameraPos.x += deltaRot.x;
            self.cameraPos.y += deltaRot.y;

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

            const dir = vec3(-@sin(self.angle), @cos(self.angle), 0.0);
            const target = rl.Vector3Add(self.cameraPos, dir);

            rl.BeginMode3D(.{
                .fovy = 40.0,
                .projection = rl.CAMERA_PERSPECTIVE,
                .up = vec3(0.0, 0.0, 1.0),
                .position = self.cameraPos,
                .target = target,
            });
            rl.BeginShaderMode(shader);

            rl.ClearBackground(rl.BLACK);

            const level = res.levels.items[self.curLevel];

            for (level.lines) |line| {
                const color = switch (line.getSpecial()) {
                    .Door => rl.RED,
                    else => rl.WHITE,
                };

                const start = level.vertices[line.startIdx];
                const end = level.vertices[line.endIdx];

                const scale = 1.0 / 32.0;

                const sx: f32 = @as(f32, @floatFromInt(start.x)) * scale;
                const sy: f32 = @as(f32, @floatFromInt(start.y)) * scale;

                const ex: f32 = @as(f32, @floatFromInt(end.x)) * scale;
                const ey: f32 = @as(f32, @floatFromInt(end.y)) * scale;

                const h: f32 = 128.0 * scale;

                var points = [4]rl.Vector3{
                    vec3(sx, sy, -h),
                    vec3(ex, ey, -h),
                    vec3(sx, sy, h),
                    vec3(ex, ey, h),
                };

                rl.DrawTriangleStrip3D(&points, 4, color);
            }

            rl.EndMode3D();
            rl.EndShaderMode();

            rl.DrawText(level.name, 5, 5, 35, rl.WHITE);

            rl.EndDrawing();
        }
    }

    pub fn deinit(self: *Renderer) void {
        _ = self;
    }
};
