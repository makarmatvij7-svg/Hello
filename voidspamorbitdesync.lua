--[[
    Rivals Raging Comp â€” Delta Mobile Rebuild
    Same void methods, orbit, desync, evasion as original
    No LinoriaLib Â· No HttpGet Â· No setfflag Â· No keypress
    Works on Delta mobile confirmed
    Tap âšˇ to open menu
]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Camera     = workspace.CurrentCamera
local LP         = Players.LocalPlayer
local Debris     = game:GetService("Debris")

-- Camera hook stored for UI status display
local _E = {}; pcall(function() _E = getfenv() end)
local hasHook = type(_E.hookmetamethod) == "function"
local _orbitActive = false

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- CONFIG
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local CFG = {
    -- Void
    VOID_ENABLED        = false,
    VOID_METHOD         = "Quantum Tunneling",
    VOID_BYPASS_MODE    = "Extreme Networking",
    VOID_DRIFT_SPEED    = 9e6,
    VOID_DRIFT_CHAOS    = 0.98,
    VOID_Y_BASE         = 1e10 + (math.random()*10e9 - 5e9) + 7369123,
    VOID_Y_DRIFT_SPEED  = 4e6,
    VOID_Y_DRIFT_RANGE  = 2e9,
    VOID_SCRAMBLE       = true,
    VOID_SCRAMBLE_TIME  = 1.2,
    VOID_ANCHOR_THRESH  = 50,
    VOID_EVADE          = true,
    VOID_EVADE_RADIUS   = 8e9,
    VOID_EVADE_SPEED    = 6e9,
    VOID_EVADE_COOLDOWN = 0.05,
    VOID_EVADE_VERT     = 3e9,
    VOID_EVADE_VERT_BIAS= 0.5,
    VOID_EVADE_FORCE_UP = false,
    VOID_LISSAJOUS_A    = 2,
    VOID_LISSAJOUS_B    = 3,
    VOID_FLICKER_INT    = 0.05,
    VOID_GRAVITY_STR    = 1e8,
    VOID_GHOSTING       = false,
    VOID_GHOSTING_INT   = 0.5,
    VOID_Y_DRIFT_RANGE_V= 10,  -- UI display value (B)
    VOID_SCRAMBLE_INT   = 12,
    VOID_FLICKER_MS     = 5,
    VOID_GRAVITY_M      = 100,

    -- Desync
    DESYNC_ENABLED      = true,
    DESYNC_TICK         = 0.18,
    DESYNC_SPOOF_Y      = 3,
    DESYNC_RADIUS       = 22,
    DESYNC_WANDER_SPEED = 3.5,
    DESYNC_WANDER_CHAOS = 0.4,

    -- Orbit
    ORBIT_ENABLED       = false,
    ORBIT_SPEED         = 5,
    ORBIT_MODE          = "Default",
    ORBIT_STABILITY     = 1,
    ORBIT_JITTER        = 0,
    HEIGHT_OFFSET       = 50000,
    ELLIPSE_RATIO       = 0.65,
    MIN_RADIUS          = 200000,
    MAX_RADIUS          = 12e9,
    LOCK_FOV            = 120,
    PREDICTION          = 0.22,
    CAM_LERP_BASE       = 0.12,
    AUTO_LOCK           = false,
    AUTO_LOCK_RADIUS    = 200,
    KILL_HP             = 0,

    -- Kill Notifier
    KILL_NOTIFIER       = true,
    -- Desync standalone
    DESYNC_STANDALONE   = false,

    -- Extras
    SPEED_ENABLED       = false,
    WALK_SPEED          = 35,
    INF_JUMP            = false,
    NOCLIP              = false,
    LOW_GRAVITY         = false,
    GRAVITY_VAL         = 50,
    FPS_BOOST           = false,
}

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- HELPERS
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local function clamp(x,a,b) return x<a and a or x>b and b or x end
local function getHRP()
    local c=LP.Character; return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c=LP.Character; return c and c:FindFirstChildOfClass("Humanoid")
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- VOID SYSTEM â€” exact same logic as original
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local elapsed         = 0
local voidX           = (math.random()-0.5)*2e8
local voidZ           = (math.random()-0.5)*2e8
local voidYOffset     = 0
local voidYDir        = 1
local voidDirX        = math.random()*2-1
local voidDirZ        = math.random()*2-1
local voidScrambleT   = 0
local voidEvadeCD     = 0
local intendedVoidPos = Vector3.new(voidX, CFG.VOID_Y_BASE, voidZ)
local desyncTimer     = 0
local spoofAngle      = math.random()*math.pi*2
local spoofAngleDir   = (math.random()>0.5) and 1 or -1
local spoofBaseX,spoofBaseZ = 0,0
local fakeGroundPos   = Vector3.new(0, CFG.DESYNC_SPOOF_Y, 0)
local inFlicker       = false
local voidConn        = nil

local function computeVoidDriftDir(t)
    local nx,nz,amp,freq = 0,0,1,0.0001
    for i=1,4 do
        nx=nx+math.noise(t*freq,0)*amp
        nz=nz+math.noise(0,t*freq)*amp
        freq=freq*2.37; amp=amp*0.5
    end
    local sp=t*0.00073
    nx=nx+math.noise(sp+13.7,7.3)*0.3
    nz=nz+math.noise(sp+31.1,17.9)*0.3
    local cp=t*0.00213
    nx=nx+math.sin(cp)*math.cos(cp*1.618)*0.2
    nz=nz+math.cos(cp*0.618)*math.sin(cp*2.718)*0.2
    local len=math.sqrt(nx*nx+nz*nz)
    if len<0.001 then
        local a=t*3.14159*0.1; return math.cos(a),math.sin(a)
    end
    return nx/len,nz/len
end

local function stepVoidDrift(dt)
    local p=Vector3.new(voidX,CFG.VOID_Y_BASE+voidYOffset,voidZ)
    local m=CFG.VOID_METHOD
    if m=="Stable" then return p
    elseif m=="Drift" then
        local dx,dz=computeVoidDriftDir(elapsed)
        voidDirX=voidDirX+(dx-voidDirX)*CFG.VOID_DRIFT_CHAOS*dt*10
        voidDirZ=voidDirZ+(dz-voidDirZ)*CFG.VOID_DRIFT_CHAOS*dt*10
        voidX=voidX+voidDirX*CFG.VOID_DRIFT_SPEED*dt
        voidZ=voidZ+voidDirZ*CFG.VOID_DRIFT_SPEED*dt
        voidYOffset=voidYOffset+voidYDir*CFG.VOID_Y_DRIFT_SPEED*dt
        if math.abs(voidYOffset)>=CFG.VOID_Y_DRIFT_RANGE then voidYDir=-voidYDir end
        return Vector3.new(voidX,CFG.VOID_Y_BASE+voidYOffset,voidZ)
    elseif m=="Chaotic" then
        voidX=voidX+(math.random()-0.5)*CFG.VOID_DRIFT_SPEED*dt*5
        voidZ=voidZ+(math.random()-0.5)*CFG.VOID_DRIFT_SPEED*dt*5
        voidYOffset=voidYOffset+(math.random()-0.5)*CFG.VOID_Y_DRIFT_SPEED*dt*5
        return Vector3.new(voidX,CFG.VOID_Y_BASE+voidYOffset,voidZ)
    elseif m=="Circle" then
        local r=1e9; return Vector3.new(voidX+math.cos(elapsed*2)*r,CFG.VOID_Y_BASE+voidYOffset,voidZ+math.sin(elapsed*2)*r)
    elseif m=="Spiral" then
        local r=1e9*(1+math.sin(elapsed)); return Vector3.new(voidX+math.cos(elapsed*3)*r,CFG.VOID_Y_BASE+voidYOffset,voidZ+math.sin(elapsed*3)*r)
    elseif m=="Lissajous" then
        local r=2e9; return Vector3.new(voidX+math.sin(elapsed*CFG.VOID_LISSAJOUS_A)*r,CFG.VOID_Y_BASE+voidYOffset,voidZ+math.sin(elapsed*CFG.VOID_LISSAJOUS_B)*r)
    elseif m=="Perlin Noise" then
        local t=elapsed*0.1; return Vector3.new(voidX+math.noise(t,0)*5e9,CFG.VOID_Y_BASE+voidYOffset,voidZ+math.noise(0,t)*5e9)
    elseif m=="Flicker Void" then
        local flip=(tick()%(CFG.VOID_FLICKER_INT*2)<CFG.VOID_FLICKER_INT)
        return flip and Vector3.new(voidX,CFG.VOID_Y_BASE,voidZ) or Vector3.new(-voidX,CFG.VOID_Y_BASE+1e9,-voidZ)
    elseif m=="Gravity Well" then
        local t=elapsed*0.5; local r=CFG.VOID_GRAVITY_STR*(1+math.sin(t))
        return Vector3.new(voidX+math.cos(t)*r,CFG.VOID_Y_BASE+math.sin(t*0.7)*r,voidZ+math.sin(t)*r)
    elseif m=="Helix" then
        local r=1e9; local t=elapsed*2
        return Vector3.new(voidX+math.cos(t)*r,CFG.VOID_Y_BASE+voidYOffset+math.sin(t*0.5)*r,voidZ+math.sin(t)*r)
    elseif m=="Figure 8" then
        local r=1.5e9; local t=elapsed*1.5
        return Vector3.new(voidX+math.sin(t)*r,CFG.VOID_Y_BASE+voidYOffset,voidZ+math.sin(t)*math.cos(t)*r)
    elseif m=="Tornado" then
        local r=2e9*math.abs(math.sin(elapsed)); local t=elapsed*5
        return Vector3.new(voidX+math.cos(t)*r,CFG.VOID_Y_BASE+math.sin(elapsed*2)*1e9,voidZ+math.sin(t)*r)
    elseif m=="Butterfly" then
        local t=elapsed
        local r=(math.exp(math.sin(t))-2*math.cos(4*t)+math.sin((2*t-math.pi)/24)^5)*5e8
        return Vector3.new(voidX+math.sin(t)*r,CFG.VOID_Y_BASE+math.cos(t)*r,voidZ+math.sin(t*0.5)*r)
    elseif m=="Double Helix" then
        local r=1e9; local t=elapsed*3; local off=(tick()%1<0.5) and 1 or -1
        return Vector3.new(voidX+math.cos(t)*r*off,CFG.VOID_Y_BASE+math.sin(t)*5e8,voidZ+math.sin(t)*r*off)
    elseif m=="Chaotic Sphere" then
        local r=2e9; local t1,t2=elapsed*2,elapsed*1.3
        return Vector3.new(voidX+math.sin(t1)*math.cos(t2)*r,CFG.VOID_Y_BASE+math.sin(t1)*math.sin(t2)*r,voidZ+math.cos(t1)*r)
    elseif m=="Quantum Tunneling" then
        local r=1e11*(math.random()>0.5 and 1 or -1)
        local j=Vector3.new((math.random()-0.5)*2e9,(math.random()-0.5)*2e8,(math.random()-0.5)*2e9)
        return Vector3.new(voidX+r,CFG.VOID_Y_BASE+j.Y,voidZ+r)+j
    elseif m=="Fractal Desync" then
        local t=elapsed*5
        local x=math.sin(t)+math.sin(t*2.1)/2+math.sin(t*3.2)/4
        local z=math.cos(t)+math.cos(t*2.2)/2+math.cos(t*3.1)/4
        return Vector3.new(voidX+x*1e10,CFG.VOID_Y_BASE+math.sin(t*10)*1e9,voidZ+z*1e10)
    elseif m=="Extreme Desync" then
        local t=elapsed*15; local r=1e12
        return Vector3.new(voidX+math.sin(t)*r,CFG.VOID_Y_BASE+math.cos(t*1.5)*r*0.1,voidZ+math.cos(t)*r)
    elseif m=="Quantum Oscillation" then
        local t=elapsed*50; local r=1e11*math.sin(t)
        return Vector3.new(voidX+r,CFG.VOID_Y_BASE+math.cos(t)*1e10,voidZ+r)
    elseif m=="Frame Skip" then
        if tick()%0.1<0.05 then return Vector3.new(voidX*2,CFG.VOID_Y_BASE+1e11,voidZ*2) end
        return Vector3.new(voidX,CFG.VOID_Y_BASE,voidZ)
    end
    return p
end

local groundY = 0  -- cached real ground Y

local function updateGroundY()
    -- Raycast from a safe position to find real map ground
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    if LP.Character then rp.FilterDescendantsInstances = {LP.Character} end
    -- Cast from sky down to find ground
    local ray = workspace:Raycast(Vector3.new(0, 1000, 0), Vector3.new(0,-2000,0), rp)
    if ray then groundY = ray.Position.Y + 3 end
end

local groundUpdateT = 0
local function stepSpoofPos(dt)
    -- Update ground Y every 5 seconds
    groundUpdateT = groundUpdateT + dt
    if groundUpdateT > 5 then groundUpdateT = 0; task.spawn(updateGroundY) end

    local nv=math.noise(elapsed*0.8,42.0)
    spoofAngle=spoofAngle+spoofAngleDir*(1.5+nv*CFG.DESYNC_WANDER_CHAOS)*CFG.DESYNC_WANDER_SPEED*dt
    if math.noise(elapsed*0.3,7.7)>0.6 then spoofAngleDir=-spoofAngleDir end
    local r=CFG.DESYNC_RADIUS*(0.5+0.5*math.abs(math.noise(elapsed*0.5,0)))
    -- Use real ground Y so server thinks we're standing on the map
    fakeGroundPos=Vector3.new(spoofBaseX+math.cos(spoofAngle)*r, groundY, spoofBaseZ+math.sin(spoofAngle)*r)
end

local function runDesyncFlicker()
    if inFlicker then return end
    local hrp=getHRP(); if not hrp then return end
    inFlicker=true
    local savedVoid=intendedVoidPos

    -- Snap to fake ground position (server sees us here briefly)
    pcall(function()
        hrp.CFrame=CFrame.new(fakeGroundPos)
        hrp.AssemblyLinearVelocity=Vector3.new(0,-0.01,0)
    end)

    -- Return to void after 1 physics frame
    task.delay(0, function()
        local hrp2=getHRP()
        if hrp2 and CFG.VOID_ENABLED then
            pcall(function()
                hrp2.CFrame=CFrame.new(savedVoid)
                hrp2.AssemblyLinearVelocity=Vector3.zero
            end)
        end
        inFlicker=false
    end)
end

local function checkVoidEvasion()
    if not CFG.VOID_EVADE or voidEvadeCD>0 then return end
    local minDist,threatVec=math.huge,Vector3.new()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local hrp=p.Character:FindFirstChild("HumanoidRootPart")
            local hum=p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health>0 then
                local vel=hrp.AssemblyLinearVelocity
                local pred=hrp.Position+vel*0.5
                local d=(pred-intendedVoidPos).Magnitude
                if d<minDist then minDist=d; threatVec=(pred-intendedVoidPos).Unit end
            end
        end
    end
    if minDist<CFG.VOID_EVADE_RADIUS then
        local esc=threatVec*-1
        local tl=clamp(1-(minDist/CFG.VOID_EVADE_RADIUS),0,1)
        voidX=voidX+esc.X*CFG.VOID_EVADE_SPEED*(1+tl*2)
        voidZ=voidZ+esc.Z*CFG.VOID_EVADE_SPEED*(1+tl*2)
        if math.random()<(CFG.VOID_EVADE_VERT_BIAS+tl*0.2) then
            local vd=CFG.VOID_EVADE_FORCE_UP and 1 or (math.random()>0.5 and 1 or -1)
            voidYOffset=voidYOffset+vd*CFG.VOID_EVADE_VERT
        end
        voidEvadeCD=CFG.VOID_EVADE_COOLDOWN*(1-tl*0.3)
    end
end

local function lockToVoid(dt)
    if inFlicker then return end
    if voidEvadeCD>0 then voidEvadeCD=voidEvadeCD-dt end
    checkVoidEvasion()
    intendedVoidPos=stepVoidDrift(dt)
    local targetPos=intendedVoidPos
    -- Anti-detect micro offset
    if CFG.VOID_METHOD~="Stable" then
        local mt=tick()*1000
        targetPos=targetPos+Vector3.new(math.sin(mt*0.1)*50,math.sin(mt*0.07)*20,math.cos(mt*0.13)*50)
    end
    local hrp=getHRP(); if not hrp then return end
    local byp=CFG.VOID_BYPASS_MODE
    if byp=="Velocity" then
        pcall(function() hrp.AssemblyLinearVelocity=(targetPos-hrp.Position)*100 end)
    elseif byp=="CFrame only" then
        pcall(function() hrp.CFrame=CFrame.new(targetPos) end)
    elseif byp=="Hybrid" then
        pcall(function() hrp.CFrame=CFrame.new(targetPos); hrp.AssemblyLinearVelocity=Vector3.new(0,0.01,0) end)
    elseif byp=="Physics Bypass" then
        pcall(function()
            hrp.CFrame=CFrame.new(targetPos)
            hrp.AssemblyLinearVelocity=Vector3.new(math.random(-1,1),math.random(-1,1),math.random(-1,1))*1e5
        end)
    else -- Extreme Networking (default) â€” most aggressive
        pcall(function()
            hrp.CFrame=CFrame.new(targetPos)
            hrp.AssemblyLinearVelocity=Vector3.zero
            hrp.AssemblyAngularVelocity=Vector3.zero
        end)
        -- Velocity chaos every ~10 frames to confuse server-side interpolation
        if math.random(1,10)==1 then
            pcall(function()
                hrp.AssemblyLinearVelocity=Vector3.new(
                    (math.random()-0.5)*2e7,
                    (math.random()-0.5)*2e7,
                    (math.random()-0.5)*2e7
                )
            end)
        end
    end

    if CFG.DESYNC_ENABLED then
        stepSpoofPos(dt)
        desyncTimer=desyncTimer+dt
        if desyncTimer>=CFG.DESYNC_TICK then
            desyncTimer=0
            task.spawn(runDesyncFlicker)
        end
    end
end

local function startVoid()
    if voidConn then voidConn:Disconnect(); voidConn=nil end

    -- Grab network ownership so server accepts our position writes
    task.spawn(function()
        local hrp=getHRP()
        if hrp then
            pcall(function() hrp:SetNetworkOwner(LP) end)
        end
        -- Initial ground Y scan for desync
        task.spawn(updateGroundY)
    end)

    -- Reset void starting point to current player position
    local hrp=getHRP()
    if hrp then
        local pos=hrp.Position
        voidX=pos.X; voidZ=pos.Z
        intendedVoidPos=Vector3.new(voidX,CFG.VOID_Y_BASE,voidZ)
        spoofBaseX=pos.X; spoofBaseZ=pos.Z
    end

    voidConn=RunService.Heartbeat:Connect(function(dt)
        if not CFG.VOID_ENABLED then voidConn:Disconnect(); voidConn=nil; return end
        elapsed=elapsed+dt
        lockToVoid(dt)
    end)
end
local function stopVoid()
    if voidConn then voidConn:Disconnect(); voidConn=nil end
end


-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- KILL NOTIFIER
-- Watches all enemy humanoids for health drops to 0
-- Shows on-screen notification with killer info
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local killNotifSG = nil
local killQueue   = {}
local notifShowing = false

local function getKillSG()
    if killNotifSG and killNotifSG.Parent then return killNotifSG end
    killNotifSG = Instance.new("ScreenGui")
    killNotifSG.Name = "KillNotif"; killNotifSG.ResetOnSpawn = false
    killNotifSG.IgnoreGuiInset = true; killNotifSG.DisplayOrder = 998
    pcall(function() killNotifSG.Parent = game:GetService("CoreGui") end)
    if not killNotifSG.Parent then killNotifSG.Parent = LP:WaitForChild("PlayerGui") end
    return killNotifSG
end

local function showKillNotif(name)
    local sg = getKillSG()
    local f = Instance.new("Frame", sg)
    f.Size = UDim2.new(0,220,0,36); f.Position = UDim2.new(0.5,-110,0,60)
    f.BackgroundColor3 = Color3.fromRGB(20,14,30); f.BorderSizePixel = 1
    f.BorderColor3 = Color3.fromRGB(160,32,240); f.ZIndex = 10
    Instance.new("UICorner",f).CornerRadius = UDim.new(0,6)
    local icon = Instance.new("TextLabel",f)
    icon.Size = UDim2.new(0,30,1,0); icon.BackgroundTransparency = 1
    icon.Text = "đź’€"; icon.TextSize = 18; icon.Font = Enum.Font.GothamBold
    icon.TextColor3 = Color3.fromRGB(255,80,80); icon.ZIndex = 11
    local lbl = Instance.new("TextLabel",f)
    lbl.Size = UDim2.new(1,-36,1,0); lbl.Position = UDim2.new(0,32,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Eliminated  " .. name
    lbl.TextColor3 = Color3.fromRGB(220,180,255)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 11
    -- Slide in then fade out after 2.5s
    task.delay(2.5, function() f:Destroy() end)
end

local watchedHumanoids = {}

local function watchPlayer(p)
    if not p or p == LP then return end
    local function hookChar(ch)
        if not ch then return end
        local hum = ch:WaitForChild("Humanoid", 5)
        if not hum then return end
        if watchedHumanoids[hum] then return end
        watchedHumanoids[hum] = true
        hum.Died:Connect(function()
            if CFG.KILL_NOTIFIER then
                showKillNotif(p.Name)
            end
            watchedHumanoids[hum] = nil
        end)
    end
    if p.Character then task.spawn(hookChar, p.Character) end
    p.CharacterAdded:Connect(hookChar)
end

for _,p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
Players.PlayerAdded:Connect(watchPlayer)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- STANDALONE DESYNC (works without void)
-- Rapidly flickers HRP between real pos and spoof pos
-- Makes server-side hitbox differ from client visual
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local desyncOnlyConn = nil
local dsFlicker      = false
local dsAcc          = 0

local function startDesyncOnly()
    if desyncOnlyConn then desyncOnlyConn:Disconnect(); desyncOnlyConn=nil end
    dsAcc = 0; dsFlicker = false
    desyncOnlyConn = RunService.Heartbeat:Connect(function(dt)
        if not CFG.DESYNC_STANDALONE then
            desyncOnlyConn:Disconnect(); desyncOnlyConn=nil; return
        end
        local hrp = getHRP(); if not hrp then return end
        dsAcc = dsAcc + dt
        if dsAcc < CFG.DESYNC_TICK then return end
        dsAcc = 0
        -- Update spoof position wander
        stepSpoofPos(dt)
        if not dsFlicker then
            -- Save real pos, flicker to spoof
            local realCF = hrp.CFrame
            pcall(function()
                hrp.CFrame = CFrame.new(fakeGroundPos)
                hrp.AssemblyLinearVelocity = Vector3.new(0,-0.01,0)
            end)
            task.delay(0.016, function()
                local hrp2 = getHRP()
                if hrp2 and CFG.DESYNC_STANDALONE then
                    pcall(function()
                        hrp2.CFrame = realCF
                        hrp2.AssemblyLinearVelocity = Vector3.zero
                    end)
                end
            end)
        end
        dsFlicker = not dsFlicker
    end)
end

local function stopDesyncOnly()
    if desyncOnlyConn then desyncOnlyConn:Disconnect(); desyncOnlyConn=nil end
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- ORBIT SYSTEM
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local orbitAngle  = math.random(0,360)
local orbitConn   = nil
local currentTgt  = nil
local lastVel     = Vector3.new()
local smoothAccel = Vector3.new()
local smoothedPred= nil

local function findBestTarget()
    -- Find by closest distance â€” works regardless of camera direction
    local best,bestDist=nil,math.huge
    local myHRP=getHRP()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local hum=p.Character:FindFirstChildOfClass("Humanoid")
            local hrp=p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health>CFG.KILL_HP then
                local origin=myHRP and myHRP.Position or Camera.CFrame.Position
                local dist=(origin-hrp.Position).Magnitude
                if dist<bestDist then bestDist=dist; best=p end
            end
        end
    end
    return best,bestDist
end

local function getOrbitOffset(resolvedPos, dt)
    local m=CFG.ORBIT_MODE
    local r_base=CFG.MIN_RADIUS+(CFG.MAX_RADIUS-CFG.MIN_RADIUS)*0.5
    local h=CFG.HEIGHT_OFFSET
    local t=orbitAngle
    if m=="Default" then
        local r=CFG.MIN_RADIUS+(CFG.MAX_RADIUS-CFG.MIN_RADIUS)*(0.5+0.5*math.sin(elapsed*0.3))
        return Vector3.new(math.cos(t)*r,h,math.sin(t)*r)
    elseif m=="Spiral" then
        local r=CFG.MIN_RADIUS+(elapsed*100000)%(CFG.MAX_RADIUS-CFG.MIN_RADIUS)
        return Vector3.new(math.cos(t)*r,h,math.sin(t)*r)
    elseif m=="Random" then
        local r=CFG.MIN_RADIUS+math.random()*(CFG.MAX_RADIUS-CFG.MIN_RADIUS)
        return Vector3.new(math.cos(t)*r,h+(math.random()-0.5)*20000,math.sin(t)*r)
    elseif m=="Lissajous" then
        local rx=CFG.MIN_RADIUS+(CFG.MAX_RADIUS-CFG.MIN_RADIUS)*0.7
        local rz=CFG.MIN_RADIUS+(CFG.MAX_RADIUS-CFG.MIN_RADIUS)*0.3
        return Vector3.new(math.sin(t*3)*rx,h,math.sin(t*2)*rz)
    elseif m=="Helix" then
        return Vector3.new(math.cos(t)*r_base,h+math.sin(t*2)*50000,math.sin(t)*r_base)
    elseif m=="Figure 8" then
        return Vector3.new(math.sin(t)*r_base,h,math.sin(t)*math.cos(t)*r_base)
    elseif m=="Pulse" then
        local pr=CFG.MIN_RADIUS+(CFG.MAX_RADIUS-CFG.MIN_RADIUS)*(0.5+0.5*math.sin(elapsed*5))
        return Vector3.new(math.cos(t)*pr,h,math.sin(t)*pr)
    elseif m=="Tornado" then
        local r=CFG.MIN_RADIUS+(CFG.MAX_RADIUS-CFG.MIN_RADIUS)*(0.3+0.7*math.abs(math.sin(elapsed*2)))
        return Vector3.new(math.cos(t*3)*r,h+math.sin(elapsed*10)*100000,math.sin(t*3)*r)
    elseif m=="Butterfly" then
        local br=(math.exp(math.sin(t))-2*math.cos(4*t)+math.sin((2*t-math.pi)/24)^5)*(CFG.MIN_RADIUS/1000000)
        return Vector3.new(math.sin(t)*br,h+math.cos(t)*br*0.3,math.sin(t*0.5)*br)
    elseif m=="Quantum Orbit" then
        local qr=CFG.MIN_RADIUS+(CFG.MAX_RADIUS-CFG.MIN_RADIUS)*(0.5+0.5*math.sin(elapsed*13))
        local qp=math.sin(elapsed*7)*math.pi
        return Vector3.new(math.cos(t+qp)*qr,h+math.sin(qp*2)*50000,math.sin(t+qp)*qr)
    elseif m=="Hyper Elliptical" then
        local rx=CFG.MIN_RADIUS+(CFG.MAX_RADIUS-CFG.MIN_RADIUS)*CFG.ELLIPSE_RATIO
        local rz=CFG.MIN_RADIUS+(CFG.MAX_RADIUS-CFG.MIN_RADIUS)*(1-CFG.ELLIPSE_RATIO)
        return Vector3.new(math.cos(t)*rx,h,math.sin(t)*rz)
    end
    -- Default fallback
    return Vector3.new(math.cos(t)*r_base,h,math.sin(t)*r_base)
end

local function startOrbit()
    if orbitConn then orbitConn:Disconnect(); orbitConn=nil end
    _orbitActive = true
    currentTgt   = nil
    -- Force scriptable so we own the camera
    pcall(function() Camera.CameraType = Enum.CameraType.Scriptable end)

    orbitConn = RunService.Heartbeat:Connect(function(dt)
        if not CFG.ORBIT_ENABLED then
            orbitConn:Disconnect(); orbitConn=nil
            _orbitActive = false; return
        end

        elapsed = elapsed + dt

        -- Force scriptable every frame (game tries to reset it)
        pcall(function()
            if Camera.CameraType ~= Enum.CameraType.Scriptable then
                Camera.CameraType = Enum.CameraType.Scriptable
            end
        end)

        -- Find target every frame â€” instant response
        if not currentTgt or not currentTgt.Character
        or not currentTgt.Character:FindFirstChild("HumanoidRootPart") then
            currentTgt = findBestTarget()
        end
        if not currentTgt then return end

        local tch  = currentTgt.Character
        local hrp  = tch and tch:FindFirstChild("HumanoidRootPart")
        local hum  = tch and tch:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then
            currentTgt = nil; return
        end

        local vel         = hrp.AssemblyLinearVelocity
        local resolvedPos = hrp.Position + vel * CFG.PREDICTION
        orbitAngle        = orbitAngle + CFG.ORBIT_SPEED * dt

        local offset   = getOrbitOffset(resolvedPos, dt)
        local jitter   = Vector3.new(
            (math.random()-0.5)*2*CFG.ORBIT_JITTER,
            (math.random()-0.5)*2*CFG.ORBIT_JITTER,
            (math.random()-0.5)*2*CFG.ORBIT_JITTER
        )
        local camPos   = resolvedPos + offset + jitter
        local targetCF = CFrame.lookAt(camPos, resolvedPos)
        local lerpF    = clamp(CFG.CAM_LERP_BASE + vel.Magnitude*0.004, CFG.CAM_LERP_BASE, 0.45)

        pcall(function()
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, lerpF * CFG.ORBIT_STABILITY)
        end)
    end)
end

local function stopOrbit()
    if orbitConn then orbitConn:Disconnect(); orbitConn=nil end
    _orbitActive = false
    pcall(function()
        Camera.CameraType = Enum.CameraType.Custom
        local hum = getHum()
        if hum then Camera.CameraSubject = hum end
    end)
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- EXTRAS
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local speedConn,noclipConn,ijConn

local function applySpeed()
    if speedConn then speedConn:Disconnect(); speedConn=nil end
    local h=getHum(); if h then pcall(function() h.WalkSpeed=CFG.SPEED_ENABLED and CFG.WALK_SPEED or 16 end) end
    if not CFG.SPEED_ENABLED then return end
    speedConn=RunService.Heartbeat:Connect(function()
        if not CFG.SPEED_ENABLED then speedConn:Disconnect(); speedConn=nil; return end
        local hum=getHum(); if hum and hum.WalkSpeed~=CFG.WALK_SPEED then pcall(function() hum.WalkSpeed=CFG.WALK_SPEED end) end
    end)
end

local function startNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
    noclipConn=RunService.Stepped:Connect(function()
        if not CFG.NOCLIP then noclipConn:Disconnect(); noclipConn=nil; return end
        local c=LP.Character; if not c then return end
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide=false end) end
        end
    end)
