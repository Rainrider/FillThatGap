--[[
	 Description:
--]]

local ADDON_NAME, ns = ...

local debug = true

local Debug = function(...)
	if (debug) then
		print("|cff00ff00"..ADDON_NAME.."|r", ...)
	end
end

local BuffsForSpec = {
	-- MAGE
	[62] = {},		-- Arcane
	[63] = {},		-- Fire
	[64] = {},		-- Frost
	-- PALADIN
	[65] = {},		-- Holy
	[66] = {},		-- Protection
	[70] = {},		-- Retribution
	-- WARRIOR
	[71] = {},		-- Arms
	[72] = {},		-- Fury
	[73] = {},		-- Protection
	-- DRUID
	[102] = {},		-- Balance
	[103] = {},		-- Feral
	[104] = {},		-- Guardian
	[105] = {},		-- Restoration
	-- DEATHKNIGHT
	[250] = {},		-- Blood
	[251] = {},		-- Frost
	[252] = {},		-- Unholy
	-- HUNTER
	[253] = {},		-- Beastmaster
	[254] = {},		-- Markmanship
	[255] = {},		-- Survival
	-- PRIEST
	[256] = {},		-- Discipline
	[257] = {},		-- Holy
	[258] = {},		-- Shadow
	-- ROGUE
	[259] = {},		-- Assasination
	[260] = {},		-- Combat
	[261] = {},		-- Subtlety
	-- SHAMAN
	[262] = {},		-- Elemental
	[263] = {},		-- Enchancement
	[264] = {},		-- Restoration
	-- WARLOCK
	[265] = {},		-- Affliction
	[266] = {},		-- Demonology
	[267] = {},		-- Destruction
	-- MONK
	[268] = {},		-- Brewmaster
	[269] = {},		-- Windwalker
	[270] = {},		-- Mistweaver
}

local DebuffsForSpec = {
	-- MAGE
	[62] = {5},			-- Arcane
	-- [63] = {},		-- Fire
	-- [64] = {},		-- Frost
	-- PALADIN
	-- [65] = {},		-- Holy
	[66] = {4},			-- Protection
	[70] = {2, 4},		-- Retribution
	-- WARRIOR
	[71] = {1, 2, 4},	-- Arms
	[72] = {1, 2, 4},	-- Fury
	[73] = {1, 4},		-- Protection
	-- DRUID
	[102] = {1},		-- Balance
	[103] = {1, 4},		-- Feral
	[104] = {1, 4},		-- Guardian
	[105] = {1},		-- Restoration
	-- DEATHKNIGHT
	[250] = {4, 5},		-- Blood
	[251] = {2, 5},		-- Frost
	[252] = {2, 5},		-- Unholy
	-- HUNTER
	-- [253] = {},		-- Beastmaster
	-- [254] = {},		-- Markmanship
	-- [255] = {},		-- Survival
	-- PRIEST
	-- [256] = {},		-- Discipline
	-- [257] = {},		-- Holy
	-- [258] = {},		-- Shadow
	-- ROGUE
	[259] = {1, 3, 5},	-- Assasination
	[260] = {1, 3, 5},	-- Combat
	[261] = {1, 3, 5},	-- Subtlety
	-- SHAMAN
	[262] = {4},		-- Elemental
	[263] = {4},		-- Enchancement
	[264] = {4},		-- Restoration
	-- WARLOCK
	[265] = {3, 4, 5},	-- Affliction
	[266] = {3, 4, 5},	-- Demonology
	[267] = {3, 4, 5},	-- Destruction
	-- MONK
	[268] = {4},		-- Brewmaster
	-- [269] = {},		-- Windwalker
	-- [270] = {},		-- Mistweaver
}

local PetsForBuffCategory = {

}

local PetsForDebuffCategory = {
	-- Weakened Armor
	[1] = {
		"Tallstrider",
		"Raptor",
	},
	-- Physical Vulnerability
	[2] = {
		"Boar",
		"Ravager",
		"Rhino (*)",
		"Worm (*)",
	},
	-- Magical Vulnerability
	[3] = {
		"Dragonhawk",
		"Wind Serpent",
	},
	-- Weakened Blows
	[4] = {
		"Bear",
		"Carrion Bird",
	},
	-- Slow Casting
	[5] = {
		"Spore Bat",
		"Fox",
		"Goat",
		"Core Hound (*)",
	},
	-- Mortal Wounds unneeded as any hunter can provide it through Widow Venom
}

local GroupSpecs = {}
local GroupDebuffCategories = {}
-- holds GUIDs awaiting inspect: [GUID] = true
local UnitsAwaitingInspect = {}
--[[
	GroupCache = {
		[guid] = {
			["name"] = "name-realmname"
			["spec"] = spec
		},
	}
--]]
local GroupCache = {}
local INSPECT_FREQ = 2.2

