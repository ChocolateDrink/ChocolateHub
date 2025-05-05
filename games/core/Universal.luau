local tab = library:AddTab('Universal', 700)
local left, right = tab:AddColumn(), tab:AddColumn()

local Service = fetch('classes/Service')
local Maid = fetch('classes/Maid')

local entity = fetch('utils/entity')

local players, inputService, runService = Service:Get(
	'Players',
	'UserInputService',
	'RunService'
)

local localPlayer = players.LocalPlayer
local camera = workspace.CurrentCamera

local maid = Maid.new()

local funcs = {}

do -- funcs
	function funcs.fly(t)
		if not t then
			maid.fly = nil
			maid.flyMover = nil
			maid.flyPlatform = nil
			return
		end

		local vertical = 0

		maid.fly = runService.Heartbeat:Connect(function(dt)
			local root, hum = entity.getRoot()
			if not root or not hum then return end

			if inputService:IsKeyDown(Enum.KeyCode.LeftControl) and not inputService:GetFocusedTextBox() then
				vertical = -1
			elseif inputService:IsKeyDown(Enum.KeyCode.Space) and not inputService:GetFocusedTextBox() then
				vertical = 1
			else
				vertical = 0
			end

			if library.flags.flyNoDrift then
				maid.flyMover = maid.flyMover or cloneref(Instance.new('BodyVelocity'))
				maid.flyMover.MaxForce = Vector3.one * math.huge

				maid.flyMover.Parent = root
				maid.flyMover.Velocity = Vector3.new(hum.MoveDirection.X, vertical, hum.MoveDirection.Z) * library.flags.flySpeed
			else
				if maid.flyMover then maid.flyMover = nil end
			end

			if library.flags.flyPlatform then
				maid.flyPlatform = maid.flyPlatform or cloneref(Instance.new('Part'))
				maid.flyPlatform.Anchored = true
				maid.flyPlatform.CanCollide = vertical == 0
				maid.flyPlatform.CanQuery = false
				maid.flyPlatform.Size = Vector3.new(4.5, 1, 4.5)
				maid.flyPlatform.Material = Enum.Material.Neon
				maid.flyPlatform.Transparency = 0.5
				maid.flyPlatform.Parent = camera
				maid.flyPlatform.Color = library.flags.menuAccentColor

				local offset = hum.RigType == Enum.HumanoidRigType.R6 and 2 or hum.HipHeight + 1.5
				maid.flyPlatform.CFrame = CFrame.new(root.Position - Vector3.new(0, offset, 0)) * CFrame.Angles(0, root.Orientation.Y * math.rad(1), 0)
			else
				maid.flyPlatform = nil
			end

			if library.flags.flyBypass then
				hum:ChangeState(Enum.HumanoidStateType.Swimming)
			end

			if library.flags.flyMode == 'Velocity' then
				root.AssemblyLinearVelocity = Vector3.new(hum.MoveDirection.X, vertical, hum.MoveDirection.Z) * library.flags.flySpeed
			else
				root.AssemblyLinearVelocity = Vector3.zero
				root.CFrame += Vector3.new(hum.MoveDirection.X, vertical, hum.MoveDirection.Z) * library.flags.flySpeed * dt
			end
		end)
	end

	function funcs.speed(t)
		if not t then
			maid.speed = nil

			local root = entity.getRoot()
			if root and library.flags.speedMode == 'Velocity' then root.AssemblyLinearVelocity = Vector3.zero end

			return
		end

		maid.speed = runService.Heartbeat:Connect(function(dt)
			local root, hum = entity.getRoot()
			if not root or not hum then return end

			if library.flags.speedNoClimb and hum:GetState() == Enum.HumanoidStateType.Climbing then return end
			if library.flags.speedGroundLock and hum.FloorMaterial == Enum.Material.Air then
				root.AssemblyLinearVelocity = Vector3.zero
				return
			end

			local newX = hum.MoveDirection.X * library.flags.speedSpeed
			local newZ = hum.MoveDirection.Z * library.flags.speedSpeed

			if library.flags.speedMode == 'Velocity' then
				local oldVelo = root.AssemblyLinearVelocity.Y
				root.AssemblyLinearVelocity = Vector3.new(newX, oldVelo, newZ)
			else
				root.CFrame += Vector3.new(newX, 0, newZ) * dt
			end
		end)
	end

	do -- noclip
		local overlap = OverlapParams.new()
		overlap.MaxParts = 9e9

		local modded = {}

		function funcs.noclip(t)
			if not t then
				maid.noclip = nil

				for i, v in next, modded do
					if not i then continue end

					i.CanCollide = true
					i.Color = v.color
				end
				table.clear(modded)

				if library.flags.noclipMode == 'Character' and library.flags.noclipInstantReset then
					local _, hum = entity.getRoot()

					hum:ChangeState(Enum.HumanoidStateType.Physics)
					task.wait()
					hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
				end

				return
			end

			maid.noclip = runService.Heartbeat:Connect(function()
				if library.flags.noclipMode == 'Surroundings' then
					local root, hum = entity.getRoot()
					if not root or not hum then return end

					local ignores = {camera, localPlayer.Character}
					for _, v in players:GetPlayers() do
						table.insert(ignores, v.Character)
					end

					overlap.FilterDescendantsInstances = ignores

					local parts = workspace:GetPartBoundsInBox(root.CFrame + Vector3.new(0, 1, 0), root.Size + Vector3.new(1, hum.HipHeight, 1), overlap)
					for _, v in parts do
						if not v.CanCollide then continue end

						modded[v] = {collide = true, color = v.Color}
						v.CanCollide = false
						if library.flags.noclipVisualizer then v.Color = library.flags.menuAccentColor end
					end

					for i in modded do
						if table.find(parts, i) then continue end

						local old = modded[i]
						i.CanCollide = true
						i.Color = old.color
						modded[i] = nil
					end
				else
					for _, v in localPlayer.Character:GetDescendants() do
						if v:IsA('BasePart') and v.CanCollide then
							v.CanCollide = false
						end
					end
				end
			end)
		end
	end

	library.uniFuncs = funcs
