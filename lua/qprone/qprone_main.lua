AddCSLuaFile()
local meta = FindMetaTable("Player")

function meta:IsProne()
	return self:GetNW2Bool("IsLaying")
end

local function boolToNumString(bool)
	return bool and "1" or "0"
end

function meta:ToggleLay(arg)
	if CLIENT then RunConsoleCommand("qprone_lay")
	else return self:SetNW2Bool("IsLaying", arg) end
end

local wep_anims = {
	ar2			= "prone_ar2",
	camera		= "prone_camera",
	crossbow	= "prone_crossbow",
	duel		= "prone_crossbow",
	fist		= "prone_knife",
	grenade		= "prone_grenade",
	knife		= "prone_knife",
	magic		= "prone_knife",
	melee		= "prone_melee",
	melee2		= "prone_melee2",
	normal		= "prone_passive",
	passive		= "prone_passive",
	pistol		= "prone_pistol",
	physgun		= "prone_physgun",
	revolver	= "prone_revolver",
	rpg			= "prone_rpg",
	shotgun		= "prone_shotgun",
	slam		= "prone_slam",
	smg			= "prone_smg1"
}

qprone = {}
qprone.goProne = {}
qprone.goProne.MaxLaySpeed = 40
qprone.goProne.ViewZ = 25
qprone.goProne.Hull = 24

hook.Add("SetupMove", "laying_move", function(ply, mv, cmd)
	if ply:IsProne() then
		if mv:KeyDown(IN_JUMP) then mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP))) end
		if mv:KeyDown(IN_DUCK) then mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_DUCK))) end

		mv:SetMaxClientSpeed(qprone.goProne.MaxLaySpeed)
		mv:SetMaxSpeed(qprone.goProne.MaxLaySpeed)
	end
end)

hook.Add("EntityNetworkedVarChanged", "laying_nw_changed_behaviour", function(ply, name, old, b)
	if name == "IsLaying" && ply:IsPlayer() then
		if b then 
			ply:SetHull(Vector(-16, -16, 0), Vector(16, 16, qprone.goProne.Hull)) 
			ply:SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, qprone.goProne.Hull)) 
		else ply:ResetHull() end

		if SERVER then
			local from, to = (b && 64 || qprone.goProne.ViewZ), (b && qprone.goProne.ViewZ || 64)
			ply.layLerp = Tween(from, to, (to == qprone.goProne.ViewZ && 0.5) || 0.25, (to == qprone.goProne.ViewZ && TWEEN_EASE_BOUNCE_OUT) || TWEEN_EASE_SINE_IN ) ply.layLerp:Start()
		end
	end
end)

