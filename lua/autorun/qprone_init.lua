-- Initial file

hook.Add("Initialize", "qprone_INIT", function()
	if SERVER then
		AddCSLuaFile("qprone/config.lua")
		AddCSLuaFile("qprone/tween.lua")
		AddCSLuaFile("qprone/qprone_main.lua")
	end

	include("qprone/config.lua")
	include("qprone/tween.lua")
	include("qprone/qprone_main.lua")

	print("qProne loaded!")
end)

-- local function Spawn(ply)
-- 	ply.NormalHeight = ply:GetViewOffset().z
-- end
-- hook.Add("PlayerSpawn", "PlayerViewOffset", Spawn)

if CLIENT then

	hook.Add("PopulateToolMenu", "qprone_options_MENU", function()
		spawnmenu.AddToolMenuOption("Options", "qProne Settings", "qprone_opts", "Controls", "", "", function(panel)
			panel:SetName("Controls")
			panel:AddControl("Header", {
				Text = "",
				Description = "Config menu for qProne."
			})

			panel:AddControl("Checkbox", {
				Label = "Enable Quick Prone",
				Command = "qprone_enabled"
			})

			panel:AddControl("Checkbox", {
				Label = "Double-tap to prone?",
				Command = "qprone_doubletap"
			})

			panel:AddControl("Checkbox", {
				Label = "Can press jump to get up",
				Command = "qprone_jump"
			})

			panel:AddControl("Checkbox", {
				Label = "Double-tap jump to get up",
				Command = "qprone_jump_doubletap"
			})

			panel:AddControl("Numpad", {
				Label = "Keybind",
				Command = "qprone_keybind"
			})
		end)
	end)
end