end

do -- ui
	local speed = left:AddSection('Speed') do
		speed:AddToggle({
			text = 'Enabled',
			flag = 'speed',
			callback = funcs.speed
		}):AddBind({
			flag = 'speed bind',
			callback = function()
				library.options.speed:SetState(not library.flags.speed)
			end
		})

		speed:AddDivider()

		speed:AddList({
			text = 'Mode',
			flag = 'speed mode',
			values = { 'Velocity', 'CFrame' }
		})

		speed:AddSlider({
			text = 'Speed',
			flag = 'speed speed',
			min = 10,
			max = 5500,
			value = 50
		})

		speed:AddToggle({
			text = 'Ground Only',
			flag = 'speed ground lock',
			tip = 'Only speeds up when you are on the ground.'
		})

		speed:AddToggle({
			text = 'Disable On Climb',
			flag = 'speed no climb',
			tip = 'Disables speed when you are climbing.'
		})
	end

	local fly = right:AddSection('Flight') do
		fly:AddToggle({
			text = 'Enabled',
			flag = 'fly',
			callback = funcs.fly
		}):AddBind({
			flag = 'fly bind',
			callback = function()
				library.options.fly:SetState(not library.flags.fly)
			end
		})

		fly:AddDivider()

		fly:AddList({
			text = 'Mode',
			flag = 'fly mode',
			values = { 'Velocity', 'CFrame' }
		})

		fly:AddSlider({
			text = 'Speed',
			flag = 'fly speed',
			min = 10,
			max = 5500,
			value = 60
		})

		fly:AddToggle({
			text = 'Anti Drift',
			flag = 'fly no drift',
			tip = 'Prevents drifting downwards/upwards, inserts a body mover to your character.'
		})

		fly:AddToggle({
			text = 'Platform',
			flag = 'fly platform',
			tip = 'Puts a platform below you.'
		})

		fly:AddToggle({
			text = 'Swim Bypass',
			flag = 'fly bypass',
			tip = 'Makes you swim in the air to bypass some anticheats.'
		})
	end

	local noclip = left:AddSection('Noclip') do
		noclip:AddToggle({
			text = 'Enabled',
			flag = 'noclip',
			callback = funcs.noclip
		}):AddBind({
			flag = 'noclip bind',
			callback = function()
				library.options.noclip:SetState(not library.flags.noclip)
			end
		})

		noclip:AddDivider()

		noclip:AddList({
			text = 'Mode',
			flag = 'noclip mode',
			values = { 'Surroundings', 'Character' }
		})

		noclip:AddToggle({
			text = 'Visualizer',
			flag = 'noclip visualizer',
			tip = 'Highlights parts that have thier collisions modified.'
		})

		noclip:AddToggle({
			text = 'Instant Reset',
			flag = 'noclip instant reset',
			tip = 'Instanly un-noclips you when in character mode.'
		})
	end
end