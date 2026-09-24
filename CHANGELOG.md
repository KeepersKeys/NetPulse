# Changelog

## 0.2.0-alpha — 2026-09-24

NetPulse's first feature-complete Alpha milestone includes:

- Live FPS, Home latency, and World latency monitoring with threshold-based colors.
- Movable, resizable horizontal and vertical display layouts with persistent per-layout sizes.
- Minimal, Dark, Blizzard, and Forged themes.
- A compact Retail settings panel for lock state, orientation, theme, minimap visibility, and display reset.
- An optional draggable minimap button with persistent position and a dedicated NetPulse icon.
- Slash commands for settings, layout, theme, lock state, reset, minimap visibility, and diagnostics.
- Hardened startup sequencing, visible fallback display state, step-level error reporting, and `/np debug` diagnostics.
- Schema 2 SavedVariables migration and validation for existing Alpha profiles.
- Timer-based polling at 0.5 seconds for FPS and 30 seconds for network latency, with no permanent idle `OnUpdate` handler.
