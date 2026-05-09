--- Puggy Communication
local LS = LibStub("LibSerialize")
local LD = LibStub("LibDeflate")

function Puggy:EnableComm()
    self:RegisterComm(self.Constants.COMM_PREFIX, "OnCommReceived")
end

function Puggy:SendPacket(target, data, priority)
    local serialized = LS:Serialize(data)
    local compressed = LD:CompressDeflate(serialized)
    local encoded = LD:EncodeForWoWAddonChannel(compressed)
    
    if target == "RAID" or target == "GUILD" or target == "PARTY" then
        self:SendCommMessage(self.Constants.COMM_PREFIX, encoded, target, nil, priority or "NORMAL")
    else
        self:SendCommMessage(self.Constants.COMM_PREFIX, encoded, "WHISPER", target, priority or "NORMAL")
    end
end

function Puggy:OnCommReceived(prefix, message, distribution, sender)
    if prefix ~= self.Constants.COMM_PREFIX then return end
    if sender == UnitName("player") then return end
    
    local decoded = LD:DecodeForWoWAddonChannel(message)
    if not decoded then return end
    
    local decompressed = LD:DecompressDeflate(decoded)
    if not decompressed then return end
    
    local success, data = LS:Deserialize(decompressed)
    if not success then return end
    
    self:HandlePacket(sender, data)
end

function Puggy:HandlePacket(sender, data)
    -- Dispatch based on packet type
    if data.type == self.Constants.MSG_TYPES.ASSIGNMENT_UPDATE then
        -- Handle assignment update
    elseif data.type == self.Constants.MSG_TYPES.VERSION_CHECK then
        -- Handle version check
    end
end
