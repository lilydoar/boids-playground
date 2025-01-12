const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});

h: f32, // 0-360
s: f32, // 0-1
v: f32, // 0-1
a: f32, // 0-1

const Self = @This();

pub fn rand(r: std.rand.Random) Self {
    return .{
        .h = r.float(f32) * 360.0,
        .s = r.float(f32),
        .v = r.float(f32),
        .a = 1.0,
    };
}

pub fn rand_hue(r: std.rand.Random, s: f32, v: f32) Self {
    return .{
        .h = r.float(f32) * 360.0,
        .s = s,
        .v = v,
        .a = 1.0,
    };
}
