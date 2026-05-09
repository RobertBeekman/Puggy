--- Puggy Assignment Engine
Puggy.Assignments = {}

function Puggy:CreateAssignment(raidId, bossId, templateId, assignments)
    self:Debug("Creating assignment for Boss %s", tostring(bossId))
    local assignment = {
        id = GetTime(), -- Temporary ID
        raidId = raidId,
        bossId = bossId,
        templateId = templateId,
        data = assignments,
        timestamp = GetServerTime(),
    }
    
    table.insert(self.db.profile.assignments, assignment)
    
    -- Update assignment counts in Roster
    if self.UpdateAssignmentCountFromAll then
        self:UpdateAssignmentCountFromAll()
    end

    self:Debug("Assignment created with ID %s. Notifying modules.", tostring(assignment.id))
    self:SendMessage("PUGGY_ASSIGNMENT_CREATED", assignment)
    return assignment
end

function Puggy:GetAssignmentsForBoss(bossId)
    local results = {}
    for _, ass in ipairs(self.db.profile.assignments) do
        if ass.bossId == bossId then
            table.insert(results, ass)
        end
    end
    return results
end

function Puggy:PushAssignment(assignmentId)
    -- Logic to broadcast assignment via Comm
    local assignment = self:GetAssignmentById(assignmentId)
    if assignment then
        self:SendPacket("RAID", {
            type = self.Constants.MSG_TYPES.ASSIGNMENT_UPDATE,
            payload = assignment
        })
    end
end

function Puggy:GetAssignmentById(id)
    for _, ass in ipairs(self.db.profile.assignments) do
        if ass.id == id then return ass end
    end
end
