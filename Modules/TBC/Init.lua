--- Puggy TBC Expansion Module
local TBC = {
    name = "The Burning Crusade",
    RaidData = {},
}

function TBC:OnRegister()
    -- Registration logic
end

--- Function to be called after all data files are loaded
function TBC:Initialize()
    for raidId, raidData in pairs(self.RaidData) do
        Puggy:RegisterRaid(Puggy.Constants.EXPANSIONS.TBC, raidId, raidData)
        
        for bossId, bossData in pairs(raidData.bosses or {}) do
            Puggy:RegisterBoss(raidId, bossId, bossData)
        end
    end
end

Puggy:RegisterExpansionModule("TBC", TBC)
