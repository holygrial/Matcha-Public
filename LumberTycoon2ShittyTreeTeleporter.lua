local Players = game:GetService("Players")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local workspace = game:GetService("Workspace")

local guiVisible = true
local mouseDown, lastMouseDown = false, false
local F1Down, dragging = false, false
local dragOffset = Vector2.new(0,0)

local guiX, guiY = 250, 650
local guiW, guiH = 300, 350
local topBarH = 25
local minGuiH = 150
local padding = 5
local lineH = 25

local guiBg = Drawing.new("Square")
guiBg.Position = Vector2.new(guiX, guiY)
guiBg.Size = Vector2.new(guiW, guiH)
guiBg.Filled = true
guiBg.Color = Color3.fromRGB(50, 50, 50)
guiBg.Visible = guiVisible

local guiTopBar = Drawing.new("Square")
guiTopBar.Position = Vector2.new(guiX, guiY)
guiTopBar.Size = Vector2.new(guiW, topBarH)
guiTopBar.Filled = true
guiTopBar.Color = Color3.fromRGB(30, 30, 30)
guiTopBar.Visible = guiVisible

local function isMouseOver(pos, size)
    return mouse and mouse.X >= pos.X and mouse.X <= pos.X + size.X
       and mouse.Y >= pos.Y and mouse.Y <= pos.Y + size.Y
end

local function getTreeClasses()
    local classes, found = {}, {}
    for _, region in ipairs(workspace:GetChildren()) do
        if region:IsA("Model") and region.Name == "TreeRegion" then
            for _, tree in ipairs(region:GetChildren()) do
                if tree:IsA("Model") then
                    local treeClass = tree:FindFirstChild("TreeClass", true)
                    if treeClass and treeClass:IsA("StringValue") and not found[treeClass.Value] then
                        table.insert(classes, treeClass.Value)
                        found[treeClass.Value] = true
                    end
                end
            end
        end
    end
    table.sort(classes)
    return classes
end

local function getTreesByClass(name)
    local trees = {}
    for _, region in ipairs(workspace:GetChildren()) do
        if region:IsA("Model") and region.Name == "TreeRegion" then
            local classMap = {}
            for _, model in ipairs(region:GetChildren()) do
                if model:IsA("Model") then
                    for _, v in ipairs(model:GetChildren()) do
                        if v:IsA("StringValue") and v.Name == "TreeClass" then
                            classMap[v.Value] = classMap[v.Value] or {}
                            table.insert(classMap[v.Value], model)
                        end
                    end
                end
            end
            for _, model in ipairs(region:GetChildren()) do
                if model:IsA("Model") then
                    local wood = model:FindFirstChild("WoodSection", true)
                    if wood and classMap[name] then
                        table.insert(trees, wood)
                    end
                end
            end
        end
    end
    return trees
end

local function teleportToTree(name)
    local trees = getTreesByClass(name)
    if #trees == 0 then return end
    local target = trees[math.random(1, #trees)]
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.Position = target.Position + Vector3.new(0, 5, 0)
    end
end

local treeClasses = getTreeClasses()
local classTexts = {}

local function updateTreeList()
    for _, t in ipairs(classTexts) do t.Visible = false end
    classTexts = {}

    local neededH = topBarH + padding*2 + #treeClasses*lineH
    guiH = math.max(minGuiH, neededH)
    guiBg.Size = Vector2.new(guiW, guiH)

    for i, name in ipairs(treeClasses) do
        local t = Drawing.new("Text")
        t.Position = Vector2.new(guiX + 10, guiY + topBarH + padding + (i-1)*lineH)
        t.Color = Color3.fromRGB(255, 255, 255)
        t.Text = name
        t.Visible = guiVisible
        classTexts[i] = t
    end
end

updateTreeList()

while true do
    mouseDown = ismouse1pressed()
    local clicked = mouseDown and not lastMouseDown

    local f1Pressed = iskeypressed(0x70)
    if f1Pressed and not F1Down then
        guiVisible = not guiVisible
        guiBg.Visible = guiVisible
        guiTopBar.Visible = guiVisible
        for _, t in ipairs(classTexts) do t.Visible = guiVisible end
        F1Down = true
    elseif not f1Pressed and F1Down then
        F1Down = false
    end

    if guiVisible then
        if clicked and isMouseOver(guiTopBar.Position, guiTopBar.Size) then
            dragging = true
            dragOffset = Vector2.new(mouse.X - guiX, mouse.Y - guiY)
        elseif not mouseDown then
            dragging = false
        end

        if dragging then
            guiX = mouse.X - dragOffset.X
            guiY = mouse.Y - dragOffset.Y
            guiBg.Position = Vector2.new(guiX, guiY)
            guiTopBar.Position = Vector2.new(guiX, guiY)
            for i, t in ipairs(classTexts) do
                t.Position = Vector2.new(guiX + 10, guiY + topBarH + padding + (i-1)*lineH)
            end
        end

        if clicked then
            for i, t in ipairs(classTexts) do
                local boxX, boxY = guiX + 10, guiY + topBarH + padding + (i-1)*lineH
                local boxW, boxH = guiW - 20, lineH
                if mouse.X >= boxX and mouse.X <= boxX + boxW and mouse.Y >= boxY and mouse.Y <= boxY + boxH then
                    teleportToTree(treeClasses[i])
                    break
                end
            end
        end
    end

    lastMouseDown = mouseDown
    wait()
end