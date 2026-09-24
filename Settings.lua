local _, NetPulse = ...

local function createLabel(parent, text, template)
    local label = parent:CreateFontString(nil, "ARTWORK", template or "GameFontNormal")
    label:SetText(text)
    return label
end

local function createButton(parent, text, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 140, 24)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

local function createCheckbox(parent, text, onClick)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(22, 22)
    check:SetScript("OnClick", onClick)

    local label = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", check, "RIGHT", 6, 1)
    label:SetText(text)
    check.label = label
    return check
end

local function createRadio(parent, text, onClick)
    local radio = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
    radio:SetSize(18, 18)
    radio:SetScript("OnClick", function()
        onClick()
        NetPulse:RefreshSettings()
    end)

    local label = radio:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", radio, "RIGHT", 6, 1)
    label:SetText(text)
    radio.label = label
    return radio
end

function NetPulse:RefreshSettings()
    if not self.settingsPanel or not self.profile then
        return
    end

    local controls = self.settingsPanel.controls
    controls.lock:SetChecked(self.profile.locked == true)
    controls.horizontal:SetChecked(self.profile.orientation == "horizontal")
    controls.vertical:SetChecked(self.profile.orientation == "vertical")

    for themeName, radio in pairs(controls.themes) do
        radio:SetChecked(self.profile.theme == themeName)
    end

    if controls.minimap and type(self.profile.minimap) == "table" then
        controls.minimap:SetChecked(self.profile.minimap.shown ~= false)
    end
end

function NetPulse:CreateSettings()
    local panel = CreateFrame("Frame")
    panel.name = "NetPulse"
    panel.controls = { themes = {} }

    local title = createLabel(panel, "NetPulse", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -18)

    local subtitle = createLabel(panel, "FPS & Network Monitor", "GameFontHighlight")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)

    local version = createLabel(panel, self.version, "GameFontHighlightSmall")
    version:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -2)

    local displayHeader = createLabel(panel, "Display", "GameFontNormalLarge")
    displayHeader:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -22)

    local lockCheck = createCheckbox(panel, "Lock NetPulse", function(check)
        self:SetLocked(check:GetChecked() == true)
    end)
    lockCheck:SetPoint("TOPLEFT", displayHeader, "BOTTOMLEFT", 0, -8)
    panel.controls.lock = lockCheck

    local orientationLabel = createLabel(panel, "Orientation", "GameFontHighlightSmall")
    orientationLabel:SetPoint("TOPLEFT", lockCheck, "BOTTOMLEFT", 0, -14)

    local horizontalRadio = createRadio(panel, "Horizontal", function()
        self:SetOrientation("horizontal")
    end)
    horizontalRadio:SetPoint("TOPLEFT", orientationLabel, "BOTTOMLEFT", 0, -6)

    local verticalRadio = createRadio(panel, "Vertical", function()
        self:SetOrientation("vertical")
    end)
    verticalRadio:SetPoint("LEFT", horizontalRadio, "LEFT", 120, 0)
    panel.controls.horizontal = horizontalRadio
    panel.controls.vertical = verticalRadio

    local themeLabel = createLabel(panel, "Theme", "GameFontHighlightSmall")
    themeLabel:SetPoint("TOPLEFT", horizontalRadio, "BOTTOMLEFT", 0, -16)

    local firstThemeRadio
    local previousThemeRadio
    for index, themeName in ipairs(self.themeOrder) do
        local selectedTheme = themeName
        local theme = self.Themes[selectedTheme]
        local radio = createRadio(panel, theme.displayName, function()
            self:SetTheme(selectedTheme)
        end)
        if index == 1 then
            radio:SetPoint("TOPLEFT", themeLabel, "BOTTOMLEFT", 0, -6)
            firstThemeRadio = radio
        elseif index % 2 == 0 then
            radio:SetPoint("LEFT", previousThemeRadio, "LEFT", 120, 0)
        else
            radio:SetPoint("TOPLEFT", firstThemeRadio, "BOTTOMLEFT", 0, -6)
        end
        panel.controls.themes[selectedTheme] = radio
        previousThemeRadio = radio
    end

    local minimapHeader = createLabel(panel, "Minimap", "GameFontNormalLarge")
    minimapHeader:SetPoint("TOPLEFT", panel.controls.themes.blizzard, "BOTTOMLEFT", 0, -22)

    local minimapCheck = createCheckbox(panel, "Show Minimap Button", function(check)
        self:SetMinimapShown(check:GetChecked() == true)
    end)
    minimapCheck:SetPoint("TOPLEFT", minimapHeader, "BOTTOMLEFT", 0, -8)
    panel.controls.minimap = minimapCheck

    local resetHeader = createLabel(panel, "Reset", "GameFontNormalLarge")
    resetHeader:SetPoint("TOPLEFT", minimapCheck, "BOTTOMLEFT", 0, -22)

    local resetButton = createButton(panel, "Reset Position & Size", 210, function()
        self:ResetPositionAndSize()
        self:Print("Position and size reset.")
    end)
    resetButton:SetPoint("TOPLEFT", resetHeader, "BOTTOMLEFT", 0, -8)

    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -14)
    hint:SetWidth(360)
    hint:SetJustifyH("LEFT")
    hint:SetText("Unlock NetPulse to drag or resize the display.")

    panel.OnCommit = function()
        -- Controls apply immediately, so there is nothing deferred to commit.
    end
    panel.OnDefault = function()
        self:SetLocked(self.defaults.locked)
        self:SetOrientation(self.defaults.orientation)
        self:SetTheme(self.defaults.theme)
        self:SetMinimapShown(self.defaults.minimap.shown)
        self:ResetPositionAndSize()
    end
    panel.OnRefresh = function()
        self:RefreshSettings()
    end

    local category = Settings.RegisterCanvasLayoutCategory(panel, "NetPulse")
    Settings.RegisterAddOnCategory(category)
    self.settingsPanel = panel
    self.settingsCategory = category
    self:RefreshSettings()
