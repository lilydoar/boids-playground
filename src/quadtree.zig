const std = @import("std");

const Boid = @import("boid.zig");

const math = @import("math.zig");
const Vec2 = math.Vec2;
const AABB = math.AABB;

// This quadtree works by storing indices of items in a list and reordering the
// indices to match the node structure

const Node = struct {
    bounds: AABB,
    contents: union(enum) {
        empty,
        children: usize,
        items: struct {
            start: usize,
            len: usize,
        },
    },
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

            // Point node at children
            self.nodes.items[node_index].contents = .{
                .children = self.nodes.items.len,
            };
            const children = self.nodes.items[node_index].contents.children;
            const bounds = self.nodes.items[node_index].bounds;

            // Create children nodes
            inline for (0..4) |i| {
                try self.nodes.append(Node{
                    .bounds = bounds.quadrant(i),
                    .contents = .empty,
                });
            }

            // Partition items among the children
            const center = bounds.center();

            // Quadrant 0
            var start = item.start;
            var left = item.start;
            var right = item.start + item.len;

            while (left < right) {
                const idx = self.indices.items[left];
                const pos = boids[idx].pos;

                if (get_point_quadrant(pos, center) == 0) {
                    left += 1;
                } else {
                    right -= 1;
                    swap(self.indices.items, left, right);
                }
            }
            if (left - start > 0) {
                self.nodes.items[children + 0].contents = .{
                    .items = .{ .start = start, .len = left - start },
                };
            }

            // Quadrant 1
            start = left;
            right = item.start + item.len;

            while (left < right) {
                const idx = self.indices.items[left];
                const pos = boids[idx].pos;

                if (get_point_quadrant(pos, center) == 1) {
                    left += 1;
                } else {
                    right -= 1;
                    swap(self.indices.items, left, right);
                }
            }
            if (left - start > 0) {
                self.nodes.items[children + 1].contents = .{
                    .items = .{ .start = start, .len = left - start },
                };
            }

            // Quadrant 2
            start = left;
            right = item.start + item.len;

            while (left < right) {
                const idx = self.indices.items[left];
                const pos = boids[idx].pos;

                if (get_point_quadrant(pos, center) == 2) {
                    left += 1;
                } else {
                    right -= 1;
                    swap(self.indices.items, left, right);
                }
            }
            if (left - start > 0) {
                self.nodes.items[children + 2].contents = .{
                    .items = .{ .start = start, .len = left - start },
                };
            }

            // Quadrant 3
            const len = item.start + item.len - left;
            start = left;

            if (len > 0) {
                self.nodes.items[children + 3].contents = .{
                    .items = .{ .start = start, .len = len },
                };
            }

            // Recurse into children
            switch (self.nodes.items[children + 0].contents) {
                .empty => {},
                .children => unreachable,
                .items => {
                    try build_rec(self, children + 0, depth + 1, boids);
                },
            }
            switch (self.nodes.items[children + 1].contents) {
                .empty => {},
                .children => unreachable,
                .items => {
                    try build_rec(self, children + 1, depth + 1, boids);
                },
            }
            switch (self.nodes.items[children + 2].contents) {
                .empty => {},
                .children => unreachable,
                .items => {
                    try build_rec(self, children + 2, depth + 1, boids);
                },
            }
            switch (self.nodes.items[children + 3].contents) {
                .empty => {},
                .children => unreachable,
                .items => {
                    try build_rec(self, children + 3, depth + 1, boids);
                },
            }
        },
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

fn swap(slice: []usize, a: usize, b: usize) void {
    if (a == b) return;
    const temp = slice[a];
    slice[a] = slice[b];
    slice[b] = temp;
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