end
local function stopNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
end

local function startIJ()
    if ijConn then ijConn:Disconnect(); ijConn=nil end
    ijConn=UIS.JumpRequest:Connect(function()
        if not CFG.INF_JUMP then ijConn:Disconnect(); ijConn=nil; return end
        local h=getHum(); if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end)
end

local origGravity=workspace.Gravity
local function applyGravity()
    pcall(function() workspace.Gravity=CFG.LOW_GRAVITY and CFG.GRAVITY_VAL or origGravity end)
end

-- FPS Boost
local function applyFPSBoost()
    pcall(function()
        local l=game:GetService("Lighting")
        l.GlobalShadows=false; l.FogEnd=9e9; l.Brightness=0
        workspace.Terrain.WaterWaveSize=0; workspace.Terrain.WaterWaveSpeed=0
        for _,v in ipairs(l:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") then
                v.Enabled=false
            end
        end
        for _,v in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Lifetime=NumberRange.new(0)
                elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") then v.Enabled=false end
            end)
        end
    end)
    print("[Rivals Raging Comp] FPS Boost applied")
end


-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- KILL NOTIFIER + HIT NOTIFICATION
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local CFG_KN = {ON=true, COLOR=Color3.fromRGB(160,32,240), SOUND=true}

local notifSG = Instance.new("ScreenGui")
notifSG.Name="RivalsRagingComp_Notifs"; notifSG.ResetOnSpawn=false
notifSG.IgnoreGuiInset=true; notifSG.DisplayOrder=998
pcall(function() notifSG.Parent=game:GetService("CoreGui") end)
if not notifSG.Parent then notifSG.Parent=LP:WaitForChild("PlayerGui") end

