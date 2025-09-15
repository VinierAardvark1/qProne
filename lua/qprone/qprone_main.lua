local meta = FindMetaTable("Player")

function meta:IsProne()
    return self:GetNW2Bool("IsLaying")
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

hook.Add("SetupMove", "laying_move", function(ply, mv, cmd)
    if ply:IsProne() then
        if mv:KeyDown(IN_JUMP) then mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP))) end
        if mv:KeyDown(IN_DUCK) then mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_DUCK))) end

        mv:SetMaxClientSpeed(qprone.goProne.MaxLaySpeed)
        mv:SetMaxSpeed(qprone.goProne.MaxLaySpeed)
    end
end)

local cvarHeightEnabled = GetConVar("sv_dynamicheight")
local cvarHeightMaxManual = GetConVar("sv_dynamicheight_max_manual")
local cvarHeightMax = GetConVar("sv_dynamicheight_max")

local function UpdateView(ply)
    if cvarHeightEnabled:GetBool() then
    -- Find the max and min height by spawning a dummy entity
    local height_max = 64

    -- Finds model's height
    local entity = ents.Create("base_anim")
    local entity2 = ents.Create("base_anim")

    entity:SetModel(ply:GetModel())
    entity:ResetSequence(entity:LookupSequence("idle_all_01"))
    local bone = entity:LookupBone("ValveBiped.Bip01_Neck1")
        if bone then
            height_max = entity:GetBonePosition(bone).z + 5
        end

    -- Removes test entities
    entity:Remove()
    entity2:Remove()

    -- Update player height
    local max = cvarHeightMax:GetInt()

    if cvarHeightMaxManual:GetBool() then
        return max
    else
        return height_max
    end

    else
        if ply.ec_ViewChanged then
            ply.ec_ViewChanged = nil
        return 64
        end
    end
        return ply:GetViewOffset().z
  end

hook.Add("EntityNetworkedVarChanged", "laying_nw_changed_behaviour", function(ply, name, old, b)
    if name == "IsLaying" and ply:IsPlayer() then
        if b then -- Sets hull while prone.
            ply:SetHull(Vector(-16, -16, 0), Vector(16, 16, qprone.goProne.Hull))
            ply:SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, qprone.goProne.Hull))
        else
            ply:ResetHull()
        end

        if SERVER then
            local from, to, factor, mode
            if b then
                from = UpdateView(ply)
                to = qprone.goProne.ViewZ
                factor = 0.7
                mode = TWEEN_EASE_BOUNCE_OUT
            else
                from = qprone.goProne.ViewZ
                to = UpdateView(ply)
                factor = 0.3
                mode = TWEEN_EASE_SINE_IN
            end

            ply.layLerp = Tween(from, to, factor, mode)
            ply.layLerp:Start()
        end
    end

end)


