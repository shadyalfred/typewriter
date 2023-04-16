Plays a typewriter key sound on every key press.

# Dependencies
- X11
- SDL2, SDL2_mixer `sudo pacman -S sdl2 sdl2_mixer`

I've tried it with Zig version 0.11.0-dev.2336+5b82b4004.

# Command to run
`zig run typewriter.zig -lc -lX11 -lSDL2 -lSDL2_mixer`

# Command to build
`zig build-exe typewriter.zig -lc -lX11 -lSDL2 -lSDL2_mixer`


[typewriter.webm](https://user-images.githubusercontent.com/3685582/232262693-80b21027-deb6-4c41-836d-61cabee4d8fd.webm)
