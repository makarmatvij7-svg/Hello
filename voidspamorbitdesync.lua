--Yeah, the UI finally stopped being buggy as hell. You're welcome.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--CORE STUFF
local Character, Humanoid, RootPart = nil, nil, nil

local voidConnection, desyncConnection, orbitConnection, godModeConnection = nil, nil, nil, nil
local heightTrackerConnection = nil

local isVoidSpamming = false
local isDesyncing = false
local isOrbiting = false
local targetPlayer = nil

local lastKnownHeight = 5
local VOID_Y = -9999999999

local ORBIT_SPEED = 8555
local ORBIT_RADIUS = 16
local ORBIT_MAX_DISTANCE = 90
local DESYNC_INTENSITY = 0.92

local CAMERA_LOCK_ENABLED = true

--CHARACTER HANDLING
local function UpdateCharacterReferences(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid", 8)
    RootPart = char:WaitForChild("HumanoidRootPart", 8)
    if RootPart then 
        lastKnownHeight = RootPart.Position.Y 
    end
end

if LocalPlayer.Character then 
    UpdateCharacterReferences(LocalPlayer.Character) 
end

LocalPlayer.CharacterAdded:Connect(UpdateCharacterReferences)
LocalPlayer.CharacterRemoving:Connect(function()
    StopVoidSpam()
    StopDesync()
    StopOrbit()
    if godModeConnection then 
        godModeConnection:Disconnect() 
        godModeConnection = nil 
    end
    Character, Humanoid, RootPart = nil, nil, nil
end)

-- Keep track of safe height when not voiding
heightTrackerConnection = RunService.Heartbeat:Connect(function()
    if RootPart and not isVoidSpamming and Humanoid and Humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
        local currentY = RootPart.Position.Y
        if currentY > lastKnownHeight and math.abs(currentY - lastKnownHeight) < 50 then
            lastKnownHeight = currentY
        end
    end
end)

--UTILITY
local function GetNearestPlayer()
    local nearest, minDist = nil, math.huge
    local myPos = (RootPart and RootPart.Position) or Vector3.zero
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (plr.Character.HumanoidRootPart.Position - myPos).Magnitude
            if dist < minDist and dist < ORBIT_MAX_DISTANCE then
                minDist = dist
                nearest = plr
            end
        end
    end
    return nearest
end

--EXPLOIT FUNCTIONS
function StartVoidSpam()
    if isVoidSpamming then return end
    isVoidSpamming = true
    
    if voidConnection then voidConnection:Disconnect() end
    
    local lastToggle = 0
    local voidState = false
    
    voidConnection = RunService.Heartbeat:Connect(function()
        if not RootPart or not isVoidSpamming then return end
        
        local now = tick()
        if now - lastToggle > 0.028 then
            lastToggle = now
            voidState = not voidState
            
            local pos = RootPart.Position
            if voidState then
                RootPart.CFrame = CFrame.new(pos.X, VOID_Y, pos.Z)
            else
                RootPart.CFrame = CFrame.new(pos.X, lastKnownHeight + 0.5, pos.Z)
            end
        end
    end)
    UpdateStatuses()
end

function StopVoidSpam()
    isVoidSpamming = false
    if voidConnection then 
        voidConnection:Disconnect() 
        voidConnection = nil 
    end
    UpdateStatuses()
end

function StartDesync()
    if isDesyncing then return end
    isDesyncing = true
    
    if desyncConnection then desyncConnection:Disconnect() end
    
    desyncConnection = RunService.Stepped:Connect(function(dt)
        if not RootPart or not isDesyncing then return end
        
        sethiddenproperty(LocalPlayer, "SimulationRadius", 1000)
        sethiddenproperty(RootPart, "RootPriority", 1)
        
        local currentVel = RootPart.Velocity
        sethiddenproperty(RootPart, "Velocity", currentVel * (1 + (DESYNC_INTENSITY - 0.9) * dt * 30))
    end)
    UpdateStatuses()
end

function StopDesync()
    isDesyncing = false
    if desyncConnection then 
        desyncConnection:Disconnect() 
        desyncConnection = nil 
    end
    UpdateStatuses()
end

function StartOrbit(target)
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
    if isOrbiting and targetPlayer == target then return end
    
    targetPlayer = target
    isOrbiting = true
    
    if orbitConnection then orbitConnection:Disconnect() end
    
    orbitConnection = RunService.RenderStepped:Connect(function()
        if not RootPart then StopOrbit(); return end
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then 
            StopOrbit(); return 
        end
        
        local targetRoot = targetPlayer.Character.HumanoidRootPart
        if (targetRoot.Position - RootPart.Position).Magnitude > ORBIT_MAX_DISTANCE then 
            StopOrbit(); return 
        end
        
        if Humanoid and (Humanoid.Sit or Humanoid.PlatformStand or Humanoid:GetState() == Enum.HumanoidStateType.Dead) then 
            return 
        end
        
        local angle = tick() * ORBIT_SPEED
        local offset = Vector3.new(
            math.cos(angle) * ORBIT_RADIUS, 
            10 + math.sin(angle * 1.4) * 6, 
            math.sin(angle) * ORBIT_RADIUS
        )
        
        RootPart.CFrame = CFrame.new(targetRoot.Position + offset) * CFrame.Angles(0, angle * 1.2, 0)
        
        if CAMERA_LOCK_ENABLED then
            local cam = Workspace.CurrentCamera
            if cam then
                cam.CFrame = CFrame.lookAt(cam.CFrame.Position, targetRoot.Position + Vector3.new(0, 2.5, 0))
            end
        end
    end)
    UpdateStatuses()
end

function StopOrbit()
    isOrbiting = false
    targetPlayer = nil
    if orbitConnection then 
        orbitConnection:Disconnect() 
        orbitConnection = nil 
    end
    UpdateStatuses()
end

function ActivateGodMode()
    if godModeConnection then
        StopVoidSpam()
        StopDesync()
        StopOrbit()
        godModeConnection:Disconnect()
        godModeConnection = nil
        UpdateStatuses()
        return
    end
    
    StartVoidSpam()
    StartDesync()
    
    godModeConnection = RunService.Heartbeat:Connect(function()
        if isOrbiting then return end
        local nearest = GetNearestPlayer()
        if nearest then 
            StartOrbit(nearest) 
        end
    end)
    UpdateStatuses()
end

--UI
local ScreenGui, MainFrame

pcall(function()
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "EDENXANDER_UI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 280, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -140, 0.3, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    Title.Text = "Rivals voidspam,etc."
    Title.TextColor3 = Color3.fromRGB(0, 255, 180)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.Parent = MainFrame

    -- Status labels
    local StatusFrame = Instance.new("Frame")
    StatusFrame.Size = UDim2.new(1, -20, 0, 140)
    StatusFrame.Position = UDim2.new(0, 10, 0, 50)
    StatusFrame.BackgroundTransparency = 1
    StatusFrame.Parent = MainFrame

    local function CreateStatus(name, y)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 22)
        lbl.Position = UDim2.new(0, 0, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.Text = name .. ": OFF"
        lbl.Parent = StatusFrame
        return lbl
    end

    local voidStatus   = CreateStatus("Void Spam", 0)
    local desyncStatus = CreateStatus("Desync", 25)
    local orbitStatus  = CreateStatus("Orbit", 50)
    local godStatus    = CreateStatus("God Mode", 75)
    local camStatus    = CreateStatus("Camera Lock", 100)

    function UpdateStatuses()
        voidStatus.Text = "Void Spam: " .. (isVoidSpamming and "ACTIVE" or "OFF")
        voidStatus.TextColor3 = isVoidSpamming and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 80, 80)
        
        desyncStatus.Text = "Desync: " .. (isDesyncing and "ACTIVE" or "OFF")
        desyncStatus.TextColor3 = isDesyncing and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 80, 80)
        
        orbitStatus.Text = "Orbit: " .. (isOrbiting and "LOCKED" or "OFF")
        orbitStatus.TextColor3 = isOrbiting and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(255, 80, 80)
        
        godStatus.Text = "God Mode: " .. (godModeConnection and "ACTIVE" or "OFF")
        godStatus.TextColor3 = godModeConnection and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 80, 80)
        
        camStatus.Text = "Camera Lock: " .. (CAMERA_LOCK_ENABLED and "ON" or "OFF")
    end

    local function CreateButton(text, y, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 35)
        btn.Position = UDim2.new(0, 10, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(220, 220, 220)
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 14
        btn.Parent = MainFrame
        
        btn.MouseButton1Click:Connect(function()
            callback()
            UpdateStatuses()
        end)
        return btn
    end

    CreateButton("Toggle Void Spam (V)", 200, function()
        if isVoidSpamming then StopVoidSpam() else StartVoidSpam() end
    end)
    
    CreateButton("Toggle Desync (D)", 240, function()
        if isDesyncing then StopDesync() else StartDesync() end
    end)
    
    CreateButton("Toggle Orbit Nearest (O)", 280, function()
        if isOrbiting then 
            StopOrbit() 
        else
            local nearest = GetNearestPlayer()
            if nearest then StartOrbit(nearest) end
        end
    end)
    
    CreateButton("Toggle God Mode (G)", 320, ActivateGodMode)
    
    CreateButton("Toggle Camera Lock (C)", 360, function()
        CAMERA_LOCK_ENABLED = not CAMERA_LOCK_ENABLED
        UpdateStatuses()
    end)

    local destroyBtn = CreateButton("SELF DESTRUCT", 400, function()
        getgenv().EDENXANDER_DESTROY()
        if ScreenGui then ScreenGui:Destroy() end
    end)
    destroyBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
end)

--CLEANUP
getgenv().EDENXANDER_DESTROY = function()
    if heightTrackerConnection then 
        heightTrackerConnection:Disconnect() 
        heightTrackerConnection = nil 
    end
    
    StopVoidSpam()
    StopDesync()
    StopOrbit()
    
    if godModeConnection then 
        godModeConnection:Disconnect() 
        godModeConnection = nil 
    end
    
    if ScreenGui then ScreenGui:Destroy() end
    
    print("🌀 EDEN-XANDER Suite v4.2 fully terminated.")
end

print("🌀 EDEN-XANDER Rivals Exploit Suite v4.2 + UI LOADED")
print("Status sync fixed. Orbit logic cleaned. Enjoy.")
