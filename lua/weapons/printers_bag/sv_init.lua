local meta = FindMetaTable("Player")

local function getDTVars(ent)
	if not ent.GetNetworkVars then return nil end
	local name, value = debug.getupvalue(ent.GetNetworkVars, 1)
	if name ~= "datatable" then
		ErrorNoHalt("Warning: Datatable cannot be stored properly in pocket. Tell a developer!")
	end

	local res = {}

	for k,v in pairs(value) do
		res[k] = v.GetFunc(ent, v.index)
	end

	return res
end

local function serialize(ent)
	local serialized = duplicator.CopyEntTable(ent)
	serialized.DT = getDTVars(ent)
	serialized.printerPocket = ent.printerPocket or {}
	serialized.ownCooler = ent.ownCooler or false;
	serialized.ownAmount = ent.ownAmount or false;
	serialized.ownTimer = ent.ownTimer or false;
	serialized.ownSilencer = ent.ownSilencer or false;
	serialized.ownArmor = ent.ownArmor or false;
	serialized.ownStealing = ent.ownStealing or false;
	serialized.owner = ent.owner or ""
	serialized.StoredMoney = ent.StoredMoney or 0

	return serialized
end

local function deserialize(ply, item)
	local ent = ents.Create(item.Class)
	duplicator.DoGeneric(ent, item)
	ent.printerPocket = item.printerPocket
	ent.ownCooler = item.ownCooler
	ent.ownAmount = item.ownAmount
	ent.ownTimer = item.ownTimer
	ent.ownSilencer = item.ownSilencer
	ent.ownArmor = item.ownArmor
	ent.ownStealing = item.ownStealing
	ent.owner = item.owner
	ent.StoredMoney = item.StoredMoney
	ent:Spawn()

	duplicator.DoGenericPhysics(ent, ply, item)
	table.Merge(ent:GetTable(), item)

	local pos, mins = ent:GetPos(), ent:WorldSpaceAABB()
	local offset = pos.z - mins.z

	local trace = {}
	trace.start = ply:EyePos()
	trace.endpos = trace.start + ply:GetAimVector() * 85
	trace.filter = ply

	local tr = util.TraceLine(trace)
	ent:SetPos(tr.HitPos + Vector(0, 0, offset))

	local phys = ent:GetPhysicsObject()
	if phys:IsValid() then phys:Wake() end

	return ent
end

local function dropAllPrintersItems(ply)
	for k,v in pairs(ply.printerPocket or {}) do
		ply:dropPrinter(k)
		ply:SetNWInt("holding", 0)
	end
end

util.AddNetworkString("Printer_Pocket")
local function sendPPrintersItems(ply)
	net.Start("Printer_Pocket")
		net.WriteTable(ply:getPPrintersItems())
	net.Send(ply)
end

/*---------------------------------------------------------------------------
Interface functions
---------------------------------------------------------------------------*/
function meta:addPrinter(ent)
	if not IsValid(ent) then error("Entity not valid", 2) end

	local serialized = serialize(ent)

	hook.Call("onPrinterItemAdded", nil, self, ent, serialized)

	ent:Remove()

	self.printerPocket = self.printerPocket or {}

	local id = table.insert(self.printerPocket, serialized)
	sendPPrintersItems(self)
	return id
end

function meta:removePrinter(item)
	if not self.printerPocket or not self.printerPocket[item] then error("Player does not contain " .. item .. " in their pocket.", 2) end

	hook.Call("onPrinterItemRemoved", nil, self, item)

	self.printerPocket[item] = nil
	sendPPrintersItems(self)

end

function meta:dropPrinter(item)
	if not self.printerPocket or not self.printerPocket[item] then error("Player does not contain " .. item .. " in their pocket.", 2) end

	local id = self.printerPocket[item]
	local ent = deserialize(self, id)

	self:removePrinter(item)
	ent:Spawn()
	return ent
end

function meta:getPPrintersItems()
	self.printerPocket = self.printerPocket or {}

	local res = {}
	for k,v in pairs(self.printerPocket) do
		res[k] = {
			model = v.Model,
			class = v.Class
		}
	end

	return res
end

util.AddNetworkString("DarkRP_spawnPrinterPocket")
net.Receive("DarkRP_spawnPrinterPocket", function(len, ply)
	local item = net.ReadFloat()
	if not ply.printerPocket[item] then return end
	ply:dropPrinter(item)
end)

local function onAdded(ply, ent, serialized)
	if not ent:IsValid() or not ent.DarkRPItem or not ent.Getowning_ent or not IsValid(ent:Getowning_ent()) then return end

	local ply = ent:Getowning_ent()
	local cmdname = string.gsub(ent.DarkRPItem.ent, " ", "_")

	ply:addCustomEntity(ent.DarkRPItem)
end


hook.Add("onPrinterItemAdded", "defaultImplementation", onAdded)

local function canHoldPrinter(ply, item)
	if not IsValid(item) then return false end
	local class = item:GetClass()

	if item.jailWall then return false, Bag.JailWall end
	if not Bag.WhiteList[class] then return false, Bag.WhiteListMsg end
	if string.find(class, "func_") then return false, Bag.func_ end

	local trace = ply:GetEyeTrace()
	if ply:EyePos():Distance(trace.HitPos) > 150 then return false end

	local phys = trace.Entity:GetPhysicsObject()
	if not phys:IsValid() then return false end

	local mass = trace.Entity.RPOriginalMass and trace.Entity.RPOriginalMass or phys:GetMass()
	if mass > 100 then return false, (Bag.Heavy) end

	local job = ply:Team()

	if ply:isbVIPMember() then
		size = Bag.PrintersVAmount
	else
		size = Bag.PrintersAmount
	end
	
	if table.Count(ply.printerPocket or {}) >= size then return false, Bag.Full end
	return true


end
hook.Add("canHoldPrinter", "defaultRestrictions", canHoldPrinter)

hook.Add("PlayerDeath", "DropPrinters", function(ply)
	if not Bag.DropPrintersOnDead or not ply.printerPocket then return end
	dropAllPrintersItems(ply)
end)

hook.Add("playerArrested", "DropPrinters", function(ply)
	if not Bag.DropPrintersArrested then return end
	dropAllPrintersItems(ply)
end)
hook.Add("PlayerDisconnected", "DropPrinters", function(ply)
	if not Bag.DropPrintersOnDisconnect  then return end
	dropAllPrintersItems(ply)
end)
