local addonName, NetPulse = ...

NetPulse.addonName = addonName
NetPulse.version = "0.1.0-alpha"
NetPulse.schemaVersion = 1

NetPulse.defaults = {
    locked = false,
    orientation = "horizontal",
    theme = "dark",
    position = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0,
    },
    size = {
        horizontal = {
            width = 320,
            height = 40,
        },
        vertical = {
            width = 180,
            height = 105,
        },
    },
}

local validPoints = {
    TOPLEFT = true,
    TOP = true,
    TOPRIGHT = true,
    LEFT = true,
    CENTER = true,
    RIGHT = true,
    BOTTOMLEFT = true,
    BOTTOM = true,
    BOTTOMRIGHT = true,
}

local function copyValue(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, child in pairs(value) do
        copy[key] = copyValue(child)
    end
    return copy
end

local function applyDefaults(target, defaults)
    for key, defaultValue in pairs(defaults) do
        if target[key] == nil then
            target[key] = copyValue(defaultValue)
        elseif type(defaultValue) == "table" and type(target[key]) == "table" then
            applyDefaults(target[key], defaultValue)
        elseif type(defaultValue) ~= type(target[key]) then
            target[key] = copyValue(defaultValue)
        end
    end
end

local function clampNumber(value, fallback, minimum, maximum)
    value = tonumber(value) or fallback
    return math.max(minimum, math.min(maximum, value))
end

function NetPulse:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff74a9d8NetPulse:|r " .. tostring(message))
end

function NetPulse:InitializeDatabase()
    if type(NetPulseDB) ~= "table" then
        NetPulseDB = {}
    end
    if type(NetPulseDB.profile) ~= "table" then
        NetPulseDB.profile = {}
    end

    applyDefaults(NetPulseDB.profile, self.defaults)
    NetPulseDB.schemaVersion = self.schemaVersion

    local profile = NetPulseDB.profile
    profile.locked = profile.locked == true

    if profile.orientation ~= "horizontal" and profile.orientation ~= "vertical" then
        profile.orientation = self.defaults.orientation
    end
    if not self.Themes or not self.Themes[profile.theme] then
        profile.theme = self.defaults.theme
    end

    local position = profile.position
    if not validPoints[position.point] then
        position.point = self.defaults.position.point
    end
    if not validPoints[position.relativePoint] then
        position.relativePoint = self.defaults.position.relativePoint
    end
    position.x = clampNumber(position.x, 0, -10000, 10000)
    position.y = clampNumber(position.y, 0, -10000, 10000)

    local horizontal = profile.size.horizontal
    horizontal.width = clampNumber(horizontal.width, self.defaults.size.horizontal.width, 300, 800)
    horizontal.height = clampNumber(horizontal.height, self.defaults.size.horizontal.height, 36, 180)

    local vertical = profile.size.vertical
    vertical.width = clampNumber(vertical.width, self.defaults.size.vertical.width, 145, 500)
    vertical.height = clampNumber(vertical.height, self.defaults.size.vertical.height, 84, 600)

    self.db = NetPulseDB
    self.profile = profile
end

function NetPulse:SetLocked(locked)
    self.profile.locked = locked == true
    self:ApplyLockState()
    self:RefreshSettings()
end

function NetPulse:SetOrientation(orientation)
    if orientation ~= "horizontal" and orientation ~= "vertical" then
        return false
    end
    if self.profile.orientation == orientation then
        return true
    end

    self.profile.orientation = orientation
    self:ApplyLayout(true)
    self:RefreshSettings()
    return true
end

function NetPulse:SetTheme(themeName)
    themeName = type(themeName) == "string" and string.lower(themeName) or ""
    if not self.Themes[themeName] then
        return false
    end

    self.profile.theme = themeName
    self:ApplyTheme()
    self:RefreshSettings()
    return true
end

function NetPulse:ResetPositionAndSize()
    self.profile.position = copyValue(self.defaults.position)
    self.profile.size = copyValue(self.defaults.size)
    self:ApplyPosition()
    self:ApplyLayout(true)
    self:RefreshSettings()
end

function NetPulse:Initialize()
    self:InitializeDatabase()
    self:CreateDisplay()
    self:CreateSettings()
    self:RegisterSlashCommands()
    self:ApplyPosition()
    self:ApplyLayout(true)
    self:ApplyTheme()
    self:ApplyLockState()
    self:StartTimers()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, _, loadedAddon)
    if loadedAddon ~= addonName then
        return
    end

    self:UnregisterEvent("ADDON_LOADED")
    NetPulse:Initialize()
end)
