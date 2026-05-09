--- Puggy Roster Management
Puggy.Roster = {}
Puggy.RosterOverrides = {
    roles = {}, -- name -> role
    specs = {}, -- name -> spec
}

function Puggy:EnableRoster()
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnRosterUpdate")
    self:RegisterEvent("UNIT_CONNECTION", "OnRosterUpdate") -- Handle disconnects
    self:RegisterEvent("UNIT_FLAGS", "OnRosterUpdate")      -- Handle status changes
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateRoster")
    
    -- Load overrides from DB if they exist
    if self.db.profile.rosterOverrides then
        self.RosterOverrides = self.db.profile.rosterOverrides
    else
        self.db.profile.rosterOverrides = self.RosterOverrides
    end

    self:UpdateRoster()
end

function Puggy:OnRosterUpdate()
    self:UpdateRoster()
end

function Puggy:UpdateRoster()
    self:Debug("Updating roster...")
    local newRoster = {}
    
    if IsInRaid() then
        self:Debug("Mode: Raid")
        -- Documentation says it's discouraged to use GetNumGroupMembers due to "holes"
        -- We loop up to 40 (MAX_RAID_MEMBERS)
        for i = 1, 40 do
            local name, _, subgroup, _, _, fileName, _, online, _, raidRole, _, combatRole = GetRaidRosterInfo(i)
            if name then
                self:Debug("Found raid member at index %d: %s", i, name)
                self:AddRosterMember(newRoster, name, fileName, subgroup, online, combatRole, raidRole)
            end
        end
    elseif IsInGroup() then
        self:Debug("Mode: Party")
        local numMembers = GetNumGroupMembers()
        for i = 1, numMembers do
            local unit = (i == numMembers) and "player" or "party" .. i
            local name, server = UnitName(unit)
            if name then
                if server and server ~= "" then name = name .. "-" .. server end
                local _, fileName = UnitClass(unit)
                local online = UnitIsConnected(unit)
                local combatRole = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit) or "NONE"
                self:Debug("Found party member: %s (unit: %s)", name, unit)
                self:AddRosterMember(newRoster, name, fileName, 1, online, combatRole, nil)
            end
        end
    else
        -- Solo
        self:Debug("Mode: Solo")
        local name, server = UnitName("player")
        if name then
            if server and server ~= "" then name = name .. "-" .. server end
            local _, fileName = UnitClass("player")
            self:AddRosterMember(newRoster, name, fileName, 1, true, "NONE", nil)
        end
    end
    
    self.Roster = newRoster
    self:Debug("Roster update complete. Total tracked: %d", (function() local c=0; for _ in pairs(newRoster) do c=c+1 end return c end)())
    self:SendMessage("PUGGY_ROSTER_UPDATED", self.Roster)
end

function Puggy:AddRosterMember(roster, name, fileName, group, online, combatRole, raidRole)
    -- Get existing data to preserve assignment counts and other transient data
    local existing = self.Roster[name]
    
    local role = self.RosterOverrides.roles[name] or self:DetectRole(fileName, name, combatRole, raidRole)
    local spec = self.RosterOverrides.specs[name] or "Unknown"
    
    self:Debug("Processing member: %s (Class: %s, Role: %s, Online: %s)", name, fileName or "UNK", role, tostring(online))

    local playerData = {
        name = name,
        class = fileName,
        group = group or 1,
        role = role,
        spec = spec,
        online = (online == 1 or online == true),
        assignmentCount = existing and existing.assignmentCount or 0,
    }
    roster[name] = playerData
end

function Puggy:DetectRole(class, name, combatRole, raidRole)
    -- 1. Prioritize Blizzard's combat role if set
    if combatRole and combatRole ~= "NONE" then
        return combatRole
    end
    
    -- 2. Check for "maintank" in raidRole
    if raidRole == "maintank" then
        return "TANK"
    end
    
    -- 3. Simple automatic detection heuristics
    if class == "WARRIOR" or class == "PALADIN" or class == "DRUID" then
        -- Could be TANK, but default to NONE if not specified
        return "NONE"
    end
    
    -- Pure DPS classes
    if class == "MAGE" or class == "WARLOCK" or class == "HUNTER" or class == "ROGUE" then
        return "DAMAGER"
    end
    
    return "NONE"
end

function Puggy:SetRoleOverride(name, role)
    self.RosterOverrides.roles[name] = role
    if self.Roster[name] then
        self.Roster[name].role = role
    end
    self:SendMessage("PUGGY_ROSTER_UPDATED", self.Roster)
end

function Puggy:SetSpecOverride(name, spec)
    self.RosterOverrides.specs[name] = spec
    if self.Roster[name] then
        self.Roster[name].spec = spec
    end
    self:SendMessage("PUGGY_ROSTER_UPDATED", self.Roster)
end

function Puggy:UpdateAssignmentCount(name, count)
    if self.Roster[name] then
        self.Roster[name].assignmentCount = count
        self:SendMessage("PUGGY_ROSTER_UPDATED", self.Roster)
    end
end

function Puggy:UpdateAssignmentCountFromAll()
    local counts = {}
    for _, assignment in ipairs(self.db.profile.assignments) do
        -- Assuming assignment.data contains names or player references
        -- This logic depends on how assignment data is structured
        -- For now, we'll just check if it's a table of names
        if type(assignment.data) == "table" then
            for _, player in pairs(assignment.data) do
                local name = type(player) == "string" and player or player.name
                if name then
                    counts[name] = (counts[name] or 0) + 1
                end
            end
        end
    end
    
    for name, player in pairs(self.Roster) do
        player.assignmentCount = counts[name] or 0
    end
    self:SendMessage("PUGGY_ROSTER_UPDATED", self.Roster)
end

function Puggy:GetRoster()
    return self.Roster
end

function Puggy:GetPlayer(name)
    return self.Roster[name]
end

function Puggy:AddPlayer(name, data)
    if not name then return end
    self.Roster[name] = data
    self:SendMessage("PUGGY_ROSTER_UPDATED", self.Roster)
end

function Puggy:UpdatePlayer(name, data)
    if not self.Roster[name] then return end
    for k, v in pairs(data) do
        self.Roster[name][k] = v
    end
    self:SendMessage("PUGGY_ROSTER_UPDATED", self.Roster)
end

function Puggy:RemovePlayer(name)
    if self.Roster[name] then
        self.Roster[name] = nil
        self:SendMessage("PUGGY_ROSTER_UPDATED", self.Roster)
    end
end
