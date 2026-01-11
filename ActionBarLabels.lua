-- ActionBarLabels Addon
-- Adds a label above the action bar with customizable text

local ADDON_NAME = "ActionBarLabels"
local LAM = LibAddonMenu2

-- Default saved variables
local defaults = {
    bar1Text = "Front Bar",
    bar2Text = "Back Bar"
}

-- Saved variables (initialized after addon loads)
local savedVars

-- Get current active bar text
local function GetCurrentBarText()
    if not savedVars then
        return ""
    end
    
    local activeWeaponPair = GetActiveWeaponPairInfo()
    if activeWeaponPair == 1 then
        return savedVars.bar1Text
    else
        return savedVars.bar2Text
    end
end

-- Check if attribute bars are visible
local function AreAttributesVisible()
    -- Check if any of the attribute bars (Health, Magicka, Stamina) are visible
    local healthBar = ZO_PlayerAttributeHealth
    local magickaBar = ZO_PlayerAttributeMagicka
    local staminaBar = ZO_PlayerAttributeStamina
    
    if healthBar and not healthBar:IsHidden() then
        return true
    end
    if magickaBar and not magickaBar:IsHidden() then
        return true
    end
    if staminaBar and not staminaBar:IsHidden() then
        return true
    end
    
    return false
end

-- Get the vertical offset based on attribute visibility
local function GetVerticalOffset()
    if AreAttributesVisible() then
        return -50  -- Higher position if attributes are showing
    else
        return -10  -- Lower position if attributes are not showing
    end
end

-- Create the label control
local function CreateLabel()
    -- Make sure savedVars is initialized
    if not savedVars then
        return false
    end
    
    -- Get the action bar control
    local actionBar = ZO_ActionBar1
    
    if not actionBar then
        -- Try again after a short delay if action bar isn't ready
        zo_callLater(CreateLabel, 100)
        return false
    end
    
    -- Check if action bar has valid dimensions
    if actionBar:GetWidth() == 0 or actionBar:GetHeight() == 0 then
        -- Try again after a short delay
        zo_callLater(CreateLabel, 100)
        return false
    end
    
    -- Check if label already exists
    if ActionBarLabels.label then
        -- Update the label text for current bar
        UpdateLabelText(GetCurrentBarText())
        return true
    end
    
    local wm = GetWindowManager()
    
    -- Try creating as child of action bar first (most reliable)
    local labelName = ADDON_NAME .. "_Label"
    local label = wm:CreateControl(labelName, actionBar, CT_LABEL)
    
    if not label then
        -- Fallback to parent if direct child fails
        local parent = actionBar:GetParent() or GuiRoot
        label = wm:CreateControl(labelName, parent, CT_LABEL)
    end
    
    if not label then
        return false
    end
    
    -- Set label dimensions first (larger to accommodate bigger text)
    label:SetDimensions(500, 40)
    
    -- Set label properties before anchoring
    label:SetFont("ZoFontHeader") -- Larger, bold font
    label:SetColor(1, 1, 1, 1) -- White color
    label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    label:SetText(GetCurrentBarText())
    
    -- Get the appropriate vertical offset based on attribute visibility
    local verticalOffset = GetVerticalOffset()
    
    -- Anchor the label above the action bar (center horizontally, offset based on attributes)
    label:SetAnchor(BOTTOM, actionBar, TOP, 0, verticalOffset)
    
    -- Set visibility and draw settings - ensure it's on top
    label:SetDrawLayer(DL_OVERLAY)
    label:SetDrawLevel(200) -- Very high draw level
    label:SetAlpha(1.0) -- Ensure full opacity
    label:SetHidden(false) -- Do this last
    
    -- Store reference for updates
    ActionBarLabels.label = label
    
    return true
end

-- Update label text
local function UpdateLabelText(text)
    if ActionBarLabels.label then
        ActionBarLabels.label:SetText(text)
    end
end

-- Handle weapon bar swap
local function OnWeaponPairChanged(eventCode, activeWeaponPair, locked)
    -- Update label text based on current active bar
    UpdateLabelText(GetCurrentBarText())
end

-- Handle interface setting changes (for attribute visibility)
local function OnInterfaceSettingChanged(eventCode, settingType, settingId)
    -- Update label position if attribute visibility might have changed
    if ActionBarLabels.label then
        local verticalOffset = GetVerticalOffset()
        ActionBarLabels.label:SetAnchor(BOTTOM, ZO_ActionBar1, TOP, 0, verticalOffset)
    end
end

-- Initialize the addon
local function Initialize()
    -- Initialize saved variables (per character)
    savedVars = ZO_SavedVars:NewCharacterIdSettings("ActionBarLabelsSV", 1, nil, defaults)
    
    -- Register for weapon bar swap events
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ACTIVE_WEAPON_PAIR_CHANGED, OnWeaponPairChanged)
    
    -- Register for interface setting changes to update label position when attributes toggle
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INTERFACE_SETTING_CHANGED, OnInterfaceSettingChanged)
    
    -- Create options panel
    local panelData = {
        type = "panel",
        name = "Action Bar Labels",
        displayName = "Action Bar Labels",
        author = "CMDR Mitchcraft",
        version = "1.0",
    }
    
    local panel = LAM:RegisterAddonPanel("ActionBarLabelsPanel", panelData)
    
    -- Create options table
    local optionsTable = {
        {
            type = "editbox",
            name = "Front Bar",
            tooltip = "Enter the text to display above action bar 1",
            getFunc = function() return savedVars.bar1Text end,
            setFunc = function(value)
                savedVars.bar1Text = value
                -- Update label if bar 1 is currently active
                if GetActiveWeaponPairInfo() == 1 then
                    UpdateLabelText(value)
                end
            end,
            default = defaults.bar1Text,
        },
        {
            type = "editbox",
            name = "Back Bar",
            tooltip = "Enter the text to display above action bar 2",
            getFunc = function() return savedVars.bar2Text end,
            setFunc = function(value)
                savedVars.bar2Text = value
                -- Update label if bar 2 is currently active
                if GetActiveWeaponPairInfo() == 2 then
                    UpdateLabelText(value)
                end
            end,
            default = defaults.bar2Text,
        },
    }
    
    LAM:RegisterOptionControls("ActionBarLabelsPanel", optionsTable)
end

-- Handle player activation (when player enters the game)
local function OnPlayerActivated()
    -- Wait a bit longer to ensure UI is fully loaded
    zo_callLater(function()
        CreateLabel()
    end, 500)
end

-- Wait for LibAddonMenu to load
local function OnAddonLoaded(event, addonName)
    if addonName == ADDON_NAME then
        -- Wait for LibAddonMenu-2.0 to be available
        if LAM then
            Initialize()
        else
            -- Try again after a short delay
            zo_callLater(function()
                if LAM then
                    Initialize()
                end
            end, 500)
        end
    end
end

-- Initialize addon namespace
ActionBarLabels = {}

-- Register events
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
