--- Puggy Core Initialization
Puggy = LibStub("AceAddon-3.0"):NewAddon("Puggy", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceTimer-3.0")

function Puggy:OnInitialize()
    -- Initialize Database
    self:InitializeDB()
    
    -- Initialize Module System
    self:InitializeModuleSystem()
    
    -- Initialize registered modules (once all files are loaded)
    for id, module in pairs(self.Modules) do
        if module.Initialize then
            module:Initialize()
        end
    end
    
    self:Print("Puggy Initialized.")
end

function Puggy:OnEnable()
    -- Enable components
    if self.EnableComm then self:EnableComm() end
    if self.EnableRoster then self:EnableRoster() end
    
    self:Print("Puggy Enabled.")
end