end

function NetPulse:OpenSettings()
    self:RefreshSettings()
    if self.settingsCategory then
        Settings.OpenToCategory(self.settingsCategory:GetID())
    end
end

function NetPulse:PrintDebugState()
    local frame = self.display or _G.NetPulseDisplay
    local profile = self.profile or {}
    local values = self.values or {}
    local minimap = type(profile.minimap) == "table" and profile.minimap or {}
    local minimapButton = self.minimapButton
    local shown = frame and frame:IsShown() or false
    local width = frame and frame:GetWidth() or 0
    local height = frame and frame:GetHeight() or 0
    local points = frame and frame:GetNumPoints() or 0
    local errorSummary = "none"
    if self.lastStartupError then
        errorSummary = tostring(self.lastStartupError):match("^[^\r\n]+") or tostring(self.lastStartupError)
    end

    self:Print("debug version=" .. tostring(self.version))
    self:Print(string.format(
        "frame=%s shown=%s size=%.0fx%.0f points=%d",
        tostring(frame ~= nil),
        tostring(shown),
        width,
        height,
        points
    ))
    self:Print(string.format(
        "orientation=%s theme=%s locked=%s FPS=%s Home=%s World=%s",
        tostring(profile.orientation),
        tostring(profile.theme),
        tostring(profile.locked),
        tostring(values.fps),
        tostring(values.home),
        tostring(values.world)
    ))
    self:Print(string.format(
        "minimap shown=%s angle=%.0f button=%s visible=%s",
        tostring(minimap.shown ~= false),
        tonumber(minimap.angle) or self.defaults.minimap.angle,
        tostring(minimapButton ~= nil),
        tostring(minimapButton and minimapButton:IsShown() or false)
    ))
    self:Print("startup error=" .. tostring(self.startupErrorStep or "none") .. ": " .. errorSummary)
end

function NetPulse:RegisterSlashCommands()
    SLASH_NETPULSE1 = "/netpulse"
    SLASH_NETPULSE2 = "/np"

    SlashCmdList.NETPULSE = function(input)
        input = input or ""
        local command, argument = input:match("^(%S*)%s*(.-)%s*$")
        command = string.lower(command or "")
        argument = string.lower(argument or "")

        if command == "" then
            self:OpenSettings()
        elseif command == "debug" then
            self:PrintDebugState()
        elseif command == "lock" then
            self:SetLocked(true)
            self:Print("Locked.")
        elseif command == "unlock" then
            self:SetLocked(false)
            self:Print("Unlocked.")
        elseif command == "reset" then
            self:ResetPositionAndSize()
            self:Print("Position and size reset.")
        elseif command == "horizontal" then
            self:SetOrientation("horizontal")
            self:Print("Horizontal layout selected.")
        elseif command == "vertical" then
            self:SetOrientation("vertical")
            self:Print("Vertical layout selected.")
        elseif command == "minimap" then
            if argument == "on" then
                self:SetMinimapShown(true)
                self:Print("Minimap button shown.")
            elseif argument == "off" then
                self:SetMinimapShown(false)
                self:Print("Minimap button hidden.")
            elseif argument == "" then
                local shown = self.profile.minimap.shown ~= false
                self:Print("Minimap button is " .. (shown and "shown" or "hidden") .. ". Options: on, off")
            else
                self:Print("Usage: /np minimap on|off")
            end
        elseif command == "theme" then
            if argument == "" then
                self:Print("Themes: minimal, dark, blizzard, forged")
            elseif self:SetTheme(argument) then
                self:Print("Theme set to " .. self.Themes[argument].displayName .. ".")
            else
                self:Print("Unknown theme. Available: minimal, dark, blizzard, forged")
            end
        else
            self:Print("Commands: debug, lock, unlock, reset, horizontal, vertical, minimap on|off, theme <name>")
        end
    end
end
