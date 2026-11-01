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

local function compactUnit(value, unit)
    if value < 10 then
        local text = string.format("%.1f", value):gsub("%.0$", "")
        return text .. " " .. unit
    end
    return rounded(value) .. " " .. unit
end

local function formatAddonMemory(kilobytes)
    kilobytes = tonumber(kilobytes) or 0
    kilobytes = math.max(0, kilobytes)
    if kilobytes < 1024 then
        return rounded(kilobytes) .. " KB"
    end

    local megabytes = kilobytes / 1024
    if megabytes < 1024 then
        return compactUnit(megabytes, "MB")
    end

    return compactUnit(megabytes / 1024, "GB")
end

function NetPulse:IsAddonMemoryEnabled()
    return self.profile and type(self.profile.metrics) == "table"
        and self.profile.metrics.addonMemory == true
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
    local frame = self.display
    if not frame or not frame.fpsText or not frame.homeText or not frame.worldText then
        return false
    end

    local theme = self.Themes and self.profile and self.Themes[self.profile.theme]
    if not theme then
        return false
    end

    local values = self.values or {}
    local fps = tonumber(values.fps) or 0
    local home = tonumber(values.home) or 0
    local world = tonumber(values.world) or 0

    frame.fpsText:SetText(
        colorText("FPS", theme.labelColor) .. " " .. colorText(rounded(fps), self:GetFPSColor(fps))
    )
    frame.homeText:SetText(
        colorText("Home", theme.labelColor) .. " " .. colorText(rounded(home) .. " ms", self:GetLatencyColor(home))
    )
    frame.worldText:SetText(
        colorText("World", theme.labelColor) .. " " .. colorText(rounded(world) .. " ms", self:GetLatencyColor(world))
    )

    if self:IsAddonMemoryEnabled() then
        if not frame.addonMemoryText then
            return false
        end
        frame.addonMemoryText:SetText(
            colorText("AddOns", theme.labelColor) .. " "
                .. colorText(formatAddonMemory(values.addonMemoryKB), theme.valueColor or theme.labelColor)
        )
    end
    return true
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

function NetPulse:UpdateAddonMemory()
    if not self:IsAddonMemoryEnabled() then
        return false
    end

    local addons = C_AddOns
    if type(UpdateAddOnMemoryUsage) ~= "function"
        or type(GetAddOnMemoryUsage) ~= "function"
        or type(addons) ~= "table"
        or type(addons.GetNumAddOns) ~= "function"
        or type(addons.IsAddOnLoaded) ~= "function" then
        return false
    end

    local updated = pcall(UpdateAddOnMemoryUsage)
    local countReady, addonCount = pcall(addons.GetNumAddOns)
    if not updated or not countReady or type(addonCount) ~= "number" then
        return false
    end

    local totalKilobytes = 0
    for index = 1, math.max(0, math.floor(addonCount)) do
        local isUserAddon = true
        if type(addons.GetAddOnInfo) == "function" then
            local infoReady, name, _, _, _, _, security = pcall(addons.GetAddOnInfo, index)
            isUserAddon = infoReady and type(name) == "string" and name ~= ""
                and not name:match("^Blizzard_") and security ~= "SECURE"
        end

        if isUserAddon then
            local loadedReady, loaded = pcall(addons.IsAddOnLoaded, index)
            if loadedReady and loaded then
                local memoryReady, kilobytes = pcall(GetAddOnMemoryUsage, index)
                if memoryReady and type(kilobytes) == "number" and kilobytes > 0 then
                    totalKilobytes = totalKilobytes + kilobytes
                end
            end
        end
    end

    self.values.addonMemoryKB = totalKilobytes
    self:RefreshMetricText()
    return true
end

function NetPulse:StopAddonMemoryMonitoring()
    if self.addonMemoryTicker then
        self.addonMemoryTicker:Cancel()
        self.addonMemoryTicker = nil
    end
end

function NetPulse:ConfigureAddonMemoryMonitoring()
    self:StopAddonMemoryMonitoring()
    self.values = self.values or { fps = 0, home = 0, world = 0, addonMemoryKB = 0 }

    if not self:IsAddonMemoryEnabled() then
        self.values.addonMemoryKB = 0
        return false
    end

    self:UpdateAddonMemory()
    self.addonMemoryTicker = C_Timer.NewTicker(15, function()
        if self:IsAddonMemoryEnabled() then
            self:UpdateAddonMemory()
        else
            self:StopAddonMemoryMonitoring()
        end
    end)
    return true
end

