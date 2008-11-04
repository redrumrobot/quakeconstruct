D_SHORT = 0
D_LONG = 1
D_STRING = 2
D_FLOAT = 3

local msgIDs = {}
local strings = {}
strings[D_SHORT] = "Short"
strings[D_LONG] = "Long"
strings[D_STRING] = "String"
strings[D_FLOAT] = "Float"

message = {}

if(SERVER) then
	local nextid = 1
	local funcs = {}
	funcs[D_SHORT] = _message.WriteShort
	funcs[D_LONG] = _message.WriteLong
	funcs[D_STRING] = _message.WriteString
	funcs[D_FLOAT] = _message.WriteFloat

	local function check(m)
		if(m != nil and m.ismessage) then
			return true
		end
		return false
	end
	
	local function checkData(v,t)
		if(t == nil) then return false end
		if(t < D_SHORT or t > D_FLOAT) then return false end
		if(t == D_STRING and type(v) != "string") then return false end
		if(t == D_SHORT and type(v) != "number") then return false end
		if(t == D_LONG and type(v) != "number") then return false end
		if(t == D_FLOAT and type(v) != "number") then return false end
		return true
	end
	
	local function addData(m,v,t)
		if(!checkData(v,t)) then return end
		if(check(m)) then table.insert(m,{v,t})end
	end

	function Message(pl,msgid)
		local tab = {}
		tab.ismessage = true
		tab.pl = pl
		tab.msgid = msgid
		return tab
	end
	
	function message.WriteShort(m,s)
		addData(m,s,D_SHORT)
	end
	
	function message.WriteLong(m,s)
		addData(m,s,D_LONG)
	end
	
	function message.WriteString(m,s)
		addData(m,s,D_STRING)
	end
	
	function message.WriteFloat(m,s)
		addData(m,s,D_FLOAT)
	end
	
	local d_Message = _Message
	local d_Send = _SendDataMessage
	
	local function MessageID(pl,id)
		if(msgIDs[id] == nil) then
			msgIDs[id] = nextid
			nextid = nextid + 1
		end
		if(pl != nil and pl:GetTable()._mconnected) then
			local tab = pl:GetTable()
			tab.msglist = tab.msglist or {}
			if(tab.msglist[id] != true) then
				local msg = d_Message(pl,2)
				_message.WriteLong(msg,msgIDs[id])
				_message.WriteString(msg,id)
				d_Send(msg)
				tab.msglist[id] = true
				return nil
			end
		else
			error("^5MESSAGE ERROR: Unable to send message to player (player was not connected)\n")
			return nil
		end
		return msgIDs[id]
	end
	
	local function SendCache(pl)
		if(pl == nil) then error("^5MESSAGE ERROR: Unable to send cache to player (player was nil)\n") return end
		local tab = pl:GetTable()
		tab.msglist = tab.msglist or {}
		
		local send = {}
		for k,v in pairs(msgIDs) do
			if(tab.msglist[k] != true) then
				print(k .. " - " .. v .. "\n")
				if(k != nil and v != nil) then
					table.insert(send, {v,k})
				end
				tab.msglist[k] = true
			end
		end
		local ts = #send
		local msg = d_Message(pl,3)
		_message.WriteLong(msg,ts)
		for i=1, ts do
			local v = send[i]
			debugprint("Send: " .. v[1] .. "->" .. v[2] .. "\n")
			_message.WriteLong(msg,v[1])
			_message.WriteString(msg,v[2])
		end
		d_Send(msg)
	end
	
	function message.Precache(str)
		if(str != nil and type(str) == "string") then
			if(msgIDs[str] == nil) then
				msgIDs[str] = nextid
				nextid = nextid + 1
				
				for k,v in pairs(GetAllPlayers()) do
					if(v:GetTable()._mconnected) then
						SendCache(v)
					end
				end
			end
		else
			error("^5MESSAGE ERROR: Failure to precache message (Use String)\n")
		end
	end
	
	function SendDataMessage(m,pl,msgid)
		if(check(m)) then
			pl = pl or m.pl
			msgid = msgid or m.msgid
			if(pl:IsBot()) then return end
			if(pl == nil) then error("^5MESSAGE ERROR: Nil Player\n") end
			if(msgid == nil) then error("^5MESSAGE ERROR: Nil Message Id\n") end
			msgid = string.lower(msgid)
			local msgid = MessageID(pl,tostring(msgid))
			if(msgid == nil) then print("^5Forced Message Precache\nUse message.Precache(name)\n") return end
			
			local msg = d_Message(pl,1)
			local contents = ""
			for k,v in pairs(m) do
				if(type(v) == "table") then
					local dtype = v[2]
					if(dtype != nil) then
						contents = contents .. tostring(dtype)
					end
				end
			end
			_message.WriteLong(msg,tonumber(contents))
			_message.WriteLong(msg,msgid)
			for k,v in pairs(m) do
				if(type(v) == "table") then
					local data = v[1]
					local dtype = v[2]
					if(checkData(v,t)) then print("^5MESSAGE ERROR: Ivalid Data\n") return end
					local b,e = pcall(funcs[dtype],msg,data)
					if(!b) then
						error("^5MESSAGE ERROR: " .. e .. "\n")
					end
				end
			end
			d_Send(msg)
		end
	end
	
	local function PlayerJoined(pl)
		pl:GetTable()._mconnected = true
		SendCache(pl)
	end
	hook.add("ClientReady","messages",PlayerJoined)
