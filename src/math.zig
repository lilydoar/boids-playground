const std = @import("std");
const epsilon = std.math.floatEps(f32);

pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn zero() Vec2 {
        return Vec2{ .x = 0.0, .y = 0.0 };
    }

    pub fn one() Vec2 {
        return Vec2{ .x = 1.0, .y = 1.0 };
    }

    /// Return a random vector inside a circle of radius r.
    pub fn rand_pos(random: std.rand.Random, radius: f32) Vec2 {
        const r = radius * @sqrt(random.float(f32));
        const angle = random.float(f32) * std.math.tau;
        return Vec2{
            .x = r * @cos(angle),
            .y = r * @sin(angle),
        };
    }

    /// Return a random direction vector.
    pub fn rand_dir(random: std.rand.Random) Vec2 {
        const angle = random.float(f32) * std.math.tau;
        return Vec2{
            .x = @cos(angle),
            .y = @sin(angle),
        };
    }

    pub fn is_zero(self: Vec2) bool {
        return @abs(self.x) < epsilon and @abs(self.y) < epsilon;
    }

    pub fn add(self: Vec2, other: Vec2) Vec2 {
        return Vec2{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    pub fn sub(self: Vec2, other: Vec2) Vec2 {
        return Vec2{
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }

    pub fn mul(self: Vec2, other: Vec2) Vec2 {
        return Vec2{
            .x = self.x * other.x,
            .y = self.y * other.y,
        };
    }

    pub fn scale(self: Vec2, scalar: f32) Vec2 {
        return Vec2{
            .x = self.x * scalar,
            .y = self.y * scalar,
        };
    }

    /// Normalize the vector to unit length.
    /// Panics if the vector is zero.
    pub fn normalize_unsafe(self: Vec2) Vec2 {
        const len = self.length();
        std.debug.assert(len != 0.0);
        return Vec2{
            .x = self.x / len,
            .y = self.y / len,
        };
    }

    /// Normalize the vector to unit length.
    /// Returns a zero vector if the vector is zero.
    pub fn normalize_safe(self: Vec2) Vec2 {
        const len = self.length();
        if (len < epsilon) return Vec2{ .x = 0.0, .y = 0.0 };
        return Vec2{
            .x = self.x / len,
            .y = self.y / len,
        };
    }

    pub fn length(self: Vec2) f32 {
        return @sqrt(self.x * self.x + self.y * self.y);
    }

    pub fn length_sqr(self: Vec2) f32 {
        return self.x * self.x + self.y * self.y;
    }

    pub fn dist(self: Vec2, other: Vec2) f32 {
        const diff = self.add(other.scale(-1.0));
        return @sqrt(diff.x * diff.x + diff.y * diff.y);
    }

    pub fn limit(self: Vec2, max: f32) Vec2 {
        const len_sqr = self.length_sqr();

        if (len_sqr > max * max) {
            return self.scale(max / @sqrt(len_sqr));
        } else {
            return self;
        }
    }

    pub fn translate(self: Vec2, other: Vec2) Vec2 {
        return add(self, other);
    }

    pub fn rotate(self: Vec2, dir: Vec2) Vec2 {
        return Vec2{
            .x = self.x * dir.x - self.y * dir.y,
            .y = self.x * dir.y + self.y * dir.x,
        };
    }
};

pub const AABB = struct {
    min: Vec2,
    max: Vec2,

    pub fn center(self: AABB) Vec2 {
        return Vec2{
            .x = (self.min.x + self.max.x) / 2.0,
            .y = (self.min.y + self.max.y) / 2.0,
        };
    }

    pub fn dimensions(self: AABB) Vec2 {
        return Vec2{
            .x = self.max.x - self.min.x,
            .y = self.max.y - self.min.y,
        };
    }

    pub fn overlaps(self: AABB, other: AABB) bool {
        return self.min.x <= other.max.x and
            self.max.x >= other.min.x and
            self.min.y <= other.max.y and
            self.max.y >= other.min.y;
    }

    pub fn contains(self: AABB, pos: Vec2) bool {
        return pos.x >= self.min.x and pos.x <= self.max.x and
            pos.y >= self.min.y and pos.y <= self.max.y;
    }

    pub fn closest_point(self: AABB, pos: Vec2) Vec2 {
        return Vec2{
            .x = std.math.clamp(pos.x, self.min.x, self.max.x),
            .y = std.math.clamp(pos.y, self.min.y, self.max.y),
        };
    }

    // Return a sub-AABB corresponding to a quadrant of the AABB:
    // 0: top-left
    // 1: top-right
    // 2: bottom-left
    // 3: bottom-right
    pub fn quadrant(self: AABB, index: usize) AABB {
        const c = self.center();
        return AABB{
            .min = switch (index) {
                0 => self.min,
                1 => Vec2{ .x = c.x, .y = self.min.y },
                2 => Vec2{ .x = self.min.x, .y = c.y },
                3 => c,
                else => unreachable,
            },
            .max = switch (index) {
                0 => c,
                1 => Vec2{ .x = self.max.x, .y = c.y },
                2 => Vec2{ .x = c.x, .y = self.max.y },
                3 => self.max,
                else => unreachable,
            },
        };
    }
};

pub fn jitter(random: std.rand.Random, value: f32, amount: f32) f32 {
    return value + (random.float(f32) - 0.5) * amount;
}
