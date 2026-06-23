if not game:IsLoaded() then game.Loaded:Wait() end
print("game loaded")
if getgenv().Ran then return end
getgenv().Ran = true
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Terrain = Workspace.Terrain
local UserSettings = UserSettings():GetService("UserGameSettings")

-- ==========================================
-- 1. THE FFLAG ARSENAL (Deep Engine Override)
-- ==========================================
pcall(function()
    setfpscap(2000) 
    
    -- Framerate & Low-Level Thread Uncapping
    setfflag("TaskSchedulerTargetFps", "2000") 
    setfflag("DFIntTaskSchedulerTargetFps", "2000")
    
    -- Skybox & Environment Material Strippers (Gray/Flat Sky Target)
    setfflag("FFlagDebugGraphicsDisableLighting", "True")      
    setfflag("FFlagDebugDisableDeferredLighting", "True")      
    setfflag("FFlagDebugGraphicsDisableHalos", "True")
    setfflag("FFlagDebugGraphicsDisablePostFX", "True")
    setfflag("FFlagDebugGraphicsDisableShadows", "True")
    setfflag("FFlagDebugGraphicsDisable3DLayeredClothing", "True")
    setfflag("FFlagDebugGraphicsDisablePBR", "True")           
    
    -- Memory Allocation Restrictions
    setfflag("DFIntTextureCompositorActiveMemoryLimit", "16")  
    setfflag("FIntDebugForceMSAASamples", "0")                 
end)

-- ==========================================
-- 2. NATIVE QUALITY FORCING
-- ==========================================
pcall(function()
    UserSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    UserSettings.QualityLevel = Enum.QualityLevel.Level01
    sethiddenproperty(Lighting, "Technology", Enum.Technology.Compatibility)
end)

-- ==========================================
-- 3. SOLID GRAY ENVIRONMENT TARGETS
-- ==========================================
local GRAY_VOID = Color3.fromRGB(128, 128, 128)

local targetLighting = {
    GlobalShadows = false,
    FogStart = 0,
    FogEnd = 150,               
    FogColor = GRAY_VOID,
    Brightness = 0,
    EnvironmentDiffuseScale = 0,
    EnvironmentSpecularScale = 0,
    OutdoorAmbient = GRAY_VOID,
    Ambient = GRAY_VOID
}

local function enforceState()
    for property, value in pairs(targetLighting) do
        if Lighting[property] ~= value then
            Lighting[property] = value
        end
    end
    if Terrain.WaterWaveSize ~= 0 or Terrain.WaterWaveSpeed ~= 0 then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 1
    end
end

for property, _ in pairs(targetLighting) do
    Lighting:GetPropertyChangedSignal(property):Connect(enforceState)
end

Terrain:GetPropertyChangedSignal("WaterWaveSize"):Connect(enforceState)
Terrain:GetPropertyChangedSignal("WaterWaveSpeed"):Connect(enforceState)
enforceState()

-- ==========================================
-- 4. RESTORED CAMERA MODIFICATION
-- ==========================================
local Cam = Workspace.CurrentCamera
local formula = CFrame.new(0, 0, 0, 1, 0, 0, 0, 0.6, 0, 0, 0, 1)

task.defer(function()
    RunService.RenderStepped:Connect(function()
        if Cam then
            Cam.CFrame = Cam.CFrame * formula
        end
    end)
end)

-- ==========================================
-- 5. LOW-FREQUENCY JANITOR THREAD
-- ==========================================
task.spawn(function()
    while task.wait(4) do
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("Sky") or effect:IsA("Clouds") then
                effect:Destroy()
            end
        end
        
        if not Lighting:FindFirstChildOfClass("Sky") then
            local flatSky = Instance.new("Sky")
            flatSky.SkyboxBk = "rbxassetid://0" 
            flatSky.SkyboxDn = "rbxassetid://0"
            flatSky.SkyboxFt = "rbxassetid://0"
            flatSky.SkyboxLf = "rbxassetid://0"
            flatSky.SkyboxRt = "rbxassetid://0"
            flatSky.SkyboxUp = "rbxassetid://0"
            flatSky.CelestialBodiesShown = false
            flatSky.Parent = Lighting
        end
        enforceState()
    end
end)

