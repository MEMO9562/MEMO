-- Phantom Hub V4.1 | Delta Android UI
-- UI + local graphics toggle only.
-- Combat buttons are UI placeholders; connect them only to systems in a game you own.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then return end

local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("PhantomHub_V41")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "PhantomHub_V41"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = obj
end

local function stroke(obj, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = 0.15
    s.Parent = obj
end

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(260, 218)
main.Position = UDim2.new(0.5, -130, 0.38, 0)
main.BackgroundColor3 = Color3.fromRGB(18, 20, 27)
main.BorderSizePixel = 0
main.Parent = gui
corner(main, 13)
stroke(main, Color3.fromRGB(72, 85, 110), 1.2)

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 42)
top.BackgroundColor3 = Color3.fromRGB(27, 31, 42)
top.BorderSizePixel = 0
top.Parent = main
corner(top, 13)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(13, 0)
title.Size = UDim2.new(1, -60, 1, 0)
title.Font = Enum.Font.GothamBold
title.Text = "PHANTOM HUB  |  V4.1"
title.TextColor3 = Color3.fromRGB(235, 240, 255)
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

local collapse = Instance.new("TextButton")
collapse.Size = UDim2.fromOffset(30, 28)
collapse.Position = UDim2.new(1, -37, 0, 7)
collapse.BackgroundColor3 = Color3.fromRGB(47, 55, 72)
collapse.Text = "—"
collapse.TextColor3 = Color3.new(1,1,1)
collapse.Font = Enum.Font.GothamBold
collapse.TextSize = 17
collapse.Parent = top
corner(collapse, 8)

local body = Instance.new("Frame")
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(12, 52)
body.Size = UDim2.new(1, -24, 1, -62)
body.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = body

local function makeButton(label, order)
    local b = Instance.new("TextButton")
    b.Name = label:gsub("%W", "") .. "Button"
    b.LayoutOrder = order
    b.Size = UDim2.new(1, 0, 0, 42)
    b.BackgroundColor3 = Color3.fromRGB(150, 48, 55)
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    b.Font = Enum.Font.GothamSemibold
    b.Text = label .. "   [OFF]"
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 13
    b.Parent = body
    corner(b, 9)
    return b
end

local parryButton = makeButton("Auto Parry", 1)
local clashButton = makeButton("Auto Clash Spam", 2)
local graphicsButton = makeButton("Ultra Low Graphic", 3)

local function setButton(button, label, enabled)
    button.Text = label .. (enabled and "   [ON]" or "   [OFF]")
    button.BackgroundColor3 = enabled and Color3.fromRGB(35, 145, 85) or Color3.fromRGB(150, 48, 55)
end

local parryOn = false
local clashOn = false
local graphicsOn = false

parryButton.Activated:Connect(function()
    parryOn = not parryOn
    setButton(parryButton, "Auto Parry", parryOn)
    if parryOn then
        warn("[Phantom Hub] Auto Parry UI enabled. Combat integration is not included.")
    end
end)

clashButton.Activated:Connect(function()
    clashOn = not clashOn
    setButton(clashButton, "Auto Clash Spam", clashOn)
    if clashOn then
        warn("[Phantom Hub] Auto Clash UI enabled. Combat integration is not included.")
    end
end)

-- Save original values so graphics can be restored when toggled off.
local saved = {}
local function saveAndDisable(obj, property)
    local ok, value = pcall(function() return obj[property] end)
    if not ok then return end
    saved[#saved + 1] = {object = obj, property = property, value = value}
    pcall(function() obj[property] = false end)
end

local function enableLowGraphics()
    saved = {}
    pcall(function()
        Lighting.GlobalShadows = false
        saved[#saved + 1] = {object = Lighting, property = "GlobalShadows", value = true}
    end)

    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
        or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            saveAndDisable(obj, "Enabled")
        elseif obj:IsA("PostEffect") then
            saveAndDisable(obj, "Enabled")
        elseif obj:IsA("Atmosphere") then
            local ok, value = pcall(function() return obj.Density end)
            if ok then
                saved[#saved + 1] = {object = obj, property = "Density", value = value}
                pcall(function() obj.Density = 0 end)
            end
        end
    end
end

local function restoreGraphics()
    for i = #saved, 1, -1 do
        local item = saved[i]
        if item.object and item.object.Parent then
            pcall(function() item.object[item.property] = item.value end)
        end
    end
    saved = {}
end

graphicsButton.Activated:Connect(function()
    graphicsOn = not graphicsOn
    setButton(graphicsButton, "Ultra Low Graphic", graphicsOn)
    if graphicsOn then
        enableLowGraphics()
    else
        restoreGraphics()
    end
end)

collapse.Activated:Connect(function()
    body.Visible = not body.Visible
    main.Size = body.Visible and UDim2.fromOffset(260, 218) or UDim2.fromOffset(260, 42)
    collapse.Text = body.Visible and "—" or "+"
end)

-- Touch/mouse dragging from the title bar.
local dragging = false
local dragInput, dragStart, startPosition
top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

top.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
end)

print("[Phantom Hub V4.1] Loaded. Combat buttons are placeholders; graphics toggle is active.")
