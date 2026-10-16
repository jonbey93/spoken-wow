local here = arg[0]:match("^(.*)/[^/]*$") or "."
package.path = here .. "/?.lua;" .. package.path
local stub = require("wow_client_stub")
local H = require("queue_helpers")
local Expect, Failures = H.Expecter(stub.print)
local env, quests = H.Fresh(stub, here .. "/../../addons/Spoken/")
local C = H.LoadCombat(stub, here .. "/../../addons/Spoken_Combat/")
local Q = env.SoundQueue
local events = H.Recorder(env)
C:Setup()

local pack
local function Install()
    pack = { version = 1, addon = "SpokenCombatAudio", voice = "nightelf-female-standard", language = "enUS", clips = {} }
    for i = 1, 8 do table.insert(pack.clips, { key = string.format("%02d", i), length = 2, format = "mp3" }) end
    _G.SpokenCombatAudioPacks = { SpokenCombatAudio = pack }
    C.bag = {}
end
local function Enter()
    stub.FireEvent("PLAYER_REGEN_ENABLED")
    stub.FireEvent("PLAYER_REGEN_DISABLED")
end

assert(loadfile(here .. "/../../addons/SpokenCombatAudio/Data/Sounds.lua"))("SpokenCombatAudio")
Expect("an empty source pack is not advertised as playable", #C:GetAudioPacks(), 0)
Expect("off on a new character", C:IsEnabled(), false)
C:SetEnabled(true)
Expect("an incomplete voice cannot play", C:Play(), false)
Expect("a missing recording spends no cooldown", C.lastPlayed, nil)
Install()
Expect("all eight recordings installed", C:IsReady(), true)
Expect("the module reports the actual audio pack", C:GetAudioPacks()[1].addon, "SpokenCombatAudio")
pack.version = 2
Expect("an unknown pack format cannot play", C:Preview(), false)
pack.version = 1
pack.language = "deDE"
Expect("another language cannot silently supply the English voice", C:Preview(), false)
pack.language = "enUS"
Enter()
Expect("combat entry plays", #stub.world.played, 1)
Expect("combat audio is resolved inside the separate sound pack",
    string.find(stub.world.played[1], [[Interface\AddOns\SpokenCombatAudio\Sounds\Combat\]], 1, true), 1)
Expect("the selected sound channel is used", stub.world.playedChannels[1], "Master")
Expect("combat speech stays out of the queue", Q:GetQueueSize(), 0)
Expect("combat speech emits no narrator callbacks", #events.log, 0)
stub.FireEvent("PLAYER_REGEN_DISABLED")
Expect("duplicate entry events do not play twice", #stub.world.played, 1)
stub.FireEvent("PLAYER_REGEN_ENABLED")
Expect("leaving combat lets the line finish", env.Reactions.clip ~= nil, true)
stub.Advance(2)
Enter()
Expect("rapid re-entry respects cooldown", #stub.world.played, 1)
stub.Advance(43)
stub.world.time = C.lastPlayed + 45
Enter()
Expect("45 seconds allows another line", #stub.world.played, 2)

local played = #stub.world.played
C:SetEnabled(false)
Expect("disabling stops the voice", env.Reactions.clip, nil)
stub.Advance(50); Enter()
Expect("disabled characters stay silent", #stub.world.played, played)
Expect("preview works while disabled and ignores cooldown", C:Preview(), true)
C:Stop()
local seen, last = {}, C.lastKey
for i = 1, 30 do
    C:Preview()
    Expect("draw " .. i .. " does not repeat the last line", C.lastKey ~= last, true)
    last = C.lastKey
    C:Stop()
end
C.bag = {}
for i = 1, 8 do C:Preview(); seen[C.lastKey] = true; C:Stop() end
local count = 0
for _ in pairs(seen) do count = count + 1 end
Expect("each shuffled pool plays every line exactly once", count, 8)

C:SetEnabled(true)
stub.Advance(50)
quests:Enqueue(H.Clip({ length = 10 }))
played = #stub.world.played
local before = C.lastPlayed
Enter()
Expect("narration suppresses combat speech", #stub.world.played, played)
Expect("suppression does not consume cooldown", C.lastPlayed, before)
Q:RemoveAllSoundsFromQueue()
Enter()
Expect("combat speech can play after narration", env.Reactions.clip ~= nil, true)
quests:Enqueue(H.Clip({ length = 10 }))
Expect("narration starting later stops combat speech", env.Reactions.clip, nil)
Q:RemoveAllSoundsFromQueue()

env.Addon.db.profile.Audio.SoundChannel = "SFX"
stub.world.cvars.Sound_EnableSFX = "0"
before = C.lastPlayed
Expect("muted audio is not played", C:Preview(), false)
Expect("muted audio spends no cooldown", C.lastPlayed, before)
stub.world.cvars.Sound_EnableSFX = "1"
local missing = C:Next()
local path = string.format([[Interface\AddOns\SpokenCombatAudio\Sounds\Combat\nightelf-female-standard-%s.mp3]], missing.key)
stub.world.missing[path] = true
Expect("missing files fail without pretending to play", C:Preview(), false)
Expect("a failed draw is kept", C:Next(), missing)
stub.world.missing[path] = nil
_G.UnitIsDeadOrGhost = function() return true end
Expect("dead characters stay silent", C:Preview(), false)
_G.UnitIsDeadOrGhost = function() return false end

for _, style in ipairs({ "none", "subtitle", "minimal", "classic", "queue", "dialogueui" }) do
    env.Addon.db.profile.Frame.Style = style
    C:Preview()
    Expect(style .. " has no combat queue entry", Q:GetQueueSize(), 0)
    C:Stop()
end
env.Version.IsAnyLegacy = true
Expect("legacy clients cannot use the independent voice", C:Preview(), false)
env.Version.IsAnyLegacy = false
pack.clips[1].key = "../../bad"
Expect("invalid manifests are refused", C:IsReady(), false)
Install()
for _, clip in ipairs(pack.clips) do clip.format = "wav" end
C.bag = { pack.clips[1] }
C:Preview()
Expect("supplied WAV recordings use their own extension", string.sub(stub.world.played[#stub.world.played], -4), ".wav")
C:Stop()
for _, clip in ipairs(pack.clips) do clip.format = "ogg" end
C.bag = { pack.clips[1] }
C:Preview()
Expect("supplied OGG recordings use their own extension", string.sub(stub.world.played[#stub.world.played], -4), ".ogg")
C:Stop()
pack.clips[1].format = "../../bad"
Expect("recording extensions cannot escape their folder", C:IsReady(), false)
Install()
C:Preview(); stub.FireEvent("PLAYER_DEAD")
Expect("death stops a playing combat reaction", env.Reactions.clip, nil)
Expect("combat setting is stored per character", SpokenCombatCharacter.SpeakOnEnteringCombat, true)
Expect("combat setting is absent from the profile", env.Addon.db.profile.CombatVoice, nil)
C:Stop()
C:SetEnabled(true)
C:Preview()
Spoken:SetPartOn("combat", false)
Expect("switching off the module stops its reaction", env.Reactions.clip, nil)
Expect("the module switch blocks preview", C:Preview(), false)
Expect("the module switch preserves the character preference", C:IsEnabled(), true)
Spoken:SetPartOn("combat", true)
Expect("switching the module back on permits preview", C:Preview(), true)
Spoken:StopAll()
Expect("the public stop command stops reactions", env.Reactions.clip, nil)

env.Addon.db.profile.Frame.Style = "classic"
env.Addon:Enable()
C:SetupOptions()
local labels = {}
for _, text in ipairs(stub.LabelsUnder(C.optionsPage.frame)) do labels[text] = true end
Expect("Combat is nested under Spoken", C.optionsPage.category.parent.name, "Spoken")
Expect("the nested page is named Combat", C.optionsPage.category.name, "Combat")
Expect("the page offers Enable Module", labels["Enable Module"], true)
Expect("the page offers Speak on Entering Combat", labels["Speak on Entering Combat"], true)
Expect("the page offers Preview Combat Voice", labels["Preview Combat Voice"], true)
SlashCmdList.SPOKEN("combat off")
Expect("the combat slash command is dispatched to the module", C:IsEnabled(), false)
SlashCmdList.SPOKEN("combat test")
Expect("slash preview works with automatic speech off", env.Reactions.clip ~= nil, true)
SlashCmdList.SPOKEN("stop")
Expect("slash stop stops the module's reaction", env.Reactions.clip, nil)
Spoken:SetPartOn("combat", false)
Expect("disabling the module leaves its settings page available", C.optionsPage.Open(), true)
Expect("nothing failed in a module callback", #env.Callbacks.errors, 0)
os.exit(Failures() == 0 and 0 or 1)
