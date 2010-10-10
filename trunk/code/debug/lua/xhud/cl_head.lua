local inf = LocalPlayer():GetInfo()
local blood1 = LoadShader("dissolve2_mul")
local blood2 = LoadShader("dissolve")

local skull = LoadModel("models/gibs/skull.md3")
local head = inf.headModel
local skin = inf.headSkin
local mins,maxs = render.ModelBounds(head)
local ref = RefEntity()
local ref2 = RefEntity()
local DAMAGE_TIME = 250
local headOrigin = Vector()

local wDamageX = 0
local wDamageY = 0
local wDamageTime = 0

ref:SetModel(head)
ref:SetSkin(skin)
ref2:SetModel(head)
ref2:SetShader(blood1)

function positionHead()
	mins,maxs = render.ModelBounds(ref:GetModel())

	headOrigin.x = 2.5 * ( maxs.x - mins.x);
	headOrigin.y = 0.5 * ( mins.y + maxs.y );
	headOrigin.z = -0.35 * ( mins.z + maxs.z );
end

positionHead()

local headStartYaw = 0
local headEndYaw = 0
local headStartPitch = 0
local headEndPitch = 0
local headStartRoll = 0
local headEndRoll = 0
local headStartTime = 0
local headEndTime = 0
local deadFrac = 0
local deadFrac2 = 0;
local dz = math.random(-1,1)
local timex = 0
local lct = CurTime()
local mvz = 0
local nalpha = 0
local calpha = 0
local calpha2 = 0
local ddir = 0
local frac_spr_x = Spring(0  ,0,  .2,  .90,  0);
local frac_spr_y = Spring(180,0,  .25,  .8,   0);
local frac_spr_z = Spring(0  ,0,  .15,  .89,  0);
local ldamaget = 0
local finisheddamage = false
local turning = 0
local waterdamage = 0
local oldhealth = 100
local firstloop = true
local modelname = nil
local m_headmodel = nil
local m_headanims = nil
local animate = false

local function findModel(name)
	return LoadModel("models/players/" .. name .. "/head_anim.md3")
end

function loadHeadAnimations(name)
	local path = "models/players/" .. name .. "/head_animation.cfg"
	local txt = packRead(path)
	if(txt == nil) then 
		return nil
	end
	
	return parseAnims(txt)
end

local function initHeadAnimations()
	for k,v in pairs(m_headanims) do
		v:SetType(ANIM_ACT_STOP)
		v:Reset()
		v:Stop()
	end
	m_headanims["IDLE"]:SetType(ANIM_ACT_PINGPONG)
	m_headanims["DEAD"]:SetType(ANIM_ACT_LOOP)
	m_headanims["WATER_DEAD"]:SetType(ANIM_ACT_LOOP)
end

local function playingPainAnimations()
	if(m_headanims["PAIN_L"].playing) then return true end
	if(m_headanims["PAIN_R"].playing) then return true end
	if(m_headanims["WATER_PAIN_L"].playing) then return true end
	if(m_headanims["WATER_PAIN_R"].playing) then return true end
	return false
end

function loadHeadModel(inf)
	if(modelname != inf.modelName) then
		print("Model changed to: " .. inf.modelName .. "\n")
		modelname = inf.modelName
		local m = findModel(modelname)
		if(m == nil or m == 0) then
			animate = false
		else
			m_headmodel = m
			m_headanims = loadHeadAnimations(modelname)
			if(m_headanims != nil) then
				animate = true
				initHeadAnimations()
			else
				animate = false
			end
		end
	end
	return m_headmodel or inf.headModel
end

