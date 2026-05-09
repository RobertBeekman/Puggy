--- Puggy Module System
Puggy.Modules = {}
Puggy.Raids = {}
Puggy.Bosses = {}

function Puggy:InitializeModuleSystem()
    -- Initialize module-related data structures
    self.Modules = {}
end

--- Registers an expansion module
-- @param id Unique identifier (e.g. "TBC")
-- @param moduleData Table containing module info and registration functions
function Puggy:RegisterExpansionModule(id, moduleData)
    if self.Modules[id] then
        self:Print("Module already registered: " .. id)
        return
    end
    
    self.Modules[id] = moduleData
    moduleData.id = id
    
    if moduleData.OnRegister then
        moduleData:OnRegister()
    end
    
    self:Print("Registered expansion module: " .. (moduleData.name or id))
end

--- Registers a raid for a specific expansion
function Puggy:RegisterRaid(expansionId, raidId, raidData)
    if not self.Raids[expansionId] then
        self.Raids[expansionId] = {}
    end
    
    self.Raids[expansionId][raidId] = raidData
    raidData.id = raidId
    raidData.expansionId = expansionId
end

--- Registers a boss for a raid
function Puggy:RegisterBoss(raidId, bossId, bossData)
    if not self.Bosses[raidId] then
        self.Bosses[raidId] = {}
    end
    
    self.Bosses[raidId][bossId] = bossData
    bossData.id = bossId
    bossData.raidId = raidId
end
