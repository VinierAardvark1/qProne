-- Initial file

hook.Add("Initialize", "qprone_INIT", function()
	if SERVER then
		AddCSLuaFile("qprone/tween.lua")
		AddCSLuaFile("qprone/qprone_main.lua")
	end

	include("qprone/tween.lua")
	include("qprone/qprone_main.lua")

	print("qProne loaded!")
end)