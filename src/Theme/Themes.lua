local ADDON, ns = ...

--------------------------------------------------------------------------
-- Every element on the screen, and what each theme does with it
--
-- A theme is one decision about how much of the addon you see, taken for every
-- element at once instead of one tick box per page. The table below is the
-- whole of it: an element is a row, a theme is a column, and each cell is one
-- of four answers.
--
--   "show"   drawn as the part draws it. The theme does not touch the frame.
--   "hide"   off the screen. The part still runs, so a key bound to a hidden
--            bar still fires, the way a bar set to drop in combat already does.
--   "hover"  invisible until the pointer is on it, and back when it leaves.
--   0.2      drawn at that fraction of itself, any number above 0 and below 1.
--
-- Every theme names every element, and Theme/Theme.lua refuses to load a theme
-- that leaves one out or names one that is not here. A default would be the
-- one cell nobody decided, and this table is the place the decision is written.
--
-- An element is claimed by the part that builds its frame, with one call to
-- ns.Theme.Wear at build, so an element here that no part wears is a row that
-- does nothing, and scripts/check.sh reads the calls off the source and says so.
--
-- It is read once, at login. Changing theme is a /reload, which is what keeps
-- the cost of a theme at zero after the loading screen: an element that is
-- "show" is never touched at all, and the others are one reparent at build.
--------------------------------------------------------------------------

local Themes = {}
ns.Themes = Themes

-- In the order the options page lists them, which is roughly the order your
-- eye crosses the screen: yourself, what you are fighting, what you press, and
-- then the furniture.
Themes.ELEMENTS = {
	{ key = "player",     label = "your frame" },
	{ key = "target",     label = "your target's frame" },
	{ key = "party",      label = "the party frames" },
	{ key = "raid",       label = "the raid frames" },
	{ key = "castbar",    label = "your cast bar" },
	{ key = "enemies",    label = "the enemy bars" },
	{ key = "swing",      label = "the swing timer" },
	{ key = "bars",       label = "the action bars" },
	{ key = "loadout",    label = "the loadout bars" },
	{ key = "charge",     label = "the Charge button" },
	{ key = "cooldowns",  label = "the cooldown rows" },
	{ key = "buffs",      label = "the buff nag" },
	{ key = "numbers",    label = "the floating combat numbers" },
	{ key = "chat",       label = "the chat window" },
	{ key = "quests",     label = "the quest tracker" },
	{ key = "minimap",    label = "the minimap" },
	{ key = "meters",     label = "the meters" },
	{ key = "feeds",      label = "the loot and combat feeds" },
	{ key = "drops",      label = "the drops sliding in" },
	{ key = "messages",   label = "the messages sliding in" },
	{ key = "standing",   label = "the standing row" },
	{ key = "experience", label = "the experience rails" },
	{ key = "keys",       label = "the mouseover key sheet" },
}

-- The three themes, in the order the options page cycles them.
Themes.ORDER = { "informational", "immersive", "exploration" }

Themes.LABEL = {
	informational = "everything the addon draws, as it draws it",
	immersive = "you and the game: your frame and your target's at a fifth, nothing else",
	exploration = "chat, quests, bars and meters wait under the pointer; drops and messages but no feeds",
}

-- How the experience rail is drawn in a theme that decides it, over the style
-- setting. Exploration keeps the thin line along the bottom edge, and a wiggle
-- to informational brings the placed rail with its reading back with the rest.
Themes.RAIL = { exploration = "minimal" }

-- Where your frame and your target's rest in the immersive theme. Enough to
-- read a health bar in the corner of your eye and not enough to be furniture.
local FAINT = 0.2

Themes.informational = {
	player     = "show",
	target     = "show",
	party      = "show",
	raid       = "show",
	castbar    = "show",
	enemies    = "show",
	swing      = "show",
	bars       = "show",
	loadout    = "show",
	charge     = "show",
	cooldowns  = "show",
	buffs      = "show",
	numbers    = "show",
	chat       = "show",
	quests     = "show",
	minimap    = "show",
	meters     = "show",
	feeds      = "show",
	drops      = "show",
	messages   = "show",
	standing   = "show",
	experience = "show",
	keys       = "show",
}

-- Bags, the map, the character sheet and every other window you open still
-- open. A theme is about what is on the screen while you are not asking for
-- anything, and none of those is.
Themes.immersive = {
	player     = FAINT,
	target     = FAINT,
	party      = "hide",
	raid       = "hide",
	castbar    = "hide",
	enemies    = "hide",
	swing      = "hide",
	bars       = "hide",
	loadout    = "hide",
	charge     = "hide",
	cooldowns  = "hide",
	buffs      = "hide",
	numbers    = "hide",
	chat       = "hide",
	quests     = "hide",
	minimap    = "hide",
	meters     = "hide",
	feeds      = "hide",
	drops      = "hide",
	messages   = "hide",
	standing   = "hide",
	experience = "hide",
	keys       = "hide",
}

-- The four things you read between fights wait under the pointer. Everything
-- a fight needs stays up, because a bar you have to find with the mouse in the
-- middle of a pull is a bar you do not have. The loadout bars stay as drawn:
-- they come up only while their key is held, and a bar that then waited for
-- the pointer as well would be a key that shows nothing. The meters wait under
-- the pointer with the rest: the damage and threat panes report on a fight
-- after it, and a report you asked for by putting the pointer on it is the
-- asking this theme is built around. The loot and combat feeds go instead,
-- because a feed is read as it arrives and one you have to find with the mouse
-- has already scrolled past. The drops and messages sliding in stay, because
-- they say what you just picked up or were just told and then leave, and with
-- chat under the pointer a floated whisper is how you hear one at all. The
-- feeds are a wiggle away: exploration swaps to informational out of the box.
Themes.exploration = {
	player     = "show",
	target     = "show",
	party      = "show",
	raid       = "show",
	castbar    = "show",
	enemies    = "show",
	swing      = "show",
	bars       = "hover",
	loadout    = "show",
	charge     = "show",
	cooldowns  = "show",
	buffs      = "show",
	numbers    = "show",
	chat       = "hover",
	quests     = "hover",
	minimap    = "show",
	meters     = "hover",
	feeds      = "hide",
	drops      = "show",
	messages   = "show",
	standing   = "show",
	experience = "show",
	keys       = "show",
}
