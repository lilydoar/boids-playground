const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});

const Boid = @import("boid.zig");
const Vec2 = @import("math.zig").Vec2;

const Self = @This();

const FlockDesc = struct {
    boid_size: f32,
    max_speed: f32,

    separation_distance: f32,
    cohesion_distance: f32,

    separation_strength: f32,
    cohesion_strength: f32,
    alignment_strength: f32,
};

desc: FlockDesc,
boids: std.ArrayList(Boid),

pub fn init(alloc: std.mem.Allocator, desc: FlockDesc) Self {
    return Self{
        .desc = desc,
        .boids = std.ArrayList(Boid).init(alloc),
    };
}
pub fn deinit(self: Self) void {
    self.boids.deinit();
}

pub const Renderer = struct {
    tris: std.ArrayList(sdl.SDL_Vertex),

    pub fn init(alloc: std.mem.Allocator) Renderer {
        return Renderer{
            .tris = std.ArrayList(sdl.SDL_Vertex).init(alloc),
        };
    }

    pub fn deinit(self: Renderer) void {
        self.tris.deinit();
    }

    pub fn render(
        self: *Renderer,
        renderer: *sdl.SDL_Renderer,
        flock: Self,
        origin: Vec2,
        size: f32,
        color: sdl.SDL_FColor,
    ) !void {
        self.tris.clearRetainingCapacity();

        for (flock.boids.items) |boid| {
            const pos = boid.pos;
            const dir = boid.vel.normalize();

            const p0 = BASE_TRIANGLE[0].scale(size).rotate(dir).add(pos).add(origin);
            const p1 = BASE_TRIANGLE[1].scale(size).rotate(dir).add(pos).add(origin);
            const p2 = BASE_TRIANGLE[2].scale(size).rotate(dir).add(pos).add(origin);

            try self.tris.append(sdl.SDL_Vertex{
                .position = .{ .x = p0.x, .y = p0.y },
                .color = color,
            });
            try self.tris.append(sdl.SDL_Vertex{
                .position = .{ .x = p1.x, .y = p1.y },
                .color = color,
            });
            try self.tris.append(sdl.SDL_Vertex{
                .position = .{ .x = p2.x, .y = p2.y },
                .color = color,
            });
        }

        if (!sdl.SDL_RenderGeometry(
            renderer,
            null,
            self.tris.items.ptr,
            @intCast(self.tris.items.len),
            null,
            0,
        ))
            return error.SDL_RenderGeometry;
    }
};

// Triangle with the nose pointing to the right.
pub const BASE_TRIANGLE = [3]Vec2{
    Vec2{ .x = 1.0, .y = 0.0 }, // nose
    Vec2{ .x = -0.5, .y = -0.5 }, // left wing
    Vec2{ .x = -0.5, .y = 0.5 }, // right wing
};
