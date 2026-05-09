local addOnName = ...

assert(LibStub, "Puggy requires LibStub")
assert(LibStub:GetLibrary("LibClassicInspector", true), "Puggy requires LibClassicInspector")
assert(LibStub:GetLibrary("LibDetours-1.0", true), "Puggy requires LibDetours-1.0")

local CI = LibStub("LibClassicInspector")

--- Puggy Core Initialization
Puggy = LibStub("AceAddon-3.0"):NewAddon("Puggy", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceTimer-3.0")

function Puggy:OnInitialize()
    -- Initialize Database
    self:InitializeDB()
    
    -- Initialize Debug Mode
    self.db.profile.debug = self.db.profile.debug or false
    
    -- Initialize Module System
    self:InitializeModuleSystem()
    
    -- Initialize registered modules (once all files are loaded)
    for id, module in pairs(self.Modules) do
        if module.Initialize then
            module:Initialize()
        end
    end
    
    self:RegisterChatCommand("puggy", "ChatCommand")
    self:Print("Puggy Initialized.")
    
    CI.RegisterCallback(addOnName, "INVENTORY_READY", function(event, guid, isInspect, unit)
        self:OnInspectorInventoryReady(guid)
    end)
    CI.RegisterCallback(addOnName, "TALENTS_READY", function(event, guid, isInspect, unit)
        self:OnInspectorTalentsReady(guid)
    end)
end

function Puggy:ChatCommand(input)
    if not input or input:trim() == "" then
        self:Print("Usage: /puggy roster | /puggy debug [on|off]")
        return
    end
    
    local arg1, arg2 = self:GetArgs(input, 2)
    
    if arg1 == "roster" then
        self:DumpRoster()
    elseif arg1 == "debug" then
        if arg2 == "on" then
            self.db.profile.debug = true
            self:Print("Debug logging enabled.")
        elseif arg2 == "off" then
            self.db.profile.debug = false
            self:Print("Debug logging disabled.")
        else
            self:Printf("Debug mode is currently: %s", self.db.profile.debug and "|cff00ff00ON|r" or "|cffff0000OFF|r")
            self:Print("Usage: /puggy debug [on|off]")
        end
        
        -- Show some basic debug info
        local count = 0
        for _ in pairs(self.Roster) do count = count + 1 end
        self:Printf("Total players tracked: %d", count)
    end
end

function Puggy:Debug(msg, ...)
    if self.db.profile.debug then
        local prefix = "|cff00ff00[PuggyDebug]|r "
        if select("#", ...) > 0 then
            self:Printf(prefix .. msg, ...)
        else
            self:Print(prefix .. msg)
        end
    end
end

function Puggy:DumpRoster()
    self:Print("--- Puggy Roster Dump ---")
    local count = 0
    for name, data in pairs(self.Roster) do
        count = count + 1
        local specStr = data.spec or "UNK"
        if data.talentPoints then
            specStr = string.format("%s (%s)", specStr, data.talentPoints)
        end
        self:Printf("%d. %s (%s) | Role: %s | Spec: %s | GS: %d | Online: %s | Ass: %d", 
            count, name, data.class or "UNK", data.role or "NONE", specStr, 
            data.gearScore or 0, data.online and "Yes" or "No", data.assignmentCount or 0)
    end
    if count == 0 then
        self:Print("Roster is empty.")
    end
end

function Puggy:OnEnable()
    -- Enable components
    if self.EnableComm then self:EnableComm() end
    if self.EnableRoster then self:EnableRoster() end
    
    self:Print("Puggy Enabled.")
end
