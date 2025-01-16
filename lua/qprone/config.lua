qprone = {}
qprone.goProne = {}
qprone.goProne.MaxLaySpeed = 40
qprone.goProne.ViewZ = 25
qprone.goProne.Hull = 24

if CLIENT then
    hook.Add("InitPostEntity","qprone_loadcfg", function()
        qprone.LP = LocalPlayer()
        qprone.goProne.CantGetUpText = "qProne | There is not enough room to get up here."
    end)
end