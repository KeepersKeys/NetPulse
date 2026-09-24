local _, NetPulse = ...

-- Deliberately centralized so the initial color behavior is easy to tune.
NetPulse.thresholds = {
    fps = {
        good = 60,
        moderate = 30,
    },
    latency = {
        good = 80,
        moderate = 160,
    },
}

NetPulse.statusColors = {
    good = { 0.35, 0.82, 0.43 },
    moderate = { 0.91, 0.74, 0.28 },
    poor = { 0.86, 0.32, 0.30 },
}

NetPulse.layoutBounds = {
    horizontal = {
        minWidth = 300,
        minHeight = 36,
        maxWidth = 800,
        maxHeight = 180,
    },
    vertical = {
        minWidth = 145,
        minHeight = 84,
        maxWidth = 500,
        maxHeight = 600,
    },
}

local function colorHex(color)
    local red = math.floor((color[1] or 1) * 255 + 0.5)
    local green = math.floor((color[2] or 1) * 255 + 0.5)
    local blue = math.floor((color[3] or 1) * 255 + 0.5)
    return string.format("ff%02x%02x%02x", red, green, blue)
end

local function colorText(text, color)
    return "|c" .. colorHex(color) .. text .. "|r"
end

local function rounded(value)
    if type(value) ~= "number" then
        return "--"
    end
    return tostring(math.floor(value + 0.5))
end

function NetPulse:GetFPSColor(fps)
    if fps >= self.thresholds.fps.good then
        return self.statusColors.good
    elseif fps >= self.thresholds.fps.moderate then
        return self.statusColors.moderate
    end
    return self.statusColors.poor
end

function NetPulse:GetLatencyColor(latency)
    if latency <= self.thresholds.latency.good then
        return self.statusColors.good
    elseif latency <= self.thresholds.latency.moderate then
        return self.statusColors.moderate
    end
    return self.statusColors.poor
end

function NetPulse:RefreshMetricText()
    if not self.display then
        return
    end

    local theme = self.Themes[self.profile.theme]
    local fps = self.values.fps
    local home = self.values.home
    local world = self.values.world

    self.display.fpsText:SetText(
        colorText("FPS", theme.labelColor) .. " " .. colorText(rounded(fps), self:GetFPSColor(fps))
    )
    self.display.homeText:SetText(
        colorText("Home", theme.labelColor) .. " " .. colorText(rounded(home) .. " ms", self:GetLatencyColor(home))
    )
    self.display.worldText:SetText(
        colorText("World", theme.labelColor) .. " " .. colorText(rounded(world) .. " ms", self:GetLatencyColor(world))
    )
end

function NetPulse:UpdateFPS()
    self.values.fps = GetFramerate() or 0
    self:RefreshMetricText()
end

function NetPulse:UpdateNetwork()
    local _, _, homeLatency, worldLatency = GetNetStats()
    self.values.home = homeLatency or 0
    self.values.world = worldLatency or 0
    self:RefreshMetricText()
end

function NetPulse:StartTimers()
    self.values = self.values or { fps = 0, home = 0, world = 0 }
    self:UpdateFPS()
    self:UpdateNetwork()

    self.fpsTicker = C_Timer.NewTicker(0.5, function()
        self:UpdateFPS()
    end)
    self.networkTicker = C_Timer.NewTicker(30, function()
        self:UpdateNetwork()
    end)
end

function NetPulse:SavePosition()
    local point, _, relativePoint, x, y = self.display:GetPoint(1)
    self.profile.position.point = point or "CENTER"
    self.profile.position.relativePoint = relativePoint or "CENTER"
    self.profile.position.x = x or 0
    self.profile.position.y = y or 0
end

function NetPulse:SaveSize()
    local savedSize = self.profile.size[self.profile.orientation]
    savedSize.width = self.display:GetWidth()
    savedSize.height = self.display:GetHeight()
end

function NetPulse:ApplyPosition()
    local position = self.profile.position
    self.display:ClearAllPoints()
    self.display:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)
end

