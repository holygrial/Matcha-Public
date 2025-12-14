--[[
    WASD = movement keys
    R = restart game
]]

local size = 20 -- 20x20 grid dont change it unless you want to fill ur screen w/ snake game
local pixels = 600 -- board pixels
local speed = 0.12 -- snake speed

local cam = workspace.CurrentCamera
local center = cam.ViewportSize / 2
local cell = pixels / size

local board = Drawing.new("Square")
board.Size = Vector2.new(pixels, pixels)
board.Position = center - board.Size / 2
board.Color = Color3.fromRGB(18, 18, 18)
board.Filled = true
board.Visible = true

local drawn = {}

local function clear()
    for i = 1, #drawn do
        drawn[i]:Remove()
    end
    drawn = {}
end

local function box(x, y, c)
    local d = Drawing.new("Square")
    d.Size = Vector2.new(cell - 1, cell - 1)
    d.Position = board.Position + Vector2.new((x - 1) * cell, (y - 1) * cell)
    d.Color = c
    d.Filled = true
    d.Visible = true
    drawn[#drawn + 1] = d
end

local snake
local apple
local dx
local dy
local alive
local last = 0

local function spawnApple()
    while true do
        local x = math.random(1, size)
        local y = math.random(1, size)
        local bad = false
        for i = 1, #snake do
            if snake[i].x == x and snake[i].y == y then
                bad = true
                break
            end
        end
        if not bad then
            apple = {x = x, y = y}
            return
        end
    end
end

local function reset()
    snake = {
        {x = 10, y = 10},
        {x = 9, y = 10},
        {x = 8, y = 10},
    }
    dx, dy = 1, 0
    alive = true
    spawnApple()
end

reset()

while true do
    if isrbxactive() then
        if iskeypressed(0x57) and dy == 0 then dx, dy = 0, -1 end
        if iskeypressed(0x53) and dy == 0 then dx, dy = 0, 1 end
        if iskeypressed(0x41) and dx == 0 then dx, dy = -1, 0 end
        if iskeypressed(0x44) and dx == 0 then dx, dy = 1, 0 end
        if iskeypressed(0x52) then reset() end
    end

    if alive and os.clock() - last > speed then
        last = os.clock()

        local head = snake[1]
        local nx = head.x + dx
        local ny = head.y + dy

        if nx < 1 or nx > size or ny < 1 or ny > size then
            alive = false
        end

        for i = 1, #snake do
            if snake[i].x == nx and snake[i].y == ny then
                alive = false
                break
            end
        end

        if alive then
            table.insert(snake, 1, {x = nx, y = ny})
            if nx == apple.x and ny == apple.y then
                spawnApple()
            else
                table.remove(snake)
            end
        end
    end

    clear()

    if apple then
        box(apple.x, apple.y, Color3.fromRGB(235, 70, 70))
    end

    for i = 1, #snake do
        local s = snake[i]
        box(
            s.x,
            s.y,
            i == 1 and Color3.fromRGB(140, 255, 140) or Color3.fromRGB(70, 200, 70)
        )
    end

    task.wait()
end
