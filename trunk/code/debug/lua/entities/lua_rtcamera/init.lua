function ENT:Initialized()
	print("Camera Init\n")
	
	print("CAMERA ANGLE: " .. self.Entity:GetSpawnAngle() .. "\n")
	print("CAMERA ANGLE2: " .. tostring(self.Entity:GetAngles()) .. "\n")
	
	local exPitch = G_SpawnString("pitch","0")
	exPitch = tonumber(exPitch)
	
	self.Entity:SetSvFlag(SVF_PORTAL)
	self.Entity:SetPos(self.Entity:GetPos())
	if(exPitch) then
		self.Entity:SetAngles(self.Entity:GetAngles() + Vector(exPitch,0,0))
	end
	
	self.Entity:SetClip(CONTENTS_TRIGGER)
end