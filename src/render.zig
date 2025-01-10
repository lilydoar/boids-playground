const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});

const Flock = @import("flock.zig");
const Vec2 = @import("math.zig").Vec2;

const Self = @This();

// Triangle with the nose pointing to the right.
const BASE_TRIANGLE = [3]Vec2{
    Vec2{ .x = 1.0, .y = 0.0 }, // nose
    Vec2{ .x = -0.5, .y = -0.5 }, // left wing
    Vec2{ .x = -0.5, .y = 0.5 }, // right wing
};

origin: Vec2,
flock: *Flock,
tris: std.ArrayList(sdl.SDL_Vertex),

pub fn init(alloc: std.mem.Allocator, origin: Vec2, flock: *Flock) Self {
    return Self{
        .origin = origin,
        .flock = flock,
        .tris = std.ArrayList(sdl.SDL_Vertex).init(alloc),
    };
}

pub fn deinit(self: Self) void {
    self.tris.deinit();
}

pub fn draw(self: *Self, renderer: *sdl.SDL_Renderer) !void {
    self.tris.clearRetainingCapacity();

    try self.draw_flock();

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

fn draw_flock(self: *Self) !void {
    for (self.flock.boids.items) |boid| {
        const pos = boid.pos;
        const dir = boid.vel.normalize();

        const p0 = BASE_TRIANGLE[0].scale(self.flock.desc.boid_size).rotate(dir).add(pos).add(self.origin);
        const p1 = BASE_TRIANGLE[1].scale(self.flock.desc.boid_size).rotate(dir).add(pos).add(self.origin);
        const p2 = BASE_TRIANGLE[2].scale(self.flock.desc.boid_size).rotate(dir).add(pos).add(self.origin);

        try self.tris.append(sdl.SDL_Vertex{
            .position = .{ .x = p0.x, .y = p0.y },
            .color = self.flock.desc.boid_color,
        });
        try self.tris.append(sdl.SDL_Vertex{
            .position = .{ .x = p1.x, .y = p1.y },
            .color = self.flock.desc.boid_color,
        });
        try self.tris.append(sdl.SDL_Vertex{
            .position = .{ .x = p2.x, .y = p2.y },
            .color = self.flock.desc.boid_color,
        });
    }
}