function DrawHead(x,y,ICON_SIZE,HEALTH)
	local hp = HEALTH
	local hp2 = HEALTH + waterdamage
	local inf = LocalPlayer():GetInfo()
	local nhead = loadHeadModel(inf)
	local nskin = inf.headSkin
	local waterlevel = entityWaterLevel(LocalPlayer())
	if(nhead != head or nskin != skin) then
		ref:SetModel(nhead)
		ref:SetSkin(nskin)
		ref2:SetModel(nhead)
		
		skin = nskin
		head = nhead
		
		positionHead()
	end
	
	if(animate) then
		local a = m_headanims
		if(playingPainAnimations() or HEALTH <= 0) then
			a["INWATER"]:Stop()
			a["IDLE"]:Stop()
		else
			if(waterlevel < 2) then
				if(a["INWATER"].playing) then
					a["INWATER"].reverse = true
				else
					if(a["INWATER"].start < a["INWATER"].frame) then
						a["INWATER"].reverse = true
						a["INWATER"]:Play()
					else
						a["INWATER"].reverse = false
						a["INWATER"]:Reset()
						a["INWATER"]:Stop()
					end
					if(a["INWATER"].playing) then
					
					else
						a["IDLE"]:Play()
					end
				end
			else
				a["IDLE"]:Reset()
				a["IDLE"]:Stop()
				a["INWATER"].reverse = false
				a["INWATER"]:Play()
			end
		end
		
		--m_headanims["PAIN_L"]:Play()
		
		for k,v in pairs(m_headanims) do
			v:SetRef(ref)
			v:Animate()
		end
		
		ref2:SetFrame(ref:GetFrame())
		ref2:SetLerp(ref:GetLerp())
		ref2:SetOldFrame(ref:GetOldFrame())
	end
	
	if not (oldhealth == HEALTH) then
		if(firstloop) then
		else
			if(oldhealth < HEALTH) then
				local heal = HEALTH - oldhealth
				waterdamage = waterdamage - heal
				if(waterdamage < 0) then waterdamage = 0 end
			else

			end
		end
		oldhealth = HEALTH
	end

	if(animate) then
		if(HEALTH <= 0) then
			if(waterlevel < 2) then
				if(m_headanims["DEATH"].frame == m_headanims["DEATH"].start) then
					m_headanims["DEATH"]:Play()
				end
				if not (m_headanims["DEATH"].playing) then
					m_headanims["DEAD"]:Play()
				end
			else
				if(m_headanims["WATER_DEATH"].frame == m_headanims["WATER_DEATH"].start) then
					m_headanims["WATER_DEATH"]:Play()
				end
				if not (m_headanims["WATER_DEATH"].playing) then
					m_headanims["WATER_DEAD"]:Play()
				end
			end	
		else
			if(m_headanims["DEATH"].playing or 
				m_headanims["DEAD"].playing or 
				m_headanims["WATER_DEATH"].playing or
				m_headanims["WATER_DEAD"].playing) then
				print("RESET\n")
				m_headanims["INWATER"]:Reset()
				m_headanims["INWATER"]:Stop()
				m_headanims["DEAD"]:Reset()
				m_headanims["DEAD"]:Stop()
				m_headanims["WATER_DEAD"]:Reset()
				m_headanims["WATER_DEAD"]:Stop()
				m_headanims["DEATH"]:Reset()
				m_headanims["DEATH"]:Stop()
				m_headanims["WATER_DEATH"]:Reset()
				m_headanims["WATER_DEATH"]:Stop()
			end
		end
	end
	
	local frac = 0
	local size = 0
	local stretch = 0
	local damageTime = _CG.damageTime
	local ltime = LevelTime()
	local damageX = _CG.damageX
	local damageY = _CG.damageY
	local delta = (ltime - damageTime)
	local angles = Vector()
	local resetf = false
	if(delta < DAMAGE_TIME) then
		if(HEALTH > 0) then
			if(waterlevel < 2) then
				if(damageX < 0) then
					m_headanims["PAIN_R"]:Reset()
				else
					m_headanims["PAIN_L"]:Reset()
				end
			else
				if(damageX < 0) then
					m_headanims["WATER_PAIN_R"]:Reset()
				else
					m_headanims["WATER_PAIN_L"]:Reset()
				end
			end
		end
		finisheddamage = true
		local hpx = 1-(math.min(math.max(hp/100,.3),1))
		frac = delta / DAMAGE_TIME
		size = ICON_SIZE * 1.25 --* ( 1.5 - frac * 0.5 );
		
		--stretch = size - ICON_SIZE * 1.25;
		--x = x - stretch * 0.5 + damageX * stretch * 0.5;
		--y = y - stretch * 0.5 + damageX * stretch * 0.5;
		
		headStartYaw = 180 + (damageX * 45) * hpx;
		
		if(damageY > 0) then
			headStartPitch = -30*(1-frac)
		else
			headStartPitch = 30*(1-frac)
		end
		
		headEndYaw = 180 + 20 * math.cos( math.random()*math.pi );
		headEndPitch = -10 * math.cos( math.random()*math.pi );
		
		--print(ddir .. "\n")
		ddir = damageX * (25) + math.random(-10,10)
		headStartRoll = ddir*(1-frac)
		headEndRoll = 0

		headStartTime = ltime;
		headEndTime = ltime + 100 + math.random() * 2000;
		if(delta < ldamaget) then
			print(delta .. " - " .. ldamaget .. "\n")
			resetf = true
		end
		ldamaget = delta
	else
		ddir = damageX * (25) + math.random(-10,10)  --((math.random(1,2)*2) - 3) * (math.random(6,10) * 2.5)
		if ( ltime >= headEndTime ) then
			headStartYaw = headEndYaw;
			headStartPitch = headEndPitch;
			headStartTime = headEndTime;
			headStartRoll = headEndRoll
			
			headEndTime = ltime + 100 + math.random() * 2000;

			local hpx = 1-(math.min(math.max(hp/100,.1),1))
			
			if(deadFrac > 0) then
				headStartTime = ltime;
				headEndTime = ltime + 50 + math.random() * 500;
			else
				headEndTime = headEndTime + (1-hpx)*800
			end
			
			headEndYaw = 180 + (40 * math.cos( math.random()*math.pi )) --*hpx;
			headEndPitch = math.abs(15 * math.cos( math.random()*math.pi )) * (1-hpx) * -1;
			
			if(deadFrac > 0) then
				headEndYaw = 180 + 60 * math.cos( math.random()*math.pi );
				headEndPitch = 40 * math.cos( math.random()*math.pi );
			end
		end

		size = ICON_SIZE * 1.25;
	end
	
	if ( headStartTime > ltime ) then
		headStartTime = ltime;
	end
	
	frac = ( ltime - headStartTime ) / ( headEndTime - headStartTime );
	frac = frac * frac * ( 3 - 2 * frac );
	
	angles.y = headStartYaw + ( headEndYaw - headStartYaw ) * frac;
	angles.x = headStartPitch + ( headEndPitch - headStartPitch ) * frac;
	angles.z = headStartRoll + ( headEndRoll - headStartRoll ) * frac;

	if(hp > 0) then
		local hpx = 1-(math.min(math.max(hp/100,.1),1))
		angles.z = angles.z + (hpx * 15)
	end
	
	if(hp <= 0) then
		if(dz > 0) then dz = 1 end
		if(dz <= 0) then dz = -1 end
		angles.y = angles.y - (angles.y - 180)*deadFrac
		angles.x = angles.x - (angles.x - 10)*deadFrac
		angles.z = 13*dz
		
		--if(waterlevel >= 2) then
			angles.x = angles.x - 30 * (1-deadFrac2)
		--end
		
		if(deadFrac == 0) then
			headStartPitch = -30
			headStartTime = ltime;
			headEndPitch = -10
			headEndTime = ltime+200;
		end
		deadFrac = deadFrac + 0.008
		deadFrac2 = deadFrac2 + 0.001
		if(deadFrac > 1) then deadFrac = 1 end
		if(deadFrac2 > 1) then deadFrac2 = 1 end
	else
		dz = math.random(-1,1)
		deadFrac = 0
		deadFrac2 = 0
	end
	
	if(hp > 100) then hp = 100 end
	if(hp > 0) then
		local hp2 = (1-(hp/200))
		timex = timex + (CurTime() - lct) * ((hp2) * math.random(20,30)/5)
		
		angles.x = angles.x + (1-(hp/100))*18

		angles.x = angles.x + math.cos(timex)*(1-(hp/70))*6
		angles.z = angles.z + math.sin(timex/3)*(1-(hp/70))*4
		
		mvz = math.cos(timex)*(1-(hp/100))*.7
	end
	
	local vang = VectorToAngles(_CG.refdef.forward)
	vang.x = math.cos((vang.x + 90)/57.3)*-90
	
	local delta_turn = getDeltaAngle(turning, vang.y)
	turning = vang.y

	angles.x = angles.x + vang.x/10
	angles.y = angles.y + delta_turn/2
	--if(angles.x > 0) then angles.x = angles.x + 360 end
	
	if(resetf) then
		local hpc = ((100-hp)/100) + .35
		local dy = angles.y - frac_spr_y.val
		frac_spr_x.val = frac_spr_x.val + (angles.x * hpc)
		frac_spr_y.val = frac_spr_y.val + (dy * hpc)
		frac_spr_z.val = frac_spr_z.val + (angles.z * hpc)
	end
	frac_spr_x.ideal = angles.x
	frac_spr_y.ideal = angles.y
	frac_spr_z.ideal = angles.z
	
	frac_spr_x:Update()
	frac_spr_y:Update()
	frac_spr_z:Update()
	
	angles.x = frac_spr_x.val
	angles.y = frac_spr_y.val
	angles.z = frac_spr_z.val
	
	render.CreateScene()

	local hpx = (1-(math.min(math.max(hp2/100,0),1)/5)) - 0.3
	if(hpx < 0) then 
		hpx = 0
	end
	nalpha = hpx
	if(delta < DAMAGE_TIME or hp <= 0) then
		local i = hpx + ((1-(delta/DAMAGE_TIME))/18)
		if(i < hpx) then i=hpx end
		if(i > 1) then i=1 end
		nalpha = i
		if(hp <= 0) then nalpha = 1 end
		if(hp <= -40) then
			if(ref:GetModel() != skull) then
				ref:SetModel(skull)
				ref:SetSkin(0)
				ref2:SetModel(skull)
				positionHead()
			end
		end
	elseif(ref:GetModel() == skull) then
		ref:SetModel(head)
		ref:SetSkin(skin)
		ref2:SetModel(head)
		positionHead()
	end
	ref:SetPos(Vector(0,headOrigin.y,headOrigin.z))
	ref2:SetPos(Vector(0,headOrigin.y,headOrigin.z))
	
	local hp2x = math.min(math.max(hp2/100,0),1)
	local na2 = math.min((hp2x/3) + .6,1)
	
	calpha = nalpha --calpha + (nalpha - calpha)*.01
	calpha2 = na2 --calpha2 + (na2 - calpha2)*.01
	if(calpha < 0.5) then calpha = 0.5 end
	
	ref:Render()
	ref2:SetColor(1,.2,.2,calpha2)
	ref2:SetShader(blood1)
	ref2:Render()
	
	ref2:SetColor(.6,.1,.1,(calpha2*.9)+.1)
	ref2:SetShader(blood1)
	ref2:Render()
	
	ref2:SetColor(1,1,1,calpha)
	ref2:SetShader(blood2)
	ref2:Render()
	
	--angles.y = angles.y + 180
	local forward = VectorForward(angles)
	
	local refdef = {}
	refdef.flags = 1
	refdef.x = x
	refdef.y = y
	refdef.width = size
	refdef.height = size
	refdef.origin = vMul(forward,-headOrigin.x)
	local aim = VectorNormalize(refdef.origin)
	aim = vMul(aim,-1)
	aim = VectorToAngles(aim)
	aim.z = angles.z
	
	refdef.origin.z = refdef.origin.z + mvz
	
	refdef.angles = aim
	refdef.angles.z = refdef.angles.z + angles.z/1.5
	local b, e = pcall(render.RenderScene,refdef)
	if(!b) then
		print("^1" .. e .. "\n")
	end
	lct = CurTime()
	
	if(firstloop) then
		firstloop = false
	end