local notifList = {}
local NOTIF_Y = 80

local function showNotif(txt, col, duration)
    if not CFG_KN.ON then return end
    col = col or CFG_KN.COLOR
    duration = duration or 2.5

    local f = Instance.new("Frame", notifSG)
    f.Size = UDim2.new(0,220,0,32)
    f.Position = UDim2.new(0.5,-110,0,NOTIF_Y + #notifList*36)
    f.BackgroundColor3 = Color3.fromRGB(14,14,18)
    f.BorderSizePixel = 1
    f.BorderColor3 = col
    f.ZIndex = 10
    Instance.new("UICorner",f).CornerRadius = UDim.new(0,6)

    -- Color accent left bar
    local bar = Instance.new("Frame",f)
    bar.Size = UDim2.new(0,3,1,0)
    bar.BackgroundColor3 = col
    bar.BorderSizePixel = 0; bar.ZIndex = 11
    Instance.new("UICorner",bar).CornerRadius = UDim.new(0,3)

    local lbl = Instance.new("TextLabel",f)
    lbl.Size = UDim2.new(1,-10,1,0)
    lbl.Position = UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt; lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 11

    table.insert(notifList, f)

    -- Play sound if enabled
    if CFG_KN.SOUND then
        pcall(function()
            local snd = Instance.new("Sound", workspace)
            snd.SoundId = "rbxassetid://4764109000"
            snd.Volume = 0.4; snd.RollOffMaxDistance = 0
            snd:Play()
            game:GetService("Debris"):AddItem(snd, 2)
        end)
    end

    task.delay(duration, function()
        pcall(function()
            for i,v in ipairs(notifList) do
                if v == f then table.remove(notifList, i); break end
            end
            f:Destroy()
            -- Reposition remaining
            for i,v in ipairs(notifList) do
                pcall(function()
                    v.Position = UDim2.new(0.5,-110,0,NOTIF_Y+(i-1)*36)
                end)
            end
        end)
    end)
end

-- Watch for kills â€” detect when enemies die
local function watchKills()
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local function hookChar(char)
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            hum.Died:Connect(function()
                showNotif("â  Killed " .. p.Name, Color3.fromRGB(160,32,240), 3)
            end)
        end
        hookChar(p.Character)
        p.CharacterAdded:Connect(hookChar)
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid",5)
        if not hum then return end
        hum.Died:Connect(function()
            if p ~= LP then
                showNotif("â  Killed " .. p.Name, Color3.fromRGB(160,32,240), 3)
            end
        end)
    end)
