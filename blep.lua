local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

if game.PlaceId == 124786371598438 then
    repeat task.wait() until game:IsLoaded()
    
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    rootPart.CFrame = CFrame.new(-22.195823669433594, 1191.672119140625, -729.8814697265625)
    
    task.wait(1)
    
    local chestsFolder = Workspace:FindFirstChild("Scripted") and Workspace.Scripted:FindFirstChild("Chests")
    if chestsFolder then
        for _, v in ipairs(chestsFolder:GetDescendants()) do
            if v.Name == "Part" then
                local prompt = v:FindFirstChild("ProximityPrompt")
                if prompt and prompt.Enabled == true then
                    local currentCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    local currentRoot = currentCharacter:WaitForChild("HumanoidRootPart")
                    
                    currentRoot.CFrame = v.CFrame
                    task.wait(0.3)
                    fireproximityprompt(prompt)
                end
                task.wait(0.3)
            end
        end
    end
    
    local currentCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local currentRoot = currentCharacter:WaitForChild("HumanoidRootPart")
    currentRoot.CFrame = CFrame.new(-22.195823669433594, 1191.672119140625, -729.8814697265625)
    task.wait(0.5)

    local prompt = Workspace:WaitForChild("Scripted"):WaitForChild("VaultStart"):WaitForChild("ProximityPrompt")
    fireproximityprompt(prompt)
    
    task.wait(2)
    
    queueonteleport([[
        repeat task.wait() until game:IsLoaded()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaSecurity/vibecode/refs/heads/main/blep.lua"))()
    ]])
    
    TeleportService:Teleport(138381251771774, LocalPlayer)
else
    local targetTouchPart = nil
    local portals = {}
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Portal" then
            local touchPart = obj:FindFirstChild("Touch")
            if touchPart and touchPart:IsA("BasePart") then
                table.insert(portals, touchPart)
            end
        end
    end

    for _, touchPart in ipairs(portals) do
        local partsInPart = Workspace:GetPartsInPart(touchPart)
        local hasPlayer = false
        
        for _, part in ipairs(partsInPart) do
            local character = part.Parent
            local player = Players:GetPlayerFromCharacter(character)
            if player then
                hasPlayer = true
                break
            end
        end
        
        if not hasPlayer then
            targetTouchPart = touchPart
            break
        end
    end

    if targetTouchPart then
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local rootPart = character:WaitForChild("HumanoidRootPart")
        rootPart.CFrame = targetTouchPart.CFrame + Vector3.new(0, 3, 0)
        
        task.wait(0.5)

        queueonteleport([[
            repeat task.wait() until game:IsLoaded()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaSecurity/vibecode/refs/heads/main/blep.lua"))()
        ]])

        local Event = ReplicatedStorage:WaitForChild("VerdantRemotes"):WaitForChild("VDT_Portal.CreateSetup")
        Event:FireServer({
            Difficulty = "Hard",
            MaxPlayers = 1
        })
    end
end
