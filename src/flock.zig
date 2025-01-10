const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});

const Boid = @import("boid.zig");
const QuadTree = @import("quadtree.zig");

const math = @import("math.zig");
const Vec2 = math.Vec2;
const AABB = math.AABB;

const Self = @This();

pub const FlockDesc = struct {
    boid_size: f32,
    boid_color: sdl.SDL_FColor,

    max_speed: f32,
    boundary: AABB,

    separation_distance: f32,
    separation_strength: f32,

    cohesion_distance: f32,
    cohesion_strength: f32,
    alignment_strength: f32,
};

desc: FlockDesc,
boids: std.ArrayList(Boid),
quadtree: QuadTree,

pub fn init(alloc: std.mem.Allocator, desc: FlockDesc) Self {
    return Self{
        .desc = desc,
        .boids = std.ArrayList(Boid).init(alloc),
        .quadtree = QuadTree.init(alloc, desc.boundary),
    };
}
pub fn deinit(self: Self) void {
    self.boids.deinit();
}