end)

task.defer(watchKills)

-- Desync notif
local desyncActive = false
RunService.Heartbeat:Connect(function()
    if CFG.DESYNC_ENABLED and CFG.VOID_ENABLED and not desyncActive then
        desyncActive = true
        showNotif("âšˇ Desync Active", Color3.fromRGB(255,200,0), 1.5)
    elseif not (CFG.DESYNC_ENABLED and CFG.VOID_ENABLED) then
        desyncActive = false
    end
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- ════════════════════════════════════════════════════════════
-- GUI — AETHER REDESIGN v2.1
-- Solid Dark Theme · High Contrast · Neon Accents · Smooth Animations
-- ════════════════════════════════════════════════════════════

local guiSG = Instance.new("ScreenGui")
guiSG.Name = "AetherRivals"
guiSG.ResetOnSpawn = false
guiSG.IgnoreGuiInset = true
guiSG.DisplayOrder = 999
pcall(function() guiSG.Parent = game:GetService("CoreGui") end)
if not guiSG.Parent then guiSG.Parent = LP:WaitForChild("PlayerGui") end

-- ════════════════════════════════════════════════════════════
-- DESIGN SYSTEM — Solid Dark with Neon Accents
-- ════════════════════════════════════════════════════════════
local DS = {
    -- SOLID Backgrounds (NO transparency - fully opaque)
    BG_DEEPEST   = Color3.fromRGB(8, 8, 14),       -- Deepest background
    BG_DEEP      = Color3.fromRGB(14, 14, 22),      -- Deep panels
    BG_PANEL     = Color3.fromRGB(22, 22, 34),     -- Panel background
    BG_CARD      = Color3.fromRGB(30, 30, 46),     -- Card/item background
    BG_HOVER     = Color3.fromRGB(38, 38, 56),     -- Hover state
    BG_INPUT     = Color3.fromRGB(18, 18, 30),     -- Input fields
    BG_TAB       = Color3.fromRGB(12, 12, 20),     -- Tab bar bg

    -- Accents — Electric Cyan & Magenta
    ACCENT_PRIMARY   = Color3.fromRGB(0, 230, 255),    -- Cyan
    ACCENT_SECONDARY = Color3.fromRGB(255, 0, 128),    -- Hot Pink
    ACCENT_TERTIARY  = Color3.fromRGB(160, 80, 255),    -- Purple
    ACCENT_GOLD      = Color3.fromRGB(255, 200, 80),    -- Gold

    -- Glow colors (darker versions for borders)
    GLOW_CYAN    = Color3.fromRGB(0, 180, 220),
    GLOW_PINK    = Color3.fromRGB(220, 0, 100),
    GLOW_PURPLE  = Color3.fromRGB(120, 60, 220),

    -- Text (high contrast)
    TXT_PRIMARY   = Color3.fromRGB(255, 255, 255),      -- Pure white
    TXT_SECONDARY = Color3.fromRGB(190, 200, 220),      -- Light gray-blue
    TXT_MUTED     = Color3.fromRGB(120, 130, 150),      -- Muted
    TXT_DARK      = Color3.fromRGB(60, 65, 80),

    -- States
    ON_GREEN  = Color3.fromRGB(0, 230, 150),
    OFF_RED   = Color3.fromRGB(255, 60, 80),
    WARN_AMBER = Color3.fromRGB(255, 160, 40),

    -- Borders
    BORDER_SUBTLE = Color3.fromRGB(45, 50, 65),
    BORDER_GLOW   = Color3.fromRGB(0, 200, 255),

    -- Gradients
    GRAD_CYAN = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 230, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 180, 220))
    }),
    GRAD_PINK = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 128)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 0, 100))
    }),
    GRAD_PURPLE = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 80, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 50, 200))
    }),
    GRAD_GOLD = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 40))
    }),
}

-- ════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS — UI Effects
-- ════════════════════════════════════════════════════════════
local TweenService = game:GetService("TweenService")

local function tween(obj, props, duration, easing, direction)
    duration = duration or 0.3
    easing = easing or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration, easing, direction)
    TweenService:Create(obj, info, props):Play()
end

local function ripple(btn, pos)
    local ripple = Instance.new("Frame")
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0, pos.X - btn.AbsolutePosition.X, 0, pos.Y - btn.AbsolutePosition.Y)
    ripple.BackgroundColor3 = Color3.new(1, 1, 1)
    ripple.BackgroundTransparency = 0.6
    ripple.BorderSizePixel = 0
    ripple.ZIndex = btn.ZIndex + 1
    ripple.Parent = btn
    Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)

    local maxSize = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.5
    tween(ripple, {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        Position = UDim2.new(0, pos.X - btn.AbsolutePosition.X - maxSize/2, 0, pos.Y - btn.AbsolutePosition.Y - maxSize/2),
        BackgroundTransparency = 1
    }, 0.6)
    task.delay(0.6, function() ripple:Destroy() end)
end

-- ════════════════════════════════════════════════════════════
-- STATUS BAR — Top overlay (SOLID background)
-- ════════════════════════════════════════════════════════════
local statusBar = Instance.new("Frame", guiSG)
statusBar.Name = "StatusBar"
statusBar.Size = UDim2.new(0, 220, 0, 66)
statusBar.Position = UDim2.new(0, 12, 0, 8)
statusBar.BackgroundColor3 = DS.BG_DEEP
statusBar.BackgroundTransparency = 0  -- FULLY OPAQUE
statusBar.BorderSizePixel = 0
statusBar.ZIndex = 15

local sbCorner = Instance.new("UICorner", statusBar)
sbCorner.CornerRadius = UDim.new(0, 10)

local sbStroke = Instance.new("UIStroke", statusBar)
sbStroke.Color = DS.BORDER_SUBTLE
sbStroke.Thickness = 1.5

-- Status glow line (gradient accent)
local sbGlow = Instance.new("Frame", statusBar)
sbGlow.Size = UDim2.new(1, 0, 0, 3)
sbGlow.Position = UDim2.new(0, 0, 0, 0)
sbGlow.BackgroundColor3 = DS.ACCENT_PRIMARY
sbGlow.BorderSizePixel = 0
sbGlow.ZIndex = 16

local sbGlowGrad = Instance.new("UIGradient", sbGlow)
sbGlowGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, DS.ACCENT_PRIMARY),
    ColorSequenceKeypoint.new(0.5, DS.ACCENT_SECONDARY),
    ColorSequenceKeypoint.new(1, DS.ACCENT_TERTIARY)
})

-- Status labels
local stVoid = Instance.new("TextLabel", statusBar)
stVoid.Name = "VoidStatus"
stVoid.Size = UDim2.new(1, -16, 0, 18)
stVoid.Position = UDim2.new(0, 10, 0, 8)
stVoid.BackgroundTransparency = 1
stVoid.Text = "◉ VOID  OFF"
stVoid.TextColor3 = DS.TXT_MUTED
stVoid.Font = Enum.Font.GothamBold
stVoid.TextSize = 11
stVoid.TextXAlignment = Enum.TextXAlignment.Left
stVoid.ZIndex = 16