-- ==========================================
-- 6. ASYNCHRONOUS HIGH-SPEED ASSET OPTIMIZER
-- ==========================================
-- Explicit lookups optimize processing speeds far better than generic tables.
local IMMEDIATE_DESTROY = {
    ["Texture"] = true, ["Decal"] = true, ["ParticleEmitter"] = true, 
    ["Trail"] = true, ["Fire"] = true, ["Smoke"] = true, 
    ["Sparkles"] = true, ["SurfaceAppearance"] = true, ["WrapLayer"] = true, 
    ["WrapTarget"] = true, ["Shirt"] = true, ["Pants"] = true, 
    ["ShirtGraphic"] = true, ["CharacterMesh"] = true, ["Accessory"] = true, 
    ["Explosion"] = true
}

local function optimizeInstance(v)
    local className = v.ClassName

    -- Immediate deletion criteria
    if IMMEDIATE_DESTROY[className] then
        v:Destroy()
        return 
    end

    -- Split basepart property manipulation off into an independent thread sequence
    if v:IsA("BasePart") then
        task.spawn(function()
            if v.Material ~= Enum.Material.SmoothPlastic then
                v.Material = Enum.Material.SmoothPlastic
            end
            if v.Reflectance ~= 0 then v.Reflectance = 0 end
            if v.CastShadow ~= false then v.CastShadow = false end
            
            if className == "MeshPart" and v.TextureID ~= "" then
                v.TextureID = ""
            end
        end)
    elseif className == "SpecialMesh" and v.TextureId ~= "" then
        v.TextureId = ""
    elseif className == "Humanoid" and v.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None then
        v.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
end

-- Distributed scanning using segmented scheduling threads to prevent framework stalling
task.defer(function()
    local descendants = Workspace:GetDescendants()
    local batchSize = 100
    
    for i = 1, #descendants, batchSize do
        task.spawn(function()
            for j = i, math.min(i + batchSize - 1, #descendants) do
                local asset = descendants[j]
                if asset then
                    optimizeInstance(asset)
                end
            end
        end)
    end
end)

-- Instant parallel filtering for newly loaded or spawned elements
Workspace.DescendantAdded:Connect(function(descendant)
    task.spawn(optimizeInstance, descendant)
end)


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ViewModels = workspace:FindFirstChild("ViewModels")

-- Modules
local TracerEffect = require(LocalPlayer.PlayerScripts.Modules.TracerEffect)
local SmokeCloud = require(LocalPlayer.PlayerScripts.Modules.SmokeCloud)
local FlashbangEffect = require(LocalPlayer.PlayerScripts.Modules.Functions.FlashbangEffect)

-- ==========================================
-- Configuration
-- ==========================================
local CONFIG = {
    TracerThickness = 0.05,
    TracerColor = {
        Friendly = Color3.fromRGB(255, 255, 255),
        Enemy = Color3.fromRGB(255, 50, 50)
    },
    FadeTime = 3,
    MaxDistance = 5000,
    Material = Enum.Material.Neon,
    UseParticles = true,
    FOV = 150,
    Smoothing = 2.5,
    MaxEspDistance = 700,
    TeamCheck = true,
    EnemyColor = Color3.fromRGB(255, 50, 50),
    DeflectColor = Color3.fromRGB(255, 165, 0),
    
    -- New Toggles
    NoSmoke = true,
    AntiFlashbang = true
}

-- Storage folder for tracers
local tracerFolder = workspace:FindFirstChild("BulletTracers") 
if not tracerFolder then
    tracerFolder = Instance.new("Folder")
    tracerFolder.Name = "BulletTracers"
    tracerFolder.Parent = workspace
end

-- ==========================================
-- Drawing Setup (FOV & ESP)
-- ==========================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = true
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled = false
FOVCircle.Radius = CONFIG.FOV
FOVCircle.Transparency = 1

local espCache = {}

local function createESP(player)
    local esp = {
        boxOutline = Drawing.new("Square"),
        box = Drawing.new("Square"),
        healthOutline = Drawing.new("Line"),
        healthBar = Drawing.new("Line"),
        name = Drawing.new("Text"),
        distance = Drawing.new("Text"),
        tool = Drawing.new("Text")
    }
    
    esp.boxOutline.Thickness = 3
    esp.boxOutline.Filled = false
    esp.boxOutline.Transparency = 0.5
    esp.boxOutline.Color = Color3.fromRGB(0, 0, 0)
    
    esp.box.Thickness = 1
    esp.box.Filled = false
    esp.box.Transparency = 1
    
    esp.healthOutline.Thickness = 3
    esp.healthOutline.Transparency = 0.5
    esp.healthOutline.Color = Color3.fromRGB(0, 0, 0)
    
    esp.healthBar.Thickness = 1
    esp.healthBar.Transparency = 1
    
    local function formatText(textDrawing, size)
        textDrawing.Size = size
        textDrawing.Center = true
        textDrawing.Outline = true
        textDrawing.Transparency = 1
        textDrawing.Color = Color3.fromRGB(255, 255, 255)
    end
    
    formatText(esp.name, 16)
    formatText(esp.distance, 14)
    formatText(esp.tool, 14)
    
    espCache[player] = esp
end

local function removeESP(player)
    if espCache[player] then
        for _, drawing in pairs(espCache[player]) do
            drawing:Remove()
        end
        espCache[player] = nil
    end
end

-- Initialize ESP
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then createESP(player) end
end
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then createESP(player) end
end)
Players.PlayerRemoving:Connect(removeESP)