end

local function processDamage(attacker,pos,dmg,death,waslocal,wasme,health)
	if(waslocal == false) then return end
	if(death == MOD_FALLING) then
		m_headanims["PAIN_L"]:Reset()
		headStartYaw = 180;
		headStartPitch = 25
		
		headEndYaw = 180;
		headEndPitch = -10;
		
		headStartRoll = -5
		headEndRoll = 0

		headStartTime = LevelTime();
		headEndTime = LevelTime() + 200;
	end
	if(death == MOD_WATER) then
		m_headanims["WATER_PAIN_L"]:Reset()
		headStartYaw = 180 + (2);
		
		headStartPitch = -30

		
		headEndYaw = 180 -- + 0 * math.cos( math.random()*math.pi );
		headEndPitch = 0
		
		headStartRoll = 2
		headEndRoll = 0

		headStartTime = LevelTime();
		headEndTime = LevelTime() + 800 + math.random() * 100;
		
		waterdamage = waterdamage + dmg
	end
end
hook.add("Damaged","cl_xhud_head",processDamage)

--[[local function newClientInfo(newinfo,entity)
	if(entity:IsClient()) then
		if(entity == LocalPlayer()) then
			print("Conditions Passed\n")
			local inf = LocalPlayer():GetInfo()
			head = inf.headModel
			skin = inf.headSkin
			ref:SetModel(head)
			ref:SetSkin(skin)
			ref2:SetModel(head)
			
			positionHead()
		end
	end
end
hook.add("ClientInfoLoaded","cl_head",newClientInfo)]]