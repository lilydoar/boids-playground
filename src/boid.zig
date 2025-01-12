const std = @import("std");
const epsilon = std.math.floatEps(f32);

const Flock = @import("flock.zig");

const math = @import("math.zig");
const Vec2 = math.Vec2;
const AABB = math.AABB;

pos: Vec2 = Vec2.zero(),
vel: Vec2 = Vec2.zero(),
acc: Vec2 = Vec2.zero(),

const Self = @This();

pub fn accumulate(self: *Self, alloc: std.mem.Allocator, flock: Flock) !void {
    var query = try flock.quadtree.query(alloc, flock.boids.items, .{
        .min = self.pos.sub(.{
            .x = flock.desc.cohesion_distance,
            .y = flock.desc.cohesion_distance,
        }),
        .max = self.pos.add(.{
            .x = flock.desc.cohesion_distance,
            .y = flock.desc.cohesion_distance,
        }),
    });
    defer query.deinit();

    var separation = Vec2.zero();
    var cohesion = Vec2.zero();
    var alignment = Vec2.zero();
    var neighbor_count: u32 = 0;

    while (try query.next()) |i| {
        const other = flock.boids.items[i];

        {
            const diff = self.pos.sub(other.pos);
            const dist = diff.length();
            if (dist >= epsilon and dist <= flock.desc.separation_distance) {
                separation = separation.add(diff.scale(1.0 / dist));
            }
        }

        {
            const diff = self.pos.sub(other.pos);
            const dist = diff.length();
            if (dist < epsilon) continue;
            if (dist > flock.desc.cohesion_distance) continue;
            neighbor_count += 1;
            cohesion = cohesion.add(other.pos);
            alignment = alignment.add(other.vel);
        }
    }

    self.acc = self.acc.add(separation.scale(flock.desc.separation_strength));

    if (neighbor_count == 0) return;

    const scalar = 1.0 / @as(f32, @floatFromInt(neighbor_count));

    cohesion = cohesion.scale(scalar).sub(self.pos).normalize_safe();
    self.acc = self.acc.add(cohesion.scale(flock.desc.cohesion_strength));

    alignment = alignment.scale(scalar).normalize_unsafe();
    self.acc = self.acc.add(alignment.scale(flock.desc.alignment_strength));
}

pub fn integrate(self: *Self, delta_time: f32, max_speed: f32) void {
    self.vel = self.vel.add(self.acc.scale(delta_time)).limit(max_speed);
    self.pos = self.pos.add(self.vel.scale(delta_time));
    self.acc = Vec2.zero();
}

pub fn wrap(self: *Self, boundary: AABB) void {
    if (self.pos.x < boundary.min.x) self.pos.x = boundary.max.x;
    if (self.pos.y < boundary.min.y) self.pos.y = boundary.max.y;
    if (self.pos.x > boundary.max.x) self.pos.x = boundary.min.x;
    if (self.pos.y > boundary.max.y) self.pos.y = boundary.min.y;
}