end

if(CLIENT) then
	local stack = {}
	local funcs = {}
	funcs[D_SHORT] = _message.ReadShort
	funcs[D_LONG] = _message.ReadLong
	funcs[D_STRING] = _message.ReadString
	funcs[D_FLOAT] = _message.ReadFloat
	
	local function readData(t)
		local d = stack[1]
		
		if(d == nil) then
			error("^5MESSAGE ERROR: OverRead Data\n")
			return
		end
		
		local data = d[1]
		local dtype = d[2]
		table.remove(stack,1)
		
		if(dtype == t) then return data end
		
		error("^5MESSAGE ERROR: Invalid Data (Skipped?)\n")
		
		if(t == D_STRING) then return "" end
		return 0
	end
	
	function message.ReadShort()
		return readData(D_SHORT)
	end
	
	function message.ReadLong()
		return readData(D_LONG)
	end
	
	function message.ReadString()
		return readData(D_STRING)
	end
	
	function message.ReadFloat()
		return readData(D_FLOAT)
	end
	
	local function handle(msgid)
		if(msgid == 1) then
			local contents = tostring(_message.ReadLong())
			local strid = _message.ReadLong()
			if(msgIDs[strid] == nil) then
				print("^5MESSAGE ERROR: Invalid Message ID: " .. strid .. "\n")
			end
			contents = string.ToTable(contents)
			for k,v in pairs(contents) do
				v = tonumber(v)
				local b,e = pcall(funcs[v])
				if(!b) then
					error("^5MESSAGE ERROR: " .. e .. "\n")
				else
					if(e != nil) then
						table.insert(stack,{e,v})
					end
				end
			end
			CallHook("HandleMessage",msgIDs[strid],contents)
			stack = {}
		elseif(msgid == 2) then
			local id = _message.ReadLong()
			local str = _message.ReadString()
			msgIDs[id] = str
			debugprint("Got messageID: " .. id .. "->" .. str .. "\n")
		elseif(msgid == 3) then
			local count = _message.ReadLong()
			for i=1, count do
				local id = _message.ReadLong()
				local str = _message.ReadString()
				msgIDs[id] = str
				debugprint("Got messageID: " .. id .. "->" .. str .. "\n")
			end
		else
			error("^5MESSAGE ERROR: Invalid Internal Message ID\n")
		end
	end
	hook.add("_HandleMessage","messages",handle)
	hook.lock("_HandleMessage")
	
	local function report(msgid,contents)
		debugprint("Message Received: " .. msgid .. "\nContents:\n")
		for k,v in pairs(contents) do
			v = tonumber(v)
			debugprint(strings[v] .. ",")
		end
		debugprint("EOM\n")
	end
	hook.add("HandleMessage","messages",report)
end

_SendDataMessage = nil
_Message = nil