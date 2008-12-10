QLUA_DEBUG = false;

function killGaps(line)
	line = string.Replace(line," ","")
	line = string.Replace(line,"\t","")
	return line
end

function ProfileFunction(func,...)
	local tps = ticksPerSecond()
	local s = ticks() / 1000
	pcall(func,arg)
	local e = ticks() / 1000
	return e - s
end

function fixcolorstring(s)
	while true do
		local pos = string.find(s, '^', 0, true)

		if (pos == nil) then
			break
		end	
		
		local left = string.sub(s, 1, pos-1)
		local right = string.sub(s, pos + 2)
		s = left .. right
	end
	return s
end

function includesimple(s)
	include("lua/" .. s .. ".lua")
end

function CurTime()
	return LevelTime()/1000
end

function debugprint(msg)
	if(QLUA_DEBUG) then
		if(SERVER) then
			print("SV: " .. msg)
		else
			print("CL: " .. msg)
		end
	end
end

function hexFormat(k)
	return string.gsub(k, ".", function (c)
	return string.format("%02x", string.byte(c))
	end)
end

if(CLIENT) then
	function drawNSBox(x,y,w,h,v,shader,nocenter)
		local d = 1/3
		draw.Rect(x,y,v,v,shader,0,0,d,d)
		draw.Rect(x+v,y,v+(w-v*3),v,shader,d,0,d*2,d)
		draw.Rect(x+(w-v),y,v,v,shader,d*2,0,d*3,d)
		
		draw.Rect(x,y+v,v,v+(h-v*3),shader,0,d,d,d*2)
		if(!nocenter) then draw.Rect(x+v,y+v,v+(w-v*3),v+(h-(v*3)),shader,d,d,d*2,d*2) end
		draw.Rect(x+(w-v),y+v,v,v+(h-(v*3)),shader,d*2,d,d*3,d*2)
		
		draw.Rect(x,y+(h-v),v,v,shader,0,d*2,d,d*3)
		draw.Rect(x+v,y+(h-v),v+(w-v*3),v,shader,d,d*2,d*2,d*3)
		draw.Rect(x+(w-v),y+(h-v),v,v,shader,d*2,d*2,d*3,d*3)
	end

	function LoadCharacter(char,skin)
		skin = skin or "default"
		local ghead = LoadModel("models/players/" .. char .. "/head.md3")
		local gtorso = LoadModel("models/players/" .. char .. "/upper.md3")
		local glegs = LoadModel("models/players/" .. char .. "/lower.md3")

		local headskin = util.LoadSkin("models/players/" .. char .. "/head_" .. skin .. ".skin")
		local torsoskin = util.LoadSkin("models/players/" .. char .. "/upper_" .. skin .. ".skin")
		local legskin = util.LoadSkin("models/players/" .. char .. "/lower_" .. skin .. ".skin")
		
		local legs = RefEntity()
		legs:SetModel(glegs)
		legs:SetSkin(legskin)

		local torso = RefEntity()
		torso:SetModel(gtorso)
		torso:SetSkin(torsoskin)

		local head = RefEntity()
		head:SetModel(ghead)
		head:SetSkin(headskin)
		
		return legs,torso,head
	end
	
	function hsv(h,s,v,...)
		h = h % 360
		local h1 = math.floor((h/60) % 6)
		local f = (h / 60) - math.floor(h / 60)
		local p = v * (1 - s)
		local q = v * (1 - (f * s) )
		local t = v * (1 - (1 - f) * s)
		
		local values =  {
			{v,t,p},
			{q,v,p},
			{p,v,t},
			{p,q,v},
			{t,p,v},
			{v,p,q}
		}
		
		local out = values[h1+1]
		
		if(arg != nil) then
			for k,v in pairs(arg) do
				table.insert(out,v)
			end
		end
		
		return unpack(out)
	end
	
	local hsvtemp = {}
	for i=0,360 do
		local r,g,b = hsv(i,1,1)
		hsvtemp[i+1] = {r,g,b}
	end
	
	function fasthue(h,v,...)
		h = h % 360
		if(h < 1) then h = 1 end
		if(h > 360) then h = 360 end
		h = math.ceil(h)
		
		local out = table.Copy(hsvtemp[h])
		out[1] = out[1] * v
		out[2] = out[2] * v
		out[3] = out[3] * v
		
		if(arg != nil) then
			for k,v in pairs(arg) do
				table.insert(out,v)
			end
		end
		
		return unpack(out)
	end
end

function SetOrigin( ent, origin )
	local tr = ent:GetTrajectory()
	tr:SetBase(origin)
	tr:SetType(TR_STATIONARY)
	tr:SetTime(0)
	tr:SetDuration(0)
	tr:SetDelta(Vector(0,0,0))
	ent:SetTrajectory(tr)
end

function BounceEntity(ent,trace,amt)
	local tr = ent:GetTrajectory()
	local hitTime = LastTime() + ( LevelTime() - LastTime() ) * trace.fraction;
	local vel = tr:EvaluateDelta(hitTime)
	local dot = DotProduct( vel, trace.normal );
	local delta = vAdd(vel,vMul(trace.normal,-2*dot))
	delta = vMul(delta,amt or .5)

	tr:SetBase(ent:GetPos())
	tr:SetDelta(delta)
	ent:SetTrajectory(tr)
	
	if ( trace.normal.z > 0 and delta.z < 40 ) then
		trace.endpos.z = trace.endpos.z + 1.0
		SetOrigin( ent, trace.endpos );
		ent:SetGroundEntity(trace.entitynum);
		return;
	end
	
	ent:SetPos(vAdd(ent:GetPos(),trace.normal))
end

function LerpReach(lr,id,v,t,thr,s,r)
	if(lr == nil or type(lr) != "table") then error("No LerpReach for you :(\n") end
	lr[id] = lr[id] or {}
	local l = lr[id]
	
	l.t = l.t or t
	l.v = l.v or v
	
	l.v = l.v + (l.t - l.v)*s
	
	if(math.abs(l.t-l.v) < thr) then
		pcall(r,l)
	end
	return l.v
end

function DamageInfo(self,inflictor,attacker,damage,meansOfDeath,killed)
	local m = "Damaged"
	if(killed) then m = "Killed" end
	print("A Player Was " .. m .. "\n")
	print("INFLICTOR: " .. GetClassname(inflictor) .. "\n")
	
	if(GetClassname(attacker) == "player") then
		print("ATTACKER: " .. GetPlayerInfo(attacker)["name"] .. "\n")
	else
		print("ATTACKER: " .. GetClassname(attacker) .. "\n")
	end
	
	print("DAMAGE: " .. damage .. "\n")
	print("MOD: " .. meansOfDeath .. "\n")
	print("The Target's Name Is: " .. GetPlayerInfo(self)["name"] .. "\n")
end

POWERUP_FOREVER = 10000*10000

debugprint("^3Tools loaded.\n")