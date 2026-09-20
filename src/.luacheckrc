-- WoW addon environment. Run ./check.sh, which runs this plus a syntax pass.
std = "lua51"
max_line_length = false
self = false

-- Every file opens `local ADDON, ns = ...` because that is the shape the game
-- hands the vararg in, and most files only need ns. Naming the first slot is
-- the house convention from the README, so the unused-local warning on it is
-- allowed here rather than worked around per file.
ignore = { "211/ADDON" }

globals = {
	-- written by this addon. Two saved variable tables: the account's and this
	-- character's, both declared in every TOC.
	"WiggleUIDB", "WiggleUICharDB",
	-- frames created with a name write a global of that name
	-- Where a frame of Blizzard's goes when this addon draws it instead. Named
	-- for the reason the blocks are: a frame that has gone missing has to be
	-- findable from a macro, and `/wui hide probe` reads the parent of every
	-- frame it reports against this one.
	"WiggleUIAttic",
	"WiggleUIChargeBinder",
	"WiggleUIMarkButton",
	"WiggleUIOptions",
	"WiggleUIClutter",
	-- The bag window, and one global per square in it, named
	-- WiggleUIBagSlot<n>. A bag button is one of the frames the client
	-- and other addons reach for by name, and a square that has landed
	-- somewhere wrong has to be findable from a macro. The squares are made
	-- with a computed name and never read back through _G, so only the
	-- window is listed here.
	"WiggleUIBags",
	-- the breakdown table, opened from the meter. Named so Escape closes it
	-- through UISpecialFrames, which is a list of names.
	"WiggleUIBreakdown",
	-- the square that holds the other addons' minimap buttons. Named so a
	-- button that has gone missing can be found from a macro or from
	-- scripts/harness.lua without Minimap/Corral.lua handing out a reference to
	-- its own tables.
	"WiggleUICorral",
	-- The four aura rows, two on each block, named for the reason the three
	-- blocks in UnitFrames/Block.lua are: a row that lands in the wrong place has
	-- to be measurable from a macro and from the harness without Auras.lua
	-- handing out a reference to its own tables.
	"WiggleUITargetDebuffs", "WiggleUITargetBuffs",
	"WiggleUIPlayerDebuffs", "WiggleUIPlayerBuffs",
	-- the secure header over your buff row whose buttons cancel a buff on a
	-- right click, named off the row by UI.Press.Cancels
	"WiggleUIPlayerBuffsCancel",
	"WiggleUIChargeButton",
	-- The performance window and the button Ctrl-R presses. The window is named
	-- so Escape closes it through UISpecialFrames, which is a list of names;
	-- the button is named because SetOverrideBindingClick binds to a name.
	"WiggleUIPerf", "WiggleUIPerfButton",
	-- the button Core/Menu.lua puts in the client's own game menu. Named
	-- because a button that did not turn up has to be findable from a macro,
	-- which is the same reason the corral and the aura rows are named.
	"WiggleUIGameMenuButton",
	"WiggleUISwitchButton",
	-- the one secure button every mouseover key presses, and the list of what
	-- you bound drawn over the world. The button is named because
	-- SetOverrideBindingClick binds to a name rather than to a frame, which is
	-- the whole reason any button in this addon has one; the sheet is named for
	-- the reason the meter and the swing bars are, so a list that has wandered
	-- off the screen can be found from a macro and measured by
	-- scripts/harness.lua without Hover/Sheet.lua handing out its row pool.
	"WiggleUIHoverButton",
	"WiggleUIHoverSheet",
	-- One per square on a cloned action bar, plus the cooldown frame each square
	-- carries, which UI/Ability.lua names after it. Both are made by CreateFrame
	-- with a name built by concatenation, so luacheck never sees the write;
	-- listed here because the game makes the global and the README says every
	-- one of those is written down. Sixty is five bars of twelve, which is every
	-- action bar this client has, and Buttons/Bars.lua hands the button's name to
	-- SetOverrideBindingClick, which is the whole reason any of them is named.
	"WiggleUIBarButton1", "WiggleUIBarButton2", "WiggleUIBarButton3", "WiggleUIBarButton4", "WiggleUIBarButton5", "WiggleUIBarButton6",
	"WiggleUIBarButton7", "WiggleUIBarButton8", "WiggleUIBarButton9", "WiggleUIBarButton10", "WiggleUIBarButton11", "WiggleUIBarButton12",
	"WiggleUIBarButton13", "WiggleUIBarButton14", "WiggleUIBarButton15", "WiggleUIBarButton16", "WiggleUIBarButton17", "WiggleUIBarButton18",
	"WiggleUIBarButton19", "WiggleUIBarButton20", "WiggleUIBarButton21", "WiggleUIBarButton22", "WiggleUIBarButton23", "WiggleUIBarButton24",
	"WiggleUIBarButton25", "WiggleUIBarButton26", "WiggleUIBarButton27", "WiggleUIBarButton28", "WiggleUIBarButton29", "WiggleUIBarButton30",
	"WiggleUIBarButton31", "WiggleUIBarButton32", "WiggleUIBarButton33", "WiggleUIBarButton34", "WiggleUIBarButton35", "WiggleUIBarButton36",
	"WiggleUIBarButton37", "WiggleUIBarButton38", "WiggleUIBarButton39", "WiggleUIBarButton40", "WiggleUIBarButton41", "WiggleUIBarButton42",
	"WiggleUIBarButton43", "WiggleUIBarButton44", "WiggleUIBarButton45", "WiggleUIBarButton46", "WiggleUIBarButton47", "WiggleUIBarButton48",
	"WiggleUIBarButton49", "WiggleUIBarButton50", "WiggleUIBarButton51", "WiggleUIBarButton52", "WiggleUIBarButton53", "WiggleUIBarButton54",
	"WiggleUIBarButton55", "WiggleUIBarButton56", "WiggleUIBarButton57", "WiggleUIBarButton58", "WiggleUIBarButton59", "WiggleUIBarButton60",
	"WiggleUIBarButton1Cooldown", "WiggleUIBarButton2Cooldown", "WiggleUIBarButton3Cooldown", "WiggleUIBarButton4Cooldown", "WiggleUIBarButton5Cooldown", "WiggleUIBarButton6Cooldown",
	"WiggleUIBarButton7Cooldown", "WiggleUIBarButton8Cooldown", "WiggleUIBarButton9Cooldown", "WiggleUIBarButton10Cooldown", "WiggleUIBarButton11Cooldown", "WiggleUIBarButton12Cooldown",
	"WiggleUIBarButton13Cooldown", "WiggleUIBarButton14Cooldown", "WiggleUIBarButton15Cooldown", "WiggleUIBarButton16Cooldown", "WiggleUIBarButton17Cooldown", "WiggleUIBarButton18Cooldown",
	"WiggleUIBarButton19Cooldown", "WiggleUIBarButton20Cooldown", "WiggleUIBarButton21Cooldown", "WiggleUIBarButton22Cooldown", "WiggleUIBarButton23Cooldown", "WiggleUIBarButton24Cooldown",
	"WiggleUIBarButton25Cooldown", "WiggleUIBarButton26Cooldown", "WiggleUIBarButton27Cooldown", "WiggleUIBarButton28Cooldown", "WiggleUIBarButton29Cooldown", "WiggleUIBarButton30Cooldown",
	"WiggleUIBarButton31Cooldown", "WiggleUIBarButton32Cooldown", "WiggleUIBarButton33Cooldown", "WiggleUIBarButton34Cooldown", "WiggleUIBarButton35Cooldown", "WiggleUIBarButton36Cooldown",
	"WiggleUIBarButton37Cooldown", "WiggleUIBarButton38Cooldown", "WiggleUIBarButton39Cooldown", "WiggleUIBarButton40Cooldown", "WiggleUIBarButton41Cooldown", "WiggleUIBarButton42Cooldown",
	"WiggleUIBarButton43Cooldown", "WiggleUIBarButton44Cooldown", "WiggleUIBarButton45Cooldown", "WiggleUIBarButton46Cooldown", "WiggleUIBarButton47Cooldown", "WiggleUIBarButton48Cooldown",
	"WiggleUIBarButton49Cooldown", "WiggleUIBarButton50Cooldown", "WiggleUIBarButton51Cooldown", "WiggleUIBarButton52Cooldown", "WiggleUIBarButton53Cooldown", "WiggleUIBarButton54Cooldown",
	"WiggleUIBarButton55Cooldown", "WiggleUIBarButton56Cooldown", "WiggleUIBarButton57Cooldown", "WiggleUIBarButton58Cooldown", "WiggleUIBarButton59Cooldown", "WiggleUIBarButton60Cooldown",
	"WiggleUIChargeCooldown",
	"WiggleUIChargeMarker",
	"WiggleUIChargeMarkerCooldown",
	"WiggleUIEnemyBarsAnchor",
	-- the meter frame. Named so the two panes can be found from a macro or from
	-- scripts/harness.lua without Meter/Window.lua handing out a reference to its
	-- own row pool.
	"WiggleUIMeter",
	-- your own cast bar. Named for the same reason the swing bars below it are:
	-- the harness has to measure what was drawn, and a bar that is empty almost
	-- all of the time has to be findable from a macro when it has wandered off
	-- the screen.
	"WiggleUIPlayerCast",
	-- the swing timer's frame, holding a gauge per hand. Named for the same
	-- reason the meter is: scripts/harness.lua has to measure what was drawn,
	-- and Swing/Gauges.lua handing out a reference to its own bars would be a
	-- worse seam than a global the client makes anyway.
	"WiggleUISwing",
	-- the experience and reputation rails. Named for the reason the swing bars
	-- are: scripts/harness.lua has to measure what was drawn, and a frame that
	-- is one thin line along the bottom edge of the screen has to be findable
	-- from a macro once somebody has dragged it somewhere else.
	"WiggleUIProgress",
	-- the buff nag's row. Named for the reason the meter and the swing bars
	-- are: the row is hidden almost all the time, so a row that has wandered
	-- off the screen has to be findable from a macro, and scripts/harness.lua
	-- has to measure what was drawn without Buffs/Nag.lua handing out its pool.
	"WiggleUIBuffs",
	-- the block the skin draws over each of the three Blizzard unit frames.
	-- Named so a block that lands in the wrong place can be measured from a
	-- macro or from scripts/harness.lua without UnitFrames/Block.lua handing out
	-- a reference to its own entry tables. Named in Skin.lua's SPECS and read
	-- from there rather than written as a literal, so
	-- luacheck never sees the write; listed here because the game makes the
	-- global and the README says every one of those is written down.
	"WiggleUISkinPlayer",
	"WiggleUISkinTarget",
	"WiggleUISkinToT",
	-- The party and raid list: the frame you drag, and the secure group header
	-- hung off it. Both named for the reason the three blocks above are, and the
	-- header for one more: it is a Blizzard template doing the work, so a list
	-- that came out in the wrong order has to be readable from a macro one
	-- attribute at a time.
	"WiggleUIGroup",
	"WiggleUIGroupHeader",
	"WiggleUI_MarkSkull",
	"WiggleUI_MarkCross",
	"WiggleUI_MarkMoon",
	-- the chat window, and the key that puts the cursor in its line. The frame
	-- is named for the same reason the meter is: so a window that has wandered
	-- off the screen can be found from a macro or from scripts/harness.lua
	-- without Chat/Window.lua handing out a reference to its own tables.
	"WiggleUIChat",
	-- the column of rooms down its left. Named for the reason the aura rows
	-- are: a column that has laid itself out wrongly has to be measurable from
	-- a macro and from scripts/harness.lua without Chat/Window.lua handing out
	-- a reference to its own tables.
	"WiggleUIChatRooms",
	-- the box a room is copied out of. Named so Escape closes it through
	-- UISpecialFrames, which is a list of names.
	"WiggleUIChatCopy",
	-- the button the enter key is bound onto while Blizzard's chat window is
	-- hidden. SetOverrideBindingClick binds to a name rather than to a frame,
	-- which is the whole reason it has one.
	"WiggleUIChatEnterButton",
	"WiggleUI_ChatEnter",
	-- the two feeds, and the tooltip they open. All three are named for the
	-- reason the meter and the chat window are: a frame that has wandered off
	-- the screen has to be findable from a macro, and scripts/harness.lua has to
	-- measure what was drawn without UI/Feed.lua handing out its row pool. The
	-- scanner is different and is not optional: a GameTooltip's own lines are
	-- reachable only as globals built from its name, so a nameless one has text
	-- on it that nothing can read.
	"WiggleUILootFeed",
	"WiggleUICombatFeed",
	"WiggleUITooltip",
	"WiggleUITooltipScan",
	-- the mail window, and the column of favourites down its left. Both named
	-- for the reason the chat window and its room rail are: a window that has
	-- wandered off the screen has to be findable from a macro, and
	-- scripts/harness.lua has to measure what was drawn without Mail/Window.lua
	-- handing out a reference to its own row pool.
	"WiggleUIMail",
	"WiggleUIMailFavourites",
	-- the quest log, and the column of quests down its left. Both named for the
	-- reason the mail window and its favourites column are, and the column for
	-- one more: a log grouped into zones lays sixty rows out from a model, and a
	-- column that has laid them out wrongly has to be measurable from a macro
	-- and from scripts/harness.lua without Quests/Window.lua handing out a
	-- reference to its own pool.
	"WiggleUIQuests",
	"WiggleUIQuestList",
	-- This addon's own quest tracker, the column of the zone you are standing
	-- in drawn over the world. Named for the reason every placeable frame here
	-- is: a frame with no chrome that has landed off the edge of the monitor is
	-- findable from a macro by its name and by nothing else, and the harness
	-- measures its rows through the same name.
	"WiggleUIQuestColumn",
	-- The two scrolling columns beside that list. Named for the same reason and
	-- for one more: the three of them share the window's width between four
	-- equal margins, and that arithmetic is only checkable from outside if each
	-- column can be found and measured.
	"WiggleUIQuestText",
	"WiggleUIQuestRewards",
	-- The other side of the tab over the middle column, and the zone drawn
	-- inside it. Both named for the reason the columns are, and the board for
	-- one more: what it draws is twelve tiles of somebody else's art cropped to
	-- the shape of a zone, and a map with a seam of black through it is only
	-- findable from outside if the tiles can be walked one texture coordinate at
	-- a time.
	"WiggleUIQuestMap",
	"WiggleUIQuestChart",
	-- The world map, and the zone drawn inside it. Both named for the reason the
	-- quest log and its board are: a window that has wandered off the screen has
	-- to be findable from a macro, and a picture carrying two hundred and fifty
	-- of another addon's icons has to be measurable from scripts/harness.lua
	-- without Map/Window.lua handing out a reference to the chart's own pools.
	"WiggleUIMap",
	"WiggleUIMapChart",
	"BINDING_HEADER_WIGGLEUI",
	"BINDING_NAME_WIGGLEUI_MARK_SKULL",
	"BINDING_NAME_WIGGLEUI_MARK_CROSS",
	"BINDING_NAME_WIGGLEUI_MARK_MOON",
	"BINDING_NAME_WIGGLEUI_CHAT",
	"SLASH_WIGGLEUI1",
	"SLASH_WIGGLEUI2",
	"SLASH_WIGGLEUI3",
	"SLASH_WIGGLEUIEXIT1",
	"SlashCmdList",
}