if CLIENT then
	local qprone_keybind = CreateClientConVar("qprone_keybind", 83, true, false, "This convar uses the numerical designation of each key. Go to Options > qProne Client Settings to change as normal.")
	local qprone_doubletap = CreateClientConVar("qprone_doubletap", 1, true, true, "Enables double tapping your keybind to go prone.")
	local qprone_jump = CreateClientConVar("qprone_jump", 1, true, true, "Enables using the jump key to exit prone.")
	local qprone_jump_doubletap = CreateClientConVar("qprone_jump_doubletap", 1, true, true, "Forces you to double tap jump to exit prone. Does nothing if qprone_jump = 0")
	local qprone_sprint = CreateClientConVar("qprone_sprint", 1, true, true, "Enables using the sprint key to exit prone.")
	local qprone_sprint_doubletap = CreateClientConVar("qprone_sprint_doubletap", 1, true, true, "Forces you to double tap sprint to exit prone. Does nothing if qprone_sprint = 0")
	local qprone_delay = CreateClientConVar("qprone_delay", 0.5, true, true, "Sets the delay between prone instances.", 0.5, 5, 2)
	local qprone_cantgetup = CreateClientConVar("qprone_cantgetup", 1, true, true, "Enable the error noise and chat message for trying to exit prone when not possible.")
	local last_request, resettime = 0, false
	local was_pressed, doubletap = false, true

	function lay_request(force)
		local ply = LocalPlayer()
		local b = !ply:GetNW2Bool("IsLaying")
		local tr = util.TraceEntity({ start = ply:GetPos(), endpos = ply:GetPos() + Vector(0, 0, 65 - qprone.goProne.Hull), filter = ply }, ply)

		if !b and tr.Hit and force != true then
			if qprone_cantgetup:GetBool() then
				ply:ChatPrint(qprone.goProne.CantGetUpText)
				ply:EmitSound("buttons/button17.wav")
				return
			else
				return
			end
		end

		if !ply:IsPlayer() or !ply:Alive() or ply:GetMoveType() == MOVETYPE_NOCLIP or ply:GetMoveType() == MOVETYPE_LADDER or !ply:OnGround() or ply:WaterLevel() > 2 then
			return
		end

		net.Start("lay_networking")
		net.WriteBool(b)
		net.SendToServer()
	end

	local qprone_jump_presstime, qprone_sprint_presstime = 0, 0

	hook.Add( "StartCommand", "laying_move_start", function( ply, cmd )
		if ply:OnGround() and !vgui.GetKeyboardFocus() and !gui.IsGameUIVisible() and !gui.IsConsoleVisible() and system.HasFocus() or system.IsLinux() then
			if input.IsKeyDown(qprone_keybind:GetInt()) then
				was_pressed = true
				resettime = CurTime() + 0.15
			else
				if was_pressed and last_request < CurTime() then
					doubletap = !doubletap
					if !qprone_doubletap:GetBool() or doubletap then
						lay_request()

						last_request = CurTime() + qprone_delay:GetFloat()
					end
				end

				was_pressed = false
			end
			if ply:IsProne() then
				if qprone_jump:GetBool() and ply:KeyPressed(IN_JUMP) then
					if !qprone_jump_doubletap:GetBool() then
						lay_request()
						cmd:RemoveKey(IN_JUMP)
					else
						if qprone_jump_presstime > CurTime() then
							lay_request()
							cmd:RemoveKey(IN_JUMP)
						else
							qprone_jump_presstime = CurTime() + qprone_delay:GetFloat()
						end
					end
				end
				if qprone_sprint:GetBool() and ply:KeyPressed(IN_SPEED) then
					if !qprone_sprint_doubletap:GetBool() then
						
						lay_request()
						cmd:RemoveKey(IN_SPEED)
					else
						if qprone_sprint_presstime > CurTime() then
							lay_request()
							cmd:RemoveKey(IN_SPEED)
						else
							qprone_sprint_presstime = CurTime() + qprone_delay:GetFloat()
						end
					end
				end
			end

			if resettime != false and resettime < CurTime() then
				resettime = false
				doubletap = true
			end
		end
	end)

	hook.Add("InitPostEntity","qprone_loadcfg", function()
		qprone.LP = LocalPlayer()
		qprone.goProne.CantGetUpText = "qProne | There is not enough room to get up here."
	end)
	
	hook.Add("PopulateToolMenu", "qprone_options_menu", function()
		spawnmenu.AddToolMenuOption("Options", "qProne", "qprone_opts", "Settings", nil, nil, function(panel)
			local sv, cl = vgui.Create("ControlPanel"), vgui.Create("ControlPanel")
			panel:AddItem(sv)
			panel:AddItem(cl)
			sv:SetName("Server")
			cl:SetName("Client")
			cl:Help("Config menu for qProne.")
			local binder = vgui.Create("DBinder")
			binder:SetConVar("qprone_keybind")
			cl:Help("Keybind")
			cl:AddItem(binder)
			
			sv:CheckBox("Enable Quick Prone", "qprone_enabled")
			cl:CheckBox("Double-tap to enter prone", "qprone_doubletap")
			cl:CheckBox([[Enable "Can't Get Up" error message]], "qprone_cantgetup")
			cl:CheckBox("Can press jump to exit prone", "qprone_jump")
			cl:CheckBox("Double-tap jump to exit prone", "qprone_jump_doubletap")
			cl:CheckBox("Can press sprint to exit prone", "qprone_sprint")
			cl:CheckBox("Double-tap sprint to exit prone", "qprone_sprint_doubletap")
			cl:NumSlider("qProne Delay", "qprone_delay", 0.5, 5, 2)
		end)
	end)
end

hook.Add("KeyPress", "qProne.Main", function(ply, key)
end)

hook.Add("CalcMainActivity", "laying_anim", function(p, vel)
	if (p:IsProne() and SERVER) and (p:GetMoveType() == MOVETYPE_NOCLIP or p:GetMoveType() == MOVETYPE_LADDER or p:WaterLevel() > 2) then
		p:ToggleLay(false)
	end

	if p.layLerp and p.layLerp.running then
		p:SetViewOffset(Vector(0, 0, p.layLerp:GetValue()))
	end

	if IsValid(p) and p:IsProne() then
		local seq = nil

		if vel:LengthSqr() >= 225 then
			seq = p:LookupSequence( "prone_walktwohand" )
		else
			local weapon, holdType = p:GetActiveWeapon(), nil
			if IsValid(weapon) then
				holdType = ((weapon:GetHoldType() != "" and weapon:GetHoldType()) or weapon.HoldType)
			end

			seq = p:LookupSequence(wep_anims[holdType] or "prone_ar2")
		end

		return -1, seq or "prone_ar2"
	end
end)


if SERVER then
	util.AddNetworkString("lay_networking")
	util.AddNetworkString("lay_networking_layanim")
	local l_enabled = CreateConVar("qprone_enabled", 1, {FCVAR_REPLICATED, FCVAR_ARCHIVE})

	net.Receive( "lay_networking", function( len, ply )
		if !l_enabled:GetBool() then
			ply:ToggleLay(false)
			return
		end
		local b = net.ReadBool()
		ply:ToggleLay(b)
	end)

	hook.Add("DoPlayerDeath", "laying_death_exit", function(ply)
		if ply:IsProne() then
			ply:ToggleLay(false)
		end
	end)

	hook.Add("PlayerSpawn", "prone.ExitOnDeath", function(ply)
		if ply:IsProne() then
			ply:ToggleLay(false)
		end
	end)
end