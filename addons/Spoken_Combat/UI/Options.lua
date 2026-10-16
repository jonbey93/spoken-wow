local _, Combat = ...

function Combat:SetupOptions()
    if self.optionsPage or not SpokenLayout or not Spoken:SettingsStyle() then return end
    local L = self.L
    local panel = CreateFrame("Frame")
    panel.name = "Spoken Combat"
    local scroller = SpokenLayout.Scroll(panel)
    local content = scroller.child
    local layout = SpokenLayout.New(content, 25, -16)
    layout:Intro([[Interface\Icons\Ability_DualWield]], "Combat")
    local function PartOn() return Spoken:IsPartOn("combat") end
    local refresh = function() layout:Refresh() end
    local switch = layout:Checkbox("Enable Module", "Enable Spoken Combat. Saved with your Spoken profile.",
        PartOn, function(value) Spoken:SetPartOn("combat", value) end, refresh)
    layout:Checkbox(L.COMBAT_VOICE_ENABLE, L.COMBAT_VOICE_TIP,
        function() return Combat:IsEnabled() end,
        function(value) Combat:SetEnabled(value) end, refresh)
    local preview = layout:Button(L.COMBAT_VOICE_PREVIEW, 200,
        function() Combat:Preview() end, L.COMBAT_VOICE_PREVIEW_TIP)
    layout:Requires(preview, function() return Combat:IsReady() end, L.COMBAT_VOICE_MISSING)
    local missing = layout:Note(L.COMBAT_VOICE_MISSING, nil, 32)
    missing:SetHeight(24)
    layout:ShowWhen(missing, function() return not Combat:IsReady() end)
    layout:RequiresAll(PartOn, "Enable the Combat module to use this.", switch)
    layout:Refresh()
    content:SetScript("OnShow", refresh)
    Spoken:RegisterCallback("PART_SWITCHED", function(key) if key == "combat" then refresh() end end)
    scroller:SetContentHeight(layout:Height() + 40)
    self.optionsPage = Spoken:AddSettingsPage(panel, "Combat", 4, layout, scroller)
    self.optionsLayout = layout
end
