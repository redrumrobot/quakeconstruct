--[[for k,v in pairs(_G) do
	print(k .. "\n")
end]]

local function includex(s)
	local b,e = pcall(include,"lua/includes/" .. s .. ".lua")
	if(!b) then
		print("^1Failure To Load \"" .. s .. "\":\n" .. e .. "\n")
	else
		print("^2Loaded: " .. s .. "\n")
	end
end

--[[includex("tools")
includex("extensions/init")
includex("vector")
includex("angles")
includex("hooks")
if(CLIENT) then includex("input") end
if(CLIENT) then includex("view") end

_qlimit()
]]
--if(true) then return end

includex("tools")
includex("extensions/init")
includex("base64")
includex("file")
includex("hooks")
includex("entities")
includex("timer")
includex("enum")
includex("vector")
includex("matrix")
includex("angles")
includex("messages")
includex("netvars")
includex("scriptmanager")
includex("commands")
if(CLIENT) then includex("sound") end
if(CLIENT) then includex("shader") end
if(CLIENT) then includex("sequence") end
if(CLIENT) then includex("animation") end
if(CLIENT) then includex("model") end
if(CLIENT) then includex("sprite") end
if(CLIENT) then includex("poly") end
if(CLIENT) then includex("input") end
if(CLIENT) then includex("view") end
includex("packs")
includex("custom")
--require "includes/functiondump"

ENTITYNUM_NONE = 1023
ENTITYNUM_WORLD	= 1022
ENTITYNUM_MAX_NORMAL = 1022

CONTENTS_SOLID = 1
CONTENTS_LAVA = 8
CONTENTS_SLIME = 16
CONTENTS_WATER = 32
CONTENTS_FOG = 64

if(SERVER) then
	local function message(str,pl)
		if(str == "_clientready") then
			CallHook("ClientReady",pl)
			--Timer(3.8,CallHook,"ClientReady",pl)
		elseif(str == "_demostarted") then
			CallHook("DemoStarted",pl)
		end
	end
	hook.add("MessageReceived","includes",message)
else
	hook.add("InitialSnapshot","includes",function() Timer(.1,SendString,"_clientready") end)
	
	local function demo()
		SendString("_demostarted")
	end
	hook.add("DemoStarted","includes",demo)	
end