function NetPulse:StartTimers()
    self.values = self.values or { fps = 0, home = 0, world = 0, addonMemoryKB = 0 }
    self.values.addonMemoryKB = tonumber(self.values.addonMemoryKB) or 0
    self:UpdateFPS()
    self:UpdateNetwork()

    self.fpsTicker = C_Timer.NewTicker(0.5, function()
        self:UpdateFPS()
    end)
    self.networkTicker = C_Timer.NewTicker(30, function()
        self:UpdateNetwork()
    end)
    self:ConfigureAddonMemoryMonitoring()
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
    local frame = self.display
    if not frame then
        error("display frame is unavailable")
    end
    if not UIParent then
        error("UIParent is unavailable")
    end
    if type(self.profile) ~= "table" then
        self:UseDefaultDatabase()
    end

    local position = self.profile.position
    local validPoints = type(self.validPoints) == "table" and self.validPoints or {}
    local point = type(position) == "table" and position.point or nil
    local relativePoint = type(position) == "table" and position.relativePoint or nil
    local x = type(position) == "table" and tonumber(position.x) or nil
    local y = type(position) == "table" and tonumber(position.y) or nil
    local savedPositionValid = validPoints[point] and validPoints[relativePoint]
        and x ~= nil and y ~= nil

    if not savedPositionValid then
        point, relativePoint, x, y = "CENTER", "CENTER", 0, 0
    end

    frame:ClearAllPoints()
    local applied, positionError = pcall(frame.SetPoint, frame, point, UIParent, relativePoint, x, y)
    if not applied then
        self:ReportStartupError("ApplyPosition saved position", positionError)
        frame:ClearAllPoints()
        local fallbackApplied, fallbackError = pcall(
            frame.SetPoint,
            frame,
            "CENTER",
            UIParent,
            "CENTER",
            0,
            0
        )
        if not fallbackApplied then
            error("CENTER fallback failed: " .. tostring(fallbackError))
        end
        point, relativePoint, x, y = "CENTER", "CENTER", 0, 0
    end

    if frame:GetNumPoints() == 0 then
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        point, relativePoint, x, y = "CENTER", "CENTER", 0, 0
    end

    if type(self.profile.position) ~= "table" then
        self.profile.position = {}
    end
    self.profile.position.point = point
    self.profile.position.relativePoint = relativePoint
    self.profile.position.x = x
    self.profile.position.y = y
end

function NetPulse:UpdateDisplayLayout()
    local frame = self.display
    if not frame or type(frame.metricTexts) ~= "table" or type(frame.separators) ~= "table" then
        return false
    end

    local width = frame:GetWidth()
    local height = frame:GetHeight()
    local orientation = self.profile.orientation
    local theme = self.Themes[self.profile.theme]
    if not theme then
        return false
    end

    local metricCount = self:IsAddonMemoryEnabled() and 4 or 3
    for _, text in ipairs(frame.metricTexts) do
        text:ClearAllPoints()
    end
    for _, separator in ipairs(frame.separators) do
        separator:ClearAllPoints()
        separator:Hide()
    end
    frame.addonMemoryText:SetShown(metricCount == 4)

    local fontSize
    if orientation == "horizontal" then
        local padding = math.max(5, math.min(14, math.floor(height * 0.18)))
        local separatorWidth = math.max(10, math.min(24, math.floor(height * 0.38)))
        local cellWidth = (width - (padding * 2) - (separatorWidth * (metricCount - 1))) / metricCount
        fontSize = math.floor(math.max(10, math.min(30, height * 0.39, cellWidth / 7.4)))

        local previousText
        for index = 1, metricCount do
            local text = frame.metricTexts[index]
            if index == 1 then
                text:SetPoint("LEFT", frame, "LEFT", padding, 0)
            else
                local separator = frame.separators[index - 1]
                separator:SetPoint("LEFT", previousText, "RIGHT", 0, 0)
                separator:SetSize(separatorWidth, height)
                separator:Show()
                text:SetPoint("LEFT", separator, "RIGHT", 0, 0)
            end
            text:SetSize(cellWidth, height)
            previousText = text
        end
    else
        local padding = math.max(5, math.min(16, math.floor(width * 0.05)))
        local rowHeight = (height - (padding * 2)) / metricCount
        fontSize = math.floor(math.max(10, math.min(32, rowHeight * 0.55, (width - padding * 2) / 7.4)))

        local previousText
        for index = 1, metricCount do
            local text = frame.metricTexts[index]
            if index == 1 then
                text:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding)
            else
                text:SetPoint("TOPLEFT", previousText, "BOTTOMLEFT", 0, 0)
            end
            text:SetSize(width - padding * 2, rowHeight)
            previousText = text
        end
    end

    for _, text in ipairs(frame.metricTexts) do
        text:SetFont(theme.font, fontSize, theme.fontFlags)
    end
    for _, separator in ipairs(frame.separators) do
        separator:SetFont(theme.font, math.max(9, fontSize - 1), theme.fontFlags)
    end
    return true
