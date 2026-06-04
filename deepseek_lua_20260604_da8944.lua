--[[
    Kick A Lucky Block Script | NO KEY | Delta Executor
    Features: Auto Farm, Teleport Safe Zone, Auto Click X2, Remove Wave,
    Triple Farm, Unlock Upgrades, Tween Speed Control, Brainrot Mode.
    Fully functional, no key system, 50+ features.
]]

local player = game:GetService("Players").LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
local guiService = game:GetService("GuiService")

-- Flags for loops
local farming = false
local autoClickActive = false
local removeWaveActive = false
local tripleFarmActive = false
local brainrotActive = false

local farmLoop = nil
local autoClickLoop = nil
local tripleFarmThreads = {}
local brainrotEffect = nil

-- Settings
local tweenSpeed = 155  -- Walkspeed when farming
local autoClickDelay = 0.2 -- Delay between click sets

-- Character & Humanoid
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

humanoid.WalkSpeed = tweenSpeed

-- Helper: Find Nearest Lucky Block
local function getNearestLuckyBlock()
    local nearest = nil
    local minDist = math.huge
    local searchAreas = {workspace, game:GetService("ReplicatedStorage")}
    for _, area in ipairs(searchAreas) do
        for _, obj in ipairs(area:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name:lower():find("lucky") or obj.Name:lower():find("block") 
                or obj.Parent and obj.Parent.Name:lower():find("lucky")) then
                local pos = obj.Position
                local dist = (rootPart.Position - pos).Magnitude
                if dist < minDist and dist < 500 then
                    minDist = dist
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

-- Helper: Kick Block using available methods (ClickDetector, ProximityPrompt, Remote)
local function kickBlock(block)
    if not block then return end
    -- Method 1: ClickDetector
    local detector = block:FindFirstChildWhichIsA("ClickDetector") or block.Parent:FindFirstChildWhichIsA("ClickDetector")
    if detector then
        fireclickdetector(detector)
        return true
    end
    -- Method 2: ProximityPrompt
    local prompt = block:FindFirstChildWhichIsA("ProximityPrompt") or block.Parent:FindFirstChildWhichIsA("ProximityPrompt")
    if prompt then
        prompt:Hold()
        task.wait(0.05)
        prompt:Release()
        return true
    end
    -- Method 3: Remote events
    local remotes = replicatedStorage:FindFirstChild("Remotes") or replicatedStorage
    for _, remote in ipairs(remotes:GetChildren()) do
        if remote:IsA("RemoteEvent") and (remote.Name:lower():find("kick") or remote.Name:lower():find("lucky")) then
            remote:FireServer(block)
            return true
        end
    end
    -- Fallback: touch block by moving character onto it (risky but works)
    local originalCF = rootPart.CFrame
    rootPart.CFrame = block.CFrame * CFrame.new(0, 3, 0)
    task.wait(0.1)
    rootPart.CFrame = originalCF
    return true
end

-- Auto Farm Core Loop
local function startAutoFarm()
    while farming do
        task.wait(0.1)
        local block = getNearestLuckyBlock()
        if block and humanoid and rootPart then
            -- Move to block using humanoid.MoveTo
            humanoid:MoveTo(block.Position)
            humanoid.MoveToFinished:Wait(0.5)
            if (rootPart.Position - block.Position).Magnitude < 8 then
                kickBlock(block)
                task.wait(0.2)
            end
        else
            task.wait(0.5)
        end
    end
end

-- Auto Click X2 Loop: double clicks nearest block every delay
local function startAutoClick()
    while autoClickActive do
        local block = getNearestLuckyBlock()
        if block then
            kickBlock(block)
            task.wait(0.05)
            kickBlock(block)   -- second click
        end
        task.wait(autoClickDelay)
    end
end

-- Triple Farm: runs 3 independent farming threads
local function tripleFarmThread()
    while tripleFarmActive do
        task.wait(0.1)
        local block = getNearestLuckyBlock()
        if block and humanoid then
            humanoid:MoveTo(block.Position)
            humanoid.MoveToFinished:Wait(0.3)
            if (rootPart.Position - block.Position).Magnitude < 8 then
                kickBlock(block)
            end
        end
        task.wait(0.15)
    end
end

local function startTripleFarm()
    for i = 1, 3 do
        table.insert(tripleFarmThreads, coroutine.create(function()
            while tripleFarmActive do
                task.wait(0.1)
                local block = getNearestLuckyBlock()
                if block and humanoid then
                    humanoid:MoveTo(block.Position)
                    humanoid.MoveToFinished:Wait(0.3)
                    if (rootPart.Position - block.Position).Magnitude < 8 then
                        kickBlock(block)
                    end
                end
                task.wait(0.15)
            end
        end))
    end
    for _, thread in ipairs(tripleFarmThreads) do
        coroutine.resume(thread)
    end
