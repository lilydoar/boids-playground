const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});

const Boid = @import("boid.zig");
const Flock = @import("flock.zig");
const Render = @import("render.zig");
const Vec2 = @import("math.zig").Vec2;

pub fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var prng = std.rand.DefaultPrng.init(0);
    const rand = prng.random();
    if (!sdl.SDL_SetAppMetadata("Boids", "0.0.1", "com.lilydoar.boids"))
        return error.SDL_SetAppMetadata;

    // SDL initialization
    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO))
        return error.SDL_INIT_VIDEO;
    defer sdl.SDL_Quit();

    const window_size = 800;
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
    const origin = .{
        .x = window_size / 2.0,
        .y = window_size / 2.0,
    };
    const flock_count = 400;
    const boid_size = 10.0;
    const boundary_padding = boid_size / 2.0;
    const draw_opts = .{
        .boundary_color = .{ .r = 0, .g = 255, .b = 255, .a = 255 },
        .quadtree_color = .{ .r = 0, .g = 255, .b = 0, .a = 255 },
    };

    var flock = Flock.init(alloc, .{
        .boid_size = boid_size,
        .boid_color = .{ .r = 255, .g = 255, .b = 255, .a = 255 },

        .max_speed = boid_size * 0.8,
        .boundary = .{
            .min = .{
                .x = -window_size / 2.0 - boundary_padding,
                .y = -window_size / 2.0 - boundary_padding,
            },
            .max = .{
                .x = window_size / 2.0 + boundary_padding,
                .y = window_size / 2.0 + boundary_padding,
            },
        },

        .separation_distance = boid_size * 2.0,
        .separation_strength = 1.6,

        .cohesion_distance = boid_size * 6.0,
        .cohesion_strength = 0.6,
        .alignment_strength = 0.5,
    });
    defer flock.deinit();

    for (0..flock_count) |_| {
        try flock.boids.append(.{
            .pos = Vec2.rand_pos(rand, window_size / 2.0),
            .vel = Vec2.rand_dir(rand).scale(flock.desc.max_speed),
        });
        flock.boids.items[flock.boids.items.len - 1].wrap(flock.desc.boundary);
    }

    var render = Render.init(alloc, renderer, origin, &flock, draw_opts);
    defer render.deinit();

    var running = true;
    while (running) {
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
        try flock.quadtree.build(flock.boids.items);

        for (flock.boids.items) |*boid| {
            boid.accumulate(flock);
        }
        for (flock.boids.items) |*boid| {
            boid.integrate(0.01, flock.desc.max_speed);
            boid.wrap(flock.desc.boundary);
        }

        // Rendering
        if (!sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255))
            return error.SDL_SetRenderDrawColor;
        if (!sdl.SDL_RenderClear(renderer))
            return error.SDL_RenderClear;

        try render.draw();

        if (!sdl.SDL_RenderPresent(renderer))
            return error.SDL_RenderPresent;
    }
}