local stOrbit = Instance.new("TextLabel", statusBar)
stOrbit.Name = "OrbitStatus"
stOrbit.Size = UDim2.new(1, -16, 0, 18)
stOrbit.Position = UDim2.new(0, 10, 0, 26)
stOrbit.BackgroundTransparency = 1
stOrbit.Text = "◉ ORBIT  OFF"
stOrbit.TextColor3 = DS.TXT_MUTED
stOrbit.Font = Enum.Font.GothamBold
stOrbit.TextSize = 11
stOrbit.TextXAlignment = Enum.TextXAlignment.Left
stOrbit.ZIndex = 16

local stDesync = Instance.new("TextLabel", statusBar)
stDesync.Name = "DesyncStatus"
stDesync.Size = UDim2.new(1, -16, 0, 18)
stDesync.Position = UDim2.new(0, 10, 0, 44)
stDesync.BackgroundTransparency = 1
stDesync.Text = "◉ DESYNC  OFF"
stDesync.TextColor3 = DS.TXT_MUTED
stDesync.Font = Enum.Font.GothamBold
stDesync.TextSize = 11
stDesync.TextXAlignment = Enum.TextXAlignment.Left
stDesync.ZIndex = 16

local function updSt()
    if CFG.VOID_ENABLED then
        stVoid.Text = "◉ VOID  ACTIVE"
        tween(stVoid, {TextColor3 = DS.ON_GREEN}, 0.2)
    else
        stVoid.Text = "◉ VOID  OFF"
        tween(stVoid, {TextColor3 = DS.TXT_MUTED}, 0.2)
    end

    if CFG.ORBIT_ENABLED then
        stOrbit.Text = "◉ ORBIT  ACTIVE"
        tween(stOrbit, {TextColor3 = DS.ACCENT_PRIMARY}, 0.2)
    else
        stOrbit.Text = "◉ ORBIT  OFF"
        tween(stOrbit, {TextColor3 = DS.TXT_MUTED}, 0.2)
    end

    local dsActive = CFG.DESYNC_ENABLED or CFG.DESYNC_STANDALONE
    if dsActive then
        stDesync.Text = "◉ DESYNC  ACTIVE"
        tween(stDesync, {TextColor3 = DS.ACCENT_SECONDARY}, 0.2)
    else
        stDesync.Text = "◉ DESYNC  OFF"
        tween(stDesync, {TextColor3 = DS.TXT_MUTED}, 0.2)
    end
end

-- ════════════════════════════════════════════════════════════
-- FLOATING ACTION BUTTON — Hexagonal trigger
-- ════════════════════════════════════════════════════════════
local fabContainer = Instance.new("Frame", guiSG)
fabContainer.Name = "FAB"
fabContainer.Size = UDim2.new(0, 64, 0, 64)
fabContainer.Position = UDim2.new(0.5, -32, 1, -90)
fabContainer.BackgroundTransparency = 1
fabContainer.ZIndex = 20

local fabBtn = Instance.new("TextButton", fabContainer)
fabBtn.Name = "FabButton"
fabBtn.Size = UDim2.new(0, 56, 0, 56)
fabBtn.Position = UDim2.new(0.5, -28, 0.5, -28)
fabBtn.BackgroundColor3 = DS.ACCENT_PRIMARY
fabBtn.BorderSizePixel = 0
fabBtn.Text = "◈"
fabBtn.TextColor3 = DS.BG_DEEPEST
fabBtn.Font = Enum.Font.GothamBold
fabBtn.TextSize = 24
fabBtn.ZIndex = 21

local fabCorner = Instance.new("UICorner", fabBtn)
fabCorner.CornerRadius = UDim.new(0, 16)

-- FAB glow ring
local fabRing = Instance.new("Frame", fabContainer)
fabRing.Size = UDim2.new(0, 64, 0, 64)
fabRing.Position = UDim2.new(0.5, -32, 0.5, -32)
fabRing.BackgroundTransparency = 1
fabRing.BorderSizePixel = 0
fabRing.ZIndex = 20

local ringStroke = Instance.new("UIStroke", fabRing)
ringStroke.Color = DS.ACCENT_PRIMARY
ringStroke.Thickness = 2
ringStroke.Transparency = 0.4

local ringCorner = Instance.new("UICorner", fabRing)
ringCorner.CornerRadius = UDim.new(0, 18)

-- FAB animation
local fabOpen = false
local function pulseFab()
    tween(fabRing, {Size = UDim2.new(0, 72, 0, 72), Position = UDim2.new(0.5, -36, 0.5, -36)}, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    tween(ringStroke, {Transparency = 0.1}, 0.4)
    task.wait(0.4)
    if fabOpen then return end
    tween(fabRing, {Size = UDim2.new(0, 64, 0, 64), Position = UDim2.new(0.5, -32, 0.5, -32)}, 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    tween(ringStroke, {Transparency = 0.4}, 0.6)
end

spawn(function()
    while fabContainer and fabContainer.Parent do
        if not fabOpen then pulseFab() end
        task.wait(2.5)
    end
end)

-- ════════════════════════════════════════════════════════════
-- MAIN WINDOW — SOLID Dark Panel
-- ════════════════════════════════════════════════════════════
local WIN_W = 300
local WIN_H = 460

local win = Instance.new("Frame", guiSG)
win.Name = "MainWindow"
win.Size = UDim2.new(0, WIN_W, 0, WIN_H)
win.Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
win.BackgroundColor3 = DS.BG_DEEP
win.BackgroundTransparency = 0  -- FULLY OPAQUE
win.BorderSizePixel = 0
win.Visible = false
win.ZIndex = 10
win.ClipsDescendants = true

local winCorner = Instance.new("UICorner", win)
winCorner.CornerRadius = UDim.new(0, 14)

local winStroke = Instance.new("UIStroke", win)
winStroke.Color = DS.BORDER_SUBTLE
winStroke.Thickness = 2

-- Animated entrance
local function showWin()
    win.Visible = true
    win.Size = UDim2.new(0, WIN_W, 0, 0)
    tween(win, {Size = UDim2.new(0, WIN_W, 0, WIN_H)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    fabBtn.Text = "✕"
    tween(fabBtn, {BackgroundColor3 = DS.OFF_RED, Rotation = 90}, 0.3)
end

local function hideWin()
    tween(win, {Size = UDim2.new(0, WIN_W, 0, 0)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    task.wait(0.3)
    win.Visible = false
    fabBtn.Text = "◈"
    tween(fabBtn, {BackgroundColor3 = DS.ACCENT_PRIMARY, Rotation = 0}, 0.3)
end

fabBtn.MouseButton1Click:Connect(function()
    fabOpen = not fabOpen
    if fabOpen then showWin() else hideWin() end
end)

-- Title bar
local titleBar = Instance.new("Frame", win)
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3 = DS.BG_DEEPEST
titleBar.BackgroundTransparency = 0  -- OPAQUE
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 11

local tbCorner = Instance.new("UICorner", titleBar)
tbCorner.CornerRadius = UDim.new(0, 14)

-- Title gradient line
local titleGlow = Instance.new("Frame", titleBar)
titleGlow.Size = UDim2.new(1, -20, 0, 2)
titleGlow.Position = UDim2.new(0, 10, 1, -3)
titleGlow.BackgroundColor3 = DS.ACCENT_PRIMARY
titleGlow.BorderSizePixel = 0
titleGlow.ZIndex = 12

local tgGrad = Instance.new("UIGradient", titleGlow)
tgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, DS.ACCENT_PRIMARY),
    ColorSequenceKeypoint.new(0.5, DS.ACCENT_SECONDARY),
    ColorSequenceKeypoint.new(1, DS.ACCENT_TERTIARY)
})

local titleIcon = Instance.new("TextLabel", titleBar)
titleIcon.Size = UDim2.new(0, 28, 0, 28)
titleIcon.Position = UDim2.new(0, 12, 0, 8)
titleIcon.BackgroundTransparency = 1
titleIcon.Text = "◈"
titleIcon.TextColor3 = DS.ACCENT_PRIMARY
titleIcon.Font = Enum.Font.GothamBold
titleIcon.TextSize = 18
titleIcon.ZIndex = 12

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1, -50, 0, 20)
titleText.Position = UDim2.new(0, 40, 0, 12)
titleText.BackgroundTransparency = 1
titleText.Text = "AETHER  //  RIVALS"
titleText.TextColor3 = DS.TXT_PRIMARY
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 13
titleText.TextXAlignment = Enum.TextXAlignment.Left

local titleVer = Instance.new("TextLabel", titleBar)
titleVer.Size = UDim2.new(0, 40, 0, 14)
titleVer.Position = UDim2.new(1, -45, 0, 15)
titleVer.BackgroundTransparency = 1
titleVer.Text = "v2.1"
titleVer.TextColor3 = DS.TXT_MUTED
titleVer.Font = Enum.Font.Gotham
titleVer.TextSize = 10
titleVer.TextXAlignment = Enum.TextXAlignment.Right

-- Drag system
local dragging = false
local dragStart, dragOffset

titleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = inp.Position
        dragOffset = win.Position
    end
end)

UIS.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = inp.Position - dragStart
        win.Position = UDim2.new(dragOffset.X.Scale, dragOffset.X.Offset + delta.X, dragOffset.Y.Scale, dragOffset.Y.Offset + delta.Y)
    end
end)

UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ════════════════════════════════════════════════════════════
-- TAB BAR — Neon segmented control
-- ════════════════════════════════════════════════════════════
local TABS = {"VOID", "ORBIT", "EXTRAS", "CONFIG"}
local tBtns = {}
local tPages = {}
local curTab = 1

local tabBar = Instance.new("Frame", win)
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -16, 0, 36)
tabBar.Position = UDim2.new(0, 8, 0, 48)
tabBar.BackgroundColor3 = DS.BG_TAB
tabBar.BackgroundTransparency = 0  -- OPAQUE
tabBar.BorderSizePixel = 0
tabBar.ZIndex = 11

local tbCorner2 = Instance.new("UICorner", tabBar)
tbCorner2.CornerRadius = UDim.new(0, 8)

