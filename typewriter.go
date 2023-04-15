package main

// #cgo LDFLAGS: -lX11
// #include <X11/Xlib.h>
// #include <X11/XKBlib.h>
import "C"
import (
	"fmt"
	"log"
	"math/rand"
	"os"
	"unsafe"

	"github.com/faiface/beep"
	"github.com/faiface/beep/speaker"
	"github.com/faiface/beep/wav"
)

const (
	defaultKey C.uint = 0
	backspace  C.uint = 22
	enter      C.uint = 36
	space      C.uint = 65
	sampleRate int    = 44100
)

type SoundInfo struct {
	start, end int
}

func main() {
	soundsInfo := make(map[C.uint][]SoundInfo)
	soundsBuffer := loadSounds(&soundsInfo)

	display := C.XOpenDisplay(nil)
	defer C.XCloseDisplay(display)

	defaultWindow := C.XDefaultRootWindow(display)

	var currentWindow C.Window
	var revert C.int
	var isAutoRepeatSet C.int

	C.XGetInputFocus(display, &currentWindow, &revert)
	C.XSelectInput(display, currentWindow, C.KeyPressMask|C.KeyReleaseMask|C.FocusChangeMask)
	C.XkbSetDetectableAutoRepeat(display, 1, &isAutoRepeatSet)

	speaker.Init(beep.SampleRate(sampleRate), sampleRate/10)

	wasReleased := true
	var latestPressedKey C.uint = 0
	for {
		var event C.XEvent
		C.XNextEvent(display, &event)
		eventType := (*C.uint)(unsafe.Pointer(&event))

		switch *eventType {
		case C.FocusOut:
			C.XGetInputFocus(display, &currentWindow, &revert)
			if currentWindow == C.PointerRoot {
				currentWindow = defaultWindow
			}
			C.XSelectInput(display, currentWindow, C.KeyPressMask|C.KeyReleaseMask|C.FocusChangeMask)
			break

		case C.KeyPress:
			pressedKey := (*C.XKeyEvent)(unsafe.Pointer(&event)).keycode
			if latestPressedKey != pressedKey {
				wasReleased = true
			}

			if !wasReleased {
				continue
			}

			var sound beep.StreamSeeker

			switch pressedKey {
			case enter:
				soundInfo := soundsInfo[enter][0]
				sound = soundsBuffer.Streamer(soundInfo.start, soundInfo.end)
				break
			case space:
				soundInfo := soundsInfo[space][0]
				sound = soundsBuffer.Streamer(soundInfo.start, soundInfo.end)
				break
			case backspace:
				soundInfo := soundsInfo[backspace][0]
				sound = soundsBuffer.Streamer(soundInfo.start, soundInfo.end)
				break
			default:
				soundInfo := soundsInfo[defaultKey][rand.Intn(4)]
				sound = soundsBuffer.Streamer(soundInfo.start, soundInfo.end)
				break
			}

			speaker.Play(sound)
			latestPressedKey = pressedKey
			wasReleased = false
			break

		case C.KeyRelease:
			wasReleased = true
			break
		}
	}
}

func loadSounds(soundsInfo *map[C.uint][]SoundInfo) *beep.Buffer {
	fileNames := [...]string{
		"key-new-01.wav",
		"key-new-02.wav",
		"key-new-03.wav",
		"key-new-04.wav",
		"key-new-05.wav",
		"backspace.wav",
		"return-new.wav",
		"space-new.wav",
	}

	keys := [...]C.uint{
		defaultKey,
		defaultKey,
		defaultKey,
		defaultKey,
		defaultKey,
		backspace,
		enter,
		space,
	}

	buffer := beep.NewBuffer(beep.Format{SampleRate: beep.SampleRate(sampleRate), NumChannels: 2, Precision: 2})
	prevEnd := 0

	for i, fileName := range fileNames {
		f, err := os.Open(fmt.Sprintf("./sounds/%s", fileName))
		if err != nil {
			log.Fatal(err)
		}

		streamer, _, err := wav.Decode(f)
		if err != nil {
			log.Fatal(err)
		}

		buffer.Append(streamer)
		streamer.Close()

		key := keys[i]
		soundInfo, exists := (*soundsInfo)[key]

		sI := SoundInfo{
			start: prevEnd + 1,
			end:   buffer.Len(),
		}

		if !exists {
			(*soundsInfo)[key] = []SoundInfo{sI}
		} else {
			(*soundsInfo)[key] = append(soundInfo, sI)
		}

		prevEnd = buffer.Len()
	}

	return buffer
}
