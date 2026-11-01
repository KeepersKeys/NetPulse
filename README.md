# NetPulse

NetPulse is a lightweight World of Warcraft Retail addon that displays current FPS, Home latency, World latency, and optional total addon memory in one movable, resizable monitor.

> Screenshot placeholder: NetPulse in-game display and settings panel.

## Features

- FPS, Home latency, and World latency monitoring
- Optional total addon-memory monitoring
- Horizontal and vertical layouts
- Persistent position and per-layout size
- Lock and unlock controls
- Minimal, Dark, Blizzard, Forged, and Blizzard Native themes
- Performance-based metric colors
- Compact native settings panel
- Optional draggable minimap button with a dedicated NetPulse icon
- Timer-based updates with no permanent idle `OnUpdate`

## Installation

1. Copy the `NetPulse` folder into `World of Warcraft\_retail_\Interface\AddOns`.
2. Confirm the final path contains `NetPulse\NetPulse.toc` directly.
3. Restart World of Warcraft or reload the UI.

## Settings

Open NetPulse settings from the minimap button, with `/netpulse` or `/np`, or from the AddOns section of the Retail Options window.

## Slash commands

- `/netpulse` or `/np` — open settings
- `/np lock` — lock the display
- `/np unlock` — unlock the display
- `/np reset` — reset position and size
- `/np horizontal` — use the horizontal layout
- `/np vertical` — use the vertical layout
- `/np minimap on|off` — show or hide the minimap button
- `/np theme` — list themes
- `/np theme minimal|dark|blizzard|forged|blizzardnative` — select a theme
- `/np debug` — print startup and display diagnostics

## Compatibility

- Version: `0.3.0`
- Client: World of Warcraft Retail 12.1.5
- Interface: `120105`

## Development status

NetPulse 0.3.0 adds optional addon-memory monitoring and the Blizzard Native theme while preserving the original three-metric display by default.
