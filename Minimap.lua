local _, NetPulse = ...

local BUTTON_SIZE = 31
local DEFAULT_ANGLE = 220
local ICON_TEXTURE = "Interface\\Icons\\INV_Misc_PocketWatch_01"

local function normalizeAngle(angle)
    angle = tonumber(angle) or DEFAULT_ANGLE
    return angle % 360
end

function NetPulse:ApplyMinimapPosition(angle)
    local button = self.minimapButton
    if not button or not Minimap then
        return false
    end

    angle = normalizeAngle(angle or (self.profile.minimap and self.profile.minimap.angle))
    local radians = math.rad(angle)
    local radius = (math.max(Minimap:GetWidth(), Minimap:GetHeight()) / 2) + 5

    button:ClearAllPoints()
    button:SetPoint(
        "CENTER",
        Minimap,
        "CENTER",
        math.cos(radians) * radius,
        math.sin(radians) * radius
    )

    self.profile.minimap.angle = angle
    return true
end

function NetPulse:ApplyMinimapVisibility()
    if not self.minimapButton or not self.profile or type(self.profile.minimap) ~= "table" then
        return false
    end

    local shown = self.profile.minimap.shown ~= false
    if not shown then
        self.minimapButton:SetScript("OnUpdate", nil)
        self.minimapButton:UnlockHighlight()
        self.minimapButton.isDragging = false
        GameTooltip:Hide()
    end
    self.minimapButton:SetShown(shown)
    return true
end

function NetPulse:SetMinimapShown(shown)
    if not self.profile then
        return false
    end
    if type(self.profile.minimap) ~= "table" then
        self.profile.minimap = {
            shown = self.defaults.minimap.shown,
            angle = self.defaults.minimap.angle,
        }
    end

    self.profile.minimap.shown = shown == true
    self:ApplyMinimapVisibility()
    self:RefreshSettings()
    return self.profile.minimap.shown
end

function NetPulse:CreateMinimapButton()
    if not Minimap then
        error("Minimap is unavailable")
    end

    if self.minimapButton then
        self:ApplyMinimapPosition()
        self:ApplyMinimapVisibility()
        return self.minimapButton
    end

    local button = CreateFrame("Button", "NetPulseMinimapButton", Minimap)
    self.minimapButton = button
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    button:SetMovable(true)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(24, 24)
    background:SetPoint("CENTER", button, "CENTER")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER", button, "CENTER")
    icon:SetTexture(ICON_TEXTURE)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(50, 50)
    border:SetPoint("TOPLEFT", button, "TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            NetPulse:OpenSettings()
        end
    end)

    local function updateFromCursor()
        local minimapX, minimapY = Minimap:GetCenter()
        local cursorX, cursorY = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        if not minimapX or not minimapY or not scale or scale == 0 then
            return
        end

        cursorX = cursorX / scale
        cursorY = cursorY / scale
        local angle = math.deg(math.atan2(cursorY - minimapY, cursorX - minimapX)) % 360
        NetPulse:ApplyMinimapPosition(angle)
    end

    button:SetScript("OnDragStart", function(minimapButton)
        minimapButton.isDragging = true
        minimapButton:LockHighlight()
        minimapButton:SetScript("OnUpdate", updateFromCursor)
        GameTooltip:Hide()
    end)

    button:SetScript("OnDragStop", function(minimapButton)
        minimapButton:SetScript("OnUpdate", nil)
        minimapButton:UnlockHighlight()
        minimapButton.isDragging = false
        NetPulse:ApplyMinimapPosition()
    end)

    button:SetScript("OnEnter", function(minimapButton)
        if minimapButton.isDragging then
            return
        end
        GameTooltip:SetOwner(minimapButton, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("NetPulse", 1, 1, 1)
        GameTooltip:AddLine("Click to open settings", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self:ApplyMinimapPosition()
    self:ApplyMinimapVisibility()
    return button
end
