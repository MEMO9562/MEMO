-- Teleport Manager | LocalScript

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local points = {}
local routes = {}
local sequence = {}

local nextPointId = 0
local nextRouteId = 0

-- Persistent data (Delta file functions are used when available)
local HttpService = game:GetService("HttpService")
local DATA_FILE = "TeleportManager_Data.json"
local persistenceAvailable = type(readfile) == "function" and type(writefile) == "function"

local function saveData()
    if not persistenceAvailable then
        return false
    end

    local data = {
        version = 1,
        points = {},
        routes = {},
        nextPointId = nextPointId,
        nextRouteId = nextRouteId
    }

    for _, point in ipairs(points) do
        table.insert(data.points, {
            id = point.id,
            name = point.name,
            x = point.position.X,
            y = point.position.Y,
            z = point.position.Z
        })
    end

    for _, route in ipairs(routes) do
        local savedRoute = {
            id = route.id,
            name = route.name,
            steps = {}
        }
        for _, step in ipairs(route.steps) do
            table.insert(savedRoute.steps, {
                pointId = step.pointId,
                name = step.name,
                delay = step.delay,
                unit = step.unit
            })
        end
        table.insert(data.routes, savedRoute)
    end

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if not ok then
        return false
    end

    local written = pcall(function()
        writefile(DATA_FILE, encoded)
    end)
    return written
end

local function loadData()
    if type(readfile) ~= "function" then
        return false
    end

    local ok, raw = pcall(function()
        return readfile(DATA_FILE)
    end)
    if not ok or type(raw) ~= "string" or raw == "" then
        return false
    end

    local decodedOk, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not decodedOk or type(data) ~= "table" then
        return false
    end

    if type(data.points) == "table" then
        for _, point in ipairs(data.points) do
            local id = tonumber(point.id)
            local x, y, z = tonumber(point.x), tonumber(point.y), tonumber(point.z)
            if id and type(point.name) == "string" and x and y and z then
                table.insert(points, {
                    id = id,
                    name = point.name,
                    position = Vector3.new(x, y, z)
                })
                nextPointId = math.max(nextPointId, id)
            end
        end
    end

    if type(data.routes) == "table" then
        for _, route in ipairs(data.routes) do
            local id = tonumber(route.id)
            if id and type(route.name) == "string" and type(route.steps) == "table" then
                local loadedRoute = {id = id, name = route.name, steps = {}}
                for _, step in ipairs(route.steps) do
                    local pointId = tonumber(step.pointId)
                    local delay = tonumber(step.delay)
                    local unit = step.unit
                    if pointId and type(step.name) == "string" and delay and delay >= 0
                        and (unit == "ms" or unit == "sec" or unit == "min") then
                        table.insert(loadedRoute.steps, {
                            pointId = pointId,
                            name = step.name,
                            delay = delay,
                            unit = unit
                        })
                    end
                end
                table.insert(routes, loadedRoute)
                nextRouteId = math.max(nextRouteId, id)
            end
        end
    end

    nextPointId = math.max(nextPointId, tonumber(data.nextPointId) or 0)
    nextRouteId = math.max(nextRouteId, tonumber(data.nextRouteId) or 0)
    return true
end

local dataLoaded = loadData()

local running = false
local runToken = 0
local activeRouteId = nil
local activeRouteButton = nil
local editingRouteId = nil

local units = {"ms", "sec", "min"}

local function create(class, props, parent)
local obj = Instance.new(class)
for k, v in pairs(props) do
obj[k] = v
end
obj.Parent = parent
return obj
end

local old = playerGui:FindFirstChild("TeleportManager")
if old then
old:Destroy()
end

local gui = create("ScreenGui", {
Name = "TeleportManager",
ResetOnSpawn = false
}, playerGui)

local main = create("Frame", {
Size = UDim2.new(0, 700, 0, 525),
Position = UDim2.new(0.5, -350, 0.5, -262.5),
BackgroundColor3 = Color3.fromRGB(18, 24, 38),
BorderSizePixel = 0
}, gui)

create("UIScale", {
Scale = 0.85
}, main)

create("UICorner", {CornerRadius = UDim.new(0, 10)}, main)

