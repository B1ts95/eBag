if SERVER then
	AddCSLuaFile("shared.lua")
	include("sv_init.lua")
	util.AddNetworkString("printer_pocket")
end

if CLIENT then
	SWEP.PrintName = "Printers Bag"
	SWEP.Slot = 2
	SWEP.SlotPos = 1
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = true
end

SWEP.Author = "Unknown"
SWEP.Instructions = "Left click to pick up, right click to drop, reload for menu"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.IconLetter = ""

SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip = false
SWEP.ViewModel = Model("models/weapons/c_crowbar.mdl")
SWEP.WorldModel = Model("models/weapons/w_crowbar.mdl")
SWEP.Base = "weapon_cs_base2"
SWEP.Spawnable = false
SWEP.AdminSpawnable = true
SWEP.Category = "Thiefs Tool"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = ""
SWEP.Weight = 0

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = ""
SWEP.PrinterPocketTime = Bag.PrinterBagSpeed

function SWEP:Initialize()
	self:SetWeaponHoldType("normal")
	self:SetNWInt("holding", 0)
	self.Owner:SetNWInt("holding",0)
end

if CLIENT then
	net.Receive("printer_pocket", function()
		local wep = net.ReadEntity()
		local time = net.ReadUInt(5)

		wep.IsPocketingPrinter = true
		wep.StartPick = CurTime()
		wep.PrinterPocketTime = time
		wep.EndPick = CurTime() + time
	end)
end


