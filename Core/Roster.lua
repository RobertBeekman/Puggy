--- Puggy Roster Management
Puggy.Roster = {}
Puggy.RosterOverrides = {
    roles = {}, -- name -> role
    specs = {}, -- name -> spec
}

assert(LibStub, "Puggy requires LibStub")
assert(LibStub:GetLibrary("LibClassicInspector", true), "Puggy requires LibClassicInspector")
assert(LibStub:GetLibrary("LibDetours-1.0", true), "Puggy requires LibDetours-1.0")

local CI = LibStub("LibClassicInspector")

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
                local unit = "raid"..i
                local guid = UnitGUID(unit)
                self:Debug("Found raid member at index %d: %s (GUID: %s)", i, name, tostring(guid))
                self:AddRosterMember(newRoster, name, fileName, subgroup, online, combatRole, raidRole, guid)
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
                local guid = UnitGUID(unit)
                self:Debug("Found party member: %s (unit: %s, GUID: %s)", name, unit, tostring(guid))
                self:AddRosterMember(newRoster, name, fileName, 1, online, combatRole, nil, guid)
            end
        end
    else
        -- Solo
        self:Debug("Mode: Solo")
        local name, server = UnitName("player")
        if name then
            if server and server ~= "" then name = name .. "-" .. server end
            local _, fileName = UnitClass("player")
            local guid = UnitGUID("player")
            self:AddRosterMember(newRoster, name, fileName, 1, true, "NONE", nil, guid)
        end
    end
    
    self.Roster = newRoster
    self:Debug("Roster update complete. Total tracked: %d", (function() local c=0; for _ in pairs(newRoster) do c=c+1 end return c end)())
    self:SendMessage("PUGGY_ROSTER_UPDATED", self.Roster)
end

function Puggy:AddRosterMember(roster, name, fileName, group, online, combatRole, raidRole, guid)
    -- Get existing data to preserve assignment counts and other transient data
    local existing = self.Roster[name]
    
    local role = self.RosterOverrides.roles[name] or self:DetectRole(fileName, name, combatRole, raidRole)
    local spec = self.RosterOverrides.specs[name] or (existing and existing.spec) or "Unknown"
    local talentPoints = (existing and existing.talentPoints)
    local gearScore = (existing and existing.gearScore) or 0
    local avgItemLevel = (existing and existing.avgItemLevel) or 0
    
    self:Debug("Processing member: %s (Class: %s, Role: %s, Online: %s, GUID: %s)", name, fileName or "UNK", role, tostring(online), tostring(guid))

    local playerData = {
        name = name,
        guid = guid,
        class = fileName,
        group = group or 1,
        role = role,
        spec = spec,
        talentPoints = talentPoints,
        gearScore = gearScore,
        avgItemLevel = avgItemLevel,
        online = (online == 1 or online == true),
        assignmentCount = existing and existing.assignmentCount or 0,
    }
    roster[name] = playerData

    if playerData.online then
        local updated = self:RefreshPlayerFromCache(playerData)
        if updated then
            self:Debug("Populated data from cache for %s", name)
        end

        -- Trigger inspection if data is still missing
        if playerData.spec == "Unknown" or playerData.gearScore == 0 then
            CI:DoInspect(guid or name)
        end
    end
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

--- LibClassicInspector Handlers

function Puggy:OnInspectorInventoryReady(guid)
    self:Debug("OnInspectorInventoryReady for %s", guid)
    if self:UpdatePlayerFromCache(guid) then
        self:SendMessage("PUGGY_ROSTER_UPDATED", self.Roster)
    end
end

function Puggy:OnGearScoreItemsLoaded(guid)
    self:OnInspectorInventoryReady(guid)
end

function Puggy:OnInspectorTalentsReady(guid)
    self:Debug("OnInspectorTalentsReady for %s", guid)
    if self:UpdatePlayerFromCache(guid) then
        self:SendMessage("PUGGY_ROSTER_UPDATED", self.Roster)
    end
end

function Puggy:UpdatePlayerFromCache(guid)
    local player = self:GetPlayerByGUID(guid)
    if player then
        return self:RefreshPlayerFromCache(player)
    end
    return false
end

function Puggy:RefreshPlayerFromCache(player)
    if not player or not player.guid then return false end
    local guid = player.guid
    local updated = false

    -- GearScore
    local gearScore, avgItemLevel = TT_GS:GetScore(guid, true)
    if gearScore > 0 then
        if player.gearScore ~= gearScore or player.avgItemLevel ~= avgItemLevel then
            player.gearScore = gearScore
            player.avgItemLevel = avgItemLevel
            updated = true
        end
    end

    -- Talents/Spec
    local specIndex = CI:GetSpecialization(guid)
    if specIndex then
        local _, englishClass = GetPlayerInfoByGUID(guid)
        local specName = CI:GetSpecializationName(englishClass or player.class, specIndex, true)
        if specName and player.spec ~= specName then
            player.spec = specName
            updated = true
        end
        
        local p1, p2, p3 = CI:GetTalentPoints(guid)
        if p1 then
            local talentPoints = string.format("%d/%d/%d", p1, p2, p3)
            if player.talentPoints ~= talentPoints then
                player.talentPoints = talentPoints
                updated = true
            end
        end
    end

    return updated
end

function Puggy:GetPlayerByGUID(guid)
    if not guid then return nil end
    for _, player in pairs(self.Roster) do
        if player.guid == guid then
            return player
        end
    end
    -- Fallback to name-based lookup if GUID is missing in roster but available via API
    local name = select(6, GetPlayerInfoByGUID(guid))
    return name and self.Roster[name]
end