local header = create("TextLabel", {
Size = UDim2.new(1, 0, 0, 38),
BackgroundColor3 = Color3.fromRGB(31, 43, 62),
Text = "TELEPORT MANAGER",
TextColor3 = Color3.new(1, 1, 1),
TextSize = 17,
Font = Enum.Font.GothamBold
}, main)

create("UICorner", {CornerRadius = UDim.new(0, 10)}, header)

-- Draggable windows
local function makeDraggable(object, dragTarget)
dragTarget = dragTarget or object
local dragging = false
local dragStart
local startPosition

object.InputBegan:Connect(function(input)  
    if input.UserInputType == Enum.UserInputType.MouseButton1  
        or input.UserInputType == Enum.UserInputType.Touch then  

        dragging = true  
        dragStart = input.Position  
        startPosition = dragTarget.Position  
    end  
end)  

UIS.InputChanged:Connect(function(input)  
    if dragging and (  
        input.UserInputType == Enum.UserInputType.MouseMovement  
        or input.UserInputType == Enum.UserInputType.Touch  
    ) then  
        local delta = input.Position - dragStart  

        dragTarget.Position = UDim2.new(  
            startPosition.X.Scale,  
            startPosition.X.Offset + delta.X,  
            startPosition.Y.Scale,  
            startPosition.Y.Offset + delta.Y  
        )  
    end  
end)  

UIS.InputEnded:Connect(function(input)  
    if input.UserInputType == Enum.UserInputType.MouseButton1  
        or input.UserInputType == Enum.UserInputType.Touch then  
        dragging = false  
    end  
end)

end

makeDraggable(header, main)

-- Always-visible toggle button
local toggleButton = create("TextButton", {
Size = UDim2.new(0, 82, 0, 42),
Position = UDim2.new(0, 15, 0.35, 0),
BackgroundColor3 = Color3.fromRGB(36, 91, 115),
Text = "GOAT",
TextColor3 = Color3.new(1, 1, 1),
TextSize = 14,
Font = Enum.Font.GothamBlack,
BorderSizePixel = 0
}, gui)

create("UICorner", {CornerRadius = UDim.new(0, 13)}, toggleButton)
create("UIStroke", {Color = Color3.fromRGB(75, 190, 190), Thickness = 1.4, Transparency = 0.15}, toggleButton)
makeDraggable(toggleButton)

toggleButton.MouseButton1Click:Connect(function()
main.Visible = not main.Visible
toggleButton.Text = "GOAT"
end)

local function makeButton(parent, text, size, position, color)
local button = create("TextButton", {
Size = size,
Position = position,
BackgroundColor3 = color or Color3.fromRGB(65, 105, 180),
Text = text,
TextColor3 = Color3.new(1, 1, 1),
TextSize = 12,
Font = Enum.Font.GothamBold,
BorderSizePixel = 0
}, parent)

create("UICorner", {CornerRadius = UDim.new(0, 6)}, button)  
return button

end

local function makeBox(parent, placeholder, size, position, defaultText)
local box = create("TextBox", {
Size = size,
Position = position,
BackgroundColor3 = Color3.fromRGB(34, 46, 64),
TextColor3 = Color3.new(1, 1, 1),
PlaceholderColor3 = Color3.fromRGB(175, 175, 175),
PlaceholderText = placeholder,
Text = defaultText or "",
TextSize = 12,
Font = Enum.Font.Gotham,
ClearTextOnFocus = false,
BorderSizePixel = 0
}, parent)

create("UICorner", {CornerRadius = UDim.new(0, 6)}, box)  
return box

end

local function makeTitle(parent, text, position)
return create("TextLabel", {
Size = UDim2.new(1, -10, 0, 24),
Position = position,
BackgroundTransparency = 1,
Text = text,
TextColor3 = Color3.new(1, 1, 1),
TextSize = 14,
Font = Enum.Font.GothamBold,
TextXAlignment = Enum.TextXAlignment.Left
}, parent)
end

-- Two side-by-side panels
local left = create("Frame", {
Size = UDim2.new(0, 330, 0, 465),
Position = UDim2.new(0, 10, 0, 48),
BackgroundColor3 = Color3.fromRGB(25, 35, 51),
BorderSizePixel = 0
}, main)

local right = create("Frame", {
Size = UDim2.new(0, 340, 0, 465),
Position = UDim2.new(0, 350, 0, 48),
BackgroundColor3 = Color3.fromRGB(35, 38, 48),
BorderSizePixel = 0
}, main)

