const std = @import("std");

const Boid = @import("boid.zig");

const math = @import("math.zig");
const Vec2 = math.Vec2;
const AABB = math.AABB;

const Node = struct {
    bounds: AABB,
    contents: union(enum) {
        empty,
        children: usize,
        items: ItemSlice,
    },
};
const ItemSlice = struct {
    start: usize,
    len: usize,
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

    try self.nodes.append(Node{
        .bounds = self.bounds,
        .contents = .{
            .items = .{
                .start = 0,
                .len = self.indices.items.len,
            },
        },
    });
    try build_rec(self, 0, 0, boids);
}

fn build_rec(
    self: *Self,
    node_index: usize,
    depth: usize,
    boids: []Boid,
) !void {
    if (depth >= max_depth) return;

    switch (self.nodes.items[node_index].contents) {
        .empty => return,
        .children => unreachable,
        .items => |item| {
            if (item.len <= max_per_node) return;

            const bounds = self.nodes.items[node_index].bounds;
            const center = bounds.center();
            const children = self.nodes.items.len;

            // Point node at children
            self.nodes.items[node_index].contents = .{ .children = children };

            // Partition indices and create children
            var start = item.start;
            inline for (0..3) |i| {
                const end = item.start + item.len;
                const p = self.partition(i, boids, center, start, end);
                try create_child_node(self, bounds.quadrant(i), p);
                start = p.start + p.len;
            }

            const remaining_len = item.start + item.len - start;
            try create_child_node(self, bounds.quadrant(3), .{
                .start = start,
                .len = remaining_len,
            });

            // Recurse into children
            inline for (0..4) |i| {
                try build_rec(self, children + i, depth + 1, boids);
            }
        },
    }
}

fn partition(
    self: *Self,
    quadrant: usize,
    boids: []Boid,
    center: Vec2,
    start: usize,
    end: usize,
) ItemSlice {
    var left = start;
    var right = end;

    while (left < right) {
        const idx = self.indices.items[left];
        const pos = boids[idx].pos;

        if (get_point_quadrant(pos, center) == quadrant) {
            left += 1;
        } else {
            right -= 1;
            swap(self.indices.items, left, right);
        }
    }

    return .{
        .start = start,
        .len = left - start,
    };
}

fn swap(slice: []usize, a: usize, b: usize) void {
    if (a == b) return;
    const temp = slice[a];
    slice[a] = slice[b];
    slice[b] = temp;
}

fn create_child_node(
    self: *Self,
    bounds: AABB,
    items: ItemSlice,
) !void {
    try self.nodes.append(Node{
        .bounds = bounds,
        .contents = if (items.len == 0) .empty else .{ .items = items },
    });
}

// Returns which quadrant a point lies in relative to a center point:
// 0: top-left
// 1: top-right
// 2: bottom-left
// 3: bottom-right
fn get_point_quadrant(point: Vec2, center: Vec2) usize {
    const right_bit: usize = @intFromBool(point.x >= center.x);
    const bottom_bit: usize = @intFromBool(point.y >= center.y);
    return (bottom_bit << 1) | right_bit;
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