local tabW = math.floor((WIN_W - 16) / #TABS)

for i, name in ipairs(TABS) do
    local btn = Instance.new("TextButton", tabBar)
    btn.Name = "Tab" .. i
    btn.Size = UDim2.new(0, tabW - 2, 0, 30)
    btn.Position = UDim2.new(0, (i-1) * tabW + 1, 0, 3)
    btn.BackgroundColor3 = i == 1 and DS.ACCENT_PRIMARY or Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = i == 1 and 0 or 1
    btn.Text = name
    btn.TextColor3 = i == 1 and DS.BG_DEEPEST or DS.TXT_SECONDARY
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.ZIndex = 12
    btn.AutoButtonColor = false

    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 6)

    tBtns[i] = btn

    -- Page container
    local pg = Instance.new("ScrollingFrame", win)
    pg.Name = "Page" .. i
    pg.Size = UDim2.new(1, -16, 0, WIN_H - 94)
    pg.Position = UDim2.new(0, 8, 0, 88)
    pg.BackgroundTransparency = 1
    pg.BorderSizePixel = 0
    pg.Visible = (i == 1)
    pg.ZIndex = 10
    pg.ScrollBarThickness = 3
    pg.ScrollBarImageColor3 = DS.ACCENT_PRIMARY
    pg.ScrollingDirection = Enum.ScrollingDirection.Y
    pg.CanvasSize = UDim2.new(0, 0, 0, 1000)
    pg.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pg.ClipsDescendants = true

    tPages[i] = pg
end

local pY = {0, 0, 0, 0}

local function switchTab(idx)
    curTab = idx
    for i, pg in ipairs(tPages) do
        pg.Visible = (i == idx)
        if i == idx then
            pg.Position = UDim2.new(0, 8, 0, 94)
            tween(pg, {Position = UDim2.new(0, 8, 0, 88)}, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end
    for i, btn in ipairs(tBtns) do
        if i == idx then
            tween(btn, {BackgroundColor3 = DS.ACCENT_PRIMARY, BackgroundTransparency = 0}, 0.2)
            tween(btn, {TextColor3 = DS.BG_DEEPEST}, 0.2)
        else
            tween(btn, {BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 1}, 0.2)
            tween(btn, {TextColor3 = DS.TXT_SECONDARY}, 0.2)
        end
    end
end

for i, btn in ipairs(tBtns) do
    local ii = i
    btn.MouseButton1Click:Connect(function()
        if curTab ~= ii then switchTab(ii) end
    end)
    btn.MouseEnter:Connect(function()
        if curTab ~= ii then
            tween(btn, {BackgroundTransparency = 0.85}, 0.15)
        end
    end)
    btn.MouseLeave:Connect(function()
        if curTab ~= ii then
            tween(btn, {BackgroundTransparency = 1}, 0.15)
        end
    end)
end

-- ════════════════════════════════════════════════════════════
-- COMPONENT BUILDERS — Solid dark with neon accents
-- ════════════════════════════════════════════════════════════
local RH = 34
local SH = 42
local G = 6
local SEC_H = 28

local function mkSec(pgIdx, txt, accentColor)
    accentColor = accentColor or DS.ACCENT_PRIMARY
    local pg = tPages[pgIdx]

    local f = Instance.new("Frame", pg)
    f.Size = UDim2.new(1, -4, 0, SEC_H)
    f.Position = UDim2.new(0, 2, 0, pY[pgIdx])
    f.BackgroundColor3 = DS.BG_DEEPEST
    f.BackgroundTransparency = 0  -- OPAQUE
    f.BorderSizePixel = 0
    f.ZIndex = 11

    local corner = Instance.new("UICorner", f)
    corner.CornerRadius = UDim.new(0, 6)

    -- Accent bar
    local bar = Instance.new("Frame", f)
    bar.Size = UDim2.new(0, 3, 0, 16)
    bar.Position = UDim2.new(0, 8, 0.5, -8)
    bar.BackgroundColor3 = accentColor
    bar.BorderSizePixel = 0
    bar.ZIndex = 12

    local barCorner = Instance.new("UICorner", bar)
    barCorner.CornerRadius = UDim.new(0, 2)

    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, -20, 1, 0)
    l.Position = UDim2.new(0, 16, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = accentColor
    l.Font = Enum.Font.GothamBold
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 12

    pY[pgIdx] = pY[pgIdx] + SEC_H + G
end

local function mkTog(pgIdx, txt, getter, setter, accent)
    accent = accent or DS.ACCENT_PRIMARY
    local pg = tPages[pgIdx]

    local f = Instance.new("Frame", pg)
    f.Name = "Toggle_" .. txt
    f.Size = UDim2.new(1, -4, 0, RH)
    f.Position = UDim2.new(0, 2, 0, pY[pgIdx])
    f.BackgroundColor3 = DS.BG_PANEL
    f.BackgroundTransparency = 0  -- OPAQUE
    f.BorderSizePixel = 0
    f.ZIndex = 11

    local fCorner = Instance.new("UICorner", f)
    fCorner.CornerRadius = UDim.new(0, 8)

    local fStroke = Instance.new("UIStroke", f)
    fStroke.Color = DS.BORDER_SUBTLE
    fStroke.Thickness = 1

    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, -60, 1, 0)
    l.Position = UDim2.new(0, 12, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = DS.TXT_PRIMARY
    l.Font = Enum.Font.Gotham
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.ZIndex = 12

    -- Modern toggle switch
    local switch = Instance.new("Frame", f)
    switch.Name = "Switch"
    switch.Size = UDim2.new(0, 42, 0, 24)
    switch.Position = UDim2.new(1, -52, 0.5, -12)
    switch.BackgroundColor3 = getter() and accent or DS.OFF_RED
    switch.BorderSizePixel = 0
    switch.ZIndex = 12

    local swCorner = Instance.new("UICorner", switch)
    swCorner.CornerRadius = UDim.new(1, 0)

    -- Knob
    local knob = Instance.new("Frame", switch)
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = getter() and UDim2.new(0, 20, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.ZIndex = 13

    local knobCorner = Instance.new("UICorner", knob)
    knobCorner.CornerRadius = UDim.new(1, 0)

    -- Glow effect when ON
    local glow = Instance.new("UIStroke", switch)
    glow.Color = accent
    glow.Thickness = 2
    glow.Transparency = getter() and 0.2 or 1

    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 14

    btn.MouseButton1Click:Connect(function()
        local v = not getter()
        setter(v)

        if v then
            tween(switch, {BackgroundColor3 = accent}, 0.2)
            tween(knob, {Position = UDim2.new(0, 20, 0.5, -10)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            tween(glow, {Transparency = 0.2}, 0.2)
        else
            tween(switch, {BackgroundColor3 = DS.OFF_RED}, 0.2)
            tween(knob, {Position = UDim2.new(0, 2, 0.5, -10)}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            tween(glow, {Transparency = 1}, 0.2)
        end

        updSt()
    end)

    -- Hover effect
    btn.MouseEnter:Connect(function()
        tween(fStroke, {Color = accent}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        tween(fStroke, {Color = DS.BORDER_SUBTLE}, 0.15)
    end)

    pY[pgIdx] = pY[pgIdx] + RH + G
end

local function mkSlide(pgIdx, txt, getter, setter, mn, mx, suf, cb, accent)
    accent = accent or DS.ACCENT_PRIMARY
    local pg = tPages[pgIdx]

    local f = Instance.new("Frame", pg)
    f.Name = "Slider_" .. txt
    f.Size = UDim2.new(1, -4, 0, SH)
    f.Position = UDim2.new(0, 2, 0, pY[pgIdx])
    f.BackgroundColor3 = DS.BG_PANEL
    f.BackgroundTransparency = 0  -- OPAQUE
    f.BorderSizePixel = 0
    f.ZIndex = 11

    local fCorner = Instance.new("UICorner", f)
    fCorner.CornerRadius = UDim.new(0, 8)

    local fStroke = Instance.new("UIStroke", f)
    fStroke.Color = DS.BORDER_SUBTLE
    fStroke.Thickness = 1

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(0.55, 0, 0, 14)
    lbl.Position = UDim2.new(0, 12, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.TextColor3 = DS.TXT_SECONDARY
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 12

    local vl = Instance.new("TextLabel", f)
    vl.Size = UDim2.new(0.45, -8, 0, 14)
    vl.Position = UDim2.new(0.55, 0, 0, 4)
    vl.BackgroundTransparency = 1
    vl.Text = tostring(getter()) .. (suf or "")
    vl.TextColor3 = accent
    vl.Font = Enum.Font.GothamBold
    vl.TextSize = 11
    vl.TextXAlignment = Enum.TextXAlignment.Right
    vl.ZIndex = 12

    -- Track background
    local trk = Instance.new("Frame", f)
    trk.Size = UDim2.new(1, -20, 0, 6)
    trk.Position = UDim2.new(0, 10, 0, 28)
    trk.BackgroundColor3 = DS.BG_DEEP
    trk.BorderSizePixel = 0
    trk.ZIndex = 12

    local trkCorner = Instance.new("UICorner", trk)
    trkCorner.CornerRadius = UDim.new(1, 0)

    -- Fill
    local fill = Instance.new("Frame", trk)
    fill.BackgroundColor3 = accent
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(clamp((getter() - mn) / math.max(mx - mn, 1), 0, 1), 0, 1, 0)
    fill.ZIndex = 13

    local fillCorner = Instance.new("UICorner", fill)
    fillCorner.CornerRadius = UDim.new(1, 0)

    -- Fill gradient
    local fillGrad = Instance.new("UIGradient", fill)
    fillGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, accent),
        ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
    })
    fillGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 0.3)
    })

    -- Thumb
    local thumb = Instance.new("Frame", trk)
    thumb.Size = UDim2.new(0, 14, 0, 14)
    thumb.Position = UDim2.new(clamp((getter() - mn) / math.max(mx - mn, 1), 0, 1), -7, 0.5, -7)
    thumb.BackgroundColor3 = Color3.new(1, 1, 1)
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 14

    local thumbCorner = Instance.new("UICorner", thumb)
    thumbCorner.CornerRadius = UDim.new(1, 0)

    local thumbGlow = Instance.new("UIStroke", thumb)
    thumbGlow.Color = accent
    thumbGlow.Thickness = 2
    thumbGlow.Transparency = 0.3

    local function sv(x)
        local pct = clamp((x - trk.AbsolutePosition.X) / math.max(trk.AbsoluteSize.X, 1), 0, 1)
        local v = clamp(math.round(mn + pct * (mx - mn)), mn, mx)
        setter(v)

        local newPct = (v - mn) / math.max(mx - mn, 1)
        tween(fill, {Size = UDim2.new(newPct, 0, 1, 0)}, 0.1)
        tween(thumb, {Position = UDim2.new(newPct, -7, 0.5, -7)}, 0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

        vl.Text = tostring(v) .. (suf or "")
        if cb then pcall(cb, v) end
    end

    local sl = false
    trk.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            sl = true
            sv(i.Position.X)
            tween(thumb, {Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(thumb.Position.X.Scale, -9, 0.5, -9)}, 0.1)
        end
    end)
    trk.InputChanged:Connect(function(i)
        if sl and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
            sv(i.Position.X)
        end
    end)
    trk.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            sl = false
            tween(thumb, {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(thumb.Position.X.Scale, -7, 0.5, -7)}, 0.1)
        end
    end)

    pY[pgIdx] = pY[pgIdx] + SH + G