-- One frame, one key button and sixteen squares per ad hoc bar, plus the
-- cooldown frame UI/Ability.lua names after each square, six bars deep. All of
-- them are made by CreateFrame with a name built by concatenation, so luacheck
-- never sees the write; listed here because the game makes the global and the
-- README says every one of those is written down. The key button is named
-- because SetOverrideBindingClick binds to a name, and the frame and the
-- squares for the reason the cloned bars' are: one that has landed somewhere
-- wrong has to be findable from a macro.
for bar = 1, 6 do
	globals[#globals + 1] = ("WiggleUIAdHoc%d"):format(bar)
	globals[#globals + 1] = ("WiggleUIAdHoc%dKey"):format(bar)
	for at = 1, 16 do
		globals[#globals + 1] = ("WiggleUIAdHoc%dButton%d"):format(bar, at)
		globals[#globals + 1] = ("WiggleUIAdHoc%dButton%dCooldown"):format(bar, at)
	end
end

read_globals = {
	"CreateFrame", "UIParent", "WorldFrame", "GameFontNormal", "DEFAULT_CHAT_FRAME",
	"GameTooltip", "GameFontHighlightSmall", "GetBindingAction",
	"RegisterStateDriver", "UnregisterStateDriver",
	"SetOverrideBindingClick", "SetOverrideBinding", "ClearOverrideBindings",
	"UISpecialFrames", "tinsert", "pcall",
	-- The interface rebuilt from scratch, which is how `/wui defaults` and the
	-- button beside it apply two dozen parts' worth of settings at once: a
	-- part reads its own settings when it is built, and there is no hook that
	-- says "read them again". Nothing else in the addon calls it.
	"ReloadUI",
	-- the client's own menu, and the call that takes a frame off its panel
	-- stack. Core/Menu.lua adds one button to the first and closes it with
	-- the second, and both are probed before they are touched: neither is
	-- built the same way on the two clients this addon ships for.
	"GameMenuFrame", "HideUIPanel",
	-- how far the client holds its own tooltip off the bottom right corner,
	-- rewritten by it whenever the bags open or an action bar appears.
	-- UI/Tooltip.lua reads both so the addon's box docks where the client's
	-- would, and falls back where a client defines neither.
	"CONTAINER_OFFSET_X", "CONTAINER_OFFSET_Y",
	"IsAltKeyDown", "GetShapeshiftForm",
	-- How wide the screen is in UIParent's own units, which is what a frame
	-- anchored to UIParent measures its offsets in. Ck/Float.lua reads it to
	-- turn "forty pixels off the centre" into an offset from the edge, and it
	-- reads it per message rather than once, so a lane survives a resolution
	-- change without being told about one. UIParent:GetWidth() answers the
	-- same number on a client and nothing at all under the harness stub.
	"GetScreenWidth",
	-- And the height in the same units, which on its own is 768 on every client
	-- and says nothing. It is read beside the width above, in UI/Pixel.lua, and
	-- the pair is what the aspect ratio is: both are in UIParent's units, so the
	-- scale divides out of the ratio and what is left is the shape of the
	-- monitor. That is how a window the size of the screen works out how wide the
	-- screen is without a second resolution CVar to parse.
	"GetScreenHeight",
	-- the four totem slots, read by Standing/Standing.lua. Probed by name
	-- rather than called outright, because nothing installed on this disk
	-- calls it and the client's own documentation marks it as a call that may
	-- return nothing at all.
	"GetTotemInfo",
	"UnitPlayerOrPetInParty", "UnitPlayerOrPetInRaid", "UnitIsPlayer",
	"C_NamePlate", "C_Spell",
	-- the pixel grid in UI/Pixel.lua. GetPhysicalScreenSize is the only honest
	-- source for the monitor's real height; it is probed by name and falls back
	-- to the resolution CVar, because nothing installed here proves it is on
	-- 2.5.6. CreateFont backs the shared font objects in UI/Text.lua.
	"GetPhysicalScreenSize", "CreateFont",
	-- action bar and macro writing, used by the Buttons part. None of these is
	-- confirmed to exist on 2.5.6 by an installed addon calling it, so Layout
	-- probes for them before it writes anything.
	"PickupSpell", "PickupMacro", "PickupItem", "PlaceAction", "PickupAction",
	-- the pet bar's slot, its cooldown, whether the pet can act on it, and the drag
	"GetPetActionInfo", "GetPetActionCooldown", "GetPetActionSlotUsable", "PickupPetAction",
	"ClearCursor", "GetCursorInfo", "GetActionInfo",
	"CreateMacro", "DeleteMacro", "EditMacro", "GetMacroInfo",
	"GetMacroIndexByName", "GetNumMacros", "GetBonusBarOffset",
	-- what a macro's own conditionals resolve to, which is the only way to ask
	-- a macro square which spell a press would cast. Probed by Buttons/Slot.lua
	-- for the same reason the rest of this block is: nothing installed here
	-- proves it exists on 2.5.6, and a square that loses it loses two rungs of
	-- the ladder rather than the bar.
	"GetMacroSpell",
	-- which frame the client says the cursor is over, read by Buttons/Trace.lua
	-- and by nothing else. Probed by name at every call: this is the one API in
	-- the addon whose only job is to answer a question about a bug, and a
	-- diagnostic that raises on a client without it would be a diagnostic that
	-- makes things worse.
	"GetMouseFocus", "GetMouseFoci",
	-- Where the pointer is, in physical pixels. Read by UI/Tooltip.lua and by
	-- nothing else, for the one box in the addon with no owner frame to hang
	-- off: a creature in the world. Nothing in this install is here to prove the
	-- call, so it is probed by name at its call site the way the two above are,
	-- and a client without it puts the box in the middle of the screen rather
	-- than not putting one up. It is an entry here because the probe is the
	-- shim and it lives beside the caller.
	"GetCursorPosition",
	-- Whether a mouse button is turning the camera, read by Theme/Theme.lua so
	-- a camera turn is not taken for a shake. Questie's tracker calls it on the
	-- installed 2.5.6 client, which is the proof it is there.
	"IsMouselooking",
	-- what one action slot is doing, read by Buttons/Slot.lua on the bar's
	-- ticker. Probed by name in Slot.CanRead for the same reason the writers
	-- above are: nothing installed here proves any of them is on 2.5.6, and a
	-- bar that raises once per button per tick is worse than a grey bar.
	"HasAction", "GetActionTexture", "GetActionCooldown", "GetActionCount",
	"IsUsableAction", "IsActionInRange",
	-- and the one fact the usable call does not hold: whether the slot is aimed
	-- at an enemy. Blizzard's 2.5.6 API documentation lists it under C_ActionBar
	-- with the loose name beside it; Slot.CanRead probes both and resolves
	-- whichever answers to a local, and a client with neither keeps the bar.
	-- Core/Core.lua's ns.SpellHarmful shim reads the spell-level pair the same
	-- way, so a macro square is asked about the spell it would cast.
	"C_ActionBar", "IsHarmfulAction", "IsHarmfulSpell",
	-- and the three that say something about a slot beyond whether a press would
	-- land: the stance you are standing in, the auto attack already swinging,
	-- and the weapon you are wielding. Probed separately from the five above and
	-- resolved to locals in Slot.CanRead, because a client without them loses a
	-- tint or a ring, not the bar. Nothing installed on this machine calls any
	-- of the three.
	"IsCurrentAction", "IsAutoRepeatAction", "IsEquippedAction",
	-- which key the binding set already holds for one of Blizzard's action
	-- buttons, read by Buttons/Bars.lua so the clone answers the keys you
	-- already had. Probed by name and pcalled at the call site rather than
	-- trusted: nothing installed here calls it, and the only other reader of a
	-- binding in this addon is GetBindingAction, which is above.
	"GetBindingKey",
	-- the spellbook, read by Buttons/Ranks.lua to find the best rank you know
	"GetNumSpellTabs", "GetSpellTabInfo",
	"GetSpellBookItemInfo", "GetSpellBookItemName",
	-- the pet's own book and family, read by Talents/Training.lua to say what
	-- the pet out already knows
	"GetSpellBookItemTexture", "HasPetSpells", "UnitCreatureFamily",
	"GetSpellInfo", "GetSpellTexture", "GetSpellCooldown", "IsUsableSpell",
	"IsSpellInRange", "IsSpellKnown",
	"GetTime", "GetRaidTargetIndex", "SetRaidTarget",
	-- items, for the weapon the charge button equips and the trash the Comfort
	-- part sells. The container API is C_Container on one client and loose
	-- globals on the other, so both are probed in Core rather than named
	-- anywhere else. C_Item is the newer home for the item lookups and is
	-- reached through _G in Core beside C_Container, so it is not an entry
	-- here.
	"GetInventoryItemLink", "GetInventoryItemTexture",
	"GetInventoryItemID", "GetInventoryItemCount",
	"GetContainerNumSlots", "GetContainerItemLink", "GetContainerNumFreeSlots",
	"GetContainerItemInfo", "UseContainerItem",
	"GetItemInfo", "GetItemInfoInstant", "C_Container",
	-- the empty-slot art each hand draws when nothing is set. Baganator calls
	-- GetInventorySlotInfo unguarded on the TBC client and TitanAmmo calls it on
	-- both. CursorHasItem was here beside it and is gone: it answered for an
	-- item and nothing else, so a slot that takes a spell could not light up
	-- from it, and GetCursorInfo, which is already in this list, answers for
	-- everything a slot will accept.
	"GetInventorySlotInfo",
	"UnitExists", "UnitGUID", "UnitClass", "UnitAffectingCombat", "IsResting", "UnitCanAttack",
	"UnitIsDead", "UnitIsGroupLeader", "UnitIsGroupAssistant", "IsInRaid",
	"IsControlKeyDown", "IsShiftKeyDown",
	"UnitHealth", "UnitHealthMax", "UnitName", "GetRealmName", "UnitIsUnit", "UnitCanAttack",
	-- power, for the second gauge on the skinned unit frames. All three are
	-- called unguarded by TitanRegen, which is loaded on this client, so they
	-- are entries here rather than shims in Core.
	"UnitPowerType", "UnitPower", "UnitPowerMax",
	-- levels, for the XP colour on the enemy bars. UnitLevel is called by
	-- Questie and OPie unguarded; GetQuestGreenRange and UnitClassification are
	-- reached through _G in Core, so they are shims rather than entries here.
	"UnitLevel",
	-- hostile or neutral, for the reaction stripe. Details calls it unguarded
	-- and tests it the same way, reaction <= 4 is something you can attack.
	"UnitReaction",
	"UnitDetailedThreatSituation", "UnitAura", "C_UnitAuras",
	"GetNumGroupMembers", "SetRaidTargetIconTexture",
	-- The group, for the party and raid blocks. UnitInRange, UnitIsGhost and
	-- UnitIsDeadOrGhost are what say a block has no reading to take;
	-- UnitGroupRolesAssigned and GetPartyAssignment are two of the four sources
	-- Unit/Role.lua reads. None of the five is called unguarded by anything in
	-- this install, so all five are probed by name before they are called and a
	-- client missing one loses that answer rather than raising once per member
	-- five times a second. They are entries here rather than shims in Core,
	-- because the probe is the shim and it lives beside the caller.
	"UnitInRange", "UnitIsGhost", "UnitIsDeadOrGhost",
	"UnitGroupRolesAssigned", "GetPartyAssignment",
	-- The right button's menu on every unit frame this addon draws. Named and
	-- not probed, because it is not a flavour question: Blizzard_UnitFrame ships
	-- it on both clients this addon has a TOC for, and it is the same function
	-- the client hands its own party, raid and compact frames through
	-- SecureUnitButton_OnLoad. It is handed over as the `menu-function`
	-- attribute and called by the client, never by us.
	"CompactUnitFrame_OpenMenu",
	-- Whether the thing under the cursor is one you could help, for the
	-- mouseover debug log. It is the reading beside `[help]`, which is the half
	-- of the filter UnitCanAttack above cannot answer, and a heal bound under
	-- the enemy filter is the failure the log exists to name. UnitCanAssist is
	-- probed by name anyway and falls back to UnitIsFriend, because nothing in
	-- this install calls it unguarded and the two disagree only on a duel.
	"UnitCanAssist", "UnitIsFriend",
	-- The PvP flag, for the one exception to "attackable gets a bar": a player
	-- of the other faction is attackable in their own zone on a PvP realm and
	-- gets no bar until they are flagged. Free-for-all is the Gurubashi flag
	-- and counts. Nothing in this install calls the two flag readers unguarded
	-- and OPie calls UnitFactionGroup, so all three are probed by name in
	-- UnitFrames/EnemyBars.lua and a client missing one treats every player as
	-- unflagged, which is a missing bar rather than an error on the ticker.
	"UnitIsPVP", "UnitIsPVPFreeForAll", "UnitFactionGroup",
	-- The client's own macro conditional parser, for the mouseover debug log. It
	-- is the only thing that can tell a clause this build does not understand
	-- from a clause that understood and did not match, and both of those cast
	-- nothing and say nothing. Probed by name before it is called, because a
	-- build without it loses that line of the log and nothing else.
	"SecureCmdOptionParse",
	-- SoftTargetEnemy is read and written by Targeting/Aim.lua, which owns
	-- the CVar out of combat and hands it back in. Both calls are pcalled: no
	-- addon here proves SetCVar takes that name on 2.5.6.
	"GetCVarBool", "GetCVar", "SetCVar",
	-- Blizzard_CombatText's table of message types, which CombatText/Blizzard.lua
	-- takes the heals and hits out of because the column it scrolls beside your
	-- character gives those types no CVar to turn off. Nothing installed on this
	-- machine touches it, so it is read off the client's own source rather than
	-- off another addon's proof: Shared/CombatTextConstants.lua on the
	-- classic_anniversary and classic_era branches, which are the two flavours
	-- this addon ships for. The addon on demand, so the name answers nil at
	-- login on a character who has never had the column on; the reader checks
	-- for a table and Describe says so when the master switch is on and the
	-- table is not there, which is what would witness the name being wrong.
	"CombatTextTypeInfo",
	"GetGameTime",
	-- Looting, for the Comfort part. Leatrix Plus is loaded on both of these
	-- clients and calls all five unguarded inside its own faster-looting
	-- feature, which is the same feature and so the same proof;
	-- GetLootThreshold is also called unguarded by TitanLootType on both.
	-- GetLootMethod is the one that is not here: C_PartyInfo carries it on one
	-- client and the loose global on the other, so Comfort/Loot.lua probes for
	-- both and treats neither answering as "do not know" rather than "no".
	"IsModifiedClick", "GetNumLootItems", "GetLootSlotInfo", "LootSlot",
	"GetLootThreshold",
	-- The merchant, for the same part. MerchantFrame is read to prove the
	-- window is still up before anything is sold, because the container call
	-- behind it uses the item instead when it is not. Leatrix calls the frame
	-- and GetCoinText unguarded, Auctionator calls GetCoinText, and GetMoney is
	-- called unguarded by TitanGold, TitanRepair and Titan itself. The two
	-- ERR_ constants are reached through _G rather than named, because a client
	-- missing one would compare a message against nil and stop a sale that was
	-- fine.
	"MerchantFrame", "GetMoney", "GetCoinText",
	-- The mouse pointer, for the sell cursor over a bag square while a merchant
	-- is open. Baganator calls both unguarded on this client, ResetCursor on
	-- every item button's OnLeave and SetCursor on a category header at a
	-- vendor, and Questie and OPie call SetCursor unguarded as well. Bags/Grid.lua
	-- asks for BUY_CURSOR by name because that is what Blizzard's own bag button
	-- asks for; a client that does not know the name leaves the arrow alone and
	-- breaks nothing.
	"SetCursor", "ResetCursor",
	-- The mailbox is deliberately absent, all of it. Every call the Mail part
	-- makes moves somebody's property, so every one of them is reached through
	-- _G and probed at its own call site rather than named here: SendMail,
	-- SetSendMailMoney, SetSendMailShowing, GetSendMailItem, GetSendMailPrice,
	-- GetInboxNumItems, GetInboxHeaderInfo, GetInboxItem, GetInboxText,
	-- AutoLootMailItem, DeleteInboxItem, ReturnInboxItem, CloseMail,
	-- ClearSendMail, ClickSendMailItemButton,
	-- ATTACHMENTS_MAX_SEND, MailFrame and the friends list either side of
	-- C_FriendList. Baganator and Syndicator prove the attach path on this
	-- client and Mail/Send.lua cites them; proving a call exists is still not
	-- the same as proving it is safe to make unguarded.
	-- Repairing, for the same window. TitanRepair and Leatrix Plus are both
	-- installed on both of these clients and both call all four unguarded,
	-- inside their own auto-repair feature, which is the same feature and so
	-- the same proof. The guild bank trio is deliberately absent:
	-- CanGuildBankRepair, GetGuildBankMoney and GetGuildBankWithdrawMoney are
	-- only proven by TitanRepair calling them, and Classic Era has no guild
	-- bank at all, so Comfort/Repair.lua reaches all three through _G and
	-- pcalls them. A client without them loses guild funding and keeps the
	-- repair, which is the right way round to be wrong.
	"CanMerchantRepair", "GetRepairAllCost", "RepairAllItems",
	"GetInventoryItemDurability",
	-- The quest log, for the clutter scan and for the Quests part. Questie calls
	-- both of these unguarded on both clients and reads the quest id out of the
	-- eighth value exactly as Clutter.lua and Quests/Client.lua do.
	-- IsQuestFlaggedCompleted is not here: it lives on the loose global on one
	-- client and under C_QuestLog on the other, so it is resolved through _G the
	-- way Questie resolves it.
	--
	-- Every other quest log call the addon makes is deliberately absent, all
	-- eighteen of them. Questie proves some and not others, the two clients
	-- genuinely differ on the rest, and three of them move somebody's quest, so
	-- Quests/Client.lua reaches the lot through _G and probes each at its own
	-- call site: SelectQuestLogEntry, GetQuestLogSelection, ExpandQuestHeader,
	-- GetQuestLogIndexByID, GetQuestLogQuestText, GetNumQuestLeaderBoards,
	-- GetQuestLogLeaderBoard, GetQuestLogTimeLeft, the six reward calls,
	-- GetQuestLogItemLink, GetQuestLogRequiredMoney, IsQuestWatched, the watch
	-- pair, GetQuestLogPushable, QuestLogPushQuest, the abandon pair and
	-- ToggleQuestLog. GetQuestLogRewardXP is not a client call at all on either
	-- of these builds; Questie's own LibQuestXP writes that global, so absent is
	-- the normal answer rather than a failure.
	"GetNumQuestLogEntries", "GetQuestLogTitle",
	-- QuestieLoader, PickupContainerItem's loose fallback and DeleteCursorItem
	-- are deliberately absent. Questie is another addon and may not be
	-- installed; the container call goes through C_Container in Core; and
	-- nothing here calls DeleteCursorItem, Questie only hooks it, which proves
	-- the global exists and is not the same as proving the call is ours to make.
	-- All three are probed and pcalled in Core: ns.Questie is the one door on
	-- QuestieLoader and scripts/check.sh refuses a second.
	-- profiling, read by the Perf part. Every one of these is called unguarded
	-- by an addon in this install: debugprofilestop by Details, Questie and
	-- Auctionator, the memory pair by Details, TitanPerformance and Leatrix,
	-- the CPU pair and GetFramerate by Details and TitanPerformance. The CPU
	-- pair is read only where someone else has already turned scriptProfile on.
	"debugprofilestop", "GetFramerate",
	"UpdateAddOnMemoryUsage", "GetAddOnMemoryUsage",
	"UpdateAddOnCPUUsage", "GetAddOnCPUUsage",
	-- The other half of the profiler, read by the frame trace. No addon in this
	-- install calls any of these, so the evidence is the client itself: all four
	-- names are in WowClassic.exe's own symbol list on 2.5.6, which is what
	-- proves a call exists rather than what somebody else got away with. Every
	-- one is still type-checked and pcalled at the point of use, because a name
	-- in the binary says the call is there and says nothing about what it
	-- answers with scriptProfile off.
	"GetScriptCPUUsage", "GetNetStats",
	"GetNumAddOns", "GetAddOnInfo",
	"RAID_CLASS_COLORS", "wipe", "InCombatLockdown",
	-- the wall clock, for the time of day a feed row landed. GetTime counts
	-- from when the client started and is the right thing to record on; `time`
	-- is what turns that into a clock a person reads, and the pair of them is
	-- how Feeds/Loot.lua says when something dropped without keeping a formatted
	-- string on every entry. Both are called unguarded by TitanClock and by
	-- Details on both clients.
	"date", "time", "GetBuildInfo",
	-- Edit Mode. Titan calls EditModeManagerFrame:GetActiveLayoutInfo()
	-- unguarded, which is what proves the frame is here. The methods the
	-- EditMode part uses past that one are probed by name before every call.
	"EditModeManagerFrame", "Enum",
	-- Post-hooked onto a unit frame's own AnchorSelectionFrame, so Edit Mode's
	-- selection lands on the block rather than on the rectangle the frame used
	-- to be. Type-checked before it is called, like every other method the
	-- skin borrows from a client it cannot be sure of.
	"hooksecurefunc",
}
