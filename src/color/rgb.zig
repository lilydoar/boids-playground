const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});

const epsilon = @import("std").math.floatEps(f32);

const HSV = @import("hsv.zig");

r: f32, // 0-1
g: f32, // 0-1
b: f32, // 0-1
a: f32, // 0-1

const Self = @This();

pub fn rand(r: std.rand.Random) Self {
    return .{
        .r = r.float(f32),
        .g = r.float(f32),
        .b = r.float(f32),
        .a = 1.0,
    };
}

pub fn from_hsv(hsv: HSV) Self {
    const h = hsv.h;
    const s = hsv.s;
    const v = hsv.v;
    const a = hsv.a;

    if (s < epsilon) {
        return .{ .r = v, .g = v, .b = v, .a = a };
    }

    const h_norm = @mod(h / 360.0, 1.0);

    const i = @as(u32, @intFromFloat(h_norm * 6.0));
    const f = h_norm * 6.0 - @as(f32, @floatFromInt(i));

    const w = v * (1.0 - s);
    const q = v * (1.0 - s * f);
    const t = v * (1.0 - s * (1.0 - f));

    return switch (i) {
        0 => .{ .r = v, .g = t, .b = w, .a = a },
        1 => .{ .r = q, .g = v, .b = w, .a = a },
        2 => .{ .r = w, .g = v, .b = t, .a = a },
        3 => .{ .r = w, .g = q, .b = v, .a = a },
        4 => .{ .r = t, .g = w, .b = v, .a = a },
        else => .{ .r = v, .g = w, .b = q, .a = a },
    };
}

pub fn luminance(self: Self) f32 {
    // https://en.wikipedia.org/wiki/Relative_luminance
    const r = 0.2126;
    const g = 0.7152;
    const b = 0.0722;
    return r * self.r + g * self.g + b * self.b;
}