function NetPulse:UpdateDisplayLayout()
    local frame = self.display
    local width = frame:GetWidth()
    local height = frame:GetHeight()
    local orientation = self.profile.orientation
    local theme = self.Themes[self.profile.theme]

    frame.fpsText:ClearAllPoints()
    frame.homeText:ClearAllPoints()
    frame.worldText:ClearAllPoints()
    frame.separatorOne:ClearAllPoints()
    frame.separatorTwo:ClearAllPoints()

    local fontSize
    if orientation == "horizontal" then
        local padding = math.max(5, math.min(14, math.floor(height * 0.18)))
        local separatorWidth = math.max(10, math.min(24, math.floor(height * 0.38)))
        local cellWidth = (width - (padding * 2) - (separatorWidth * 2)) / 3
        fontSize = math.floor(math.max(10, math.min(30, height * 0.39, cellWidth / 7.4)))

        frame.fpsText:SetPoint("LEFT", frame, "LEFT", padding, 0)
        frame.fpsText:SetSize(cellWidth, height)
        frame.separatorOne:SetPoint("LEFT", frame.fpsText, "RIGHT", 0, 0)
        frame.separatorOne:SetSize(separatorWidth, height)
        frame.homeText:SetPoint("LEFT", frame.separatorOne, "RIGHT", 0, 0)
        frame.homeText:SetSize(cellWidth, height)
        frame.separatorTwo:SetPoint("LEFT", frame.homeText, "RIGHT", 0, 0)
        frame.separatorTwo:SetSize(separatorWidth, height)
        frame.worldText:SetPoint("LEFT", frame.separatorTwo, "RIGHT", 0, 0)
        frame.worldText:SetSize(cellWidth, height)

        frame.separatorOne:Show()
        frame.separatorTwo:Show()
    else
        local padding = math.max(5, math.min(16, math.floor(width * 0.05)))
        local rowHeight = (height - (padding * 2)) / 3
        fontSize = math.floor(math.max(10, math.min(32, rowHeight * 0.55, (width - padding * 2) / 7.4)))

        frame.fpsText:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding)
        frame.fpsText:SetSize(width - padding * 2, rowHeight)
        frame.homeText:SetPoint("TOPLEFT", frame.fpsText, "BOTTOMLEFT", 0, 0)
        frame.homeText:SetSize(width - padding * 2, rowHeight)
        frame.worldText:SetPoint("TOPLEFT", frame.homeText, "BOTTOMLEFT", 0, 0)
        frame.worldText:SetSize(width - padding * 2, rowHeight)

        frame.separatorOne:Hide()
        frame.separatorTwo:Hide()
    end

    frame.fpsText:SetFont(theme.font, fontSize, theme.fontFlags)
    frame.homeText:SetFont(theme.font, fontSize, theme.fontFlags)
    frame.worldText:SetFont(theme.font, fontSize, theme.fontFlags)
    frame.separatorOne:SetFont(theme.font, math.max(9, fontSize - 1), theme.fontFlags)
    frame.separatorTwo:SetFont(theme.font, math.max(9, fontSize - 1), theme.fontFlags)
end

function NetPulse:ApplyLayout(useSavedSize)
    local orientation = self.profile.orientation
    local bounds = self.layoutBounds[orientation]
    self.display:SetResizeBounds(bounds.minWidth, bounds.minHeight, bounds.maxWidth, bounds.maxHeight)

    if useSavedSize then
        local size = self.profile.size[orientation]
        self.display:SetSize(size.width, size.height)
    end

    self:UpdateDisplayLayout()
end

function NetPulse:ApplyTheme()
    if not self.display then
        return
    end

    local theme = self.Themes[self.profile.theme]
    self.display:SetBackdrop(theme.backdrop)
    self.display:SetBackdropColor(unpack(theme.backgroundColor))
    self.display:SetBackdropBorderColor(unpack(theme.borderColor))
    self.display.separatorOne:SetTextColor(unpack(theme.separatorColor))
    self.display.separatorTwo:SetTextColor(unpack(theme.separatorColor))
    self.display.resizeGrip:SetAlpha(theme.gripAlpha)
    self:UpdateDisplayLayout()
    self:RefreshMetricText()
end

function NetPulse:ApplyLockState()
    if not self.display then
        return
    end

    local unlocked = not self.profile.locked
    self.display:SetMovable(unlocked)
    self.display:SetResizable(unlocked)
    self.display:EnableMouse(unlocked)
    self.display.resizeGrip:SetShown(unlocked)
end

function NetPulse:CreateDisplay()
    local frame = CreateFrame("Frame", "NetPulseDisplay", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")

    local function createMetricText()
        local text = frame:CreateFontString(nil, "OVERLAY")
        text:SetJustifyH("CENTER")
        text:SetJustifyV("MIDDLE")
        text:SetWordWrap(false)
        return text
    end

    frame.fpsText = createMetricText()
    frame.homeText = createMetricText()
    frame.worldText = createMetricText()

    frame.separatorOne = frame:CreateFontString(nil, "OVERLAY")
    frame.separatorOne:SetText("|")
    frame.separatorOne:SetJustifyH("CENTER")
    frame.separatorOne:SetJustifyV("MIDDLE")

    frame.separatorTwo = frame:CreateFontString(nil, "OVERLAY")
    frame.separatorTwo:SetText("|")
    frame.separatorTwo:SetJustifyH("CENTER")
    frame.separatorTwo:SetJustifyV("MIDDLE")

    local resizeGrip = CreateFrame("Button", nil, frame)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    frame.resizeGrip = resizeGrip

    frame:SetScript("OnDragStart", function(display)
        if not NetPulse.profile.locked then
            display:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(display)
        display:StopMovingOrSizing()
        NetPulse:SavePosition()
    end)
    frame:SetScript("OnSizeChanged", function()
        NetPulse:UpdateDisplayLayout()
        NetPulse:SaveSize()
    end)

    resizeGrip:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not NetPulse.profile.locked then
            frame:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeGrip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        NetPulse:SaveSize()
    end)

    self.display = frame
    self.values = { fps = 0, home = 0, world = 0 }
end
