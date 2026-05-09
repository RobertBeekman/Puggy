--- Puggy Database
local defaults = {
    profile = {
        modules = {},
        assignments = {},
        roster = {},
        ui = {
            minimap = {
                hide = false,
            },
        },
    },
}

function Puggy:InitializeDB()
    self.db = LibStub("AceDB-3.0"):New("PuggyDB", defaults, true)
    
    -- Register callbacks if needed
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

function Puggy:RefreshConfig()
    -- Logic to refresh components after DB profile change
end
