# Selects

A fast macOS image viewer for culling and rating photos.

Browse folders, rate images with 1–5 stars, and delete with a single key. JPG + RAW pairs are handled as one unit.

## Features

- **Sidebar** – filesystem tree for quick folder navigation
- **Main view** – large preview with star rating overlay
- **Filmstrip** – all images in a scrollable strip, auto-scrolls to current
- **Rate** – press 1–5 to set star rating (written to macOS extended attributes, visible in Finder)
- **Delete** – press ⌫ to trash JPG + RAW simultaneously
- **Fullscreen** – press Space to toggle

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon or Intel

## Install

### Download

Download the latest release from [Releases](https://github.com/vemsom/selects/releases).

### Build from source

```bash
git clone https://github.com/vemsom/selects.git
cd selects
swift run
```

Or use the build script which creates a proper `.app` bundle:

```bash
bash run.sh
```

## Usage

| Key | Action |
|-----|--------|
| ← / → | Previous / next image |
| ⌫ Delete | Move to Trash (JPG + RAW) |
| 1–5 | Set star rating |
| 0 | Clear rating |
| Space | Toggle fullscreen |
| ⌘O | Open folder |
| Swipe | Navigate left / right |

## License

MIT
