local _, CombatVoice = ...
_G.SpokenCombat = CombatVoice
CombatVoice.bag = {}
CombatVoice.L = {
    COMBAT_VOICE_TITLE = "Combat Voice",
    COMBAT_VOICE_ENABLE = "Speak on Entering Combat",
    COMBAT_VOICE_TIP = "Your character speaks a short night elf line when combat begins, at most once every 45 seconds. Uses the female night elf voice in English on any character. Saved for this character. Skips while Spoken is narrating and shows no narrator or subtitles.",
    COMBAT_VOICE_PREVIEW = "Preview Combat Voice",
    COMBAT_VOICE_PREVIEW_TIP = "Plays a random line without enabling combat speech or waiting for the combat cooldown.",
    COMBAT_VOICE_MISSING = "Install and enable Spoken Combat Audio, then restart WoW. Download it from spoken.rusty.one/enUS/combat.",
    COMBAT_VOICE_UNSUPPORTED = "Combat Voice needs a current WoW client; legacy 1.12, 2.4.3 and 3.3.5 clients are not supported.",
    COMBAT_VOICE_BUSY = "Another Spoken voice is already playing.",
    COMBAT_VOICE_DEAD = "Combat Voice cannot play while dead.",
    COMBAT_VOICE_ON = "Combat Voice enabled for this character.",
    COMBAT_VOICE_OFF = "Combat Voice disabled for this character.",
}
local L = CombatVoice.L

function CombatVoice:IsEnabled()
    return self.settings and self.settings.SpeakOnEnteringCombat == true
end

function CombatVoice:SetEnabled(enabled)
    self.settings.SpeakOnEnteringCombat = enabled and true or false
    if not enabled then self:Stop() end
end

function CombatVoice:Stop()
    Spoken:StopReaction(self.source)
end

function CombatVoice:Next()
    local pack = self:GetVoicePack()
    if self.pack ~= pack then self.bag, self.pack = {}, pack end
    if not self.bag[1] then
        for _, clip in ipairs(pack.clips) do table.insert(self.bag, clip) end
        for index = table.getn(self.bag), 2, -1 do
            local other = math.random(index)
            self.bag[index], self.bag[other] = self.bag[other], self.bag[index]
        end
        -- The first draw after a reshuffle must not repeat the last voice heard.
        local last = table.getn(self.bag)
        if self.bag[last].key == self.lastKey then
            self.bag[1], self.bag[last] = self.bag[last], self.bag[1]
        end
    end
    return self.bag[table.getn(self.bag)]
end

function CombatVoice:Play(preview)
    if not Spoken:IsPartOn("combat") then return false end
    if not preview and not self:IsEnabled() then return false end
    if not self:IsReady() then return false, L.COMBAT_VOICE_MISSING end
    if Spoken:IsReactionPlaying() or Spoken:IsPlaying() then return false, L.COMBAT_VOICE_BUSY end
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return false, L.COMBAT_VOICE_DEAD end
    if not preview and self.lastPlayed and GetTime() - self.lastPlayed < 45 then return false end
    local line = self:Next()
    local clip = { path = self:ClipPath(self.pack, line), length = line.length }
    local played, why = Spoken:PlayReaction(self.source, clip)
    if not played then
        local reasons = { missing = L.COMBAT_VOICE_MISSING, busy = L.COMBAT_VOICE_BUSY,
            unsupported = L.COMBAT_VOICE_UNSUPPORTED }
        return false, reasons[why] or why
    end
    table.remove(self.bag)
    self.lastKey = line.key
    if not preview then self.lastPlayed = GetTime() end
    return true
end

function CombatVoice:Preview()
    local played, why = self:Play(true)
    if not played and why then print("Spoken: " .. why) end
    return played
end

function CombatVoice:Command(input)
    if input == "on" then self:SetEnabled(true)
    elseif input == "off" then self:SetEnabled(false)
    elseif input == "test" or input == "preview" then self:Preview(); return
    else print("Spoken: /spoken combat on | off | test"); return end
    print("Spoken: " .. (self:IsEnabled() and L.COMBAT_VOICE_ON or L.COMBAT_VOICE_OFF))
    if self:IsEnabled() and not self:IsReady() then print("Spoken: " .. L.COMBAT_VOICE_MISSING) end
    if self.optionsLayout then self.optionsLayout:Refresh() end
end

function CombatVoice:Setup()
    if self.frame then return end
    if not (Spoken and Spoken.PlayReaction) then return end
    SpokenCombatCharacter = SpokenCombatCharacter or {}
    self.settings = SpokenCombatCharacter
    if self.settings.SpeakOnEnteringCombat == nil then
        local old = _G.SpokenSettings
        local key = UnitName("player") .. " - " .. GetRealmName()
        local char = old and old.char and old.char[key]
        self.settings.SpeakOnEnteringCombat = char and char.CombatVoice == true or false
    end
    self.source = Spoken:RegisterSource("combat", {
        title = "Combat", addon = "Spoken_Combat", order = 4,
        icon = [[Interface\Icons\Ability_DualWield]],
        packs = function() return self:GetAudioPacks() end,
    })
    Spoken:RegisterCommand("combat", function(input) self:Command(input) end)
    local frame = CreateFrame("Frame")
    self.frame = frame
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_DEAD")
    frame:RegisterEvent("PLAYER_LOGOUT")
    frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            if not self.inCombat then self.inCombat = true; self:Play(false) end
        elseif event == "PLAYER_REGEN_ENABLED" then self.inCombat = false
        else self:Stop() end
    end)
end
