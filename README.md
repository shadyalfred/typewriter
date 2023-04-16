Plays a typewriter key sound on every key press.

# Dependencies
- X11
- SDL2, SDL2_mixer `sudo pacman -S sdl2 sdl2_mixer`

I've tried it with Zig version 0.11.0-dev.2336+5b82b4004.

# Command to run
`zig run typewriter.zig -lc -lX11 -lSDL2 -lSDL2_mixer`

# Command to build
`zig build-exe typewriter.zig -lc -lX11 -lSDL2 -lSDL2_mixer`
