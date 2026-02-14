# zelerK

A native macOS menu bar application for playing [AzuraCast](https://www.azuracast.com/) radio streams.

## Features

- Menu bar playback controls (left-click to play/pause, right-click for full menu)
- MP3 and HLS stream format support
- Now-playing song display with optional menu bar title
- AzuraCast API integration for live metadata (song title, artist, album)
- Multi-station management with quick switching
- Volume control
- Start at Login support (macOS 13+)

## Requirements

- macOS 12.0 (Monterey) or later
- Swift 5.9+

## Building

```
make build       # compile release binary
make app         # create .app bundle
make dmg         # create DMG installer
make install     # copy .app to /Applications
make clean       # remove build artifacts
```

## Installation

Download the latest DMG from [Releases](https://github.com/ruohki/zelerk-player/releases), open it, and drag zelerK to your Applications folder.

Or build from source:

```
make install
```

## Configuration

Right-click the menu bar icon and select "Stations..." to add your AzuraCast stations. Each station needs:

- **Name** -- display name in the menu
- **Stream URL** -- direct MP3 or HLS stream URL
- **API URL** (optional) -- AzuraCast now-playing API endpoint for live metadata

## Releasing

Versions are managed through the Makefile:

```
make version          # show current version
make release-patch    # 1.0.0 -> 1.0.1 (signed commit + tag)
make release-minor    # 1.0.0 -> 1.1.0
make release-major    # 1.0.0 -> 2.0.0
```

After creating a release, push to trigger the GitHub Actions build:

```
git push && git push --tags
```

This automatically builds the DMG and creates a GitHub Release.

## License

All rights reserved.
