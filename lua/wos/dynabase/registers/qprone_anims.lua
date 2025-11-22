wOS.DynaBase:RegisterSource({
    Name = "qProne Animation",
    Type = WOS_DYNABASE.EXTENSION,

    -- model paths per gender:
    Shared = "models/police_ss.mdl",      -- default or neutral model
    Female = "models/f_anm.mdl",    -- female-specific model (optional)
    Male   = "models/m_anm.mdl"     -- optional if you have a male version
})

hook.Add("PreLoadAnimations", "wOS.DynaBase.MountqProne", function(gender)
    if gender == WOS_DYNABASE.SHARED then
        IncludeModel("models/police_ss.mdl")
    elseif gender == WOS_DYNABASE.FEMALE then
        IncludeModel("models/f_anm.mdl")
    elseif gender == WOS_DYNABASE.MALE then
        IncludeModel("models/m_anm.mdl")
    end
end)