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

local cvarHeightMax = GetConVar("sv_dynamicheight_max")
if cvarHeightMax then -- If Dynamic Height isn't installed this will be nil
    print(cvarHeightMax:GetInt()) -- This is the value to use for camera height
end

hook.Add("EntityNetworkedVarChanged", "laying_nw_changed_behaviour", function(ply, name, old, b)
    if name == "IsLaying" && ply:IsPlayer() then
        if b then -- Sets hull while prone.
            ply:SetHull(Vector(-16, -16, 0), Vector(16, 16, qprone.goProne.Hull))
            ply:SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, qprone.goProne.Hull))
        else
            ply:ResetHull()
        end
 
        if SERVER then
            local from, to = (b && cvarHeightMax:GetInt() + 0 || qprone.goProne.ViewZ), (b && qprone.goProne.ViewZ || cvarHeightMax:GetInt() + 0) -- This sets the view height  gdi
            ply.layLerp = Tween(from, to, (to == qprone.goProne.ViewZ && 0.7) || 0.3, (to == qprone.goProne.ViewZ && TWEEN_EASE_BOUNCE_OUT) || TWEEN_EASE_SINE_IN ) ply.layLerp:Start()
        end
    end
end)

if CLIENT then
    local sprint_keybind = CreateClientConVar("qprone_keybind", 83, true, false, "This convar uses the numerical designation of each key. Go to Options > qProne Client Settings to change as normal.")
    local is_doubletap = CreateClientConVar("qprone_doubletap", 1, true, false, "Enables double tapping your keybind to go prone. 1 is true, 0 is false.")
    local last_request, resettime = 0, false
    local was_pressed, doubletap = false, true

    function lay_request(force)
        local ply = qprone.LP
        local b = !ply:GetNW2Bool("IsLaying")
        local tr = util.TraceEntity({ start = ply:GetPos(), endpos = ply:GetPos() + Vector(0, 0, 65 - qprone.goProne.Hull), filter = ply }, ply)

        if !b && tr.Hit && force != true then
            ply:ChatPrint(qprone.goProne.CantGetUpText)
            ply:EmitSound("buttons/button17.wav")
            return
        end

        if !ply:IsPlayer() || !ply:Alive() || ply:GetMoveType() == MOVETYPE_NOCLIP || ply:GetMoveType() == MOVETYPE_LADDER || !ply:OnGround() || ply:WaterLevel() > 2 then return end

        net.Start("lay_networking")
        net.WriteBool(b)
        net.SendToServer()
    end

    hook.Add( "StartCommand", "laying_move_start", function( ply, mv )
        if ply:OnGround() && !vgui.GetKeyboardFocus() && !gui.IsGameUIVisible() && !gui.IsConsoleVisible() && system.HasFocus() or system.IsLinux() then
            if input.IsKeyDown(sprint_keybind:GetInt()) then 
                was_pressed = true
                resettime = CurTime() + 0.11 -- Time between button presses in seconds (make into slider?)
            else 
                if was_pressed then 
                    if last_request < CurTime() then
                        doubletap = !doubletap
                        if !is_doubletap:GetBool() || doubletap then
                            lay_request() 
                        end
                    end
                end 

                was_pressed = false
            end

            if resettime ~= false && resettime < CurTime() then
                resettime = false
                doubletap = true
            end
        end
    end)
    
    concommand.Add( "qprone_lay",lay_request)
end

hook.Add("CalcMainActivity", "laying_anim", function(p, vel)
    if (p:IsProne() && SERVER) && (p:GetMoveType() == MOVETYPE_NOCLIP || p:GetMoveType() == MOVETYPE_LADDER || p:WaterLevel() > 2) then p:ToggleLay(false) end
    
    if p.layLerp then
        p:SetViewOffset(Vector(0, 0, p.layLerp:GetValue()))
    end

    if IsValid(p) && p:IsProne() then
        local seq = nil
        
        if vel:LengthSqr() >= 225 then
            seq = p:LookupSequence( "prone_walktwohand" )
        else
            local weapon, holdType = p:GetActiveWeapon(), nil
            if IsValid(weapon) then holdType = ((weapon:GetHoldType() != "" && weapon:GetHoldType()) || weapon.HoldType) end

            seq = p:LookupSequence(wep_anims[holdType] || "prone_ar2")
        end

        return -1, seq || "prone_ar2"
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
end