end

local function mkDropdown(pgIdx, txt, options, getter, setter, accent)
    accent = accent or DS.ACCENT_PRIMARY
    local pg = tPages[pgIdx]

    local f = Instance.new("Frame", pg)
    f.Name = "Dropdown_" .. txt
    f.Size = UDim2.new(1, -4, 0, RH)
    f.Position = UDim2.new(0, 2, 0, pY[pgIdx])
    f.BackgroundColor3 = DS.BG_PANEL
    f.BackgroundTransparency = 0  -- OPAQUE
    f.BorderSizePixel = 0
    f.ZIndex = 11

    local fCorner = Instance.new("UICorner", f)
    fCorner.CornerRadius = UDim.new(0, 8)

    local fStroke = Instance.new("UIStroke", f)
    fStroke.Color = DS.BORDER_SUBTLE
    fStroke.Thickness = 1

    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(0.35, 0, 1, 0)
    l.Position = UDim2.new(0, 12, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = DS.TXT_SECONDARY
    l.Font = Enum.Font.Gotham
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 12

    local vl = Instance.new("TextButton", f)
    vl.Size = UDim2.new(0.65, -14, 0, 26)
    vl.Position = UDim2.new(0.35, 2, 0.5, -13)
    vl.BackgroundColor3 = DS.BG_INPUT
    vl.BorderSizePixel = 0
    vl.TextColor3 = accent
    vl.Font = Enum.Font.GothamBold
    vl.TextSize = 10
    vl.Text = getter()
    vl.ZIndex = 12
    vl.TextTruncate = Enum.TextTruncate.AtEnd
    vl.AutoButtonColor = false

    local vlCorner = Instance.new("UICorner", vl)
    vlCorner.CornerRadius = UDim.new(0, 6)

    local vlStroke = Instance.new("UIStroke", vl)
    vlStroke.Color = DS.BORDER_SUBTLE
    vlStroke.Thickness = 1

    -- Arrow icon
    local arrow = Instance.new("TextLabel", vl)
    arrow.Size = UDim2.new(0, 16, 0, 16)
    arrow.Position = UDim2.new(1, -18, 0.5, -8)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▸"
    arrow.TextColor3 = DS.TXT_MUTED
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 12
    arrow.ZIndex = 13

    local idx = 1
    for i, v in ipairs(options) do
        if v == getter() then idx = i; break end
    end

    vl.MouseButton1Click:Connect(function()
        idx = (idx % #options) + 1
        setter(options[idx])
        vl.Text = options[idx]
        tween(vlStroke, {Color = accent}, 0.2)
        tween(arrow, {Rotation = 90}, 0.15)
        task.wait(0.15)
        tween(arrow, {Rotation = 0}, 0.15)
        task.wait(0.2)
        tween(vlStroke, {Color = DS.BORDER_SUBTLE}, 0.3)
    end)

    vl.MouseEnter:Connect(function()
        tween(vl, {BackgroundColor3 = DS.BG_HOVER}, 0.15)
    end)
    vl.MouseLeave:Connect(function()
        tween(vl, {BackgroundColor3 = DS.BG_INPUT}, 0.15)
    end)

    pY[pgIdx] = pY[pgIdx] + RH + G
end

local function mkBtn(pgIdx, txt, fn, accent)
    accent = accent or DS.ACCENT_PRIMARY
    local pg = tPages[pgIdx]

    local f = Instance.new("TextButton", pg)
    f.Size = UDim2.new(1, -4, 0, 30)
    f.Position = UDim2.new(0, 2, 0, pY[pgIdx])
    f.BackgroundColor3 = accent
    f.BorderSizePixel = 0
    f.TextColor3 = DS.BG_DEEPEST
    f.Font = Enum.Font.GothamBold
    f.TextSize = 11
    f.Text = txt
    f.ZIndex = 11
    f.AutoButtonColor = false

    local fCorner = Instance.new("UICorner", f)
    fCorner.CornerRadius = UDim.new(0, 8)

    local fGrad = Instance.new("UIGradient", f)
    fGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, accent),
        ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
    })
    fGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 0.2)
    })
    fGrad.Rotation = 90

    f.MouseButton1Click:Connect(function(pos)
        ripple(f, pos or Vector2.new(f.AbsolutePosition.X + f.AbsoluteSize.X/2, f.AbsolutePosition.Y + f.AbsoluteSize.Y/2))
        fn()
    end)

    f.MouseEnter:Connect(function()
        tween(f, {BackgroundColor3 = Color3.new(1, 1, 1)}, 0.15)
        tween(f, {TextColor3 = accent}, 0.15)
    end)
    f.MouseLeave:Connect(function()
        tween(f, {BackgroundColor3 = accent}, 0.15)
        tween(f, {TextColor3 = DS.BG_DEEPEST}, 0.15)
    end)

    pY[pgIdx] = pY[pgIdx] + 30 + G
end

-- ════════════════════════════════════════════════════════════
-- TAB 1: VOID — Cyan accent
-- ════════════════════════════════════════════════════════════
mkSec(1, "◈  VOID CONTROL", DS.ACCENT_PRIMARY)
mkTog(1, "Enable Void", function() return CFG.VOID_ENABLED end, function(v)
    CFG.VOID_ENABLED = v
    updSt()
    if v then startVoid() else stopVoid() end
end, DS.ACCENT_PRIMARY)

mkDropdown(1, "Void Method",
    {"Stable","Drift","Chaotic","Circle","Spiral","Lissajous","Perlin Noise",
     "Flicker Void","Gravity Well","Helix","Figure 8","Tornado","Butterfly",
     "Double Helix","Chaotic Sphere","Quantum Tunneling","Fractal Desync",
     "Extreme Desync","Quantum Oscillation","Frame Skip"},
    function() return CFG.VOID_METHOD end,
    function(v) CFG.VOID_METHOD = v end,
    DS.ACCENT_PRIMARY
)

mkDropdown(1, "Bypass Method",
    {"None","Velocity","CFrame only","Hybrid","Physics Bypass","Extreme Networking"},
    function() return CFG.VOID_BYPASS_MODE end,
    function(v) CFG.VOID_BYPASS_MODE = v end,
    DS.ACCENT_PRIMARY
)

mkSlide(1, "Drift Speed", function() return math.floor(CFG.VOID_DRIFT_SPEED/1e6) end, function(v) CFG.VOID_DRIFT_SPEED = v*1e6 end, 1, 200, " M/s", nil, DS.ACCENT_PRIMARY)
mkSlide(1, "Drift Chaos", function() return math.floor(CFG.VOID_DRIFT_CHAOS*100) end, function(v) CFG.VOID_DRIFT_CHAOS = v*0.01 end, 1, 100, "%", nil, DS.ACCENT_PRIMARY)
mkSlide(1, "Void Altitude", function() return math.floor(CFG.VOID_Y_BASE/1e12) end, function(v) CFG.VOID_Y_BASE = v*1e12 end, 1, 1000, "B", nil, DS.ACCENT_PRIMARY)
mkTog(1, "Scramble Position", function() return CFG.VOID_SCRAMBLE end, function(v) CFG.VOID_SCRAMBLE = v end, DS.ACCENT_PRIMARY)
mkSlide(1, "Lissajous A", function() return CFG.VOID_LISSAJOUS_A end, function(v) CFG.VOID_LISSAJOUS_A = v end, 1, 10, "", nil, DS.ACCENT_PRIMARY)
mkSlide(1, "Lissajous B", function() return CFG.VOID_LISSAJOUS_B end, function(v) CFG.VOID_LISSAJOUS_B = v end, 1, 10, "", nil, DS.ACCENT_PRIMARY)

mkSec(1, "◈  EVASION & DESYNC", DS.ACCENT_SECONDARY)
mkTog(1, "Enable Desync", function() return CFG.DESYNC_ENABLED end, function(v) CFG.DESYNC_ENABLED = v; updSt() end, DS.ACCENT_SECONDARY)
mkSlide(1, "Desync Rate", function() return math.floor(CFG.DESYNC_TICK*100) end, function(v) CFG.DESYNC_TICK = v*0.01 end, 1, 100, "×0.01s", nil, DS.ACCENT_SECONDARY)
mkSlide(1, "Desync Radius", function() return CFG.DESYNC_RADIUS end, function(v) CFG.DESYNC_RADIUS = v end, 1, 100, " studs", nil, DS.ACCENT_SECONDARY)
mkTog(1, "Dodge Enemies", function() return CFG.VOID_EVADE end, function(v) CFG.VOID_EVADE = v end, DS.ACCENT_SECONDARY)
mkSlide(1, "Evasion Radius", function() return math.floor(CFG.VOID_EVADE_RADIUS/1e9) end, function(v) CFG.VOID_EVADE_RADIUS = v*1e9 end, 1, 50, "B", nil, DS.ACCENT_SECONDARY)
mkSlide(1, "Evasion Speed", function() return math.floor(CFG.VOID_EVADE_SPEED/1e9) end, function(v) CFG.VOID_EVADE_SPEED = v*1e9 end, 1, 50, "B", nil, DS.ACCENT_SECONDARY)
mkTog(1, "Enable Ghosting", function() return CFG.VOID_GHOSTING end, function(v) CFG.VOID_GHOSTING = v end, DS.ACCENT_SECONDARY)
mkSlide(1, "Ghosting Intensity", function() return math.floor(CFG.VOID_GHOSTING_INT*100) end, function(v) CFG.VOID_GHOSTING_INT = v*0.01 end, 1, 100, "%", nil, DS.ACCENT_SECONDARY)

mkSec(1, "◈  ADVANCED", DS.ACCENT_TERTIARY)
mkSlide(1, "Y Drift Range", function() return CFG.VOID_Y_DRIFT_RANGE_V end, function(v) CFG.VOID_Y_DRIFT_RANGE_V = v; CFG.VOID_Y_DRIFT_RANGE = v*1e9 end, 0, 10, "B", nil, DS.ACCENT_TERTIARY)
mkSlide(1, "Scramble Interval", function() return CFG.VOID_SCRAMBLE_INT end, function(v) CFG.VOID_SCRAMBLE_INT = v; CFG.VOID_SCRAMBLE_TIME = v*0.1 end, 1, 100, "×0.1s", nil, DS.ACCENT_TERTIARY)
mkSlide(1, "Flicker Interval", function() return CFG.VOID_FLICKER_MS end, function(v) CFG.VOID_FLICKER_MS = v; CFG.VOID_FLICKER_INT = v*0.01 end, 1, 50, "ms", nil, DS.ACCENT_TERTIARY)
mkTog(1, "Force Vertical Evasion", function() return CFG.VOID_EVADE_FORCE_UP end, function(v) CFG.VOID_EVADE_FORCE_UP = v end, DS.ACCENT_TERTIARY)
mkSlide(1, "Gravity Well Strength", function() return CFG.VOID_GRAVITY_M end, function(v) CFG.VOID_GRAVITY_M = v; CFG.VOID_GRAVITY_STR = v*1e6 end, 1, 1000, "M", nil, DS.ACCENT_TERTIARY)

