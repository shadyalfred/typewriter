const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/XKBlib.h");
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_mixer.h");
});

const std = @import("std");
var RandGen = std.rand.DefaultPrng.init(0);
const print = std.debug.print;

const Key = enum(c_uint) {
    Other = 0,
    Backspace = 22,
    Enter = 36,
    Space = 65,
};

pub fn main() !void {
    if (c.SDL_Init(c.SDL_INIT_AUDIO) < 0) {
        c.SDL_Quit();
        return;
    }
    defer c.SDL_Quit();

    if (c.Mix_OpenAudio(44100, c.MIX_DEFAULT_FORMAT, 2, 1024) == -1) {
        print("Couldn't initialize mix\n", .{});
        return;
    }

    var key_sounds = [_]*c.Mix_Chunk{
        c.Mix_QuickLoad_WAV(@constCast(@embedFile("./sounds/key-new-01.wav"))),
        c.Mix_QuickLoad_WAV(@constCast(@embedFile("./sounds/key-new-02.wav"))),
        c.Mix_QuickLoad_WAV(@constCast(@embedFile("./sounds/key-new-03.wav"))),
        c.Mix_QuickLoad_WAV(@constCast(@embedFile("./sounds/key-new-04.wav"))),
        c.Mix_QuickLoad_WAV(@constCast(@embedFile("./sounds/key-new-05.wav"))),
    };
    defer freeKeySounds(&key_sounds);

    const enter_sound = c.Mix_QuickLoad_WAV(@constCast(@embedFile("./sounds/return-new.wav")));
    defer freeKeySound(enter_sound);

    const space_sound = c.Mix_QuickLoad_WAV(@constCast(@embedFile("./sounds/space-new.wav")));
    defer freeKeySound(space_sound);

    const backspace_sound = c.Mix_QuickLoad_WAV(@constCast(@embedFile("./sounds/backspace.wav")));
    defer freeKeySound(backspace_sound);

    _ = c.Mix_AllocateChannels(10);

    const display = c.XOpenDisplay(0);
    defer _ = c.XCloseDisplay(display);

    const default_window = c.XDefaultRootWindow(display);

    var current_window: c.Window = undefined;
    var revert: c_int = 0;
    var is_auto_repeat_set: c_int = 0;

    _ = c.XGetInputFocus(display, &current_window, &revert);
    _ = c.XSelectInput(display, current_window, c.KeyPressMask | c.KeyReleaseMask | c.FocusChangeMask);
    _ = c.XkbSetDetectableAutoRepeat(display, 1, &is_auto_repeat_set);

    var was_released = true;
    var latest_pressed_key: c_uint = 0;

    while (true) {
        const optional_system_event = getEvent();

        if (optional_system_event) |system_event| {
            switch (system_event.type) {
                c.SDL_QUIT => break,
                else => {},
            }
        }

        var event: c.XEvent = undefined;

        _ = c.XNextEvent(display, &event);

        switch (event.type) {
            c.FocusOut => {
                _ = c.XGetInputFocus(display, &current_window, &revert);
                if (current_window == c.PointerRoot) {
                    current_window = default_window;
                }
                _ = c.XSelectInput(display, current_window, c.KeyPressMask | c.KeyReleaseMask | c.FocusChangeMask);
            },

            (c.KeyPress) => {
                const pressed_key = event.xkey.keycode;

                if (latest_pressed_key != pressed_key) {
                    was_released = true;
                }

                if (!was_released) {
                    continue;
                }

                switch (pressed_key) {
                    @enumToInt(Key.Enter) => {
                        _ = c.Mix_PlayChannel(-1, enter_sound, 0);
                    },
                    @enumToInt(Key.Backspace) => {
                        _ = c.Mix_PlayChannel(-1, backspace_sound, 0);
                    },
                    @enumToInt(Key.Space) => {
                        _ = c.Mix_PlayChannel(-1, space_sound, 0);
                    },
                    else => {
                        _ = c.Mix_PlayChannel(-1, key_sounds[@mod(RandGen.random().int(usize), 5)], 0);
                    },
                }

                latest_pressed_key = pressed_key;
                was_released = false;
            },

            (c.KeyRelease) => {
                was_released = true;
            },

            else => continue,
        }
    }
}

fn getEvent() ?c.SDL_Event {
    var event: c.SDL_Event = undefined;

    if (c.SDL_PollEvent(&event) == 0) {
        return null;
    }

    return event;
}

fn freeKeySounds(mix_chunks: []*c.Mix_Chunk) void {
    for (mix_chunks) |mix_chunk| {
        c.Mix_FreeChunk(mix_chunk);
    }
}

fn freeKeySound(mix_chunk: *c.Mix_Chunk) void {
    c.Mix_FreeChunk(mix_chunk);
}
