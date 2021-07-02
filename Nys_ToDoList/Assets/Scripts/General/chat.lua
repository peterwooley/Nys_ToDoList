-- Namespaces
local addonName, addonTable = ...

-- addonTable aliases
local core = addonTable.core
local chat = addonTable.chat
local utils = addonTable.utils
local database = addonTable.database
local mainFrame = addonTable.mainFrame
local tutorialsManager = addonTable.tutorialsManager

-- Variables
local L = core.L

--/*******************/ CHAT RELATED FUNCTIONS /*************************/--

function chat:Print(...)
  if (not NysTDL.db.profile.showChatMessages) then return end -- we don't print anything if the user chose to deactivate this
  self:PrintForced(...)
end

local T_PrintForced = {}
function chat:PrintForced(...)
  if (... == nil) then return end

  local hex = utils:RGBToHex(database.themes.theme)
  local prefix = string.format("|cff%s%s|r", hex, core.toc.title..':')

  wipe(T_PrintForced)
  local message = T_PrintForced
  for i = 1, select("#", ...) do
    local s = (select(i, ...))
    if type(s) == "table" then
      for j = 1, #s do
        table.insert(message, (select(j, unpack(s))))
      end
    else
      table.insert(message, s)
    end
  end

  DEFAULT_CHAT_FRAME:AddMessage(string.join(' ', prefix, unpack(message)))
end

-- Warning function
function chat:Warn()
  if (not mainFrame:autoResetedThisSessionGET()) then -- we don't want to show this warning if it's the first log in of the day, only if it is the next ones
    if (NysTDL.db.profile.showWarnings) then
      local haveWarned = false
      local warn = "--------------| |cffff0000"..L["WARNING"].."|r |--------------"

      if (NysTDL.db.profile.favoritesWarning) then -- and the user allowed this functionnality
        local _, _, _, ucFavs = mainFrame:updateRemainingNumbers()
        local daily, weekly = ucFavs.Daily, ucFavs.Weekly
        if ((daily + weekly) > 0) then -- and there is at least one daily or weekly favorite left to do
          local str = ""

          -- we first check if there are daily ones
          if (daily > 0) then
            if ((NysTDL.db.profile.autoReset["Daily"] - time()) < 86400) then -- pretty much all the time
              str = str..daily.." ("..L["Daily"]..")"
            end
          end

          -- then we check if there are weekly ones
          if (weekly > 0) then
            if ((NysTDL.db.profile.autoReset["Weekly"] - time()) < 86400) then -- if there is less than one day left before the weekly reset
              if (str ~= "") then
                str = str.." + "
              end
              str = str..weekly.." ("..L["Weekly"]..")"
            end
          end

          if (str ~= "") then
            local hex = utils:RGBToHex({ NysTDL.db.profile.favoritesColor[1]*255, NysTDL.db.profile.favoritesColor[2]*255, NysTDL.db.profile.favoritesColor[3]*255} )
            str = string.format("|cff%s%s|r", hex, str)
            if (not haveWarned) then self:PrintForced(warn) haveWarned = true end
            self:PrintForced(utils:SafeStringFormat(L["You still have %s favorite item(s) to do before the next reset, don't forget them!"], str))
          end
        end
      end

      if (NysTDL.db.profile.normalWarning) then
        local _, _, uc = mainFrame:updateRemainingNumbers()
        local daily, weekly = uc.Daily, uc.Weekly
        if ((daily + weekly) > 0) then -- and there is at least one daily or weekly item left to do (favorite or not)
          local total = 0

          -- we first check if there are daily ones
          if (daily > 0) then
            if ((NysTDL.db.profile.autoReset["Daily"] - time()) < 86400) then -- pretty much all the time
              total = total + daily
            end
          end

          -- then we check if there are weekly ones
          if (weekly > 0) then
            if ((NysTDL.db.profile.autoReset["Weekly"] - time()) < 86400) then -- if there is less than one day left before the weekly reset
              total = total + weekly
            end
          end

          if (total ~= 0) then
            if (not haveWarned) then self:PrintForced(warn) haveWarned = true end
            self:PrintForced(L["Total number of items left to do before tomorrow:"]..' '..tostring(total))
          end
        end
      end

      if (haveWarned) then
        local timeUntil = autoReset:GetTimeUntilReset()
        local str2 = utils:SafeStringFormat(L["Time remaining: %i hours %i min"], timeUntil.hour, timeUntil.min + 1)
        self:PrintForced(str2)
      end
    end
  end
