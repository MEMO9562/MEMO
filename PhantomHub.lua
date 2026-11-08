-- Phantom Hub
-- Roblox Studio LocalScript. Place in StarterPlayer > StarterPlayerScripts.
-- Auto Parry and Auto Clash Spam are integration hooks; connect them only
-- to your own game's approved, server-validated combat logic.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "PhantomHub"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(220, 178)
frame.Position = UDim2.new(0, 18, 0.35, 0)
frame.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local header = Instance.new("TextButton")
header.Size = UDim2.new(1, 0, 0, 34)
header.BackgroundColor3 = Color3.fromRGB(34, 38, 48)
header.Text = "PHANTOM HUB     [−]"
header.TextColor3 = Color3.new(1, 1, 1)
header.Font = Enum.Font.GothamBold
header.TextSize = 13
header.Parent = frame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 9)

local holder = Instance.new("Frame")
holder.Name = "Controls"
holder.Position = UDim2.fromOffset(10, 43)
holder.Size = UDim2.new(1, -20, 1, -52)
holder.BackgroundTransparency = 1
holder.Parent = frame
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.Parent = holder

local states = {autoParry = false, autoClashSpam = false, lowGraphic = false}
local function makeToggle(label, key, callback)
    local button = Instance.new("TextButton")
    button.Name = key
    button.Size = UDim2.new(1, 0, 0, 34)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 12
    button.Parent = holder
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
    local function refresh()
        button.Text = label .. ": " .. (states[key] and "ON" or "OFF")
        button.BackgroundColor3 = states[key] and Color3.fromRGB(35,145,82) or Color3.fromRGB(150,45,48)
    end
    button.Activated:Connect(function()
        states[key] = not states[key]
        refresh()
        if callback then callback(states[key]) end
    end)
    refresh()
end

local savedEffects = {}
local savedShadows
local addedConnection
local function disableEffect(item)
    if item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam")
        or item:IsA("Fire") or item:IsA("Smoke") or item:IsA("Sparkles")
        or item:IsA("PostEffect") then
        if savedEffects[item] == nil then savedEffects[item] = item.Enabled end
        item.Enabled = false
    end
end
local function setLowGraphics(enabled)
    if enabled then
        savedShadows = Lighting.GlobalShadows
        Lighting.GlobalShadows = false
        table.clear(savedEffects)
        for _, item in ipairs(game:GetDescendants()) do disableEffect(item) end
        addedConnection = game.DescendantAdded:Connect(function(item)
            if states.lowGraphic then disableEffect(item) end
        end)
    else
        if addedConnection then addedConnection:Disconnect(); addedConnection = nil end
        for item, wasEnabled in pairs(savedEffects) do
            if item and item.Parent then pcall(function() item.Enabled = wasEnabled end) end
        end
        table.clear(savedEffects)
        if savedShadows ~= nil then Lighting.GlobalShadows = savedShadows; savedShadows = nil end
    end
end

makeToggle("Auto Parry", "autoParry", function(on)
    print("[Phantom Hub] Auto Parry " .. (on and "ON" or "OFF") .. " — connect your game's parry logic here.")
end)
makeToggle("Auto Clash Spam", "autoClashSpam", function(on)
    print("[Phantom Hub] Auto Clash Spam " .. (on and "ON" or "OFF") .. " — connect your game's clash logic here.")
end)
makeToggle("Ultra Low Graphic", "lowGraphic", setLowGraphics)

local collapsed = false
header.Activated:Connect(function()
    collapsed = not collapsed
    holder.Visible = not collapsed
    frame.Size = collapsed and UDim2.fromOffset(220,34) or UDim2.fromOffset(220,178)
    header.Text = collapsed and "PHANTOM HUB     [+]" or "PHANTOM HUB     [−]"
end)

local dragging, dragStart, startPos, dragInput
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
