local RunService = {}
local RenderBinds = {}

local function Signal()
	local self = {}
	self._connections = {}
	self._waiting = {}

	function self:Connect(fn)
		assert(type(fn) == "function", "Expected function")

		local conn = {
			Connected = true,
			_fn = fn,
		}

		self._connections[#self._connections + 1] = conn

		function conn:Disconnect()
			if not self.Connected then
				return
			end
			self.Connected = false
		end

		return conn
	end

	function self:Fire(...)
		local conns = self._connections
		local alive = 0

		for i = 1, #conns do
			local c = conns[i]
			if c.Connected then
				alive += 1
				conns[alive] = c
				c._fn(...)
			end
		end

		for i = alive + 1, #conns do
			conns[i] = nil
		end
	end

	function self:Wait()
		local thread = coroutine.running()
		local conn

		conn = self:Connect(function(...)
			conn:Disconnect()
			coroutine.resume(thread, ...)
		end)

		return coroutine.yield()
	end

	return self
end

RunService.Heartbeat = Signal()
RunService.RenderStepped = Signal()
RunService.Stepped = Signal()
RunService.PreSimulation = Signal()
RunService.PostSimulation = Signal()
RunService.PreAnimation = Signal()
RunService.PreRender = Signal()

local RenderStepCounter = 0

function RunService:BindToRenderStep(name, priority, fn)
	assert(type(fn) == "function", "Expected function")
	RenderStepCounter += 1

	RenderBinds[name] = {
		Priority = priority or 0,
		Order = RenderStepCounter,
		Function = fn,
	}
end

function RunService:UnbindFromRenderStep(name)
	RenderBinds[name] = nil
end

spawn(function()
	local last = os.clock()

	while true do
		local now = os.clock()
		local delta = now - last
		last = now

		if delta > 1 / 15 then
			delta = 1 / 15
		end

		RunService.PreSimulation:Fire(delta)
		RunService.Stepped:Fire(now, delta)
		RunService.PostSimulation:Fire(delta)
		RunService.PreAnimation:Fire(delta)
		RunService.PreRender:Fire(delta)

		local list = {}
		for _, bind in pairs(RenderBinds) do
			list[#list + 1] = bind
		end

		table.sort(list, function(a, b)
			if a.Priority == b.Priority then
				return a.Order < b.Order
			end
			return a.Priority < b.Priority
		end)

		for i = 1, #list do
			list[i].Function(delta)
		end

		RunService.RenderStepped:Fire(delta)
		RunService.Heartbeat:Fire(delta)

		wait()
	end
end)

local Players = game.Players
local LocalPlayer = Players.LocalPlayer

local ESPObjects = {}

local function CreateESP(player)
	local box = Drawing.new("Square")
	box.Visible = false
	box.Thickness = 1
	box.Filled = true
	box.Color = Color3.fromRGB(47, 0, 255)
	box.Transparency = 0.5
	box.Size = Vector2.new(60, 60)

	ESPObjects[player] = box
end

for _, player in pairs(Players:GetPlayers()) do
	if player ~= LocalPlayer then
		CreateESP(player)
	end
end

Players.PlayerAdded:Connect(function(player)
	if player ~= LocalPlayer then
		CreateESP(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local box = ESPObjects[player]
	if box then
		box:Remove()
		ESPObjects[player] = nil
	end
end)

RunService.RenderStepped:Connect(function()
	for player, box in pairs(ESPObjects) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")

		if not root then
			box.Visible = false
			continue
		end

		local screenPos, onScreen = WorldToScreen(root.Position)
		if not onScreen then
			box.Visible = false
			continue
		end

		box.Visible = true
		box.Position = Vector2.new(screenPos.X - box.Size.X / 2, screenPos.Y - box.Size.Y / 2)
	end
end)