-- ════════════════════════════════════════════════════════════
-- TAB 2: ORBIT — Pink accent
-- ════════════════════════════════════════════════════════════
mkSec(2, "◈  ORBIT CONTROL", DS.ACCENT_SECONDARY)
mkTog(2, "Enable Orbit", function() return CFG.ORBIT_ENABLED end, function(v)
    CFG.ORBIT_ENABLED = v
    updSt()
    if v then startOrbit() else stopOrbit() end
end, DS.ACCENT_SECONDARY)

mkDropdown(2, "Orbit Pattern",
    {"Default","Spiral","Random","Lissajous","Helix","Figure 8","Pulse",
     "Tornado","Butterfly","Quantum Orbit","Hyper Elliptical"},
    function() return CFG.ORBIT_MODE end,
    function(v) CFG.ORBIT_MODE = v end,
    DS.ACCENT_SECONDARY
)

mkSlide(2, "Orbit Speed", function() return math.floor(CFG.ORBIT_SPEED*10) end, function(v) CFG.ORBIT_SPEED = v*0.1 end, 0, 100, "×0.1", nil, DS.ACCENT_SECONDARY)
mkSlide(2, "Orbit Jitter", function() return CFG.ORBIT_JITTER end, function(v) CFG.ORBIT_JITTER = v end, 0, 360, "°", nil, DS.ACCENT_SECONDARY)
mkSlide(2, "Orbit Stability", function() return math.floor(CFG.ORBIT_STABILITY*10) end, function(v) CFG.ORBIT_STABILITY = v*0.1 end, 1, 100, "%", nil, DS.ACCENT_SECONDARY)
mkSlide(2, "Camera Height", function() return math.floor(CFG.HEIGHT_OFFSET/1000) end, function(v) CFG.HEIGHT_OFFSET = v*1000 end, 0, 2000, "k st", nil, DS.ACCENT_SECONDARY)
mkSlide(2, "Min Radius", function() return math.floor(CFG.MIN_RADIUS/10000) end, function(v) CFG.MIN_RADIUS = v*10000 end, 1, 1000, "k", nil, DS.ACCENT_SECONDARY)
mkSlide(2, "Max Radius", function() return math.floor(CFG.MAX_RADIUS/1e8) end, function(v) CFG.MAX_RADIUS = v*1e8 end, 1, 10000, "B", nil, DS.ACCENT_SECONDARY)
mkSlide(2, "Lock FOV", function() return CFG.LOCK_FOV end, function(v) CFG.LOCK_FOV = v end, 1, 180, "°", nil, DS.ACCENT_SECONDARY)
mkSlide(2, "Prediction", function() return math.floor(CFG.PREDICTION*100) end, function(v) CFG.PREDICTION = v*0.01 end, 1, 100, "%", nil, DS.ACCENT_SECONDARY)
mkTog(2, "Auto Lock", function() return CFG.AUTO_LOCK end, function(v) CFG.AUTO_LOCK = v end, DS.ACCENT_SECONDARY)
mkSlide(2, "Auto Lock Radius", function() return CFG.AUTO_LOCK_RADIUS end, function(v) CFG.AUTO_LOCK_RADIUS = v end, 10, 2000, " st", nil, DS.ACCENT_SECONDARY)

mkBtn(2, "↺  Restore Camera", function()
    stopOrbit()
    showNotif("Camera restored", DS.ACCENT_SECONDARY, 2)
end, DS.ACCENT_SECONDARY)

mkBtn(2, "✕  Drop Target", function()
    currentTgt = nil
    showNotif("Target dropped", DS.ACCENT_SECONDARY, 2)
end, DS.ACCENT_SECONDARY)

-- ════════════════════════════════════════════════════════════
-- TAB 3: EXTRAS — Gold accent
-- ════════════════════════════════════════════════════════════
mkSec(3, "◈  KILL NOTIFIER", DS.ACCENT_GOLD)
mkTog(3, "Kill Notifier", function() return CFG.KILL_NOTIFIER end, function(v) CFG.KILL_NOTIFIER = v end, DS.ACCENT_GOLD)

mkSec(3, "◈  STANDALONE DESYNC", DS.ACCENT_TERTIARY)
mkTog(3, "Desync ON", function() return CFG.DESYNC_STANDALONE end, function(v)
    CFG.DESYNC_STANDALONE = v
    updSt()
    if v then startDesyncOnly() else stopDesyncOnly() end
end, DS.ACCENT_TERTIARY)
mkSlide(3, "Desync Rate", function() return math.floor(CFG.DESYNC_TICK*100) end, function(v) CFG.DESYNC_TICK = v*0.01 end, 1, 100, "×0.01s", nil, DS.ACCENT_TERTIARY)
mkSlide(3, "Desync Radius", function() return CFG.DESYNC_RADIUS end, function(v) CFG.DESYNC_RADIUS = v end, 1, 100, " st", nil, DS.ACCENT_TERTIARY)

mkSec(3, "◈  MOVEMENT", DS.ACCENT_PRIMARY)
mkTog(3, "Speed Boost", function() return CFG.SPEED_ENABLED end, function(v) CFG.SPEED_ENABLED = v; applySpeed() end, DS.ACCENT_PRIMARY)
mkSlide(3, "Walk Speed", function() return CFG.WALK_SPEED end, function(v) CFG.WALK_SPEED = v; if CFG.SPEED_ENABLED then applySpeed() end end, 16, 100, "", nil, DS.ACCENT_PRIMARY)
mkTog(3, "Infinite Jump", function() return CFG.INF_JUMP end, function(v) CFG.INF_JUMP = v; if v then startIJ() end end, DS.ACCENT_PRIMARY)
mkTog(3, "Noclip", function() return CFG.NOCLIP end, function(v) CFG.NOCLIP = v; if v then startNoclip() else stopNoclip() end end, DS.ACCENT_PRIMARY)
mkTog(3, "Low Gravity", function() return CFG.LOW_GRAVITY end, function(v) CFG.LOW_GRAVITY = v; applyGravity() end, DS.ACCENT_PRIMARY)
mkSlide(3, "Gravity Value", function() return CFG.GRAVITY_VAL end, function(v) CFG.GRAVITY_VAL = v; if CFG.LOW_GRAVITY then applyGravity() end end, 5, 196, "", nil, DS.ACCENT_PRIMARY)

mkSec(3, "◈  NOTIFICATIONS", DS.ACCENT_SECONDARY)
mkTog(3, "Kill Notifier", function() return CFG_KN.ON end, function(v) CFG_KN.ON = v end, DS.ACCENT_SECONDARY)
mkTog(3, "Kill Sound", function() return CFG_KN.SOUND end, function(v) CFG_KN.SOUND = v end, DS.ACCENT_SECONDARY)

mkSec(3, "◈  PERFORMANCE", DS.ACCENT_GOLD)
mkBtn(3, "⚡  FPS Booster", function() applyFPSBoost() end, DS.ACCENT_GOLD)

mkSec(3, "◈  INFO", DS.TXT_MUTED)
local inf = Instance.new("TextLabel", tPages[3])
inf.Size = UDim2.new(1, -8, 0, 50)
inf.Position = UDim2.new(0, 4, 0, pY[3])
inf.BackgroundTransparency = 1
inf.Text = "Void: CFrame position manipulation\nOrbit: Camera movement patterns\nTap method name to cycle options"
inf.TextColor3 = DS.TXT_MUTED
inf.Font = Enum.Font.Gotham
inf.TextSize = 10
inf.TextWrapped = true
inf.TextXAlignment = Enum.TextXAlignment.Left
inf.ZIndex = 11
pY[3] = pY[3] + 52

-- ════════════════════════════════════════════════════════════
-- TAB 4: CONFIG — Purple accent
-- ════════════════════════════════════════════════════════════
mkSec(4, "◈  UI SETTINGS", DS.ACCENT_TERTIARY)
mkTog(4, "Show FOV Circle", function() return false end, function(v) end, DS.ACCENT_TERTIARY)

local camSt = Instance.new("TextLabel", tPages[4])
camSt.Size = UDim2.new(1, -8, 0, 20)
camSt.Position = UDim2.new(0, 4, 0, pY[4])
camSt.BackgroundTransparency = 1
camSt.Text = "Camera Hook: " .. (hasHook and "✅ Active" or "⚠️ Fallback")
camSt.TextColor3 = hasHook and DS.ON_GREEN or DS.WARN_AMBER
camSt.Font = Enum.Font.Gotham
camSt.TextSize = 11
camSt.TextXAlignment = Enum.TextXAlignment.Left
camSt.ZIndex = 11
pY[4] = pY[4] + 22

mkSec(4, "◈  SYSTEM", DS.ACCENT_PRIMARY)
mkBtn(4, "↻  Reset All Settings", function()
    CFG.VOID_ENABLED = false
    CFG.ORBIT_ENABLED = false
    CFG.DESYNC_ENABLED = false
    CFG.DESYNC_STANDALONE = false
    CFG.SPEED_ENABLED = false
    CFG.INF_JUMP = false
    CFG.NOCLIP = false
    CFG.LOW_GRAVITY = false
    stopVoid()
    stopOrbit()
    stopDesyncOnly()
    stopNoclip()
    applySpeed()
    applyGravity()
    updSt()
    showNotif("All settings reset", DS.ACCENT_PRIMARY, 2)
end, DS.OFF_RED)

-- Initialize
switchTab(1)

-- ════════════════════════════════════════════════════════════
-- RESPAWN HANDLER
-- ════════════════════════════════════════════════════════════
LP.CharacterAdded:Connect(function()
    task.wait(1)
    if CFG.VOID_ENABLED then startVoid() end
    if CFG.ORBIT_ENABLED then startOrbit() end
    if CFG.SPEED_ENABLED then applySpeed() end
    if CFG.INF_JUMP then startIJ() end
    if CFG.NOCLIP then startNoclip() end
    if CFG.LOW_GRAVITY then applyGravity() end
    if CFG.DESYNC_STANDALONE then startDesyncOnly() end
    for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
    updSt()
end)
