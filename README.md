# NetPulse

NetPulse is a lightweight World of Warcraft Retail addon that displays current FPS, Home latency, and World latency in one movable, resizable monitor.

> Screenshot placeholder: NetPulse in-game display and settings panel.

## Features

- FPS, Home latency, and World latency monitoring
- Horizontal and vertical layouts
- Persistent position and per-layout size
- Lock and unlock controls
- Minimal, Dark, Blizzard, and Forged themes
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
- `/np theme minimal|dark|blizzard|forged` — select a theme
- `/np debug` — print startup and display diagnostics

## Compatibility

- Version: `0.2.0-alpha`
- Client: World of Warcraft Retail 12.1.0
- Interface: `120100`

## Development status

NetPulse is Alpha software. Its focused feature set is complete for the 0.2.0 Alpha milestone, but in-game testing across different UI scales and addon combinations is still encouraged.
