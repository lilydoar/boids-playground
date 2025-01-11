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
    quadtree_color: sdl.SDL_FColor,
};

renderer: *sdl.SDL_Renderer,
origin: Vec2,
flock: *Flock,
opts: DrawOpts,

tris: std.ArrayList(sdl.SDL_Vertex),
rects: std.ArrayList(sdl.SDL_FRect),

pub fn init(
    alloc: std.mem.Allocator,
    renderer: *sdl.SDL_Renderer,
    origin: Vec2,
    flock: *Flock,
    opts: DrawOpts,
) Self {
    return Self{
        .renderer = renderer,
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

pub fn draw(self: *Self) !void {
    try self.draw_flock();
    try self.draw_boundary();
    try self.draw_quadtree();
}

fn draw_flock(self: *Self) !void {
    self.tris.clearRetainingCapacity();

    for (self.flock.boids.items) |boid| {
        const pos = boid.pos;
        const dir = boid.vel.normalize();
        const color = self.flock.desc.boid_color;

        inline for (BASE_TRIANGLE) |point| {
            const p = point
                .scale(self.flock.desc.boid_size)
                .rotate(dir)
                .add(pos)
                .add(self.origin);
            try self.tris.append(sdl.SDL_Vertex{
                .position = .{ .x = p.x, .y = p.y },
                .color = color,
            });
        }
    }

    if (!sdl.SDL_RenderGeometry(
        self.renderer,
        null,
        self.tris.items.ptr,
        @intCast(self.tris.items.len),
        null,
        0,
    ))
        return error.SDL_RenderGeometry;
}

fn draw_boundary(self: *Self) !void {
    self.rects.clearRetainingCapacity();

    try self.rects.append(sdl.SDL_FRect{
        .x = self.flock.desc.boundary.min.x + self.origin.x,
        .y = self.flock.desc.boundary.min.y + self.origin.y,
        .w = self.flock.desc.boundary.max.x - self.flock.desc.boundary.min.x,
        .h = self.flock.desc.boundary.max.y - self.flock.desc.boundary.min.y,
    });

    try self.set_draw_color(self.opts.boundary_color);

    if (!sdl.SDL_RenderRects(
        self.renderer,
        self.rects.items.ptr,
        @intCast(self.rects.items.len),
    ))
        return error.SDL_RenderRects;
}

fn draw_quadtree(self: *Self) !void {
    self.rects.clearRetainingCapacity();

    for (self.flock.quadtree.nodes.items) |node| {
        try self.rects.append(sdl.SDL_FRect{
            .x = node.bounds.min.x + self.origin.x,
            .y = node.bounds.min.y + self.origin.y,
            .w = node.bounds.max.x - node.bounds.min.x,
            .h = node.bounds.max.y - node.bounds.min.y,
        });
    }

    try self.set_draw_color(self.opts.quadtree_color);

    if (!sdl.SDL_RenderRects(
        self.renderer,
        self.rects.items.ptr,
        @intCast(self.rects.items.len),
    ))
        return error.SDL_RenderRects;
}

fn set_draw_color(self: *Self, color: sdl.SDL_FColor) !void {
    if (!sdl.SDL_SetRenderDrawColor(
        self.renderer,
        @intFromFloat(color.r),
        @intFromFloat(color.g),
        @intFromFloat(color.b),
        @intFromFloat(color.a),
    ))
        return error.SDL_SetRenderDrawColor;
}
