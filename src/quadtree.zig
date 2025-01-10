const std = @import("std");

const Boid = @import("boid.zig");

const math = @import("math.zig");
const Vec2 = math.Vec2;
const AABB = math.AABB;

// This quadtree works by storing indices of items in a list and reordering the
// indices to match the node structure

const Node = struct {
    bounds: AABB,

    // FIXME: I think this could be a union since a node only ever has children
    // or indices
    children: ?usize = null,
    start: ?usize = null,
    count: ?usize = null,
};

const Self = @This();

const max_depth = 8;
const max_per_node = 8;

bounds: AABB,
nodes: std.ArrayList(Node),
indices: std.ArrayList(usize),

pub fn init(alloc: std.mem.Allocator, bounds: AABB) Self {
    return Self{
        .bounds = bounds,
        .nodes = std.ArrayList(Node).init(alloc),
        .indices = std.ArrayList(usize).init(alloc),
    };
}

pub fn deinit(self: Self) void {
    self.nodes.deinit();
    self.indices.deinit();
}

pub fn build(self: *Self, boids: []Boid) !void {
    self.nodes.clearRetainingCapacity();
    self.indices.clearRetainingCapacity();

    for (boids, 0..) |_, i| {
        try self.indices.append(i);
    }

    try self.nodes.append(.{
        .bounds = self.bounds,
        .start = 0,
        .count = self.indices.items.len,
    });
    try build_rec(self, 0, 0, boids);
}

fn build_rec(
    self: *Self,
    node_index: usize,
    depth: usize,
    boids: []Boid,
) !void {
    const node = self.nodes.items[node_index];

    if (depth >= max_depth or node.count.? <= max_per_node) {
        return;
    }

    // Create children
    self.nodes.items[node_index].children = self.nodes.items.len;
    for (0..4) |i| {
        try self.nodes.append(Node{
            .bounds = node.bounds.quadrant(i),
            .start = 0,
            .count = 0,
        });
    }

    // Partition boid indices into quadrants
    var partitions = [_]usize{ node.start.?, 0, 0, 0 };
    var counts = [_]usize{ 0, 0, 0, 0 };

    const center = node.bounds.center();

    // TODO: Extract the partitioning into a function

    // Partition entities, maintaining the invariant that:
    // - Everything before i is in the current quadrant
    // - Everything after j is in a later quadrant
    // - Items between i and j are yet to be classified
    var i = node.start.?;
    var j = node.start.? + node.count.?;

    // Partition quadrant 0
    while (i <= j) {
        const idx = self.indices.items[i];
        const pos = boids[idx].pos;
        const quadrant = get_point_quadrant(pos, center);

        if (quadrant == 0) {
            i += 1;
            counts[quadrant] += 1;
        } else {
            j -= 1;
            swap(self.indices.items, i, j);
        }
    }
    partitions[1] = i;

    // Partition quadrant 1
    j = node.start.? + node.count.? - 1;
    while (i <= j) {
        const idx = self.indices.items[i];
        const pos = boids[idx].pos;
        const quadrant = get_point_quadrant(pos, center);

        if (quadrant == 1) {
            i += 1;
            counts[quadrant] += 1;
        } else {
            j -= 1;
            swap(self.indices.items, i, j);
        }
    }
    partitions[2] = i;

    // Partition quadrant 2
    j = node.start.? + node.count.? - 1;
    while (i <= j) {
        const idx = self.indices.items[i];
        const pos = boids[idx].pos;
        const quadrant = get_point_quadrant(pos, center);

        if (quadrant == 2) {
            i += 1;
            counts[quadrant] += 1;
        } else {
            j -= 1;
            swap(self.indices.items, i, j);
        }
    }
    partitions[3] = i;
    counts[3] = node.start.? + node.count.? - i;

    // Setup child ranges and recurse
    for (0..4) |idx| {
        const child_index = node.children.? + idx;
        self.nodes.items[child_index].start = partitions[idx];
        self.nodes.items[child_index].count = counts[idx];

        if (self.nodes.items[child_index].count.? > 0) {
            try build_rec(self, child_index, depth + 1, boids);
        }
    }
}

// const QueryIterator = struct {
//     quadtree: *Self,
//     region: AABB,
//     to_check: std.ArrayList(Node),
//
//     pub fn next(self: *Self) ?*Boid {
//         _ = self; // autofix
//         return null;
//     }
// };
// pub fn query(self: *Self, bounds: AABB) QueryIterator {}

fn swap(self: []usize, a: usize, b: usize) void {
    const temp = self[a];
    self[a] = self[b];
    self[b] = temp;
}

// Returns which quadrant a point lies in relative to a center point:
// 0: top-left
// 1: top-right
// 2: bottom-left
// 3: bottom-right
fn get_point_quadrant(point: Vec2, center: Vec2) usize {
    const is_right = point.x >= center.x;
    const is_bottom = point.y >= center.y;
    if (!is_right and !is_bottom) return 0; // top-left
    if (is_right and !is_bottom) return 1; // top-right
    if (!is_right and is_bottom) return 2; // bottom-left
    return 3; // bottom-right
}
