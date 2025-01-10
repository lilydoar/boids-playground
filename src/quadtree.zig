const std = @import("std");

const Boid = @import("boid.zig");

const math = @import("math.zig");
const Vec2 = math.Vec2;
const AABB = math.AABB;

const Node = struct {
    // Store the index of the first child if this node is a branch
    // Store the index of the first element if this node is a leaf
    children: usize,
    // Store the number of elements in a leaf node
    count: ?i32,
};


const Self = @This();

node_capacity: usize = 4,
max_depth: usize = 8,

bounds: AABB,
boids: []Boid,
nodes: std.ArrayList(Node),

pub fn init(alloc: std.mem.Allocator, bounds: AABB) Self {
    return Self{
        .bounds = bounds,
        .boids = &[_]Boid{},
        .nodes = std.ArrayList(Node).init(alloc),
    };
}

pub fn deinit(self: Self) void {
    self.nodes.deinit();
}

pub fn build(self: *Self, boids: []Boid) !void {
    self.boids = boids;
}

const QueryIterator = struct {
    quadtree: *Self,
    region: AABB,
    to_check: std.ArrayList(Node),

    pub fn next(self: *Self) ?*Boid {
        _ = self; // autofix
        return null;
    }
};
pub fn query(self: *Self, bounds: AABB) QueryIterator {
}
