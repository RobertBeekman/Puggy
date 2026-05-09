--- Puggy Roster Management
Puggy.Roster = {}

function Puggy:EnableRoster()
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnRosterUpdate")
    self:UpdateRoster()
end

function Puggy:OnRosterUpdate()
    self:UpdateRoster()
end

function Puggy:UpdateRoster()
    local numMembers = GetNumGroupMembers()
    local roster = {}
    
    if numMembers > 0 then
        local unitPrefix = IsInRaid() and "raid" or "party"
        for i = 1, numMembers do
            local unit = unitPrefix .. i
            if unitPrefix == "party" and i == numMembers then
                unit = "player"
            end
            
            local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
            if name then
                roster[name] = {
                    name = name,
                    class = fileName,
                    subgroup = subgroup,
                    role = role,
                    online = online,
                }
            end
        end
    end
    
    self.Roster = roster
    self:SendMessage("PUGGY_ROSTER_UPDATED", self.Roster)
end

function Puggy:GetRoster()
    return self.Roster
end
