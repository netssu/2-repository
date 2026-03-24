local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local VFXHelper = require(ReplicatedStorage.Modules.VFX_Helper)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local cutsceneEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Client"):WaitForChild("DartWaderMaxCutscene")

local running = false

local FADE_TIME = 0.45
local DEFAULT_FALLBACK_DURATION = 6
local CAMERA_HEIGHT_OFFSET = -1.5

local function tweenBlack(frame: Frame, transparency: number)
	local tween = TweenService:Create(frame, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		BackgroundTransparency = transparency,
	})
	tween:Play()
	tween.Completed:Wait()
end

local function setCharacterInvisible(character: Model, visible: boolean)
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = visible and 0 or 1
		elseif descendant:IsA("Decal") then
			descendant.Transparency = visible and 0 or 1
		elseif descendant:IsA("Texture") then
			descendant.Transparency = visible and 0 or 1
		end
	end
end

local function getAnimatorForInstance(instance: Instance): Animator?
	local humanoid = instance:FindFirstChildWhichIsA("Humanoid", true)
	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		return animator
	end

	local animationController = instance:FindFirstChildWhichIsA("AnimationController", true)
	if not animationController and instance:IsA("Model") then
		animationController = Instance.new("AnimationController")
		animationController.Name = "AutoAnimationController"
		animationController.Parent = instance
	end

	if animationController then
		local animator = animationController:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = animationController
		end
		return animator
	end

	return nil
end

local function buildVfxPartMap(vfxContainer: Instance?): {[string]: Instance}
	local partMap = {}
	if not vfxContainer then
		return partMap
	end

	for _, descendant in vfxContainer:GetDescendants() do
		if descendant:IsA("BasePart") then
			partMap[descendant.Name] = descendant
		end
	end

	return partMap
end

local function attachTrackVfxEvents(track: AnimationTrack, vfxPartMap: {[string]: Instance}): {RBXScriptConnection}
	local connections = {}

	local function emitByName(vfxName: string)
		local target = vfxPartMap[vfxName]
		if target then
			VFXHelper.EmitAllParticles(target)
		end
	end

	table.insert(connections, track.KeyframeReached:Connect(emitByName))

	for vfxName in pairs(vfxPartMap) do
		table.insert(connections, track:GetMarkerReachedSignal(vfxName):Connect(function()
			emitByName(vfxName)
		end))
	end

	return connections
end

local function playAnimationsOnCutsceneClones(clones: {Instance}, vfxContainer: Instance?)
	local tracks = {}
	local trackConnections = {}
	local vfxPartMap = buildVfxPartMap(vfxContainer)

	for _, clone in clones do
		if clone.Name ~= "Sphere" then
			local animator = getAnimatorForInstance(clone)
			if animator then
				for _, animation in clone:GetDescendants() do
					if animation:IsA("Animation") then
						local track = animator:LoadAnimation(animation)
						for _, connection in attachTrackVfxEvents(track, vfxPartMap) do
							table.insert(trackConnections, connection)
						end
						track:Play(0)
						table.insert(tracks, track)
					end
				end
			end
		end
	end

	if #tracks == 0 then
		task.wait(DEFAULT_FALLBACK_DURATION)
		return
	end

	local timeoutAt = os.clock() + DEFAULT_FALLBACK_DURATION
	while os.clock() < timeoutAt do
		local anyPlaying = false
		for _, track in tracks do
			if track.IsPlaying then
				anyPlaying = true
				break
			end
		end

		if not anyPlaying then
			break
		end

		task.wait(0.1)
	end

	for _, connection in trackConnections do
		connection:Disconnect()
	end
end

local function positionCloneAtPlayer(clone: Instance, cframe: CFrame)
	if clone:IsA("Model") then
		clone:PivotTo(cframe)
	elseif clone:IsA("BasePart") then
		clone.CFrame = cframe
	end
end

local function runCutscene()
	if running then
		return
	end
	running = true

	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		running = false
		return
	end

	local sourceFolder = ReplicatedStorage:FindFirstChild("Cutscene")
		or ReplicatedStorage:FindFirstChild("Custscenes")
		or ReplicatedStorage:FindFirstChild("Custescene")
	if not sourceFolder then
		warn("Cutscene/Custscenes/Custescene não foi encontrado em ReplicatedStorage")
		running = false
		return
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DartWaderMaxCutsceneGui"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local blackFrame = Instance.new("Frame")
	blackFrame.Name = "Fade"
	blackFrame.Size = UDim2.fromScale(1, 1)
	blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	blackFrame.BackgroundTransparency = 1
	blackFrame.BorderSizePixel = 0
	blackFrame.Parent = screenGui

	local oldCameraType = camera.CameraType
	local oldCameraSubject = camera.CameraSubject
	local oldCameraCFrame = camera.CFrame
	local cameraConnection: RBXScriptConnection? = nil

	local clones = {}
	local clonedModelTwo: Instance? = nil
	local clonedCutsceneModel: Instance? = nil

	tweenBlack(blackFrame, 0)

	setCharacterInvisible(character, false)

	for _, child in sourceFolder:GetChildren() do
		local clone = child:Clone()
		clone.Parent = workspace
		positionCloneAtPlayer(clone, humanoidRootPart.CFrame)
		table.insert(clones, clone)

		if clone.Name == "2" then
			clonedModelTwo = clone
		end

		if clone.Name:lower() == "cutscene" then
			clonedCutsceneModel = clone
		end
	end

	if not clonedModelTwo then
		local modelCounter = 0
		for _, clone in clones do
			if clone:IsA("Model") then
				modelCounter += 1
				if modelCounter == 2 then
					clonedModelTwo = clone
					break
				end
			end
		end
	end

	local vfxContainer = clonedCutsceneModel and clonedCutsceneModel:FindFirstChild("VFX", true)

	local cameraRootPart: BasePart? = nil
	for _, clone in clones do
		if clone.Name == "Camera" then
			if clone:IsA("Model") then
				cameraRootPart = clone:FindFirstChild("RootPart", true)
			elseif clone:IsA("BasePart") and clone.Name == "RootPart" then
				cameraRootPart = clone
			end
			break
		end
	end

	if cameraRootPart then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = cameraRootPart.CFrame * CFrame.new(0, CAMERA_HEIGHT_OFFSET, 0)
		cameraConnection = RunService.RenderStepped:Connect(function()
			if cameraRootPart.Parent then
				camera.CFrame = cameraRootPart.CFrame * CFrame.new(0, CAMERA_HEIGHT_OFFSET, 0)
			end
		end)
	end

	tweenBlack(blackFrame, 1)

	local playableClones = clones
	if clonedModelTwo then
		playableClones = {clonedModelTwo}
	end

	playAnimationsOnCutsceneClones(playableClones, vfxContainer)

	tweenBlack(blackFrame, 0)

	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end

	camera.CameraType = oldCameraType
	camera.CameraSubject = oldCameraSubject
	camera.CFrame = oldCameraCFrame
	setCharacterInvisible(character, true)

	for _, clone in clones do
		clone:Destroy()
	end

	tweenBlack(blackFrame, 1)
	screenGui:Destroy()

	running = false
end

cutsceneEvent.OnClientEvent:Connect(function()
	runCutscene()
end)
