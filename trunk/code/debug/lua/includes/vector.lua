local matrix = require("includes/matrix")
local function identity()
	return matrix {{1,0,0},{0,1,0},{0,0,1}}
end

local function identityx(x,y,z)
	return matrix {{x},
				   {y},
				   {z}}
end
local rotation = identity()
local camera = identityx(0,0,0)

local function m_projection(e,d,out)
	out[1][1] = (d.x - e.x) * (e.z/d.z)
	out[2][1] = (d.y - e.y) * (e.z/d.z)
	return out
end

function vAdd(v1,v2)
	return v1 + v2
end

function vSub(v1,v2)
	return v1 - v2
end

function vMul(v1,v2)
	return v1 * v2
end

function vAbs(v)
	local out = Vector()
	out.x = math.abs(v.x)
	out.y = math.abs(v.y)
	out.z = math.abs(v.z)
	return out
end

if(CLIENT) then
	local w,h = 320,240
	function VectorToScreen(vec,pos,ang,in_fov)
		if(vec == nil) then return end
		local mat = identityx(vec.x,vec.y,vec.z)
		local out = Vector()
		
		local o = pos or _CG.viewOrigin
		local f = _CG.refdef.forward
		local r = _CG.refdef.right
		local u = _CG.refdef.up
		local fov = _CG.refdef.fov_x/2
		if(in_fov) then fov = in_fov/2 end
		
		fov = ((3.58 - (fov/25.2))*5) - (3.58 + 1.79 + 1.79)
		
		if(ang != nil) then
			f,r,u = AngleVectors(ang)
		end
		
		--local fov = 90
		--fov = fov / 2
		--fov = 1/math.tan(fov/2)
		
		camera = identityx(o.x,o.y,o.z)
		rotation = matrix {{-r.x,-r.y,-r.z},
						   {-u.x,-u.y,-u.z},
						   {-f.x,-f.y,-f.z},}
		
		if(mat ~= nil) then
			local mt = mat
			mt = (rotation * (mt - camera))
					
			local d = {x=mt[1][1],y=mt[2][1],z=mt[3][1]}
			local e = {x=0,y=0,z=fov}
			mt = m_projection(e,d,mt)

			mt[1][1] = mt[1][1] * -1.12
			mt[2][1] = mt[2][1] * -1.5
			
			mt[1][1] = mt[1][1] + 1
			mt[2][1] = mt[2][1] + 1
			
			out.x = mt[1][1] * (w/2) + w/2
			out.y = mt[2][1] * (h/2) + h/2
			out.z = mt[3][1]
			
			mt = nil
		end
		
		local draw = true
		if(out.z > 0) then draw = false end
		
		return out,draw
	end
end

--[[function Vector(x,y,z)
	x = x or 0
	y = y or 0
	z = z or 0
	return {x=x,y=y,z=z}
end]]

function Vectorv(tab)
	return Vector(tab.x,tab.y,tab.z) --{x=tab.x,y=tab.y,z=tab.z}
end