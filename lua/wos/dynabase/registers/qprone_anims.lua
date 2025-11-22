wOS.DynaBase:RegisterSource({
    Name = "qProne Animation",
    Type = WOS_DYNABASE.EXTENSION,

    -- model paths per gender:
    Shared = "models/player/wiltos/anim_extension_prone.mdl",      -- default or neutral model
    Female = "models/player/wiltos/anim_extension_prone.mdl",    -- female-specific model (optional)
    Male   = "models/player/wiltos/anim_extension_prone.mdl"     -- optional if you have a male version
})

hook.Add("PreLoadAnimations", "wOS.DynaBase.MountqProne", function(gender)
    if gender == WOS_DYNABASE.SHARED then
        IncludeModel("models/player/wiltos/anim_extension_prone.mdl")
    elseif gender == WOS_DYNABASE.FEMALE then
        IncludeModel("models/player/wiltos/anim_extension_prone.mdl")
    elseif gender == WOS_DYNABASE.MALE then
        IncludeModel("models/player/wiltos/anim_extension_prone.mdl")
    end
end)