--[[ PrintersBag by Unknown ]]

local plyMeta = FindMetaTable("Player")
Bag = {}

Bag.isVIP = {"vip", "superadmin", "owner"} // want more groups? add a coma and the usergroup, for example "vip", "goldvip", "premiumvip"

-- VIP Members Configurations ( DO NOT TOUCH THIS )
-- ==========================
function plyMeta:isbVIPMember()
	local groups = self:GetNWString("usergroup")
	groups = string.lower(groups)
	if not IsValid(self) then return false end
	return table.HasValue(Bag.isVIP,groups)
end
-- ==============================================

-- Printers Version ( If you're using 2.4.x set DakrRP24 = true )
--======================================================================================================
Bag.DarkRP24 = false
--======================================================================================================


-- Printers Bag Configuration ( Version 2 )
--======================================================================================================
Bag.PrintersAmount = 2
Bag.PrintersVAmount = 5
Bag.PrinterBagSpeed = 20
Bag.PrinterVBagSpeed = 5
Bag.PrinterStatus = true -- If true then there's going to be a timer until you "bag" the printer ( c.down)
Bag.PrintersPocketDistance = 100 -- Distance allowed to hold printers in your bag ( default: 100 )
Bag.PrintersPocketAttempt = 2 -- Time between attempts to hold printers in your bag ( default: 2 )
Bag.PrintersUPocketInterval = 2 -- Time between attempts to drop printers from your bag ( default: 2 )
Bag.DropPrintersOnDead = true -- ( default: false / set true to drop printers on dead )
Bag.DropPrintersArrested = true -- ( default: false / set true to drop printers when you get arrested )
Bag.DropPrintersOnDisconnect = true  -- default: true, drop the printers if the user disconnect
Bag.ShowSize = true
--======================================================================================================


-- Bagable Printers 
--======================================================================================================
Bag.WhiteList = { -- ( default: "money_printer" , you can add more by typing: ["printer_name"] = true, )
	["money_printer0"] = true,
	["money_printer2"] = true,
	["money_printer3"] = true,
	["money_printer4"] = true,
	["money_printer5"] = true,
	["money_printer6"] = true,
	["money_printer7"] = true,
	["money_printer8"] = true,
	["money_printer9"] = true,
	["money_printer10"] = true,
} 
--======================================================================================================


-- Messages Customization
--======================================================================================================
Bag.CannotPlaceItem = ("You're not allowed to place this item in your bag") -- Not allowed to pick it up
Bag.JailWall = ("You're not allowed to place this item in your bag") -- Jail Stuff
Bag.WhiteListMsg = ("You're not allowed to place this item in your bag") -- Is not in WhiteList
Bag.EmptyBag = ("Your bag doesn't contain Printers") -- If the bag is empty this is the message.
Bag.StolenMsg = ("You've stolen the printer successfully")
Bag.PickingUpMsg = ("Placing printer into bag")
Bag.func_ = ("You're not allowed to place this item in your bag") -- func_ ( server )
Bag.Heavy = ("This object is too heavy to place it in your bag") -- Heavy Item
Bag.Full = ("Your bag is full, you can't place more items inside") -- Bag Full
--======================================================================================================
