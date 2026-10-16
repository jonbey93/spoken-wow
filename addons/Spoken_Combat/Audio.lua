local _, Combat = ...

local function Valid(pack)
    if type(pack) ~= "table" or pack.version ~= 1 or pack.language ~= "enUS"
        or pack.voice ~= "nightelf-female-standard" or type(pack.addon) ~= "string"
        or not string.find(pack.addon, "^[%w_%-]+$")
        or type(pack.clips) ~= "table" or table.getn(pack.clips) ~= 8 then return false end
    local seen = {}
    for _, clip in ipairs(pack.clips) do
        if type(clip) ~= "table" or type(clip.key) ~= "string" or not string.find(clip.key, "^0[1-8]$")
            or seen[clip.key] or (clip.format ~= "mp3" and clip.format ~= "ogg" and clip.format ~= "wav")
            or type(clip.length) ~= "number" or not (clip.length > 0 and clip.length <= 6) then return false end
        seen[clip.key] = true
    end
    return true
end

function Combat:GetAudioPacks()
    local packs = {}
    for _, pack in pairs(_G.SpokenCombatAudioPacks or {}) do
        if Valid(pack) then table.insert(packs, pack) end
    end
    table.sort(packs, function(a, b) return a.addon < b.addon end)
    return packs
end

function Combat:GetVoicePack()
    return self:GetAudioPacks()[1]
end

function Combat:IsReady()
    return self:GetVoicePack() ~= nil
end

function Combat:ClipPath(pack, clip)
    return string.format([[Interface\AddOns\%s\Sounds\Combat\%s-%s.%s]],
        pack.addon, pack.voice, clip.key, clip.format)
end
