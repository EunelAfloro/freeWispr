# FreeWispr — Local Whisper-based Dictation for macOS

## Overview

A native macOS menu bar app that replaces Apple Dictation with local, privacy-first speech-to-text powered by whisper.cpp. All processing runs on-device — no cloud, no network calls.

## Architecture

Single native macOS app (SwiftUI) that lives in the menu bar. No main window — just a menu bar icon with a dropdown for settings.

Flow:
1. Listens for a global hotkey via CGEvent tap (requires Accessibility permission)
2. Records audio from the default input device using AVAudioEngine (requires Microphone permission)
3. Detects silence to know when the user stopped speaking (energy threshold + timeout)
4. Runs whisper.cpp inference on the audio buffer using the embedded C library
5. Injects text into the focused application via AXUIElement Accessibility APIs

## Technology

- **Language:** Swift
- **UI:** SwiftUI (menu bar only)
- **Speech-to-text:** whisper.cpp embedded via Swift Package Manager
- **Audio:** AVAudioEngine
- **Hotkey:** CGEvent tap
- **Text injection:** AXUIElement Accessibility API + CGEvent keyboard simulation fallback

## Components

| Component | Responsibility |
|-----------|---------------|
| `FreeWisprApp` | SwiftUI app entry point, menu bar setup |
| `HotkeyManager` | Registers/handles global hotkey via CGEvent tap |
| `AudioRecorder` | Captures audio via AVAudioEngine, detects silence |
| `WhisperTranscriber` | Wraps whisper.cpp C API — loads model, runs inference |
| `TextInjector` | Inserts transcribed text into focused app via AXUIElement |
| `ModelManager` | Downloads/manages whisper.ggml model files |
| `SettingsView` | SwiftUI view for hotkey config, model selection, language |

## Data Flow

```
Hotkey pressed -> Start audio capture -> User speaks -> Silence detected ->
Stop capture -> Convert to 16kHz mono float -> whisper_full() ->
Get text segments -> Inject text into focused app via Accessibility API
```

## Key Technical Details

- **Audio format:** whisper.cpp expects 16kHz mono float32 PCM. AVAudioEngine captures and converts.
- **Model storage:** `~/Library/Application Support/FreeWispr/models/` — downloaded on first run or when user switches model size.
- **Hotkey default:** Option+Space (configurable in settings). CGEvent tap for global capture.
- **Silence detection:** RMS energy threshold — if audio energy stays below threshold for ~1.5 seconds, stop recording.
- **Text injection:** AXUIElementSetAttributeValue with kAXValueAttribute, or simulated keyboard input via CGEvent for apps that don't support AX text setting.
- **Model sizes:** User-configurable — tiny, base (default), small, medium.
- **Transcription mode:** Batch after silence detection (not streaming).

## Permissions Required

- **Accessibility** (System Settings > Privacy > Accessibility) — for global hotkey + text injection
- **Microphone** (System Settings > Privacy > Microphone) — for audio capture

## Settings (Menu Bar Dropdown)

- Model size: tiny / base / small / medium (default: base)
- Language: auto-detect or specific language
- Hotkey: configurable shortcut
- Silence timeout: adjustable (default 1.5s)
