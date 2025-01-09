const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});

const Boid = @import("boid.zig");
const Flock = @import("flock.zig");
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
    const boid_size = 10.0;
    var flock = Flock.init(alloc, .{
        .boid_size = boid_size,
        .max_speed = boid_size * 0.8,

        .separation_distance = boid_size * 2.2,
        .cohesion_distance = boid_size * 8.0,

        .separation_strength = 1.4,
        .cohesion_strength = 0.6,
        .alignment_strength = 0.8,
    });
    defer flock.deinit();

    const flock_count = 200;
    for (0..flock_count) |_| {
        try flock.boids.append(.{
            .pos = Vec2.rand_pos(rand, window_size / 2.0),
            .vel = Vec2.rand_dir(rand).scale(flock.desc.max_speed),
        });
    }

    var flock_render = Flock.Renderer.init(alloc);
    defer flock_render.deinit();

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
        for (flock.boids.items) |*boid| {
            boid.accumulate(flock);
        }
        for (flock.boids.items) |*boid| {
            boid.integrate(0.01, flock.desc.max_speed);
        }

        // Rendering
        if (!sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255))
            return error.SDL_SetRenderDrawColor;
        if (!sdl.SDL_RenderClear(renderer))
            return error.SDL_RenderClear;

        const origin = Vec2{ .x = window_size / 2.0, .y = window_size / 2.0 };
        const color = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
        try flock_render.render(renderer, flock, origin, boid_size, color);

        if (!sdl.SDL_RenderPresent(renderer))
            return error.SDL_RenderPresent;
    }
}
