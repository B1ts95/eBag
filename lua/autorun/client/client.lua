function DrawHUD()
	if not LocalPlayer():Alive() then return end
	if LocalPlayer():Alive() and IsValid(LocalPlayer()) then
		if Bag.ShowSize and LocalPlayer():GetActiveWeapon():GetClass() == "printers_bag" then
			draw.RoundedBox(0, ScrW() * 0.9375, ScrH() * 0.0092592592592593, ScrW() * 0.0520833333333333, ScrH() * 0.0416666666666667 , Color(32,32,32,200))
			surface.SetDrawColor(Color(62,62,62,255))
			surface.DrawOutlinedRect(ScrW() * 0.9375,ScrH() * 0.0092592592592593,ScrW() * 0.0520833333333333,ScrH() * 0.0416666666666667)
			draw.SimpleText("Printers", "DarkRPHUD1", ScrW() * 0.9619791666666667, ScrH()* 0.0185185185185185, Color(255,255,255,200), 1, 1)
			if LocalPlayer():isbVIPMember() then
				draw.SimpleText(LocalPlayer():GetNWInt("holding").." / "..Bag.PrintersVAmount, "DarkRPHUD1", ScrW() * 0.9619791666666667, ScrH() * 0.037037037037037, Color(255,255,255,200), 1, 1)
			else
				draw.SimpleText(LocalPlayer():GetNWInt("holding").." / "..Bag.PrintersAmount, "DarkRPHUD1", ScrW() * 0.9619791666666667, ScrH() * 0.037037037037037, Color(255,255,255,200), 1, 1)
			end
		end
	end
end
hook.Add("HUDPaint", "DrawHUD", DrawHUD)