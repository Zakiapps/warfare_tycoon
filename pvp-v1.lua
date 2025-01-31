local player = game.Players.LocalPlayer
local camera = game.Workspace.CurrentCamera -- Get the player's camera
local aimbotEnabled = true
local espEnabled = true
local hbeEnabled = true
local aimRange = 200 -- Maximum range for auto-aim to detect enemies
local switchCooldown = 1 -- Cooldown time between switching targets (in seconds)
local lastSwitchTime = tick() -- Track the last time a target was switched
local playerTeam = player:GetAttribute("MG_Team")
local currentTarget = nil -- Track the current target
local attacker = nil -- Track the enemy currently attacking the player

-- Function to update player's team
local function updateTeam()
    playerTeam = player:GetAttribute("MG_Team")
    if playerTeam == nil then
        warn("Player does not have a valid MG_Team attribute")
    else
        print("Player's MG_Team updated to: ", playerTeam)
    end
end

-- Initial team check
updateTeam()

-- Listen for changes to the `MG_Team` attribute
player:GetAttributeChangedSignal("MG_Team"):Connect(updateTeam)

-- Function to check if the target is on the opposing team based on `MG_Team`
local function isOpposingTeam(targetPlayer)
    local targetTeam = targetPlayer:GetAttribute("MG_Team")
    if targetTeam == nil then
        warn(targetPlayer.Name .. " does not have a valid MG_Team attribute")
        return false
    end
    return (playerTeam == "Blue" and targetTeam == "Red") or (playerTeam == "Red" and targetTeam == "Blue")
end

-- Function to prioritize the enemy attacking the player
local function prioritizeAttacker()
    if attacker and attacker.Character and attacker.Character:FindFirstChild("Humanoid") and attacker.Character.Humanoid.Health > 0 then
        local distance = (player.Character.HumanoidRootPart.Position - attacker.Character.HumanoidRootPart.Position).Magnitude
        if distance <= aimRange then
            return attacker.Character
        end
    end
    return nil
end

-- Function to find the closest enemy if no one is attacking
local function getClosestEnemy()
    local closestTarget = nil
    local closestDistance = math.huge

    for _, targetPlayer in pairs(game.Players:GetPlayers()) do
        if targetPlayer ~= player and isOpposingTeam(targetPlayer) and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") and targetPlayer.Character.Humanoid.Health > 0 then
            local distance = (player.Character.HumanoidRootPart.Position - targetPlayer.Character.HumanoidRootPart.Position).Magnitude

            if distance <= aimRange and distance < closestDistance then
                closestDistance = distance
                closestTarget = targetPlayer.Character
            end
        end
    end

    return closestTarget
end

-- Function to instantly lock the camera onto the target's head
local function lockAimOnTarget(target)
    if target and target:FindFirstChild("Head") and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
        -- Instantly snap the camera to the target's head
        camera.CFrame = CFrame.new(camera.CFrame.Position, target.Head.Position)
        print("Instantly locked onto:", target.Name)

        -- If the target dies, switch to another target
        target.Humanoid.Died:Connect(function()
            print("Target died, switching to another target...")
            currentTarget = nil -- Clear the current target so a new one can be selected
        end)
    else
        currentTarget = nil -- Clear target if the player is already dead or invalid
    end
end

-- Function to handle when the player takes damage
local function onPlayerDamaged(damage, attackerPlayer)
    if isOpposingTeam(attackerPlayer) then
        attacker = attackerPlayer
    end
end

-- Connect to the player's humanoid taking damage to track attackers
player.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.TakingDamage:Connect(function(damage, attackerPlayer)
        onPlayerDamaged(damage, attackerPlayer)
    end)
end)

-- ESP Function: Add ESP for enemy players
local function addESP(targetPlayer)
    if not targetPlayer.Character or targetPlayer == player or not isOpposingTeam(targetPlayer) then
        return 
    end

    local char = targetPlayer.Character

    -- Add ESP Box for each body part
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") and not part:FindFirstChild("ESP") then
            local espBox = Instance.new("BoxHandleAdornment")
            espBox.Name = "ESP"
            espBox.AlwaysOnTop = true
            espBox.ZIndex = 1
            espBox.Adornee = part
            espBox.Color3 = Color3.new(1, 0, 0) -- Red color for ESP
            espBox.Transparency = 0.7
            espBox.Size = part.Size
            espBox.Parent = part
        end
    end
