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

-- ===========================================================================
--  STATIC CONFIG  (everything else is in the /itt menu)
-- ===========================================================================

local FONT_FLAGS = "OUTLINE"    -- "" | "OUTLINE" | "THICKOUTLINE"
local ANCHOR     = "TOPLEFT"    -- corner of the slot the marker sits in
local OFFSET_X   = 2
local OFFSET_Y   = -2

-- Saved defaults. The menu edits these at runtime -> saved per account.
local DEFAULTS = {
    fontSize    = 12,
    showCrafted = true,
    colors = {
        E = {0.62, 0.62, 0.62}, -- Explorer   - gray
        A = {0.12, 1.00, 0.00}, -- Adventurer - green
        V = {0.00, 0.80, 0.80}, -- Veteran    - teal
        C = {0.00, 0.44, 1.00}, -- Champion   - blue
        H = {1.00, 0.50, 0.00}, -- Hero       - orange
        M = {1.00, 0.40, 0.80}, -- Myth       - pink
    },
}

-- Display order + readable names for the settings menu.
local TRACK_ORDER = {
    { key = "E", name = "Explorer" },
    { key = "A", name = "Adventurer" },
    { key = "V", name = "Veteran" },
    { key = "C", name = "Champion" },
    { key = "H", name = "Hero" },
    { key = "M", name = "Myth" },
}

-- For other locales, run /itt debug and add the word here.
local TRACK_KEY = {
    Explorer = "E", Adventurer = "A", Veteran = "V",
    Champion = "C", Hero = "H", Myth = "M",
    Forscher = "E", Abenteurer = "A", Held = "H", Mythos = "M",
}

-- ===========================================================================
--  SAVED VARIABLES
-- ===========================================================================

local function ApplyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            ApplyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

local DB  -- set on ADDON_LOADED

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
    fs:SetFont(STANDARD_TEXT_FONT, DB and DB.fontSize or DEFAULTS.fontSize, FONT_FLAGS)
    fs:SetPoint(ANCHOR, button, ANCHOR, OFFSET_X, OFFSET_Y)
    fs:SetDrawLayer("OVERLAY", 7)
    tags[button] = fs
    return fs
end

-- ===========================================================================
--  GETTERS
-- ===========================================================================

-- Upgrade track is the word right before the "<cur>/<max>" rank.
-- Ignore any prefixes (Sporefused:, Ascendant Voidforged etc.) automatically.
local function GetTrackLetter(slotID)
    local data = C_TooltipInfo.GetInventoryItem("player", slotID)
    if not data or not data.lines then return nil end
    for _, line in ipairs(data.lines) do
        local text = line.leftText
        if text then
            local word = text:match("([^%s:]+)%s+%d+%s*/%s*%d+")
            if word then
                local letter = TRACK_KEY[word]
                if letter then return letter end
            end
        end
    end
    return nil
end

-- Crafting quality tier (1-5) for crafted gear
local function GetCraftedQuality(slotID)
    local link = GetInventoryItemLink("player", slotID)
    if not link then return nil end
    local f = C_TradeSkillUI and C_TradeSkillUI.GetItemCraftedQualityByItemInfo
    if not f then return nil end
    local q = f(link)
    if q and q > 0 then return q end
    return nil
end

-- ===========================================================================
--  RENDER
-- ===========================================================================

local function UpdateSlot(button)
    local fs = GetTag(button)
    fs:SetFont(STANDARD_TEXT_FONT, DB.fontSize, FONT_FLAGS)
    local slotID = button:GetID()

    -- Crafted quality icon takes priority when enabled.
    if DB.showCrafted then
        local q = GetCraftedQuality(slotID)
        if q then
            local s = DB.fontSize + 2
            fs:SetText(("|A:Professions-ChatIcon-Quality-Tier%d:%d:%d|a"):format(q, s, s))
            fs:SetTextColor(1, 1, 1)
            fs:Show()
            return
        end
    end

    -- Otherwise the upgrade-track letter.
    local letter = GetTrackLetter(slotID)
    if letter then
        local c = DB.colors[letter]
        fs:SetText(letter)
        fs:SetTextColor(c[1], c[2], c[3])
        fs:Show()
        return
    end

    fs:SetText("")
    fs:Hide()
end

local function RefreshAll()
    if not DB or not CharacterFrame or not CharacterFrame:IsShown() then return end
    for _, slotName in ipairs(SLOTS) do
        local button = _G[slotName]
        if button then UpdateSlot(button) end
    end
end

-- ===========================================================================
--  COLOR PICKER
-- ===========================================================================

local function ShowColorPicker(r, g, b, onChange)
    ColorPickerFrame:SetupColorPickerAndShow({
        r = r, g = g, b = b,
        hasOpacity = false,
        swatchFunc = function()
            onChange(ColorPickerFrame:GetColorRGB())
        end,
        cancelFunc = function(prev)
            if prev then
                onChange(prev.r or prev[1], prev.g or prev[2], prev.b or prev[3])
            end
        end,
    })
end

-- ===========================================================================
--  SETTINGS PANEL  (/itt)
-- ===========================================================================

local panel  -- built lazy

