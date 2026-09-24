# NetPulse

NetPulse is a lightweight World of Warcraft Retail addon that displays current FPS, Home latency, and World latency as one movable and resizable unit.

## Alpha features

- Horizontal and vertical layouts
- Persistent position and per-layout size
- Lock and unlock controls
- Minimal, Dark, Blizzard, and Forged themes
- Performance-based colors for FPS and latency
- Small in-game settings panel
- Optional draggable minimap button
- Dedicated NetPulse addon and minimap icon
- Timer-based updates with no permanent idle `OnUpdate`

## Installation

Copy the `NetPulse` folder into:

`World of Warcraft\_retail_\Interface\AddOns\NetPulse`

The final path must contain `NetPulse\NetPulse.toc` directly. Restart World of Warcraft or reload the UI after installing.

## Slash commands

- `/netpulse` or `/np` — open settings
- `/np lock`
- `/np unlock`
- `/np reset`
- `/np debug` — print Alpha startup and display state
- `/np horizontal`
- `/np vertical`
- `/np minimap on|off`
- `/np theme` — list themes
- `/np theme minimal|dark|blizzard|forged`

## Version

`0.1.6-alpha`

## Screenshots

Screenshot coming later.

## Development status

NetPulse is an early Alpha focused only on FPS, Home latency, and World latency.
