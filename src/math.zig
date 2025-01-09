const std = @import("std");

pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn zero() Vec2 {
        return Vec2{ .x = 0.0, .y = 0.0 };
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

    pub fn normalize(self: Vec2) Vec2 {
        const len = @sqrt(self.x * self.x + self.y * self.y);
        std.debug.assert(len != 0.0);

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