function SWEP:PrimaryAttack()
	self.Weapon:SetNextPrimaryFire(CurTime() + Bag.PrintersPocketAttempt)
	
	if self.IsPocketingPrinter then
		return 
	end

	local trace = self.Owner:GetEyeTrace()
	local e = trace.Entity
	if not IsValid(e) or trace.HitPos:Distance(self.Owner:GetShootPos()) > (Bag.PrintersPocketDistance) then
		return
	end
	
	if not SERVER then 
		return 
	end
	
	local ent = self.Owner:GetEyeTrace().Entity
	local canPickup, message = hook.Call("canHoldPrinter", nil, self.Owner, ent)

	if ent:IsOnFire() then 
		if Bag.DarkRP24 then
			GAMEMODE:Notify(self.Owner, 1, 4, ("This printer is overheating run !"))
		else
			DarkRP.notify(self.Owner, 1, 4, ("This printer is overheating run !"))
		end
		return
	end

	if not canPickup then
		if message then DarkRP.notify(self.Owner, 1, 4, message) end
		return
	end

	if SERVER then
		self.IsPocketingPrinter = true
		self.StartPick = CurTime()

		if self.Owner:isbVIPMember() then
			self.PrinterPocketTime = Bag.PrinterVBagSpeed
		else
			self.PrinterPocketTime = Bag.PrinterBagSpeed
		end

		net.Start("printer_pocket")
			net.WriteEntity(self)
			net.WriteUInt(self.PrinterPocketTime, 5)
		net.Send(self.Owner)
		self.EndPick = CurTime() + self.PrinterPocketTime

		timer.Create("PocketingSounds", 1, self.PrinterPocketTime, function()
			if not IsValid(self) then return end
			local snd = {1,3,4}
			self:EmitSound("physics/body/body_medium_impact_soft".. tostring(snd[math.random(1, #snd)]) ..".wav", 50, 100)
		end)
	end
end

function SWEP:Holster()
	self.IsPocketingPrinter = false
	if SERVER then timer.Destroy("PocketingSounds") end
	if not SERVER then return true end
	
	self.Owner:DrawViewModel(true)
	self.Owner:DrawWorldModel(true)

	return true
end

function SWEP:Succeed()

	local ent = self.Owner:GetEyeTrace().Entity
	if ent:IsPlayer() then return false end
	if ent:GetClass() == "prop_physics" then 
	
	self.IsPocketingPrinter = false
	self:SetWeaponHoldType("normal")
	if SERVER then 
		timer.Destroy("PocketingSounds")
	end
	return false end
	local trace = self.Owner:GetEyeTrace()
	self.IsPocketingPrinter = false
	self:SetWeaponHoldType("normal")

	if SERVER then
		if IsValid(trace.Entity) then
			self.Owner:addPrinter(ent)
			if Bag.DarkRP24 then
				GAMEMODE:Notify(self.Owner, 2, 2, (Bag.StolenMsg))
			else
				DarkRP.notify(self.Owner, 2, 2, (Bag.StolenMsg))
			end
		end

		timer.Destroy("PocketingSounds") 
	end
	self:SetNWInt("holding", self:GetNWInt("holding") + 1)
	self.Owner:SetNWInt("holding", self.Owner:GetNWInt("holding") + 1)
	
end

function SWEP:Fail()
	self.IsPocketingPrinter = false
	self:SetWeaponHoldType("normal")
	
	if SERVER then 
		timer.Destroy("PocketingSounds")
	end
end

function SWEP:Think()
	if self.IsPocketingPrinter and self.EndPick then
		local trace = self.Owner:GetEyeTrace()
		
		if not IsValid(trace.Entity) then
			self:Fail()
		end
		
		if trace.HitPos:Distance(self.Owner:GetShootPos()) > Bag.PrintersPocketDistance  then
			self:Fail()
		end
			if trace.Entity:IsOnFire() then
				self:Fail()
				return
			end	
		if self.EndPick <= CurTime() then
			self:Succeed()
		end
	end
end



function SWEP:DrawHUD()
	if self.IsPocketingPrinter and self.EndPick then
		self.Dots = self.Dots or ""
		local w = ScrW()
		local h = ScrH()
		local x,y,width,height = w/2-w/10,ScrH() * 0.8, w/5, h/15
		local time = self.EndPick - self.StartPick
		local curtime = CurTime() - self.StartPick
		local status = curtime/time
		local BarWidth = status * (width - 16) + 8

		draw.RoundedBox(0, x-3, y - 30, width +5, 25 , Color(32,32,32,200))
		draw.RoundedBox(0, x-3, y - 30, width +5, 25 , Color(32,32,32,200))

		draw.RoundedBox(0, x-3, y -3, width +5, height , Color(32,32,32,200))
		draw.RoundedBox(0,  x-3, y -3	, width +5, height, Color(10,10,10,180))
		surface.SetDrawColor(Color(255-(status*255), 0+(status*255), 0, 255))
		surface.DrawOutlinedRect(x-3, y -3	, width +5, height)
		
		surface.DrawOutlinedRect(x-3, y -30	, width +5, 25)

		draw.RoundedBox(0, x+2, y+2, BarWidth, height - 10, Color(255-(status*255), 0+(status*255), 0, 100))
		draw.SimpleText(Bag.PickingUpMsg, "DarkRPHUD1", w/2, y-17, Color(255,255,255,200), 1, 1)
		if Bag.PrinterStatus then
			draw.SimpleText(math.Round(time-curtime), "DarkRPHUD1", w/2.01, ScrH() * 0.8 + height/2, Color(255,255,255,200), 1, 1)
		end
	end
end

function SWEP:SecondaryAttack()
	self.Weapon:SetNextSecondaryFire(CurTime() + Bag.PrintersUPocketInterval)
	if not SERVER then 
		return
	end
	local item = #self.Owner:getPPrintersItems()
	if item <= 0 then
		if Bag.DarkRP24 then
			GAMEMODE:Notify(self.Owner, 1, 4, Bag.EmptyBag)
			else 
			DarkRP.notify(self.Owner, 1, 4, Bag.EmptyBag)
		end
		return
	end

	self.Owner:dropPrinter(item)
	if self:GetNWInt("holding") > 0 then
		self:SetNWInt("holding", self:GetNWInt("holding") - 1)
		self.Owner:SetNWInt("holding", self.Owner:GetNWInt("holding") -1)
	else
		return false 
	end
end