end

--/*******************/ CHAT COMMANDS /*************************/--

-- Commands:
chat.commands = {
  [""] = function()
    mainFrame:Toggle()
  end,

  [L["info"]] = function()
    local hex = utils:RGBToHex(database.themes.theme2)
    local str = L["Here are a few commands to help you:"].."\n"
    str = str.." -- "..string.format("|cff%s%s|r", hex, "/tdl "..L["toggle"])
    str = str.." -- "..string.format("|cff%s%s|r", hex, "/tdl "..L["categories"])
    str = str.." -- "..string.format("|cff%s%s|r", hex, "/tdl "..L["favorites"])
    str = str.." -- "..string.format("|cff%s%s|r", hex, "/tdl "..L["descriptions"])
    str = str.." -- "..string.format("|cff%s%s|r", hex, "/tdl "..L["hyperlinks"])
    str = str.." -- "..string.format("|cff%s%s|r", hex, "/tdl "..L["rename"])
    str = str.." -- "..string.format("|cff%s%s|r", hex, "/tdl "..L["tutorial"])
    chat:PrintForced(str)
  end,

  [L["toggle"]] = function()
    chat:PrintForced(L["To toggle the list, you have several ways:"]..'\n- '..L["minimap button (the default)"]..'\n- '..L["a normal TDL button"]..'\n- '..L["databroker plugin (eg. titan panel)"]..'\n- '..L["the '/tdl' command"]..'\n- '..L["key binding"]..'\n'..L["You can go to the addon options in the game's interface settings to customize this."])
  end,

  [L["categories"]] = function()
    chat:PrintForced(L["Information on categories:"].."\n- "..L["The same category can be present in multiple tabs, as long as there are items for each of those tabs."].."\n- "..L["A category cannot be empty, if it is, it will just get deleted from the tab."].."\n- "..L["Left-click on the category names to expand or shrink their content."].."\n- "..L["Right-click on the category names to add new items."])
  end,

  [L["favorites"]] = function()
    chat:PrintForced(L["You can favorite items!"].."\n"..L["To do so, hold the SHIFT key when the list is opened, then click on the star icons to favorite the items that you want!"])
    chat:PrintForced(L["Perks of favorite items:"].."\n- "..L["cannot be deleted"].."\n- "..L["customizable color"].."\n- "..L["sorted first in categories"].."\n- "..L["have their own more visible remaining numbers"].."\n- "..L["have an auto chat warning/reminder system!"])
  end,

  [L["descriptions"]] = function()
    chat:PrintForced(L["You can add descriptions on items!"].."\n"..L["To do so, hold the CTRL key when the list is opened, then click on the page icons to open a description frame!"].."\n- "..L["they are auto-saved and have no length limitations"].."\n- "..L["if an item has a description, he cannot be deleted (empty the description if you want to do so)"])
  end,

  [L["hyperlinks"]] = function()
    chat:PrintForced(L["You can add hyperlinks in the list!"]..' '..L["It works the same way as when you link items or other things in the chat, just shift-click!"])
  end,

  [L["rename"]] = function()
    chat:PrintForced(L["For items: just double click on them."].."\n"..L["For categories, and items with hyperlinks in them: hold ALT then double click on them."])
  end,

  [L["tutorial"]] = function()
    tutorialsManager:Redo()
    chat:PrintForced(L["The tutorial has been reset!"])
  end,
}

-- Command catcher:
function chat.HandleSlashCommands(str)
  local path = chat.commands -- easier to read

  if (#str == 0) then
    -- we just entered "/tdl" with no additional args.
    path[""]()
    return
  end

  local args = {string.split(' ', str)}

  local deep = 1
  for id, arg in pairs(args) do
    if (path[arg]) then
      if (type(path[arg]) == "function") then
        -- all remaining args passed to our function!
        path[arg](select(id + 1, unpack(args)))
        return
      elseif (type(path[arg]) == "table") then
        deep = deep + 1
        path = path[arg] -- another sub-table found!

        if ((select(deep, unpack(args))) == nil) then
          -- here we just entered into a sub table, with no additional args
          path[""]()
          return
        end
      end
    else
      -- does not exist!
      chat.commands[L["info"]]()
      return
    end
  end
end