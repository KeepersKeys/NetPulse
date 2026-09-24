local _, NetPulse = ...

local function createLabel(parent, text, size)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetText(text)
    if size then
        local font, _, flags = label:GetFont()
        label:SetFont(font, size, flags)
    end
    return label
end

local function createButton(parent, text, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 140, 24)
    button.baseText = text
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

local function setSelected(button, selected)
    button:SetEnabled(not selected)
    if selected then
        button:SetText("[" .. button.baseText .. "]")
    else
        button:SetText(button.baseText)
    end
end

function NetPulse:RefreshSettings()
    if not self.settingsPanel or not self.profile then
        return
    end

    local controls = self.settingsPanel.controls
    controls.lock:SetText(self.profile.locked and "Unlock NetPulse" or "Lock NetPulse")
    setSelected(controls.horizontal, self.profile.orientation == "horizontal")
    setSelected(controls.vertical, self.profile.orientation == "vertical")

    for themeName, button in pairs(controls.themes) do
        setSelected(button, self.profile.theme == themeName)
    end
end

function NetPulse:CreateSettings()
    local panel = CreateFrame("Frame")
    panel.name = "NetPulse"
    panel.controls = { themes = {} }

    local title = createLabel(panel, "NetPulse", 20)
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetText("FPS & Network Monitor  |  " .. self.version)

    local lockLabel = createLabel(panel, "Locking")
    lockLabel:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -24)
    local lockButton = createButton(panel, "Lock NetPulse", 160, function()
        self:SetLocked(not self.profile.locked)
    end)
    lockButton:SetPoint("TOPLEFT", lockLabel, "BOTTOMLEFT", 0, -8)
    panel.controls.lock = lockButton

    local layoutLabel = createLabel(panel, "Layout")
    layoutLabel:SetPoint("TOPLEFT", lockButton, "BOTTOMLEFT", 0, -24)
    local horizontalButton = createButton(panel, "Horizontal", 130, function()
        self:SetOrientation("horizontal")
    end)
    horizontalButton:SetPoint("TOPLEFT", layoutLabel, "BOTTOMLEFT", 0, -8)
    local verticalButton = createButton(panel, "Vertical", 130, function()
        self:SetOrientation("vertical")
    end)
    verticalButton:SetPoint("LEFT", horizontalButton, "RIGHT", 8, 0)
    panel.controls.horizontal = horizontalButton
    panel.controls.vertical = verticalButton

    local themeLabel = createLabel(panel, "Theme")
    themeLabel:SetPoint("TOPLEFT", horizontalButton, "BOTTOMLEFT", 0, -24)

    local previousButton
    for index, themeName in ipairs(self.themeOrder) do
        local selectedTheme = themeName
        local theme = self.Themes[selectedTheme]
        local button = createButton(panel, theme.displayName, 130, function()
            self:SetTheme(selectedTheme)
        end)
        if index == 1 then
            button:SetPoint("TOPLEFT", themeLabel, "BOTTOMLEFT", 0, -8)
        elseif index % 2 == 0 then
            button:SetPoint("LEFT", previousButton, "RIGHT", 8, 0)
        else
            button:SetPoint("TOPLEFT", previousButton, "BOTTOMLEFT", -138, -8)
        end
        panel.controls.themes[selectedTheme] = button
        previousButton = button
    end

    local resetButton = createButton(panel, "Reset Position & Size", 268, function()
        self:ResetPositionAndSize()
        self:Print("Position and size reset.")
    end)
    resetButton:SetPoint("TOPLEFT", panel.controls.themes.forged, "BOTTOMRIGHT", -268, -28)

    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -14)
    hint:SetWidth(360)
    hint:SetJustifyH("LEFT")
    hint:SetText("Unlock NetPulse to drag the unit or resize it from the lower-right corner.")

    panel.OnCommit = function()
        -- Controls apply immediately, so there is nothing deferred to commit.
    end
    panel.OnDefault = function()
        self:SetLocked(self.defaults.locked)
        self:SetOrientation(self.defaults.orientation)
        self:SetTheme(self.defaults.theme)
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
    if self.settingsCategory then
        Settings.OpenToCategory(self.settingsCategory:GetID())
    end
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
        elseif command == "theme" then
            if argument == "" then
                self:Print("Themes: minimal, dark, blizzard, forged")
            elseif self:SetTheme(argument) then
                self:Print("Theme set to " .. self.Themes[argument].displayName .. ".")
            else
                self:Print("Unknown theme. Available: minimal, dark, blizzard, forged")
            end
        else
            self:Print("Commands: lock, unlock, reset, horizontal, vertical, theme <name>")
        end
    end
end
