local basics = {}

local runService = cloneref(game:GetService('RunService'))
local players = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))

local localPlayer = players.localPlayer

local entity = fetch('utils/eneity')

local Maid = fetch('classes/Maid')
local maid = Maid.new()

do -- con disabler
	local function disable()
		local root = entity.getRoot()
		if not root then
			repeat task.wait()
				root = entity.getRoot()
			until root
		end

		for _, v in getconnections(root:GetPropertyChangedSignal('CFrame')) do
			hookfunction(v.Function, function() end)
		end
		for _, v in getconnections(root:GetPropertyChangedSignal('Velocity')) do
			hookfunction(v.Function, function() end)
		end
		for _, v in getconnections(root:GetPropertyChangedSignal('AssemblyLinearVelocity')) do
			hookfunction(v.Function, function() end)
		end
	end

	function basics.removeCons(t)
		if not t then
			maid.disabler = nil
			return
		end

		disable()
		maid.disabler = localPlayer.CharacterAdded:Connect(disable)
	end
end

function basics.spinBot(t, options)
	options = options or {}
	if not t then
		maid.spin = nil
		return
	end

	maid.spin = runService.Heartbeat:Connect(function()
		local root = entity.getRoot()
		if not root then return end

		if options.check and options.check() then return end

		root.CFrame = CFrame.new(root.CFrame.Position) * CFrame.Angles(0, (tick() * options.speed) % 360, 0)
	end)
end

function basics.speed(t, options)
	options = options or {}
	if not t then
		maid.speed = nil

		if options.stop then
			local root = entity.getRoot()
			if root then root.AssemblyLinearVelocity = Vector3.zero end
		end

		return
	end

	maid.speed = runService.Heartbeat:Connect(function()
		local root, hum = entity.getRoot()
		if not root or not hum then return end

		local oldVelo = root.AssemblyLinearVelocity.Y
		root.AssemblyLinearVelocity = Vector3.new(hum.MoveDirection.X * options.speed, oldVelo, hum.MoveDirection.Z * options.speed)
	end)
end

function basics.fly(t, options)
	options = options or {}
	if not t then
		maid.fly = nil

		if options.stop then
			local root = entity.getRoot()
			if root then root.AssemblyLinearVelocity = Vector3.zero end
		end

		return
	end

	local vertical = 0

	maid.fly = runService.Heartbeat:Connect(function()
		local root, hum = entity.getRoot()
		if not root or not hum then return end

		if inputService:IsKeyDown(Enum.KeyCode.LeftControl) and not inputService:GetFocusedTextBox() then
			vertical = -1
		elseif inputService:IsKeyDown(Enum.KeyCode.Space) and not inputService:GetFocusedTextBox() then
			vertical = 1
		else
			vertical = 0
		end

		root.AssemblyLinearVelocity = Vector3.new(hum.MoveDirection.X, vertical, hum.MoveDirection.Z) * options.speed
	end)
end

function basics.flyMover(t, options)
	options = options or {}
	if not t then
		maid.flyMover = nil
		maid.flyMoverInst = nil

		if options.stop then
			local root = entity.getRoot()
			if root then root.AssemblyLinearVelocity = Vector3.zero end
		end

		return
	end

	maid.flyMoverInst = cloneref(Instance.new('BodyVelocity'))
	maid.flyMoverInst.MaxForce = Vector3.one * math.huge

	local vertical = 0

	maid.flyMover = runService.Heartbeat:Connect(function()
		local root, hum = entity.getRoot()
		if not root or not hum then return end

		if inputService:IsKeyDown(Enum.KeyCode.LeftControl) and not inputService:GetFocusedTextBox() then
			vertical = -1
		elseif inputService:IsKeyDown(Enum.KeyCode.Space) and not inputService:GetFocusedTextBox() then
			vertical = 1
		else
			vertical = 0
		end

		maid.flyMoverInst.Parent = root
		maid.flyMoverInst.Velocity = Vector3.new(hum.MoveDirection.X, vertical, hum.MoveDirection.Z) * options.speed
	end)
end

return basics