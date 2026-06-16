--[[ Item Track Tags ---------------------------------------------------------
  Puts a tiny colored letter on each equipped item in the Character panel (C)
  showing its upgrade track: E A V C H M.

  Lightweight: no options UI, no SavedVariables. 
  
  You can edit the TRACKS table to add track names for other localizations, or to change letters/colors,
----------------------------------------------------------------------------]]

-- ===========================================================================
--  CONFIG  --
-- ===========================================================================

-- Map a track's tooltip name -> the letter to show and its color {r, g, b}.
-- The KEY must match the word as it appears in the tooltip's upgrade line.
-- 
-- ===========================================================================
--  How to add localization?  --  
-- ===========================================================================
-- For any other locale, run  "/itt debug"  (with gear of different tracks equipped ofc) to see the
-- exact words, then add the lines like  ["Heros"] = { letter = "H", color = {1, 0.5, 0} }
-- #### Help with localization would be highly appreciated! Just create a PR ! ####

local E = { letter = "E", color = {0.62, 0.62, 0.62} } -- Explorer   - gray
local A = { letter = "A", color = {0.12, 1.00, 0.00} } -- Adventurer - green
local V = { letter = "V", color = {0.00, 0.80, 0.80} } -- Veteran    - teal
local C = { letter = "C", color = {0.00, 0.44, 1.00} } -- Champion   - blue
local H = { letter = "H", color = {1.00, 0.50, 0.00} } -- Hero       - orange
local M = { letter = "M", color = {1.00, 0.40, 0.80} } -- Myth       - pink

local TRACKS = {
    -- enUS
    ["Explorer"]   = E,
    ["Adventurer"] = A,
    ["Veteran"]    = V,
    ["Champion"]   = C,
    ["Hero"]       = H,
    ["Myth"]       = M,
    -- deDE
    ["Forscher"]   = E,
    ["Abenteurer"] = A,
    ["Held"]       = H,
    ["Mythos"]     = M,
}

local FONT_SIZE   = 14              -- letter size (px)
local FONT_FLAGS  = "OUTLINE"       -- "" | "OUTLINE" | "THICKOUTLINE"
local ANCHOR      = "TOPLEFT"       -- corner of the slot to sit in
local OFFSET_X    = 2
local OFFSET_Y    = -2

-- ===========================================================================
--  INTERNALS
-- ===========================================================================

-- equipment slots on the Character page
local SLOTS = {
    "CharacterHeadSlot", "CharacterNeckSlot", "CharacterShoulderSlot",
    "CharacterBackSlot", "CharacterChestSlot", "CharacterWristSlot",
    "CharacterHandsSlot", "CharacterWaistSlot", "CharacterLegsSlot",
    "CharacterFeetSlot", "CharacterFinger0Slot", "CharacterFinger1Slot",
    "CharacterTrinket0Slot", "CharacterTrinket1Slot",
    "CharacterMainHandSlot", "CharacterSecondaryHandSlot",
}

local tags = {} 

local function GetTag(button)
    if tags[button] then return tags[button] end
    local fs = button:CreateFontString(nil, "OVERLAY")
    fs:SetFont(STANDARD_TEXT_FONT, FONT_SIZE, FONT_FLAGS)
    fs:SetPoint(ANCHOR, button, ANCHOR, OFFSET_X, OFFSET_Y)
    fs:SetDrawLayer("OVERLAY", 7)  -- above the item icon
    tags[button] = fs
    return fs
end

-- Read the upgrade track for an inventory slot id.
-- Returns trackInfo, current, max   (nil if the item has no track)
local function GetTrackForSlot(slotID)
    local data = C_TooltipInfo.GetInventoryItem("player", slotID)
    if not data or not data.lines then return nil end

    for _, line in ipairs(data.lines) do
        local text = line.leftText
        if text then
            for name, info in pairs(TRACKS) do
                -- Match "<TrackName> ... <cur>/<max>" anywhere on the line.
                -- Keying off the cur/max number pattern keeps this locale-safe
                -- as long as the track name itself is in the TRACKS table.
                local cur, max = text:match(name .. "%s+(%d+)%s*/%s*(%d+)")
                if cur then
                    return info, tonumber(cur), tonumber(max)
                end
            end
        end
    end
    return nil
end

local function UpdateAll()
    if not CharacterFrame or not CharacterFrame:IsShown() then return end
    for _, slotName in ipairs(SLOTS) do
        local button = _G[slotName]
        if button then
            local fs = GetTag(button)
            local info = GetTrackForSlot(button:GetID())
            if info then
                fs:SetText(info.letter)
                fs:SetTextColor(info.color[1], info.color[2], info.color[3])
                fs:Show()
            else
                fs:SetText("")
                fs:Hide()
            end
        end
    end
end

-- ===========================================================================
--  EVENTS
-- ===========================================================================

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
f:RegisterEvent("UNIT_INVENTORY_CHANGED")
f:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGIN" then
        if CharacterFrame then
            CharacterFrame:HookScript("OnShow", UpdateAll)
        end
        return
    end
    if event == "UNIT_INVENTORY_CHANGED" and arg1 ~= "player" then return end

    -- Tooltip data can lag a frame right after equipping; refresh now + soon.
    UpdateAll()
    C_Timer.After(0.1, UpdateAll)
end)

-- ===========================================================================
--  DEBUG  --  /itt debug    to print the raw upgrade line of each equipped item
-- ===========================================================================
SLASH_ITEMTRACKTAGS1 = "/itt"
SlashCmdList["ITEMTRACKTAGS"] = function(msg)
    if msg == "debug" then
        print("|cff88ccffItemTrackTags|r upgrade lines for equipped gear:")
        for _, slotName in ipairs(SLOTS) do
            local button = _G[slotName]
            local slotID = button and button:GetID()
            if slotID then
                local data = C_TooltipInfo.GetInventoryItem("player", slotID)
                if data and data.lines then
                    for _, line in ipairs(data.lines) do
                        if line.leftText and line.leftText:match("%d+%s*/%s*%d+") then
                            print("  " .. slotName .. ": " .. line.leftText)
                        end
                    end
                end
            end
        end
        print("Add any track word above to the TRACKS table in ItemTrackTags.lua")
    else
        print("|cff88ccffItemTrackTags|r: /itt debug  -- show raw upgrade lines (for adding non-English track names)")
    end
end
