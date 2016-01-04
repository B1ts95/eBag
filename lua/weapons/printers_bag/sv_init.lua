local meta = FindMetaTable("Player")

/*---------------------------------------------------------------------------
Functions
---------------------------------------------------------------------------*/
-- workaround: GetNetworkVars doesn't give entities because the /duplicator/ doesn't want to save entities
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

	return serialized
end

local function deserialize(ply, item)
	local ent = ents.Create(item.Class)
	duplicator.DoGeneric(ent, item)
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

function printerName(ent)
	if ent == "money_printer2" 		then return Prc.PrinterName2
	elseif ent == "money_printer0" 	then return Prc.PrinterName
	elseif ent == "money_printer3" 	then return Prc.printerName3
	elseif ent == "money_printer4" 	then return Prc.printerName4
	elseif ent == "money_printer5" 	then return Prc.printerName5	
	elseif ent == "money_printer6" 	then return Prc.printerName6
	elseif ent == "money_printer7" 	then return Prc.printerName7
	elseif ent == "money_printer8" 	then return Prc.printerName8
	elseif ent == "money_printer9" 	then return Prc.printerName9
	elseif ent == "money_printer10"	then return Prc.printerName10
	end
end

function meta:getPrinters()
	local result = {}
	for k,v in pairs(self.printerPocket or {}) do
		table.insert(result, printerName(v.Class))
	end
	result = table.concat(result, "\n");
	return result
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

	ent.USED = nil

	hook.Call("onPocketItemDropped", nil, self, ent, item, id)

	self:removePrinter(item)
	ent:Spawn()
	return ent
end



-- serverside implementation
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

/*---------------------------------------------------------------------------
Commands
---------------------------------------------------------------------------*/
util.AddNetworkString("DarkRP_spawnPrinterPocket")
net.Receive("DarkRP_spawnPrinterPocket", function(len, ply)
	local item = net.ReadFloat()
	if not ply.printerPocket[item] then return end
	ply:dropPrinter(item)
end)

/*---------------------------------------------------------------------------
Hooks
---------------------------------------------------------------------------*/

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

-- Drop printers when:

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