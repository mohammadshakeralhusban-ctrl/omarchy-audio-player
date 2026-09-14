# Caelestia Audio Player

A now-playing audio player bar widget for [Omarchy Quattro](https://omarchy.org/) with album art, MusicBrainz genre detection, and vocal/instrumental classification.

## Features

- **Smart player selection** — automatically follows your active music player (Spotify, Vesktop, Chromium, Firefox, mpv, etc.)
- **Album art** — shows current track artwork in the bar and popup
- **Genre detection** — queries MusicBrainz to identify song genre
- **Vocal/Instrumental** — classifies tracks as vocal or instrumental
- **Sticky display** — remembers the last track even if a player momentarily clears its metadata
- **Controls** — play/pause, next/previous, scroll wheel navigation
- **Themed** — adapts to your Omarchy shell colors automatically

## Install

```bash
omarchy plugin add https://github.com/mohammadshakeralhusban-ctrl/omarchy-audio-player --enable
```

## Controls

| Action | How |
|---|---|
| Play / Pause | Click the widget |
| Next track | Click the right arrow, scroll wheel down, or middle-click |
| Previous track | Click the left arrow, scroll wheel up |
| Open popup | Right-click the widget |

## Requirements

- `curl` (for MusicBrainz API lookups)
- Internet connection (genre detection only; playback works offline)

## IPC Commands

Use these to control the player from scripts or other tools:

```bash
omarchy shell caelestia-audio status
omarchy shell caelestia-audio playPause
omarchy shell caelestia-audio next
omarchy shell caelestia-audio previous
omarchy shell caelestia-audio ping
```

## Remove

```bash
omarchy plugin disable mohammad284284.caelestia-audio
rm -rf ~/.config/omarchy/plugins/mohammad284284.caelestia-audio
```

## License

MIT