local QueueInspect = function(self, elapsed)
	self.elapsed = self.elapsed + elapsed

	for guid in pairs(UnitsAwaitingInspect) do
		local name = GroupCache[guid]["name"]		-- TODO: error attempted to index field "?" (a nil value)
		if (CanInspect(name) and self.elapsed >= INSPECT_FREQ) then -- TODO: check whether the IspectFrame is open. This causes issues?
			self.elapsed = 0
			Debug("|cff00ffffQueing inspect for", name, "|r")
			NotifyInspect(name)
		else
			if (not UnitIsConnected(name)) then
				UnitsAwaitingInspect[guid] = nil -- will requeue upon UNIT_CONNECTION
				Debug("Dequeued", name)
			end
		end
	end

	if (next(UnitsAwaitingInspect) == nil) then
		Debug("Queue is empty. Hiding the frame...")
		self:Hide()
	end
end

local ftg = CreateFrame("Frame", ADDON_NAME, UIParent)
ftg.elapsed = 0
ftg:Hide()
ftg:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)
ftg:SetScript("OnUpdate", QueueInspect)
ftg:RegisterEvent("ADDON_LOADED")

function ftg:ADDON_LOADED(event, name)
	if (ADDON_NAME ~= name) then return end
	-- load Blizzard_DebugTools
	if (debug and not IsAddOnLoaded("Blizzard_DebugTools")) then
		LoadAddOn("Blizzard_DebugTools")
	end

	-- slash commands

	-- events
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("INSPECT_READY")
	--self:RegisterEvent("PLAYER_REGEN_ENABLED")
	--self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("UNIT_CONNECTION")
end

function ftg:INSPECT_READY(event, guid)
	if (not UnitsAwaitingInspect[guid]) then return end

	local name = GroupCache[guid]["name"]
	Debug("|cff00ff00Getting spec for", name, "|r")
	-- get global spec
	local spec = GetInspectSpecialization(name)

	if (spec) then
		if (not GroupSpecs[spec]) then
			GroupSpecs[spec] = 1
		else
			GroupSpecs[spec] = GroupSpecs[spec] + 1
		end

		GroupCache[guid]["spec"] = spec
	end

	-- we cached it, so dismiss further notifications about this unit
	Debug("Got data for", name, "spec:", spec)
	ClearInspectPlayer(name)
	UnitsAwaitingInspect[guid] = nil
end

function ftg:CleanGroupCache()
	for guid in pairs(GroupCache) do
		local name = GroupCache[guid]["name"]
		if (not UnitInRaid(name) and not UnitInParty(name)) then
			local spec = GroupCache[guid]["spec"]
			if (spec and GroupSpecs[spec]) then
				if (GroupSpecs[spec] == 1) then
					GroupSpecs[spec] = nil
				else
					GroupSpecs[spec] = GroupSpecs[spec] - 1
				end
			end
			GroupCache[guid] = nil
			if (UnitsAwaitingInspect[guid]) then
				UnitsAwaitingInspect[guid] = nil
			end
			Debug(name, "is no more a group member. Removed")
		end
	end
end

function ftg:ScanGroup()
	self:CleanGroupCache()
	local numGroupMembers = GetNumGroupMembers()
	if (numGroupMembers <= 0) then return end

	local groupType = IsInRaid() and "raid" or "party"

	for i = 1, numGroupMembers do
		local unitid = groupType..i

		if (not UnitIsUnit(unitid, "player")) then
			local guid = UnitGUID(unitid)

			if (guid and not GroupCache[guid]) then
				local name, realm = UnitName(unitid)
				if (realm == "") then realm = nil end
				name = realm and name.."-"..realm or name
				Debug("Added:", name)

				if (name) then -- UnitName fails sometimes???
					UnitsAwaitingInspect[guid] = true
					GroupCache[guid] = {}				-- TODO: consider meta tables
					GroupCache[guid]["name"] = name
				else
					Debug("Unable to retrieve name for", unitid)
				end
			end
		end
	end

	self:Show()
end

function ftg:DebugTables(tbl)
	if tbl == 1 then
		DevTools_Dump(UnitsAwaitingInspect)
	elseif tbl == 2 then
		DevTools_Dump(GroupCache)
	else
		DevTools_Dump(GroupSpecs)
	end
end

function ftg:GROUP_ROSTER_UPDATE(event)
	-- clean up the guids that left the group
	-- add new group members
end

function ftg:PLAYER_REGEN_ENABLED(event)
	ftg:Show()
end

function ftg:PLAYER_REGEN_DISABLED(event)
	-- prevent QueueInspect from queing further inspects
	ftg:Hide()
end

function ftg:UNIT_CONNECTION(event, unitid)
	local guid = UnitGUID(unitid) -- yep, offline players have guids
	if (not UnitIsConnected(unitid) and UnitsAwaitingInspect[guid]) then
		UnitsAwaitingInspect[guid] = nil
	end

	if (UnitIsConnected(unitid) and not UnitsAwaitingInspect[guid]) then
		UnitsAwaitingInspect[guid] = true
	end
end