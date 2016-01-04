function ulx.printers(calling_ply, target_ply)
    
    if (#target_ply:getPrinters() == 0) then
    	calling_ply:ChatPrint("The user is not holding printers.")
    	return
    end
    calling_ply:ChatPrint(target_ply:Nick().." is currently holding:\n")
    calling_ply:ChatPrint(target_ply:getPrinters())
end
local printers = ulx.command("Printers Bag", "ulx printers", ulx.printers, "!printers",true)
printers:addParam{ type=ULib.cmds.PlayerArg }

printers:defaultAccess( ULib.ACCESS_ADMIN )
printers:help( "Get Target Printers." )


function getPrinters(ent, callback)
    for k,v in pairs(ents.GetAll()) do
    	if not (table.HasValue(ent:getPPrintersItems(), class) == table.HasValue(Bag.WhiteList, class)) then return end
        if not v:IsValid() then 
        	continue 
        end
        local class = v:GetClass()

        if (table.HasValue(Bag.WhiteList, class))then
            continue
        end
        callback(v)
    end
end