create("UICorner", {CornerRadius = UDim.new(0, 8)}, left)
create("UICorner", {CornerRadius = UDim.new(0, 8)}, right)

-- LEFT PANEL: Saved Points
makeTitle(left, "SAVED POINTS", UDim2.new(0, 10, 0, 5))

local pointName = makeBox(
left,
"Point name",
UDim2.new(0, 195, 0, 32),
UDim2.new(0, 8, 0, 32)
)

local savePointButton = makeButton(
left,
"SAVE POINT",
UDim2.new(0, 115, 0, 32),
UDim2.new(0, 207, 0, 32),
Color3.fromRGB(40, 145, 90)
)

local pointsList = create("ScrollingFrame", {
Size = UDim2.new(1, -16, 0, 380),
Position = UDim2.new(0, 8, 0, 73),
BackgroundColor3 = Color3.fromRGB(18, 27, 41),
BorderSizePixel = 0,
ScrollBarThickness = 5,
CanvasSize = UDim2.new(0, 0, 0, 0)
}, left)

create("UICorner", {CornerRadius = UDim.new(0, 6)}, pointsList)

local pointsGrid = create("UIGridLayout", {
CellSize = UDim2.new(0, 96, 0, 76),
CellPadding = UDim2.new(0, 5, 0, 5),
SortOrder = Enum.SortOrder.LayoutOrder
}, pointsList)

pointsGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
pointsList.CanvasSize = UDim2.new(
0, 0, 0, pointsGrid.AbsoluteContentSize.Y + 8
)
end)

-- RIGHT PANEL: Route Builder
makeTitle(right, "AUTO ROUTE BUILDER", UDim2.new(0, 10, 0, 5))

create("TextLabel", {
Size = UDim2.new(1, -16, 0, 30),
Position = UDim2.new(0, 8, 0, 30),
BackgroundTransparency = 1,
Text = "Tap + ADD STEP on any point. Repeat to add it again.",
TextColor3 = Color3.fromRGB(190, 190, 200),
TextSize = 10,
Font = Enum.Font.Gotham,
TextWrapped = true
}, right)

local sequenceList = create("ScrollingFrame", {
Size = UDim2.new(1, -16, 0, 175),
Position = UDim2.new(0, 8, 0, 63),
BackgroundColor3 = Color3.fromRGB(29, 32, 41),
BorderSizePixel = 0,
ScrollBarThickness = 6,
ScrollBarImageColor3 = Color3.fromRGB(75, 190, 190),
AutomaticCanvasSize = Enum.AutomaticSize.Y,
CanvasSize = UDim2.new(0, 0, 0, 0)
}, right)

create("UICorner", {CornerRadius = UDim.new(0, 6)}, sequenceList)

local sequenceLayout = create("UIListLayout", {
Padding = UDim.new(0, 5),
SortOrder = Enum.SortOrder.LayoutOrder
}, sequenceList)

sequenceLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
sequenceList.CanvasSize = UDim2.new(
0, 0, 0, sequenceLayout.AbsoluteContentSize.Y + 8
)
end)

local routeName = makeBox(
right,
"Route name",
UDim2.new(0, 205, 0, 32),
UDim2.new(0, 8, 0, 245)
)

local saveRouteButton = makeButton(
right,
"SAVE ROUTE",
UDim2.new(0, 115, 0, 32),
UDim2.new(0, 217, 0, 245),
Color3.fromRGB(40, 145, 90)
)

makeTitle(right, "SAVED ROUTES", UDim2.new(0, 10, 0, 282))

local routesList = create("ScrollingFrame", {
Size = UDim2.new(1, -16, 0, 145),
Position = UDim2.new(0, 8, 0, 308),
BackgroundColor3 = Color3.fromRGB(29, 32, 41),
BorderSizePixel = 0,
ScrollBarThickness = 5,
CanvasSize = UDim2.new(0, 0, 0, 0)
}, right)

create("UICorner", {CornerRadius = UDim.new(0, 6)}, routesList)

local routesLayout = create("UIListLayout", {
Padding = UDim.new(0, 5),
SortOrder = Enum.SortOrder.LayoutOrder
}, routesList)

routesLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
routesList.CanvasSize = UDim2.new(
0, 0, 0, routesLayout.AbsoluteContentSize.Y + 8
)
end)

