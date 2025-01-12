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
    background_col: sdl.SDL_FColor,
    boundary_col: sdl.SDL_FColor,
    quadtree_col: sdl.SDL_FColor,

    draw_boundary: bool = false,
    draw_quadtree: bool = false,
};

renderer: *sdl.SDL_Renderer,
origin: Vec2,
flocks: []Flock,
opts: DrawOpts,

tris: std.ArrayList(sdl.SDL_Vertex),
rects: std.ArrayList(sdl.SDL_FRect),

pub fn init(
    alloc: std.mem.Allocator,
    renderer: *sdl.SDL_Renderer,
    origin: Vec2,
    flocks: []Flock,
    opts: DrawOpts,
) Self {
    return Self{
        .renderer = renderer,
        .origin = origin,
        .flocks = flocks,
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
    try self.clear();

    for (self.flocks) |flock| {
        try self.draw_flock(flock);
        if (self.opts.draw_boundary) try self.draw_boundary(flock);
        if (self.opts.draw_quadtree) try self.draw_quadtree(flock);
    }

    if (!sdl.SDL_RenderPresent(self.renderer))
        return error.SDL_RenderPresent;
}

fn clear(self: *Self) !void {
    if (!sdl.SDL_SetRenderDrawColor(
        self.renderer,
        @intFromFloat(self.opts.background_col.r),
        @intFromFloat(self.opts.background_col.g),
        @intFromFloat(self.opts.background_col.b),
        @intFromFloat(self.opts.background_col.a),
    ))
        return error.SDL_SetRenderDrawColor;
    if (!sdl.SDL_RenderClear(self.renderer))
        return error.SDL_RenderClear;
}

fn draw_flock(self: *Self, flock: Flock) !void {
    self.tris.clearRetainingCapacity();

    for (flock.boids.items) |boid| {
        const pos = boid.pos;
        var dir = boid.vel.normalize_safe();
        if (dir.is_zero()) dir = Vec2{ .x = 1.0, .y = 0.0 };
        const color = flock.desc.boid_color;

        inline for (BASE_TRIANGLE) |point| {
            const p = point
                .scale(flock.desc.boid_size)
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

fn draw_boundary(self: *Self, flock: Flock) !void {
    self.rects.clearRetainingCapacity();

    try self.rects.append(sdl.SDL_FRect{
        .x = flock.desc.boundary.min.x + self.origin.x,
        .y = flock.desc.boundary.min.y + self.origin.y,
        .w = flock.desc.boundary.max.x - flock.desc.boundary.min.x,
        .h = flock.desc.boundary.max.y - flock.desc.boundary.min.y,
    });

    try self.set_draw_color(self.opts.boundary_col);

    if (!sdl.SDL_RenderRects(
        self.renderer,
        self.rects.items.ptr,
        @intCast(self.rects.items.len),
    ))
        return error.SDL_RenderRects;
}

fn draw_quadtree(self: *Self, flock: Flock) !void {
    self.rects.clearRetainingCapacity();

    for (flock.quadtree.nodes.items) |node| {
        try self.rects.append(sdl.SDL_FRect{
            .x = node.bounds.min.x + self.origin.x,
            .y = node.bounds.min.y + self.origin.y,
            .w = node.bounds.max.x - node.bounds.min.x,
            .h = node.bounds.max.y - node.bounds.min.y,
        });
    }

    try self.set_draw_color(self.opts.quadtree_col);

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
