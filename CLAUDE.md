# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Zelerk is a native macOS menu bar application for playing AzuraCast radio streams. It supports MP3 and HLS stream formats with playback controls and now-playing song display.

## Build Commands

```bash
swift build
swift run
```

## Architecture

This is a Swift-based macOS menu bar app using:
- **AppKit** for menu bar integration via NSStatusItem
- **AVFoundation** (AVPlayer) for HLS/MP3 audio playback
- **UserDefaults** for station configuration storage
- **URLSession** for AzuraCast API integration (now-playing metadata)

### Project Structure

```
Sources/Zelerk/
├── main.swift                 # App entry point
├── App/
│   └── ZelerkApp.swift        # NSApplicationDelegate setup
├── MenuBar/
│   ├── StatusBarController.swift   # NSStatusItem management
│   ├── MenuBuilder.swift           # NSMenu construction
│   └── ScrollingTextView.swift     # Animated song title
├── Player/
│   └── StreamPlayer.swift          # AVPlayer wrapper
├── Models/
│   ├── Station.swift               # Stream URL + metadata
│   └── NowPlaying.swift            # Current song info
├── Services/
│   ├── StationManager.swift        # Station CRUD + persistence
│   └── NowPlayingService.swift     # AzuraCast API polling
└── Views/
    └── ConfigurationWindow.swift   # Station management UI
```

### Minimum Requirements
- macOS 12.0 (Monterey)
- Swift 5.9+
