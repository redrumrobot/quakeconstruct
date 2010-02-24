local XPDMG = {}
	XPDMG[MOD_GAUNTLET] = 4
	XPDMG[MOD_SHOTGUN] = 1
	XPDMG[MOD_MACHINEGUN] = 2
	XPDMG[MOD_GRENADE] = 3
	XPDMG[MOD_GRENADE_SPLASH] = 1
	XPDMG[MOD_ROCKET] = 2
	XPDMG[MOD_ROCKET_SPLASH] = 1
	XPDMG[MOD_PLASMA] = 1
	XPDMG[MOD_PLASMA_SPLASH] = 1
	XPDMG[MOD_RAILGUN] = 1.5
	XPDMG[MOD_LIGHTNING] = 1.5
	XPDMG[MOD_BFG] = .75
	XPDMG[MOD_BFG_SPLASH] = .5
	XPDMG[MOD_TELEFRAG] = 2
	
local pT = {}
local baseXPScalar = 1
local eventBuffer = nil

includesimple("levelup/shared")
includesimple("levelup/eventdispatcher")
includesimple("levelup/shop")

downloader.add("lua/levelup/shared.lua")
downloader.add("lua/levelup/cl_effects.lua")
downloader.add("lua/levelup/cl_init.lua")

local function beginPlayerTable(id)
	pT[id] = {}
	pT[id].xp = 0
	pT[id].targetxp = 800
	pT[id].level = 1
	pT[id].weapons = {}
end

local function tableForPlayer(pl)
	if(pl == nil) then return end
	local id = pl:EntIndex()
	if(pT[id] == nil) then
		beginPlayerTable(id)
	end
	
	return pT[pl:EntIndex()]
end

LV_tableForPlayer = tableForPlayer

local function gamestate(pl)
	local t = tableForPlayer(pl)
	
	E.event(LVMSG_GAMESTATE)
	E.WriteShort(t.xp)
	E.WriteShort(t.targetxp)
	E.WriteShort(t.level)
	E.dispatch(pl)
end
hook.add("MessageReceived","levelup",function(str,pl) 
	if(str == "lvl_gamestate") then
		print("SV: Player: " .. pl:GetInfo().name .. " requested gamestate\n")
		gamestate(pl)
	end 
end)

local function addXP(pl,xp,source)
	local t = tableForPlayer(pl)
	t.xp = t.xp + xp
	
	E.event(LVMSG_XP_ADDED)
	E.WriteShort(t.xp)
	E.WriteVector(source)
	E.dispatch(pl)
	
	if(t.xp > t.targetxp) then
		t.level = t.level + 1
		t.targetxp = t.targetxp + math.floor(t.targetxp*.5)
		print("SV: Player Leveled Up: " .. pl:GetInfo().name .. " : " .. t.level .. " : " .. t.targetxp .. " : " .. t.xp .. "\n")
		
		E.event(LVMSG_LEVELUP)
		E.WriteShort(t.targetxp)
		E.WriteShort(t.level)
		E.dispatch(pl)
	end
end

local function playerHasQuad(pl)
	return (pl:GetPowerup(PW_QUAD) - LevelTime()) > 0
end

local function PlayerDamaged(self,inflictor,attacker,damage,dtype)
	if(self == nil or attacker == nil or self == attacker or self:GetHealth() <= 0) then return end

	if(XPDMG[dtype] ~= nil) then
		addXP(attacker,XPDMG[dtype] * baseXPScalar * damage,self:GetPos())
	end
end
hook.add("PlayerDamaged","levelup",PlayerDamaged)