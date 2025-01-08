const std = @import("std");
const testing = std.testing;

const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});

pub fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    if (!sdl.SDL_SetAppMetadata("Boids", "0.0.1", "com.lilydoar.boids"))
        return error.SDL_SetAppMetadata;

    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO))
        return error.SDL_INIT_VIDEO;
    defer sdl.SDL_Quit();

    const window = sdl.SDL_CreateWindow("Boids", 600, 600, 0) orelse
        return error.SDL_CreateWindowAndRenderer;
    defer sdl.SDL_DestroyWindow(window);

    const renderer = sdl.SDL_CreateRenderer(window, null) orelse
        return error.SDL_CreateRenderer;
    defer sdl.SDL_DestroyRenderer(renderer);

    const vert = try alloc.alloc(sdl.SDL_Vertex, 3);

    // center
    vert[0].position.x = 400;
    vert[0].position.y = 150;
    vert[0].color.r = 1.0;
    vert[0].color.g = 0.0;
    vert[0].color.b = 0.0;
    vert[0].color.a = 1.0;

    // left
    vert[1].position.x = 200;
    vert[1].position.y = 450;
    vert[1].color.r = 0.0;
    vert[1].color.g = 0.0;
    vert[1].color.b = 1.0;
    vert[1].color.a = 1.0;

    // right
    vert[2].position.x = 800;
    vert[2].position.y = 450;
    vert[2].color.r = 0.0;
    vert[2].color.g = 1.0;
    vert[2].color.b = 0.0;
    vert[2].color.a = 1.0;

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

        // Rendering
        if (!sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255))
            return error.SDL_SetRenderDrawColor;
        if (!sdl.SDL_RenderClear(renderer))
            return error.SDL_RenderClear;
        if (!sdl.SDL_RenderGeometry(renderer, null, vert.ptr, 3, null, 0))
            return error.SDL_RenderGeometry;
        if (!sdl.SDL_RenderPresent(renderer))
            return error.SDL_RenderPresent;
    }
}