-- ==========================================
-- Utility Functions
-- ==========================================
local function isEnemy(player)
    if not CONFIG.TeamCheck then return true end
    local myTeam = LocalPlayer:GetAttribute("TeamID")
    local theirTeam = player:GetAttribute("TeamID")
    
    if myTeam == nil or theirTeam == nil then return true end
    return myTeam ~= theirTeam
end

local function isDeflecting(plr)
    if not ViewModels then return false end
    
    local targetViewmodel = nil
    local pattern = "^" .. plr.Name .. " %-" 

    for _, model in ipairs(ViewModels:GetChildren()) do
        if string.match(model.Name, pattern) then
            targetViewmodel = model
            break
        end
    end

    if targetViewmodel then
        local animcontroller = targetViewmodel:FindFirstChild("AnimationController")
        if animcontroller then
            local animator = animcontroller:FindFirstChild("Animator")
            if animator then
                local tracks = animator:GetPlayingAnimationTracks()
                for _, track in ipairs(tracks) do
                    if track.Animation and track.Animation.AnimationId == "rbxassetid://14761220206" then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function getClosestPlayerInFOV()
    local closestPlayer = nil
    local shortestDistance = CONFIG.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isEnemy(player) and not isDeflecting(player) then
            local character = player.Character
            if character and character:FindFirstChild("Head") and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
                
                local dist = (Camera.CFrame.Position - character.HumanoidRootPart.Position).Magnitude
                if dist <= CONFIG.MaxDistance then
                    local head = character.Head
                    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    
                    if onScreen then
                        local headVector2 = Vector2.new(screenPos.X, screenPos.Y)
                        local distanceFromMouse = (headVector2 - mousePos).Magnitude
                        
                        if distanceFromMouse < shortestDistance then
                            shortestDistance = distanceFromMouse
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- ==========================================
-- Visual Tracer Part Creator
-- ==========================================
local function createTracerPart(startPos, endPos, isEnemyPlayer)
    local distance = (startPos - endPos).Magnitude
    if distance > CONFIG.MaxDistance then return end
    
    local tracer = Instance.new("Part")
    tracer.Name = "BulletTracer"
    tracer.Anchored = true
    tracer.CanCollide = false
    tracer.CanQuery = false
    tracer.CastShadow = false
    tracer.Material = CONFIG.Material
    tracer.Color = isEnemyPlayer and CONFIG.TracerColor.Enemy or CONFIG.TracerColor.Friendly
    tracer.Transparency = 0.3
    tracer.Size = Vector3.new(CONFIG.TracerThickness, CONFIG.TracerThickness, distance)
    tracer.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -distance / 2)
    tracer:SetAttribute("CreationTime", os.clock())
    
    local light = Instance.new("PointLight")
    light.Color = tracer.Color
    light.Brightness = 2
    light.Range = 10
    light.Parent = tracer
    
    if CONFIG.UseParticles then
        local attachment0 = Instance.new("Attachment")
        attachment0.Position = Vector3.new(0, 0, distance/2)
        attachment0.Parent = tracer
        
        local attachment1 = Instance.new("Attachment")
        attachment1.Position = Vector3.new(0, 0, -distance/2)
        attachment1.Parent = tracer
        
        local trail = Instance.new("Trail")
        trail.Color = ColorSequence.new(tracer.Color)
        trail.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(1, 1)
        })
        trail.Lifetime = 0.2
        trail.WidthScale = NumberSequence.new(1)
        trail.Attachment0 = attachment0
        trail.Attachment1 = attachment1
        trail.Parent = tracer
    end
    
    tracer.Parent = tracerFolder
    
    local tweenInfo = TweenInfo.new(CONFIG.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local fadeTween = TweenService:Create(tracer, tweenInfo, {
        Transparency = 1,
        Size = Vector3.new(CONFIG.TracerThickness * 0.5, CONFIG.TracerThickness * 0.5, distance)
    })
    local lightTween = TweenService:Create(light, tweenInfo, {
        Brightness = 0
    })
    
    fadeTween:Play()
    lightTween:Play()
    
    fadeTween.Completed:Connect(function()
        tracer:Destroy()
    end)
end

-- ==========================================
-- OTH Function Hooking
-- ==========================================

-- 1. Bullet Tracers Hook Setup
local originalPlay = TracerEffect.Play
TracerEffect.Play = newcclosure(function(self, tracerData, config, options)
    return originalPlay(self, tracerData, config, options)
end)

oth.hook(TracerEffect.Play, function(self, tracerData, config, options)
    task.spawn(function()
        if not tracerData or not tracerData.RaycastResults then return end
        
        for _, raycastResult in ipairs(tracerData.RaycastResults) do
            local startPos = raycastResult.StartPosition or (options and options.MuzzlePosition)
            local endPos = raycastResult.Position
            
            if startPos and endPos then
                createTracerPart(startPos, endPos, tracerData.IsEnemy or false)
            end
        end
    end)
    return oth.get_root_callback()(self, tracerData, config, options)
end)

-- 2. NoSmoke Hook Setup
local originalSmokeSetup = SmokeCloud._Setup
SmokeCloud._Setup = newcclosure(function(self)
    return originalSmokeSetup(self)
end)

oth.hook(SmokeCloud._Setup, function(self)
    if CONFIG.NoSmoke then
        -- Instantiating an empty invisible model so engine methods like :ScaleTo() run without erroring
        self.Model = Instance.new("Model") 
        self._start_spring.Target = 1
        return
    end
    return oth.get_root_callback()(self)
end)

-- 3. Anti-Flashbang Hook Setup
-- We use a proxy logic wrapper to hook the direct function module safely
local originalFlashbang = FlashbangEffect
local flashbangHook; flashbangHook = hookfunction(FlashbangEffect, newcclosure(function(...)
    if CONFIG.AntiFlashbang then
        return -- Intercept the call entirely to stop screen flashing or particle generation
    end
    return flashbangHook(...)
end))

-- ==========================================
-- Main Render Loop
-- ==========================================
RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = mousePos

    -- Update ESP Render Calculations
    for player, esp in pairs(espCache) do
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        
        if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Head") and humanoid and humanoid.Health > 0 then
            local distObj = (Camera.CFrame.Position - character.HumanoidRootPart.Position).Magnitude
            local isE = isEnemy(player)
            
            if isE and distObj <= CONFIG.MaxEspDistance then
                local deflecting = isDeflecting(player)
                local displayColor = deflecting and CONFIG.DeflectColor or CONFIG.EnemyColor
                esp.box.Color = displayColor
                
                local headPos, onScreen = Camera:WorldToViewportPoint(character.Head.Position + Vector3.new(0, 0.5, 0))
                local rootPos = Camera:WorldToViewportPoint(character.HumanoidRootPart.Position - Vector3.new(0, 3, 0))
                
                if onScreen then
                    local topY = math.min(headPos.Y, rootPos.Y)
                    local bottomY = math.max(headPos.Y, rootPos.Y)
                    
                    local height = math.abs(bottomY - topY)
                    local width = height / 2 
                    local boxPosition = Vector2.new(rootPos.X - width / 2, topY)
                    
                    esp.boxOutline.Size = Vector2.new(width, height)
                    esp.boxOutline.Position = boxPosition
                    esp.box.Size = Vector2.new(width, height)
                    esp.box.Position = boxPosition
                    
                    local healthPct = humanoid.Health / humanoid.MaxHealth
                    local healthColor = Color3.fromRGB(255 - (healthPct * 255), 255 * healthPct, 0)
                    local barX = boxPosition.X - 6
                    
                    esp.healthOutline.From = Vector2.new(barX, topY)
                    esp.healthOutline.To = Vector2.new(barX, bottomY)
                    
                    esp.healthBar.From = Vector2.new(barX, bottomY - (height * healthPct))
                    esp.healthBar.To = Vector2.new(barX, bottomY)
                    esp.healthBar.Color = healthColor
                    
                    esp.name.Text = player.DisplayName
                    esp.name.Position = Vector2.new(rootPos.X, topY - 20)
                    esp.name.Color = displayColor
                    
                    esp.distance.Text = "[" .. math.floor(distObj) .. "m]"
                    esp.distance.Position = Vector2.new(rootPos.X, bottomY + 5)
                    
                    local tool = character:FindFirstChildOfClass("Tool")
                    if deflecting then
                        esp.tool.Text = "[DEFLECTING]"
                        esp.tool.Color = CONFIG.DeflectColor
                    else
                        esp.tool.Text = tool and tool.Name or "None"
                        esp.tool.Color = Color3.fromRGB(255, 255, 255)
                    end
                    esp.tool.Position = Vector2.new(rootPos.X, bottomY + 20)
                    
                    for _, drawing in pairs(esp) do drawing.Visible = true end
                else
                    for _, drawing in pairs(esp) do drawing.Visible = false end
                end
            else
                for _, drawing in pairs(esp) do drawing.Visible = false end
            end
        else
            for _, drawing in pairs(esp) do drawing.Visible = false end
        end
    end

    -- Camera/Mouse Alignment Logic
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getClosestPlayerInFOV()
        if target then
            local headPos, _ = Camera:WorldToViewportPoint(target.Character.Head.Position)
            local deltaX = headPos.X - mousePos.X
            local deltaY = headPos.Y - mousePos.Y
            
            mousemoverel(deltaX / CONFIG.Smoothing, deltaY / CONFIG.Smoothing)
        end
    end
end)

-- Garbage Collection / Cleanup Thread
task.spawn(function()
    while task.wait(5) do
        local now = os.clock()
        for _, child in ipairs(tracerFolder:GetChildren()) do
            local creationTime = child:GetAttribute("CreationTime")
            if creationTime and (now - creationTime > 5) then
                child:Destroy()
            end
        end
    end
end)
print("loaded da bs")
-- this is sooooo stupid
queueonteleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/LuaSecurity/vibecode/refs/heads/main/Assist.lua'))()")
