local addonName, NetPulse = ...

NetPulse.addonName = addonName
NetPulse.version = "0.2.0-beta"
NetPulse.schemaVersion = 2

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
    minimap = {
        shown = true,
        angle = 220,
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
NetPulse.validPoints = validPoints

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
    local formatted = "|cff74a9d8NetPulse:|r " .. tostring(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(formatted)
    elseif print then
        print("NetPulse: " .. tostring(message))
    end
end

local function startupErrorHandler(errorMessage)
    local message = tostring(errorMessage)
    if type(debugstack) == "function" then
        local stack = debugstack(2, 12, 12)
        if stack and stack ~= "" then
            message = message .. "\n" .. stack
        end
    end
    return message
end

function NetPulse:ReportStartupError(stepName, errorMessage)
    local message = tostring(errorMessage)
    self.startupErrors = self.startupErrors or {}
    self.startupErrors[#self.startupErrors + 1] = {
        step = stepName,
        error = message,
    }
    self.startupErrorStep = stepName
    self.lastStartupError = message

    local formatted = "NetPulse startup error [" .. stepName .. "]: " .. message
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff6666" .. formatted .. "|r")
    elseif print then
        print(formatted)
    end
end

function NetPulse:RunStartupStep(stepName, callback)
    local success, result = xpcall(callback, startupErrorHandler)
    if not success then
        self:ReportStartupError(stepName, result)
        return false, result
    end
    return true, result
end

function NetPulse:UseDefaultDatabase()
    NetPulseDB = {
        schemaVersion = self.schemaVersion,
        profile = copyValue(self.defaults),
    }
    self.db = NetPulseDB
    self.profile = NetPulseDB.profile
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

    local minimap = profile.minimap
    minimap.shown = minimap.shown ~= false
    minimap.angle = tonumber(minimap.angle) or self.defaults.minimap.angle
    minimap.angle = minimap.angle % 360

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
    self.startupErrors = {}
    self.startupErrorStep = nil
    self.lastStartupError = nil

    local databaseReady = self:RunStartupStep("InitializeDatabase", function()
        self:InitializeDatabase()
    end)
    if not databaseReady then
        self:UseDefaultDatabase()
    end

    local slashReady = self:RunStartupStep("RegisterSlashCommands", function()
        self:RegisterSlashCommands()
    end)
    local displayCreated = self:RunStartupStep("CreateDisplay", function()
        self:CreateDisplay()
    end)

    local positionReady = false
    local layoutReady = false
    local themeReady = false
    local lockReady = false
    local timersReady = false

    if self.display then
        positionReady = self:RunStartupStep("ApplyPosition", function()
            self:ApplyPosition()
        end)
        layoutReady = self:RunStartupStep("ApplyLayout", function()
            self:ApplyLayout(true)
        end)
        themeReady = self:RunStartupStep("ApplyTheme", function()
            self:ApplyTheme()
        end)
        lockReady = self:RunStartupStep("ApplyLockState", function()
            self:ApplyLockState()
        end)
        timersReady = self:RunStartupStep("StartTimers", function()
            self:StartTimers()
        end)
        self.display:Show()
    end

    local essentialReady = databaseReady and slashReady and displayCreated and positionReady
        and layoutReady and themeReady and lockReady and timersReady
    if essentialReady then
        local message = "NetPulse " .. self.version .. " loaded."
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage("|cff74a9d8" .. message .. "|r")
        elseif print then
            print(message)
        end
    end

    self:RunStartupStep("CreateMinimapButton", function()
        self:CreateMinimapButton()
    end)

    self:RunStartupStep("CreateSettings", function()
        self:CreateSettings()
    end)

    return essentialReady
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, _, loadedAddon)
    if loadedAddon ~= addonName then
        return
    end

    local initialized, initializeError = xpcall(function()
        NetPulse:Initialize()
    end, startupErrorHandler)
    if not initialized then
        NetPulse:ReportStartupError("Initialize", initializeError)
        return
    end

    self:UnregisterEvent("ADDON_LOADED")
end)