end

function NetPulse:ApplyLayout(useSavedSize)
    if type(self.profile) ~= "table" then
        self:UseDefaultDatabase()
    end
    local orientation = self.profile and self.profile.orientation or "horizontal"
    if orientation ~= "horizontal" and orientation ~= "vertical" then
        orientation = "horizontal"
        self.profile.orientation = orientation
    end
    local bounds = self.layoutBounds[orientation]
    self.display:SetResizeBounds(bounds.minWidth, bounds.minHeight, bounds.maxWidth, bounds.maxHeight)

    if useSavedSize then
        local profileSize = type(self.profile.size) == "table" and self.profile.size or nil
        local size = profileSize and profileSize[orientation]
        local defaultSize = self.defaults.size[orientation]
        local width = type(size) == "table" and tonumber(size.width) or defaultSize.width
        local height = type(size) == "table" and tonumber(size.height) or defaultSize.height
        width = math.max(bounds.minWidth, math.min(bounds.maxWidth, width or defaultSize.width))
        height = math.max(bounds.minHeight, math.min(bounds.maxHeight, height or defaultSize.height))
        self.display:SetSize(width, height)
    end

    if self.display:GetWidth() <= 0 or self.display:GetHeight() <= 0 then
        self.display:SetSize(self.defaults.size.horizontal.width, self.defaults.size.horizontal.height)
    end

    self:UpdateDisplayLayout()
end

function NetPulse:ApplyTheme()
    local frame = self.display
    if not frame then
        return false
    end

    local theme = self.Themes and self.profile and self.Themes[self.profile.theme]
    if not theme then
        return false
    end

    frame:SetBackdrop(theme.backdrop)
    frame:SetBackdropColor(unpack(theme.backgroundColor))
    frame:SetBackdropBorderColor(unpack(theme.borderColor))
    if type(frame.separators) == "table" then
        for _, separator in ipairs(frame.separators) do
            separator:SetTextColor(unpack(theme.separatorColor))
        end
    end
    if frame.resizeGrip then
        frame.resizeGrip:SetAlpha(theme.gripAlpha)
    end

    local layoutReady = self:UpdateDisplayLayout()
    local textReady = self:RefreshMetricText()
    if layoutReady and textReady and frame.fallbackBackground then
        frame.fallbackBackground:Hide()
    end
    return layoutReady and textReady
end

function NetPulse:ApplyLockState()
    local frame = self.display
    if not frame then
        return
    end

    local unlocked = not self.profile.locked
    frame:SetMovable(unlocked)
    frame:SetResizable(unlocked)
    frame:EnableMouse(unlocked)
    if frame.resizeGrip then
        frame.resizeGrip:SetShown(unlocked)
    end
end

function NetPulse:CreateDisplay()
    local frame = CreateFrame("Frame", "NetPulseDisplay", UIParent, "BackdropTemplate")
    self.display = frame
    self.values = { fps = 0, home = 0, world = 0, addonMemoryKB = 0 }

    -- Establish a visible, anchored fallback before any optional frame setup.
    frame:SetSize(320, 40)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    local fallbackBackground = frame:CreateTexture(nil, "BACKGROUND")
    fallbackBackground:SetAllPoints(frame)
    fallbackBackground:SetColorTexture(0.035, 0.045, 0.06, 0.90)
    frame.fallbackBackground = fallbackBackground
    frame:Show()

    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")

    local function createMetricText()
        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetJustifyH("CENTER")
        text:SetJustifyV("MIDDLE")
        text:SetWordWrap(false)
        return text
    end

    frame.fpsText = createMetricText()
    frame.homeText = createMetricText()
    frame.worldText = createMetricText()
    frame.addonMemoryText = createMetricText()
    frame.fpsText:SetText("FPS --")
    frame.homeText:SetText("Home -- ms")
    frame.worldText:SetText("World -- ms")
    frame.addonMemoryText:SetText("AddOns --")

    frame.separatorOne = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.separatorOne:SetText("|")
    frame.separatorOne:SetJustifyH("CENTER")
    frame.separatorOne:SetJustifyV("MIDDLE")

    frame.separatorTwo = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.separatorTwo:SetText("|")
    frame.separatorTwo:SetJustifyH("CENTER")
    frame.separatorTwo:SetJustifyV("MIDDLE")

    frame.separatorThree = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.separatorThree:SetText("|")
    frame.separatorThree:SetJustifyH("CENTER")
    frame.separatorThree:SetJustifyV("MIDDLE")

    frame.metricTexts = {
        frame.fpsText,
        frame.homeText,
        frame.worldText,
        frame.addonMemoryText,
    }
    frame.separators = {
        frame.separatorOne,
        frame.separatorTwo,
        frame.separatorThree,
    }

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

end