local status = create("TextLabel", {
Size = UDim2.new(1, -20, 0, 22),
Position = UDim2.new(0, 10, 0, 488),
BackgroundTransparency = 1,
Text = "Status: Ready",
TextColor3 = Color3.fromRGB(220, 220, 220),
TextSize = 12,
Font = Enum.Font.Gotham
}, main)

local stopButton = makeButton(
main,
"STOP AUTO TELEPORT",
UDim2.new(0, 180, 0, 28),
UDim2.new(1, -190, 0, 484),
Color3.fromRGB(170, 55, 55)
)

-- Teleport function
local function teleport(position)
local character = player.Character

if character and character:FindFirstChild("HumanoidRootPart") then  
    character:PivotTo(CFrame.new(position))  
    return true  
end  

return false

end

local function clearFrames(container)
for _, child in ipairs(container:GetChildren()) do
if child:IsA("Frame") then
child:Destroy()
end
end
end

-- Each sequence step has its own delay and unit
local function refreshSequence()
clearFrames(sequenceList)

for index, step in ipairs(sequence) do  
    local currentStep = step  

    local row = create("Frame", {  
        Size = UDim2.new(1, -8, 0, 36),  
        BackgroundColor3 = Color3.fromRGB(38, 52, 72),  
        BorderSizePixel = 0,  
        LayoutOrder = index  
    }, sequenceList)  

    create("UICorner", {CornerRadius = UDim.new(0, 5)}, row)  

    local nameLabel = create("TextLabel", {  
        Size = UDim2.new(0, 85, 1, 0),  
        Position = UDim2.new(0, 5, 0, 0),  
        BackgroundTransparency = 1,  
        Text = currentStep.name,  
        TextColor3 = Color3.new(1, 1, 1),  
        TextSize = 11,  
        Font = Enum.Font.Gotham,  
        TextTruncate = Enum.TextTruncate.AtEnd  
    }, row)  

    local delayBox = makeBox(  
        row,  
        "Time",  
        UDim2.new(0, 65, 0, 27),  
        UDim2.new(0, 94, 0, 4),  
        tostring(currentStep.delay)  
    )  

    delayBox.FocusLost:Connect(function()  
        local value = tonumber(delayBox.Text)  

        if value and value >= 0 then  
            currentStep.delay = value  
        else  
            delayBox.Text = tostring(currentStep.delay)  
        end  
    end)  

    local unitButton = makeButton(  
        row,  
        currentStep.unit,  
        UDim2.new(0, 55, 0, 27),  
        UDim2.new(0, 164, 0, 4),  
        Color3.fromRGB(90, 90, 130)  
    )  

    unitButton.MouseButton1Click:Connect(function()  
        local currentIndex = 1  

        for i, unit in ipairs(units) do  
            if unit == currentStep.unit then  
                currentIndex = i  
                break  
            end  
        end  

        currentIndex = currentIndex % #units + 1  
        currentStep.unit = units[currentIndex]  
        unitButton.Text = currentStep.unit  
    end)  

    local removeButton = makeButton(  
        row,  
        "X",  
        UDim2.new(0, 28, 0, 27),  
        UDim2.new(1, -33, 0, 4),  
        Color3.fromRGB(170, 55, 55)  
    )  

    removeButton.MouseButton1Click:Connect(function()  
        for i, savedStep in ipairs(sequence) do  
            if savedStep == currentStep then  
                table.remove(sequence, i)  
                break  
            end  
        end  

        refreshSequence()  
    end)  
end

    task.defer(function()
        task.wait()
        local bottom = math.max(0, sequenceList.AbsoluteCanvasSize.Y - sequenceList.AbsoluteSize.Y)
        sequenceList.CanvasPosition = Vector2.new(0, bottom)
    end)
end

-- Add a point to the route sequence.
-- The same point can be added as many times as needed.
local function addStep(point)
table.insert(sequence, {
pointId = point.id,
name = point.name,
delay = 1,
unit = "sec"
})

refreshSequence()  
status.Text = "Status: Added step - " .. point.name

end

local function refreshPoints()
clearFrames(pointsList)

