const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});

const Flock = @import("flock.zig");
const math = @import("math.zig");
const Vec2 = math.Vec2;

const Self = @This();

// Triangle with the nose pointing to the right.
const BASE_TRIANGLE = [3]Vec2{
    Vec2{ .x = 1.0, .y = 0.0 }, // nose
    Vec2{ .x = -0.5, .y = -0.5 }, // left wing
    Vec2{ .x = -0.5, .y = 0.5 }, // right wing
};

pub const DrawOpts = struct {
    boundary_color: sdl.SDL_FColor,
};

origin: Vec2,
flock: *Flock,
opts: DrawOpts,

tris: std.ArrayList(sdl.SDL_Vertex),
rects: std.ArrayList(sdl.SDL_FRect),

pub fn init(
    alloc: std.mem.Allocator,
    origin: Vec2,
    flock: *Flock,
    opts: DrawOpts,
) Self {
    return Self{
        .origin = origin,
        .flock = flock,
        .opts = opts,
        .tris = std.ArrayList(sdl.SDL_Vertex).init(alloc),
        .rects = std.ArrayList(sdl.SDL_FRect).init(alloc),
    };
}

pub fn deinit(self: Self) void {
    self.tris.deinit();
    self.rects.deinit();
}

pub fn draw(
    self: *Self,
    renderer: *sdl.SDL_Renderer,
) !void {
    self.tris.clearRetainingCapacity();
    self.rects.clearRetainingCapacity();

    try self.draw_flock();
    try self.draw_boundary();

    if (!sdl.SDL_RenderGeometry(
        renderer,
        null,
        self.tris.items.ptr,
        @intCast(self.tris.items.len),
        null,
        0,
    ))
        return error.SDL_RenderGeometry;

    if (!sdl.SDL_SetRenderDrawColor(
        renderer,
        @intFromFloat(self.opts.boundary_color.r),
        @intFromFloat(self.opts.boundary_color.g),
        @intFromFloat(self.opts.boundary_color.b),
        @intFromFloat(self.opts.boundary_color.a),
    ))
        return error.SDL_SetRenderDrawColor;

    if (!sdl.SDL_RenderRects(
        renderer,
        self.rects.items.ptr,
        @intCast(self.rects.items.len),
    ))
        return error.SDL_RenderRects;
}

fn draw_flock(self: *Self) !void {
    for (self.flock.boids.items) |boid| {
        const pos = boid.pos;
        const dir = boid.vel.normalize();
        const color = self.flock.desc.boid_color;

        const p0 = BASE_TRIANGLE[0].scale(self.flock.desc.boid_size).rotate(dir).add(pos).add(self.origin);
        const p1 = BASE_TRIANGLE[1].scale(self.flock.desc.boid_size).rotate(dir).add(pos).add(self.origin);
        const p2 = BASE_TRIANGLE[2].scale(self.flock.desc.boid_size).rotate(dir).add(pos).add(self.origin);

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
}

fn draw_boundary(self: *Self) !void {
    try self.rects.append(sdl.SDL_FRect{
        .x = self.flock.desc.boundary.min.x + self.origin.x,
        .y = self.flock.desc.boundary.min.y + self.origin.y,
        .w = self.flock.desc.boundary.max.x - self.flock.desc.boundary.min.x,
        .h = self.flock.desc.boundary.max.y - self.flock.desc.boundary.min.y,
    });
}
