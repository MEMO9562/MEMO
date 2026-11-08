-- Phantom Hub | General client UI for Roblox experiences you own
-- Install as a LocalScript in StarterPlayer > StarterPlayerScripts.
-- Combat buttons emit a BindableEvent; connect it to your game's own combat system.
-- This is not an executor, injector, or exploit.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("PhantomHub")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "PhantomHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local combatEvent = Instance.new("BindableEvent")
combatEvent.Name = "CombatModeChanged"
combatEvent.Parent = gui

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local main = make("Frame", {
    Name = "Main", Size = UDim2.fromOffset(260, 220),
    Position = UDim2.new(0.5, -130, 0.5, -110),
    BackgroundColor3 = Color3.fromRGB(15, 18, 25),
    BorderSizePixel = 0,
}, gui)
make("UICorner", {CornerRadius = UDim.new(0, 12)}, main)
make("UIStroke", {Color = Color3.fromRGB(55, 68, 88), Thickness = 1.2}, main)

local top = make("Frame", {
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = Color3.fromRGB(25, 31, 43),
    BorderSizePixel = 0,
}, main)
make("UICorner", {CornerRadius = UDim.new(0, 12)}, top)
make("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0),
    Size = UDim2.new(1, -75, 1, 0), Font = Enum.Font.GothamBold,
    Text = "PHANTOM HUB", TextColor3 = Color3.fromRGB(235, 242, 255),
    TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
}, top)

local minimize = make("TextButton", {
    Size = UDim2.fromOffset(30, 26), Position = UDim2.new(1, -36, 0, 6),
    BackgroundColor3 = Color3.fromRGB(48, 58, 76), Text = "—",
    TextColor3 = Color3.new(1,1,1), TextSize = 18, Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
}, top)
make("UICorner", {CornerRadius = UDim.new(0, 7)}, minimize)

local body = make("Frame", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 48),
    Size = UDim2.new(1, -24, 1, -60),
}, main)
make("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, body)

local status = make("TextLabel", {
    LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 22),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham,
    Text = "Ready • connect your game combat handler",
    TextColor3 = Color3.fromRGB(155, 169, 190), TextSize = 10,
    TextWrapped = true,
}, body)

local states = {parry = false, clash = false, low = false}
local buttons = {}

local function emitCombatMode()
    local mode = states.clash and "Clash" or (states.parry and "Parry" or "Off")
    combatEvent:Fire(mode, states.parry, states.clash)
    status.Text = "Combat mode: " .. mode .. " • handler required"
end

local function addToggle(label, key, order)
    local button = make("TextButton", {
        LayoutOrder = order, Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Color3.fromRGB(145, 48, 55),
        BorderSizePixel = 0, AutoButtonColor = true,
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = Color3.new(1,1,1),
    }, body)
    make("UICorner", {CornerRadius = UDim.new(0, 8)}, button)
    buttons[key] = button
    local function refresh()
        button.BackgroundColor3 = states[key] and Color3.fromRGB(35, 145, 87) or Color3.fromRGB(145, 48, 55)
        button.Text = label .. (states[key] and "  [ON]" or "  [OFF]")
    end
    refresh()
    button.Activated:Connect(function()
        states[key] = not states[key]
        refresh()
        if key == "parry" or key == "clash" then
            emitCombatMode()
        else
            status.Text = states.low and "Low graphics enabled" or "Graphics restored"
        end
    end)
end

addToggle("Auto Parry", "parry", 1)
addToggle("Auto Clash Spam", "clash", 2)
addToggle("Ultra Low Graphic", "low", 3)

-- Drag support (mouse + touch)
local dragging, dragInput, dragStart, startPos
top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
top.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local minimized = false
minimize.Activated:Connect(function()
    minimized = not minimized
    body.Visible = not minimized
    main.Size = minimized and UDim2.fromOffset(260, 38) or UDim2.fromOffset(260, 220)
    minimize.Text = minimized and "+" or "—"
end)

-- Reversible graphics reduction: only properties changed here are restored.
local saved = {}
local function remember(instance, property)
    local ok, value = pcall(function() return instance[property] end)
    if ok then
        saved[instance] = saved[instance] or {}
        if saved[instance][property] == nil then saved[instance][property] = value end
    end
end

local function setLowGraphics(enabled)
    if enabled then
        remember(Lighting, "GlobalShadows")
        Lighting.GlobalShadows = false
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
                or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles")
                or obj:IsA("PostEffect") then
                remember(obj, "Enabled")
                pcall(function() obj.Enabled = false end)
            elseif obj:IsA("BasePart") then
                remember(obj, "Material")
                remember(obj, "Reflectance")
                pcall(function()
                    obj.Material = Enum.Material.Plastic
                    obj.Reflectance = 0
                end)
            end
        end
    else
        for instance, properties in pairs(saved) do
            if instance and instance.Parent then
                for property, value in pairs(properties) do
                    pcall(function() instance[property] = value end)
                end
            end
        end
        table.clear(saved)
    end
end

buttons.low.Activated:Connect(function()
    setLowGraphics(states.low)
end)

gui.Destroying:Connect(function()
    if states.low then setLowGraphics(false) end
end)

-- Other LocalScripts can listen:
-- playerGui.PhantomHub.CombatModeChanged.Event:Connect(function(mode, parryOn, clashOn) ... end)