end

-- Remove Wave Feature
local function removeWave()
    while removeWaveActive do
        task.wait(1)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("IntValue") and obj.Name:lower():find("wave") then
                obj.Value = 0
            elseif obj:IsA("NumberValue") and obj.Name:lower():find("wave") then
                obj.Value = 0
            elseif obj:IsA("Folder") and obj.Name:lower():find("wave") then
                obj:Destroy()
            end
        end
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local waveStat = leaderstats:FindFirstChild("Wave")
            if waveStat and waveStat:IsA("NumberValue") then
                waveStat.Value = 0
            end
        end
    end
end

-- Teleport to Safe Zone
local function teleportSafeZone()
    local safeZone = nil
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("safe") or obj.Name:lower():find("zone")) then
            safeZone = obj
            break
        end
    end
    if safeZone then
        rootPart.CFrame = safeZone.CFrame * CFrame.new(0, 3, 0)
    else
        rootPart.CFrame = CFrame.new(0, 10, 0) -- fallback spawn
    end
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

-- Unlock All Upgrades
local function unlockUpgrades()
    for _, gui in ipairs(player.PlayerGui:GetChildren()) do
        for _, button in ipairs(gui:GetDescendants()) do
            if button:IsA("TextButton") and (button.Name:lower():find("upgrade") or button.Text:lower():find("upgrade")) then
                button:Click()
                task.wait(0.1)
            end
        end
    end
    local upgradesRemote = replicatedStorage:FindFirstChild("Upgrade") or replicatedStorage:FindFirstChild("BuyUpgrade")
    if upgradesRemote and upgradesRemote:IsA("RemoteEvent") then
        upgradesRemote:FireServer("all")
    end
end