for index, point in ipairs(points) do  
    local currentPoint = point  

    local tile = create("Frame", {  
        BackgroundColor3 = Color3.fromRGB(49, 52, 64),  
        BorderSizePixel = 0,  
        LayoutOrder = index  
    }, pointsList)  

    create("UICorner", {CornerRadius = UDim.new(0, 6)}, tile)  

    local goButton = makeButton(  
        tile,  
        currentPoint.name,  
        UDim2.new(1, -4, 0, 40),  
        UDim2.new(0, 2, 0, 2),  
        Color3.fromRGB(65, 105, 180)  
    )  
    goButton.TextTruncate = Enum.TextTruncate.AtEnd  

    goButton.MouseButton1Click:Connect(function()  
        if teleport(currentPoint.position) then  
            status.Text = "Status: Manual teleport - " .. currentPoint.name  
        else  
            status.Text = "Status: Character not found"  
        end  
    end)  

    local addButton = makeButton(  
        tile,  
        "+ ADD STEP",  
        UDim2.new(1, -4, 0, 27),  
        UDim2.new(0, 2, 0, 45),  
        Color3.fromRGB(40, 145, 90)  
    )  

    addButton.TextSize = 10  

    addButton.MouseButton1Click:Connect(function()  
        addStep(currentPoint)  
    end)  

    local deleteButton = makeButton(  
        tile,  
        "X",  
        UDim2.new(0, 20, 0, 20),  
        UDim2.new(1, -22, 0, 2),  
        Color3.fromRGB(170, 55, 55)  
    )  
    deleteButton.TextSize = 10  

    deleteButton.MouseButton1Click:Connect(function()  
        for i, saved in ipairs(points) do  
            if saved.id == currentPoint.id then  
                table.remove(points, i)  
                break  
            end  
        end  

        saveData()
        refreshPoints()  
        status.Text = "Status: Point deleted"  
    end)  
end

end

local function refreshRoutes()
clearFrames(routesList)

for index, route in ipairs(routes) do  
    local currentRoute = route  

    local row = create("Frame", {  
        Size = UDim2.new(1, -8, 0, 36),  
        BackgroundColor3 = Color3.fromRGB(49, 52, 64),  
        BorderSizePixel = 0,  
        LayoutOrder = index  
    }, routesList)  

    create("UICorner", {CornerRadius = UDim.new(0, 5)}, row)  

    local playButton = makeButton(  
        row,  
        "PLAY: " .. currentRoute.name,  
        UDim2.new(1, -130, 1, -4),  
        UDim2.new(0, 3, 0, 2),  
        Color3.fromRGB(190, 65, 75)  
    )  
    playButton.TextTruncate = Enum.TextTruncate.AtEnd  

    local editButton = makeButton(
        row,
        "EDIT",
        UDim2.new(0, 58, 1, -4),
        UDim2.new(1, -124, 0, 2),
        Color3.fromRGB(75, 105, 155)
    )

    editButton.MouseButton1Click:Connect(function()
        sequence = {}
        for _, step in ipairs(currentRoute.steps) do
            table.insert(sequence, {
                pointId = step.pointId,
                name = step.name,
                delay = step.delay,
                unit = step.unit
            })
        end
        editingRouteId = currentRoute.id
        routeName.Text = currentRoute.name
        saveRouteButton.Text = "UPDATE ROUTE"
        refreshSequence()
        status.Text = "Status: Editing - " .. currentRoute.name
    end)

    playButton.MouseButton1Click:Connect(function()
        if running and activeRouteId == currentRoute.id then
            running = false
            runToken += 1
            activeRouteId = nil
            activeRouteButton = nil
            playButton.Text = "PLAY: " .. currentRoute.name
            playButton.BackgroundColor3 = Color3.fromRGB(190, 65, 75)
            status.Text = "Status: Auto teleport stopped - " .. currentRoute.name
            return
        end

        if #currentRoute.steps == 0 then  
            status.Text = "Status: Route is empty"  
            return  
        end  

        local routeSteps = {}  

        for _, step in ipairs(currentRoute.steps) do  
            local foundPoint = nil  

            for _, point in ipairs(points) do  
                if point.id == step.pointId then  
                    foundPoint = point  
                    break  
                end  
            end  

            if foundPoint then  
                table.insert(routeSteps, {  
                    position = foundPoint.position,  
                    name = foundPoint.name,  
                    delay = step.delay,  
                    unit = step.unit  
                })  
            end  
        end  

        if #routeSteps == 0 then  
            status.Text = "Status: No valid points in this route"  
            return  
        end  

        running = false
        runToken += 1

        if activeRouteButton then
            activeRouteButton.Text = "PLAY: " .. activeRouteButton:GetAttribute("RouteName")
            activeRouteButton.BackgroundColor3 = Color3.fromRGB(190, 65, 75)
        end

        local myToken = runToken
        running = true
        activeRouteId = currentRoute.id
        activeRouteButton = playButton
        activeRouteButton:SetAttribute("RouteName", currentRoute.name)
        playButton.Text = "STOP: " .. currentRoute.name
        playButton.BackgroundColor3 = Color3.fromRGB(35, 160, 105)

        status.Text = "Status: Running - " .. currentRoute.name  

        task.spawn(function()  
            while running and runToken == myToken do  
                for _, step in ipairs(routeSteps) do  
                    if not running or runToken ~= myToken then  
                        break  
                    end  

                    teleport(step.position)  
                    status.Text = "Status: Teleporting - " .. step.name  

                    local waitTime = step.delay  

                    if step.unit == "ms" then  
                        waitTime = waitTime / 1000  
                    elseif step.unit == "min" then  
                        waitTime = waitTime * 60  
                    end  

                    task.wait(math.max(waitTime, 0.03))  
                end  
            end  
        end)  
    end)  

    local deleteButton = makeButton(  
        row,  
        "DELETE",  
        UDim2.new(0, 58, 1, -4),
        UDim2.new(1, -63, 0, 2),  
        Color3.fromRGB(170, 55, 55)  
    )  

    deleteButton.MouseButton1Click:Connect(function()
        if editingRouteId == currentRoute.id then
            editingRouteId = nil
            sequence = {}
            routeName.Text = ""
            saveRouteButton.Text = "SAVE ROUTE"
            refreshSequence()
        end
        for i, saved in ipairs(routes) do  
            if saved.id == currentRoute.id then  
                table.remove(routes, i)  
                break  
            end  
        end  

        saveData()
        refreshRoutes()  
    end)  