if CLIENT then
    local qprone_keybind = CreateClientConVar("qprone_keybind", 83, true, false, "This convar uses the numerical designation of each key. Go to Options > qProne Client Settings to change as normal.")
    local qprone_doubletap = CreateClientConVar("qprone_doubletap", 1, true, false, "Enables double tapping your keybind to go prone.")
    local qprone_jump = CreateClientConVar("qprone_jump_enable", "1", 1, false, "Enables using the jump key to exit prone.")
    local qprone_jump_doubletap = CreateClientConVar("qprone_jump_doubletap", 1, true, false, "Forces you to double tap jump to exit prone. Does nothing if qprone_jump = 0")
    local qprone_delay = CreateClientConVar("qprone_delay", 0.00, true, false, "Sets the delay between prone instances.", 0, 10)

    local last_request, resettime = 0, false
    local was_pressed, doubletap = false, true

    function lay_request(force)
        local ply = qprone.LP
        local b = !ply:GetNW2Bool("IsLaying")
        local tr = util.TraceEntity({ start = ply:GetPos(), endpos = ply:GetPos() + Vector(0, 0, 65 - qprone.goProne.Hull), filter = ply }, ply)

        if !b and tr.Hit and force != true then
            ply:ChatPrint(qprone.goProne.CantGetUpText)
            ply:EmitSound("buttons/button17.wav")
            return
        end

        if !ply:IsPlayer() or !ply:Alive() or ply:GetMoveType() == MOVETYPE_NOCLIP or ply:GetMoveType() == MOVETYPE_LADDER or !ply:OnGround() or ply:WaterLevel() > 2 then return end

        net.Start("lay_networking")
        net.WriteBool(b)
        net.SendToServer()
    end

    hook.Add( "StartCommand", "laying_move_start", function( ply, mv )
        if ply:OnGround() and !vgui.GetKeyboardFocus() and !gui.IsGameUIVisible() and !gui.IsConsoleVisible() and system.HasFocus() or system.IsLinux() then
            if input.IsKeyDown(qprone_keybind:GetInt()) then
                was_pressed = true
                resettime = CurTime() + 0.11 -- Time between button presses in seconds (make into slider?)
            else
                if was_pressed and last_request < CurTime() then
                    doubletap = !doubletap
                    if !qprone_doubletap:GetBool() or doubletap then
                        lay_request()

                        last_request = CurTime() + qprone_delay:GetInt() -- Currently doesn't recognize any number after the decimal
                    end
                end

                was_pressed = false
            end

            if resettime != false and resettime < CurTime() then
                resettime = false
                doubletap = true
            end
        end
    end)

    concommand.Add( "qprone_lay", lay_request)
end

local qprone_jump_presstime = 0
hook.Add("KeyPress", "qProne.qProne_Jump", function(ply, key)
    if IsFirstTimePredicted() and ply:IsProne() and key == IN_JUMP then
        if qprone_jump_enable == 1 then
            ply:ToggleLay(false)
        else
            if qprone_jump_presstime > CurTime() then
                ply:ToggleLay(false)
            else
                qprone_jump_presstime = CurTime() + 0.4 -- qprone_delay:GetInt()
            end
        end
    end
end)

hook.Add("CalcMainActivity", "laying_anim", function(p, vel)
    if (p:IsProne() and SERVER) and (p:GetMoveType() == MOVETYPE_NOCLIP or p:GetMoveType() == MOVETYPE_LADDER or p:WaterLevel() > 2) then p:ToggleLay(false) end

    if p.layLerp and p.layLerp.running then
        p:SetViewOffset(Vector(0, 0, p.layLerp:GetValue()))
    end

    if IsValid(p) and p:IsProne() then
        local seq = nil

        if vel:LengthSqr() >= 225 then
            seq = p:LookupSequence( "prone_walktwohand" )
        else
            local weapon, holdType = p:GetActiveWeapon(), nil
            if IsValid(weapon) then holdType = ((weapon:GetHoldType() != "" and weapon:GetHoldType()) or weapon.HoldType) end

            seq = p:LookupSequence(wep_anims[holdType] or "prone_ar2")
        end

        return -1, seq or "prone_ar2"
    end
end)

if SERVER then
    util.AddNetworkString("lay_networking")
    util.AddNetworkString("lay_networking_layanim")
    local l_enabled = CreateConVar("qprone_enabled", 1, {FCVAR_REPLICATED, FCVAR_ARCHIVE})

    net.Receive( "lay_networking", function( len, ply ) if !l_enabled:GetBool() then ply:ToggleLay(false) return end
        local b = net.ReadBool()
        ply:ToggleLay(b)
    end)

    hook.Add("DoPlayerDeath", "laying_death_exit", function(ply)
        if ply:IsProne() then ply:ToggleLay(false) end
    end)

    hook.Add("PlayerSpawn", "prone.ExitOnDeath", function(ply)
        if ply:IsProne() then ply:ToggleLay(false) end
    end)
end