local function BuildPanel()
    if panel then return panel end

    panel = CreateFrame("Frame", "ItemTrackTagsConfig", UIParent, "BackdropTemplate")
    panel:SetSize(240, 310)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:Hide()

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -14)
    title:SetText("ItemTrackTags")

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)

    -- Font size: label + steppers + value ------------------------------------
    local fsLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fsLabel:SetPoint("TOPLEFT", 16, -44)
    fsLabel:SetText("Font size")

    local minus = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    minus:SetSize(22, 20)
    minus:SetPoint("TOPLEFT", 120, -40)
    minus:SetText("-")

    local sizeText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    sizeText:SetPoint("LEFT", minus, "RIGHT", 8, 0)
    sizeText:SetWidth(24)
    sizeText:SetJustifyH("CENTER")

    local plus = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    plus:SetSize(22, 20)
    plus:SetPoint("LEFT", sizeText, "RIGHT", 8, 0)
    plus:SetText("+")

    local function refreshSizeText() sizeText:SetText(DB.fontSize) end
    minus:SetScript("OnClick", function()
        DB.fontSize = math.max(6, DB.fontSize - 1); refreshSizeText(); RefreshAll()
    end)
    plus:SetScript("OnClick", function()
        DB.fontSize = math.min(24, DB.fontSize + 1); refreshSizeText(); RefreshAll()
    end)

    -- Crafted toggle ----------------------------------------------------------
    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 14, -74)
    cb:SetSize(24, 24)
    local cbLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbLabel:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    cbLabel:SetText("Show crafted quality icons")
    cb:SetScript("OnClick", function(self)
        DB.showCrafted = self:GetChecked() and true or false
        RefreshAll()
    end)

    -- Track colors ------------------------------------------------------------
    local colorsHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colorsHeader:SetPoint("TOPLEFT", 16, -106)
    colorsHeader:SetText("Track colors")

    local y = -128
    for _, t in ipairs(TRACK_ORDER) do
        local letter, name = t.key, t.name

        local swatch = CreateFrame("Button", nil, panel)
        swatch:SetSize(18, 18)
        swatch:SetPoint("TOPLEFT", 20, y)

        local bdr = swatch:CreateTexture(nil, "BACKGROUND")
        bdr:SetPoint("TOPLEFT", -1, 1)
        bdr:SetPoint("BOTTOMRIGHT", 1, -1)
        bdr:SetColorTexture(0, 0, 0, 1)

        local fill = swatch:CreateTexture(nil, "ARTWORK")
        fill:SetAllPoints()
        local c = DB.colors[letter]
        fill:SetColorTexture(c[1], c[2], c[3])

        local lbl = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lbl:SetPoint("LEFT", swatch, "RIGHT", 8, 0)
        lbl:SetText(("%s  (%s)"):format(name, letter))

        swatch:SetScript("OnClick", function()
            local cc = DB.colors[letter]
            ShowColorPicker(cc[1], cc[2], cc[3], function(nr, ng, nb)
                cc[1], cc[2], cc[3] = nr, ng, nb
                fill:SetColorTexture(nr, ng, nb)
                RefreshAll()
            end)
        end)

        y = y - 26
    end

    -- Sync widgets to current DB whenever shown.
    panel:SetScript("OnShow", function()
        refreshSizeText()
        cb:SetChecked(DB.showCrafted)
    end)

    return panel
end

local function TogglePanel()
    BuildPanel()
    if panel:IsShown() then panel:Hide() else panel:Show() end
end

-- ===========================================================================
--  EVENTS
-- ===========================================================================

local f = CreateFrame("Frame")
        f:RegisterEvent("ADDON_LOADED")
        f:RegisterEvent("PLAYER_LOGIN")
        f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        f:RegisterEvent("UNIT_INVENTORY_CHANGED")
        f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "ItemTrackTags" then
            ItemTrackTagsDB = ItemTrackTagsDB or {}
            ApplyDefaults(ItemTrackTagsDB, DEFAULTS)
            DB = ItemTrackTagsDB
        end
        return
    elseif event == "PLAYER_LOGIN" then
        if CharacterFrame then CharacterFrame:HookScript("OnShow", RefreshAll) end
        return
    end
    if event == "UNIT_INVENTORY_CHANGED" and arg1 ~= "player" then return end
    RefreshAll()
    C_Timer.After(0.1, RefreshAll)  -- Tooltip data can lag a frame after equip
end)

-- ===========================================================================
--  MENU:  /itt  -> menu  |  /itt debug  -> parser dump
-- ===========================================================================
SLASH_ITEMTRACKTAGS1 = "/itt"
SlashCmdList["ITEMTRACKTAGS"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "debug" then
        print("|cff88ccffItemTrackTags|r upgrade lines for equipped gear:")
        for _, slotName in ipairs(SLOTS) do
            local button = _G[slotName]
            local slotID = button and button:GetID()
            if slotID then
                local data = C_TooltipInfo.GetInventoryItem("player", slotID)
                if data and data.lines then
                    for _, line in ipairs(data.lines) do
                        local text = line.leftText
                        if text and text:match("%d+%s*/%s*%d+") then
                            local word = text:match("([^%s:]+)%s+%d+%s*/%s*%d+")
                            local tag = (word and TRACK_KEY[word])
                                and ("|cff44ff44(track "..TRACK_KEY[word]..")|r")
                                or (word and "|cffff4444(unknown: "..word..")|r" or "")
                            print("  " .. slotName .. ": " .. text .. " " .. tag)
                        end
                    end
                end
                local q = GetCraftedQuality(slotID)
                if q then print("  " .. slotName .. ": |cffffcc00crafted quality "..q.."|r") end
            end
        end
    elseif msg == "help" then
        print("|cff88ccffItemTrackTags|r:  /itt  (settings)  |  /itt debug  (parser dump)")
    else
        TogglePanel()
    end
end