end

-- HBE Function: Add Hitbox ESP for enemy players
local function addHitboxESP(targetPlayer)
    if not targetPlayer.Character or targetPlayer == player or not isOpposingTeam(targetPlayer) then return end
    
    local char = targetPlayer.Character
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") and not part:FindFirstChild("HBE") then
            local hbeBox = Instance.new("BoxHandleAdornment")
            hbeBox.Name = "HBE"
            hbeBox.AlwaysOnTop = true
            hbeBox.ZIndex = 2
            hbeBox.Adornee = part
            hbeBox.Color3 = Color3.new(0, 1, 0) -- Green color for HBE
            hbeBox.Transparency = 0.4
            hbeBox.Size = part.Size
            hbeBox.Parent = part
        end
    end
end

-- Create the GUI for toggling Aimbot, ESP, and HBE
local gui = Instance.new("ScreenGui")
gui.Name = "AimbotESP_GUI"
gui.Parent = player:WaitForChild("PlayerGui") -- Add the GUI to the player's PlayerGui
gui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 250)
mainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local aimbotButton = Instance.new("TextButton")
aimbotButton.Size = UDim2.new(0, 250, 0, 40)
aimbotButton.Position = UDim2.new(0.1, 0, 0.25, 0)
aimbotButton.BackgroundColor3 = Color3.fromRGB(0, 85, 255)
aimbotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
aimbotButton.Text = "Aimbot: ON"
aimbotButton.Font = Enum.Font.SourceSans
aimbotButton.TextSize = 18
aimbotButton.Parent = mainFrame

aimbotButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    aimbotButton.Text = aimbotEnabled and "Aimbot: ON" or "Aimbot: OFF"
end)

local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(0, 250, 0, 40)
espButton.Position = UDim2.new(0.1, 0, 0.45, 0)
espButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
espButton.TextColor3 = Color3.fromRGB(255, 255, 255)
espButton.Text = "ESP: ON"
espButton.Font = Enum.Font.SourceSans
espButton.TextSize = 18
espButton.Parent = mainFrame

espButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espButton.Text = espEnabled and "ESP: ON" or "ESP: OFF"
end)

local hbeButton = Instance.new("TextButton")
hbeButton.Size = UDim2.new(0, 250, 0, 40)
hbeButton.Position = UDim2.new(0.1, 0, 0.65, 0)
hbeButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
hbeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hbeButton.Text = "HBE: ON"
hbeButton.Font = Enum.Font.SourceSans
hbeButton.TextSize = 18
hbeButton.Parent = mainFrame

hbeButton.MouseButton1Click:Connect(function()
    hbeEnabled = not hbeEnabled
    hbeButton.Text = hbeEnabled and "HBE: ON" or "HBE: OFF"
end)

-- Aimbot, ESP, HBE loop with attacker prioritization and dead target handling
game:GetService("RunService").RenderStepped:Connect(function()
    local currentTime = tick()

    if aimbotEnabled then
        -- Prioritize attacker if there is one
        local target = prioritizeAttacker()

        -- If no attacker, fall back to the closest target
        if not target or currentTime - lastSwitchTime > switchCooldown then
            target = getClosestEnemy()
            lastSwitchTime = currentTime -- Update the last switch time
        end

        -- Lock aim on the chosen target
        if target then
            lockAimOnTarget(target)
        end
    end

    -- ESP Logic
    if espEnabled then
        for _, targetPlayer in pairs(game.Players:GetPlayers()) do
            addESP(targetPlayer)
        end
    end

    -- HBE Logic
    if hbeEnabled then
        for _, targetPlayer in pairs(game.Players:GetPlayers()) do
            addHitboxESP(targetPlayer)
        end
    end
end)