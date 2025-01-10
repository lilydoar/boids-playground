const std = @import("std");
const epsilon = @import("std").math.floatEps(f32);

const Flock = @import("flock.zig");

const math = @import("math.zig");
const Vec2 = math.Vec2;
const AABB = math.AABB;

pos: Vec2 = Vec2.zero(),
vel: Vec2 = Vec2.zero(),
acc: Vec2 = Vec2.zero(),

const Self = @This();

pub fn accumulate(self: *Self, flock: Flock) void {
    accumulate_separation(self, flock);
    accumulate_cohesion_and_alignment(self, flock);
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

fn accumulate_separation(self: *Self, flock: Flock) void {
    var separation = Vec2.zero();

    for (flock.boids.items) |other| {
        const diff = self.pos.sub(other.pos);
        const dist = diff.length();
        if (dist < epsilon) continue;
        if (dist > flock.desc.separation_distance) continue;
        separation = separation.add(diff.scale(1.0 / dist));
    }

    self.acc = self.acc.add(separation.scale(flock.desc.separation_strength));
}

fn accumulate_cohesion_and_alignment(self: *Self, flock: Flock) void {
    var cohesion_force = Vec2.zero();
    var alignment_force = Vec2.zero();
    var neighbor_count: u32 = 0;

    for (flock.boids.items) |other| {
        const diff = self.pos.sub(other.pos);
        const dist = diff.length();
        if (dist < epsilon) continue;
        if (dist > flock.desc.cohesion_distance) continue;
        neighbor_count += 1;
        cohesion_force = cohesion_force.add(other.pos);
        alignment_force = alignment_force.add(other.vel);
    }
    if (neighbor_count == 0) return;

    const scalar = 1.0 / @as(f32, @floatFromInt(neighbor_count));
    cohesion_force = cohesion_force.scale(scalar).sub(self.pos).normalize();
    alignment_force = alignment_force.scale(scalar).normalize();

    self.acc = self.acc.add(cohesion_force.scale(flock.desc.cohesion_strength));
    self.acc = self.acc.add(alignment_force.scale(flock.desc.alignment_strength));
}