end

end

-- Save point
savePointButton.MouseButton1Click:Connect(function()
local character = player.Character
local root = character and character:FindFirstChild("HumanoidRootPart")

if not root then  
    status.Text = "Status: Character not found"  
    return  
end  

local name = pointName.Text  

if name == "" then  
    name = "Point " .. tostring(#points + 1)  
end  

nextPointId += 1  

table.insert(points, {  
    id = nextPointId,  
    name = name,  
    position = root.Position  
})  

pointName.Text = ""
saveData()
refreshPoints()  

status.Text = "Status: Point saved - " .. name

end)

-- Save a new route or update the route currently being edited
saveRouteButton.MouseButton1Click:Connect(function()
if #sequence == 0 then
status.Text = "Status: Add at least one step"
return
end

local name = routeName.Text
if name == "" then
    name = "Route " .. tostring(#routes + 1)
end

local savedSteps = {}
for _, step in ipairs(sequence) do
    table.insert(savedSteps, {
        pointId = step.pointId,
        name = step.name,
        delay = step.delay,
        unit = step.unit
    })
end

if editingRouteId then
    for _, route in ipairs(routes) do
        if route.id == editingRouteId then
            route.name = name
            route.steps = savedSteps
            break
        end
    end
    editingRouteId = nil
    status.Text = "Status: Route updated - " .. name
else
    nextRouteId += 1
    table.insert(routes, {
        id = nextRouteId,
        name = name,
        steps = savedSteps
    })
    status.Text = "Status: Route saved - " .. name
end

sequence = {}
routeName.Text = ""
saveRouteButton.Text = "SAVE ROUTE"
refreshSequence()
saveData()
refreshRoutes()
end)

-- Stop auto teleport
stopButton.MouseButton1Click:Connect(function()
running = false
runToken += 1
activeRouteId = nil

if activeRouteButton then
    activeRouteButton.Text = "PLAY: " .. activeRouteButton:GetAttribute("RouteName")
    activeRouteButton.BackgroundColor3 = Color3.fromRGB(190, 65, 75)
    activeRouteButton = nil
end

status.Text = "Status: Auto teleport stopped"
end)

refreshPoints()
refreshSequence()
refreshRoutes()