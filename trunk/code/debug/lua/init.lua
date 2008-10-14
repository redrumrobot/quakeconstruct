--SendScript("lua/cl_debugbar.lua")
--SendScript("lua/cl_marks.lua")
--includesimple("sctest")

--SendScript("lua/vampiric_cl.lua")
--SendScript("lua/includes/scriptmanager.lua")

require "turrets"

function makeMessage()
	for k,v in pairs(GetEntitiesByClass("player")) do
		local msg = Message(v,1)
		message.WriteString(msg,base64.enc("I Rock!"))
		message.WriteFloat(msg,100.0)
		message.WriteFloat(msg,120.5)
		message.WriteShort(msg,10)
		SendDataMessage(msg)
	end
end
concommand.Add("msgtest",makeMessage)

local function writeVector(msg,v)
	message.WriteFloat(msg,v.x)
	message.WriteFloat(msg,v.y)
	message.WriteFloat(msg,v.z)
end

local function ItemPickup(item, other, trace, itemid)
	if(item and other and itemid) then
		local vec = item:GetPos()
		local vec2 = other:GetVelocity()
		
		for k,v in pairs(GetEntitiesByClass("player")) do
			local msg = Message(v,2)
			message.WriteString(msg,item:Classname())
			writeVector(msg,vec)
			writeVector(msg,vec2)
			message.WriteLong(msg,itemid)
			SendDataMessage(msg)
		end
	end
	--return false
end
hook.add("ItemPickup","init",ItemPickup)

local function PlayerDamaged(self,inflictor,attacker,damage,meansOfDeath)
	for k,v in pairs(GetEntitiesByClass("player")) do
		local msg = Message(v,3)
		message.WriteLong(msg,damage)
		message.WriteShort(msg,meansOfDeath)
		message.WriteShort(msg,self:EntIndex())
		message.WriteLong(msg,self:GetInfo().health)
		if(attacker) then
			message.WriteShort(msg,1)
			message.WriteString(msg,attacker:GetInfo().name)
			writeVector(msg,attacker:GetPos())
			message.WriteShort(msg,attacker:EntIndex())
		else
			message.WriteShort(msg,0)
		end
		SendDataMessage(msg)
	end
	if(meansOfDeath != MOD_TRIGGER_HURT) then
		--return 0
	end
end

hook.add("PlayerDamaged","Accention",PlayerDamaged)

local function PlayerSpawned(pl)
	for k,v in pairs(GetEntitiesByClass("player")) do
		local msg = Message(v,0)
		message.WriteShort(msg,pl:EntIndex())
		SendDataMessage(msg)
	end
end
hook.add("PlayerSpawned","init",PlayerSpawned)