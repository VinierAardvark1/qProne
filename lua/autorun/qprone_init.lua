-- Initial file
AddCSLuaFile()

hook.Add("Initialize", "qprone_INIT", function()
	include("qprone/tween.lua")
	include("qprone/qprone_main.lua")

	print("qProne loaded!")
end)