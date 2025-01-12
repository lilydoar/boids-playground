const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});

const HSV = @import("color/hsv.zig");
const RGB = @import("color/rgb.zig");

const Boid = @import("boid.zig");
const Flock = @import("flock.zig");
const Render = @import("render.zig");
const Vec2 = @import("math.zig").Vec2;

pub fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const scratch = arena.allocator();

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();
    if (!sdl.SDL_SetAppMetadata("Boids", "0.0.1", "com.lilydoar.boids"))
        return error.SDL_SetAppMetadata;

    // SDL initialization
    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO))
        return error.SDL_INIT_VIDEO;
    defer sdl.SDL_Quit();

    const window_size = 1100;
    const window = sdl.SDL_CreateWindow(
        "Boids",
        window_size,
        window_size,
        0,
    ) orelse
        return error.SDL_CreateWindowAndRenderer;
    defer sdl.SDL_DestroyWindow(window);

    const renderer = sdl.SDL_CreateRenderer(window, null) orelse
        return error.SDL_CreateRenderer;
    defer sdl.SDL_DestroyRenderer(renderer);

    // Flock initialization
    const origin = Vec2{
        .x = @as(f32, @floatFromInt(window_size)) / 2.0,
        .y = @as(f32, @floatFromInt(window_size)) / 2.0,
    };
    const flock_size = 200;
    const boid_size = 10.0;
    const boundary_padding = Vec2{
        .x = boid_size / 2.0,
        .y = boid_size / 2.0,
    };
    const draw_opts = .{
        .background_col = .{ .r = 64, .g = 64, .b = 64, .a = 255 },
        .boundary_col = .{ .r = 0, .g = 255, .b = 255, .a = 255 },
        .quadtree_col = .{ .r = 0, .g = 255, .b = 0, .a = 255 },
    };

    var flocks = std.ArrayList(Flock).init(alloc);
    defer {
        for (flocks.items) |flock| flock.deinit();
        flocks.deinit();
    }

    const flock_count = 4;
    for (0..flock_count) |_| {
        const boid_color = RGB.from_hsv(HSV.rand_hue(rand, 0.9, 1.0));
        var flock = Flock.init(alloc, .{
            .boid_size = boid_size,
            .boid_color = .{
                .r = boid_color.r,
                .g = boid_color.g,
                .b = boid_color.b,
                .a = 1.0,
            },

            .max_speed = boid_size * 0.8,
            .boundary = .{
                .min = origin.scale(-1.0).sub(boundary_padding),
                .max = origin.add(boundary_padding),
            },

            .separation_distance = boid_size * 2.0,
            .separation_strength = 1.6,

            .cohesion_distance = boid_size * 6.0,
            .cohesion_strength = 0.6,
            .alignment_strength = 0.5,
        });

        for (0..flock_size) |_| {
            try flock.boids.append(.{
                .pos = Vec2.rand_pos(rand, @as(f32, @floatFromInt(window_size)) / 2.0),
                .vel = Vec2.rand_dir(rand).scale(flock.desc.max_speed),
            });
            flock.boids.items[flock.boids.items.len - 1].wrap(flock.desc.boundary);
        }

        try flocks.append(flock);
    }

    var render = Render.init(alloc, renderer, origin, flocks.items, draw_opts);
    defer render.deinit();

    var running = true;
    while (running) {
        defer _ = arena.reset(.retain_capacity);

        // Event handling
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event)) {
            if (event.type == sdl.SDL_EVENT_QUIT) {
                running = false;
            }
            if (event.type == sdl.SDL_EVENT_KEY_DOWN and
                event.key.key == sdl.SDLK_ESCAPE)
            {
                running = false;
            }
        }

        // Update
        for (flocks.items) |*flock| {
            try flock.quadtree.build(flock.boids.items);

            for (flock.boids.items) |*boid| {
                try boid.accumulate(scratch, flock.*);
            }
            for (flock.boids.items) |*boid| {
                boid.integrate(0.01, flock.desc.max_speed);
                boid.wrap(flock.desc.boundary);
            }
        }

        // Rendering
        try render.draw();
    }
}
