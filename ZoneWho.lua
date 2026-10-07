-- ZoneWho v1.2
-- Shows players in the current zone via background /who queries.
-- Compatible with World of Warcraft 1.12.1 (Vanilla / VanillaPlus).

local ADDON_VERSION = "1.2"
local UPDATE_SEC    = 20
local MAX_LINES     = 40
local WHO_TIMEOUT   = 4   -- seconds to wait for WHO_LIST_UPDATE

local CLASS_COLORS = {
  ["Warrior"] = "C79C6E",
  ["Paladin"] = "F58CBA",
  ["Hunter"]  = "ABD473",
  ["Rogue"]   = "FFF569",
  ["Priest"]  = "FFFFFF",
  ["Shaman"]  = "0070DE",
  ["Mage"]    = "69CCF0",
  ["Warlock"] = "9482C9",
  ["Druid"]   = "FF7D0A",
}

local frame, text
local lastZone   = ""
local ticker     = 0
local ourWho     = false   -- true while we are waiting for our own who response
local pendingGuard = nil   -- temporary OnUpdate frame for timeout

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------
local function C(name, class)
  local hex = CLASS_COLORS[class or ""] or "FFFFFF"
  return "|cff" .. hex .. (name or "?") .. "|r"
end

local function Zone()
  local z = GetRealZoneText and GetRealZoneText() or nil
  if not z or z == "" then z = GetZoneText() end
  return z or ""
end

local function SetText(s)
  if text then text:SetText(s or "") end
end

-- Temporarily stop FriendsFrame from reacting to WHO_LIST_UPDATE
-- so the Social/Who window never flashes open for our background queries.
local function SilenceFriendsFrame()
  if FriendsFrame then
    FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE")
  end
end

local function RestoreFriendsFrame()
  if FriendsFrame then
    FriendsFrame:RegisterEvent("WHO_LIST_UPDATE")
  end
end

local function ClearGuard()
  if pendingGuard then
    pendingGuard:SetScript("OnUpdate", nil)
    pendingGuard = nil
  end
end

local function FinishOurWho()
  ourWho = false
  ClearGuard()
  RestoreFriendsFrame()
end

------------------------------------------------------------------------
-- Who request / response
------------------------------------------------------------------------
local function RequestWho()
  if ourWho then return end          -- already waiting for a previous request

  local z = Zone()
  if z == "" then return end

  lastZone = z
  ourWho   = true

  SilenceFriendsFrame()

  if SetWhoToUI then SetWhoToUI(1) end
  SendWho(string.format('z-"%s" 1-60', z))

  -- Safety timeout: if server never answers, restore UI handling
  local t = 0
  pendingGuard = CreateFrame("Frame")
  pendingGuard:SetScript("OnUpdate", function()
    t = t + arg1
    if t >= WHO_TIMEOUT then
      FinishOurWho()
    end
  end)
end

local function OnWhoUpdate()
  if not ourWho then
    -- Manual /who from the player — leave FriendsFrame alone
    return
  end

  FinishOurWho()

  local z = lastZone
  if z == "" then z = Zone() end

  local n = 0
  if GetNumWhoResults then n = GetNumWhoResults() or 0 end

  local lines = {}
  table.insert(lines, "|cffFFD100" .. z .. "|r (" .. n .. ")")

  local my = UnitName("player")
  local shown = 0
  for i = 1, n do
    if shown >= MAX_LINES then
      table.insert(lines, "|cffaaaaaa...|r")
      break
    end
    local name, guild, level, race, class = GetWhoInfo(i)
    if name then
      local g = (guild and guild ~= "") and (" |cff888888<" .. guild .. ">|r") or ""
      local star = (name == my) and " |cff00ff00*|r" or ""
      table.insert(lines, string.format("%2d %s %s%s%s",
        tonumber(level) or 0, C(name, class), class or "", g, star))
      shown = shown + 1
    end
  end

  if n == 0 then
    table.insert(lines, "|cffaaaaaaпусто / лимит who|r")
  end

  SetText(table.concat(lines, "\n"))
end

------------------------------------------------------------------------
-- UI
------------------------------------------------------------------------
local function CreateUI()
  if frame then return end

  frame = CreateFrame("Frame", "ZoneWhoFrame", UIParent)
  frame:SetWidth(230)
  frame:SetHeight(160)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() this:StartMoving() end)
  frame:SetScript("OnDragStop",  function() this:StopMovingOrSizing() end)
  frame:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  frame:SetBackdropColor(0, 0, 0, 0.85)

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", frame, "TOP", 0, -6)
  title:SetText("ZoneWho " .. ADDON_VERSION)

  text = frame:CreateFontString("ZoneWhoText", "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("TOPLEFT",     frame, "TOPLEFT",     8, -22)
  text:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8,  8)
  text:SetJustifyH("LEFT")
  text:SetJustifyV("TOP")
  SetText("|cffaaaaaaзагрузка...|r")

  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:RegisterEvent("ZONE_CHANGED")
  frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  frame:RegisterEvent("WHO_LIST_UPDATE")

  frame:SetScript("OnEvent", function()
    if event == "WHO_LIST_UPDATE" then
      OnWhoUpdate()
    else
      -- zone change → request soon
      ticker = UPDATE_SEC - 1
    end
  end)

  frame:SetScript("OnUpdate", function()
    ticker = ticker + arg1
    if ticker >= UPDATE_SEC then
      ticker = 0
      RequestWho()
    end
  end)

  frame:Show()
end

------------------------------------------------------------------------
-- Boot
------------------------------------------------------------------------
local boot = CreateFrame("Frame")
boot:RegisterEvent("VARIABLES_LOADED")
boot:SetScript("OnEvent", function()
  CreateUI()
  ticker = UPDATE_SEC - 2
  DEFAULT_CHAT_FRAME:AddMessage("|cffFFD100ZoneWho|r v" .. ADDON_VERSION .. " loaded")
end)

------------------------------------------------------------------------
-- Slash commands
------------------------------------------------------------------------
SLASH_ZONEWHO1 = "/zonewho"
SlashCmdList["ZONEWHO"] = function(msg)
  msg = string.lower(tostring(msg or ""))
  if not frame then CreateUI() end

  if msg == "hide" then
    frame:Hide()
  elseif msg == "show" then
    frame:Show()
  elseif msg == "now" then
    RequestWho()
    DEFAULT_CHAT_FRAME:AddMessage("|cffFFD100ZoneWho:|r who sent")
  elseif msg == "debug" then
    DEFAULT_CHAT_FRAME:AddMessage(
      "ZoneWho v" .. ADDON_VERSION ..
      "  zone=" .. Zone() ..
      "  n=" .. tostring(GetNumWhoResults and GetNumWhoResults() or "?") ..
      "  ourWho=" .. tostring(ourWho)
    )
  elseif msg == "version" or msg == "ver" then
    DEFAULT_CHAT_FRAME:AddMessage("|cffFFD100ZoneWho|r version " .. ADDON_VERSION)
  else
    if frame:IsShown() then frame:Hide() else frame:Show() end
  end
end
