Plays a typewriter key sound on every key press.

# Dependencies
- X11
- SDL2, SDL2_mixer `sudo pacman -S sdl2 sdl2_mixer`

I've tried it with Zig version 0.11.0-dev.2336+5b82b4004.

# Command to run
`zig run typewriter.zig -lc -lX11 -lSDL2 -lSDL2_mixer`

# Command to build
`zig build-exe typewriter.zig -lc -lX11 -lSDL2 -lSDL2_mixer`


[typewriter.webm](https://user-images.githubusercontent.com/3685582/232880927-938941ac-b92f-47f0-8120-e6c4b5b29596.webm)
