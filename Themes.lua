local _, NetPulse = ...

local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local STANDARD_FONT = "Fonts\\FRIZQT__.TTF"

NetPulse.themeOrder = {
    "minimal",
    "dark",
    "blizzard",
    "forged",
    "blizzardnative",
}

NetPulse.Themes = {
    minimal = {
        displayName = "Minimal",
        font = STANDARD_FONT,
        fontFlags = "OUTLINE",
        labelColor = { 0.72, 0.74, 0.77 },
        valueColor = { 0.90, 0.91, 0.93 },
        separatorColor = { 0.42, 0.45, 0.49 },
        backdrop = {
            bgFile = WHITE_TEXTURE,
        },
        backgroundColor = { 0.02, 0.02, 0.02, 0.02 },
        borderColor = { 0, 0, 0, 0 },
        gripAlpha = 0.55,
    },
    dark = {
        displayName = "Dark",
        font = STANDARD_FONT,
        fontFlags = "OUTLINE",
        labelColor = { 0.78, 0.80, 0.84 },
        valueColor = { 0.90, 0.92, 0.95 },
        separatorColor = { 0.38, 0.42, 0.48 },
        backdrop = {
            bgFile = WHITE_TEXTURE,
            edgeFile = WHITE_TEXTURE,
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        },
        backgroundColor = { 0.035, 0.045, 0.06, 0.86 },
        borderColor = { 0.20, 0.24, 0.30, 0.95 },
        gripAlpha = 0.78,
    },
    blizzard = {
        displayName = "Blizzard",
        font = STANDARD_FONT,
        fontFlags = "OUTLINE",
        labelColor = { 0.96, 0.82, 0.40 },
        valueColor = { 0.96, 0.93, 0.84 },
        separatorColor = { 0.60, 0.46, 0.21 },
        backdrop = {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        },
        backgroundColor = { 0.035, 0.025, 0.015, 0.90 },
        borderColor = { 0.70, 0.55, 0.24, 0.90 },
        gripAlpha = 0.82,
    },
    forged = {
        displayName = "Forged",
        font = STANDARD_FONT,
        fontFlags = "OUTLINE",
        labelColor = { 0.70, 0.73, 0.75 },
        valueColor = { 0.88, 0.90, 0.91 },
        separatorColor = { 0.44, 0.47, 0.48 },
        backdrop = {
            bgFile = WHITE_TEXTURE,
            edgeFile = WHITE_TEXTURE,
            edgeSize = 2,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        },
        backgroundColor = { 0.055, 0.06, 0.065, 0.94 },
        borderColor = { 0.34, 0.37, 0.39, 1.00 },
        gripAlpha = 0.72,
    },
    blizzardnative = {
        displayName = "Blizzard Native",
        font = STANDARD_FONT,
        fontFlags = "OUTLINE",
        labelColor = { 0.94, 0.80, 0.42 },
        valueColor = { 0.94, 0.91, 0.82 },
        separatorColor = { 0.58, 0.46, 0.25 },
        backdrop = {
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        },
        backgroundColor = { 0.13, 0.10, 0.065, 0.96 },
        borderColor = { 0.78, 0.62, 0.30, 0.92 },
        gripAlpha = 0.82,
    },
}