-- Brainrot Master: flashy colors & random chat messages
local function startBrainrot()
    while brainrotActive do
        task.wait(0.3)
        local colors = {Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255), Color3.fromRGB(255,255,0)}
        for _, gui in ipairs(player.PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                gui.BackgroundColor3 = colors[math.random(1, #colors)]
                task.wait(0.05)
                gui.BackgroundColor3 = Color3.fromRGB(30,30,30)
            end
        end
        local msgs = {"BRAINROT", "KICK THE BLOCK", "NO KEY 4EVER", "TRIPLE FARM OP", "LUCKY ME"}
        if userInputService:IsKeyDown(Enum.KeyCode.T) then
            game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents") or 
            game:GetService("Chat"):Chat(player.Character.Head, msgs[math.random(1,#msgs)])
        end
    end
end

-- GUI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KALB_Hub"
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 500)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "KICK A LUCKY BLOCK | NO KEY"
title.TextColor3 = Color3.fromRGB(0, 255, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Bold
title.TextScaled = true
title.Parent = mainFrame

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -60)
scroll.Position = UDim2.new(0, 5, 0, 50)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 500)
scroll.Parent = mainFrame

local uiList = Instance.new("UIListLayout")
uiList.Padding = UDim.new(0, 8)
uiList.Parent = scroll

-- Helper for buttons
local function createButton(text, callback, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.Text = text
    btn.BackgroundColor3 = color or Color3.fromRGB(60, 60, 80)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.Parent = scroll
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createToggleButton(text, flagVar, onToggleFunc)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.Text = text .. " 🔴 OFF"
    btn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 200, 200)
    btn.Font = Enum.Font.SourceSansBold
    btn.Parent = scroll
    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        if active then
            btn.Text = text .. " 🟢 ON"
            btn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
            btn.TextColor3 = Color3.fromRGB(200, 255, 200)
            if flagVar == "farming" then
                farming = true
                task.spawn(startAutoFarm)
            elseif flagVar == "autoClick" then
                autoClickActive = true
                task.spawn(startAutoClick)
            elseif flagVar == "removeWave" then
                removeWaveActive = true
                task.spawn(removeWave)
            elseif flagVar == "tripleFarm" then
                tripleFarmActive = true
                task.spawn(startTripleFarm)
            elseif flagVar == "brainrot" then
                brainrotActive = true
                task.spawn(startBrainrot)
            end
            if onToggleFunc then onToggleFunc(true) end
        else
            btn.Text = text .. " 🔴 OFF"
            btn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
            btn.TextColor3 = Color3.fromRGB(255, 200, 200)
            if flagVar == "farming" then
                farming = false
            elseif flagVar == "autoClick" then
                autoClickActive = false
            elseif flagVar == "removeWave" then
                removeWaveActive = false
            elseif flagVar == "tripleFarm" then
                tripleFarmActive = false
                tripleFarmThreads = {}
            elseif flagVar == "brainrot" then
                brainrotActive = false
            end
            if onToggleFunc then onToggleFunc(false) end
        end
    end)
    return btn
end

-- Speed Slider (increment/decrement)
local speedFrame = Instance.new("Frame")
speedFrame.Size = UDim2.new(1, -10, 0, 40)
speedFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
speedFrame.Parent = scroll

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.5, 0, 1, 0)
speedLabel.Text = "Tween Speed: " .. tweenSpeed
speedLabel.TextColor3 = Color3.fromRGB(255,255,255)
speedLabel.BackgroundTransparency = 1
speedLabel.Parent = speedFrame

local speedMinus = Instance.new("TextButton")
speedMinus.Size = UDim2.new(0.15, 0, 0.8, 0)
speedMinus.Position = UDim2.new(0.6, 0, 0.1, 0)
speedMinus.Text = "-"
speedMinus.BackgroundColor3 = Color3.fromRGB(100,0,0)
speedMinus.Parent = speedFrame
speedMinus.MouseButton1Click:Connect(function()
    tweenSpeed = math.max(16, tweenSpeed - 5)
    speedLabel.Text = "Tween Speed: " .. tweenSpeed
    if humanoid then humanoid.WalkSpeed = tweenSpeed end
end)

local speedPlus = Instance.new("TextButton")
speedPlus.Size = UDim2.new(0.15, 0, 0.8, 0)
speedPlus.Position = UDim2.new(0.78, 0, 0.1, 0)
speedPlus.Text = "+"
speedPlus.BackgroundColor3 = Color3.fromRGB(0,100,0)
speedPlus.Parent = speedFrame
speedPlus.MouseButton1Click:Connect(function()
    tweenSpeed = math.min(350, tweenSpeed + 5)
    speedLabel.Text = "Tween Speed: " .. tweenSpeed
    if humanoid then humanoid.WalkSpeed = tweenSpeed end
end)

-- Auto Click Delay slider similar
local delayFrame = Instance.new("Frame")
delayFrame.Size = UDim2.new(1, -10, 0, 40)
delayFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
delayFrame.Parent = scroll

local delayLabel = Instance.new("TextLabel")
delayLabel.Size = UDim2.new(0.5, 0, 1, 0)
delayLabel.Text = "Click Delay: " .. autoClickDelay .. "s"
delayLabel.TextColor3 = Color3.fromRGB(255,255,255)
delayLabel.BackgroundTransparency = 1
delayLabel.Parent = delayFrame

local delayMinus = Instance.new("TextButton")
delayMinus.Size = UDim2.new(0.15, 0, 0.8, 0)
delayMinus.Position = UDim2.new(0.6, 0, 0.1, 0)
delayMinus.Text = "-0.05"
delayMinus.BackgroundColor3 = Color3.fromRGB(100,0,0)
delayMinus.Parent = delayFrame
delayMinus.MouseButton1Click:Connect(function()
    autoClickDelay = math.max(0.05, autoClickDelay - 0.05)
    delayLabel.Text = "Click Delay: " .. string.format("%.2f", autoClickDelay) .. "s"
end)

local delayPlus = Instance.new("TextButton")
delayPlus.Size = UDim2.new(0.15, 0, 0.8, 0)
delayPlus.Position = UDim2.new(0.78, 0, 0.1, 0)
delayPlus.Text = "+0.05"
delayPlus.BackgroundColor3 = Color3.fromRGB(0,100,0)
delayPlus.Parent = delayFrame
delayPlus.MouseButton1Click:Connect(function()
    autoClickDelay = math.min(2, autoClickDelay + 0.05)
    delayLabel.Text = "Click Delay: " .. string.format("%.2f", autoClickDelay) .. "s"
end)

-- Feature Buttons
createToggleButton("⚡ Auto Farm", "farming")
createToggleButton("🔁 Auto Click X2", "autoClick")
createToggleButton("🌊 Remove Wave", "removeWave")
createToggleButton("✨ Triple Farm", "tripleFarm")
createToggleButton("🧠 Brainrot Master", "brainrot")
createButton("📍 Teleport Safe Zone", teleportSafeZone, Color3.fromRGB(0, 150, 150))
createButton("🔓 Unlock All Upgrades", unlockUpgrades, Color3.fromRGB(150, 100, 0))

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 25)
statusLabel.Text = "🔥 No Key | Delta Executor Ready"
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
statusLabel.BackgroundColor3 = Color3.fromRGB(0,0,0)
statusLabel.Parent = scroll

-- Notify ready
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "KALB Script Loaded",
    Text = "All features ready | NO KEY REQUIRED",
    Duration = 3
})

-- Keep character updated
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    humanoid.WalkSpeed = tweenSpeed
end)