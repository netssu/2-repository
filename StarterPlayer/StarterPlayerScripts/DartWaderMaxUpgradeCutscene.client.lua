local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService: TweenService = game:GetService("TweenService")
local RunService: RunService = game:GetService("RunService")
local StarterGui: StarterGui = game:GetService("StarterGui")
local ContentProvider: ContentProvider = game:GetService("ContentProvider")

local modulesFolder: Folder = ReplicatedStorage:WaitForChild("Modules")
local VFXHelper = require(modulesFolder:WaitForChild("VFX_Helper"))

local FADE_TIME: number = 0.45
local DEFAULT_FALLBACK_DURATION: number = 6
local CAMERA_HEIGHT_OFFSET: number = -1.5
local CUTSCENE_GUI_NAME: string = "DartWaderMaxCutsceneGui"
local CUTSCENE_VFX_MODEL_NAME: string = "CutSceneVfx"
local TRACK_MODEL_NAME: string = "2"

local player: Player = Players.LocalPlayer
local camera: Camera = workspace.CurrentCamera

local cutsceneEvent: RemoteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Client"):WaitForChild("DartWaderMaxCutscene")

local running: boolean = false
local cutsceneReady: boolean = false

local cachedClones: {Instance} = {}
local cachedTracks: {AnimationTrack} = {}
local cachedMaxDuration: number = 0
local cachedCameraRootPart: BasePart? = nil

local function tween_black(frame: Frame, transparency: number): ()
	local tween = TweenService:Create(frame, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		BackgroundTransparency = transparency,
	})
	tween:Play()
	tween.Completed:Wait()
end

local function set_character_visibility(character: Model, isVisible: boolean): ()
	for _, descendant: Instance in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = isVisible and 0 or 1
		elseif descendant:IsA("Decal") then
			descendant.Transparency = isVisible and 0 or 1
		elseif descendant:IsA("Texture") then
			descendant.Transparency = isVisible and 0 or 1
		end
	end
end

local function get_cutscene_source_folder(): Instance?
	return ReplicatedStorage:FindFirstChild("Cutscene")
		or ReplicatedStorage:FindFirstChild("Custescene")
		or ReplicatedStorage:FindFirstChild("Cutscenes")
		or ReplicatedStorage:FindFirstChild("Custscenes")
end

local function get_animator_for_instance(instance: Instance): Animator?
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

local function position_clone_at_player(clone: Instance, targetCFrame: CFrame): ()
	if clone:IsA("Model") then
		clone:PivotTo(targetCFrame)
	elseif clone:IsA("BasePart") then
		clone.CFrame = targetCFrame
	end
end

local function get_cutscene_vfx_parts(clones: {Instance}): {[string]: BasePart}
	local vfxPartsByName: {[string]: BasePart} = {}

	for _, clone: Instance in clones do
		if clone.Name == CUTSCENE_VFX_MODEL_NAME then
			for _, descendant: Instance in clone:GetDescendants() do
				if descendant:IsA("BasePart") then
					vfxPartsByName[descendant.Name] = descendant
				end
			end
			break
		end
	end

	return vfxPartsByName
end

local function connect_vfx_markers(track: AnimationTrack, vfxPartsByName: {[string]: BasePart}): ()
	for markerName: string, part: BasePart in vfxPartsByName do
		track:GetMarkerReachedSignal(markerName):Connect(function()
			if not part or part.Parent == nil then
				return
			end

			if not part:IsDescendantOf(game) then
				return
			end

			VFXHelper.EmitAllParticles(part)
		end)
	end
end

local function preload_cutscene(): ()
	if cutsceneReady then return end

	local sourceFolder = get_cutscene_source_folder()
	if not sourceFolder then
		warn("Pasta da cutscene não foi encontrada em ReplicatedStorage")
		return
	end

	for _, child: Instance in sourceFolder:GetChildren() do
		local clone = child:Clone()
		clone.Parent = ReplicatedStorage
		cachedClones[#cachedClones + 1] = clone

		if clone.Name == "Camera" then
			if clone:IsA("Model") then
				local found = clone:FindFirstChild("camera", true)
				if found and found:IsA("BasePart") then
					cachedCameraRootPart = found
				end
			elseif clone:IsA("BasePart") and clone.Name == "camera" then
				cachedCameraRootPart = clone
			end
		end
	end

	local vfxPartsByName = get_cutscene_vfx_parts(cachedClones)
	local animationsToLoad: {Animation} = {}

	for _, clone: Instance in cachedClones do
		if clone.Name ~= "Sphere" and clone.Name ~= CUTSCENE_VFX_MODEL_NAME then
			local animator = get_animator_for_instance(clone)
			if animator then
				for _, animationObject: Instance in clone:GetDescendants() do
					if animationObject:IsA("Animation") then
						animationsToLoad[#animationsToLoad + 1] = animationObject
						local track = animator:LoadAnimation(animationObject)

						if clone.Name == TRACK_MODEL_NAME then
							connect_vfx_markers(track, vfxPartsByName)
						end

						cachedTracks[#cachedTracks + 1] = track
					end
				end
			end
		end
	end

	if #animationsToLoad > 0 then
		ContentProvider:PreloadAsync(animationsToLoad)
	end

	for _, track: AnimationTrack in cachedTracks do
		local waitTime: number = 0

		while track.Length == 0 and waitTime < 5 do
			waitTime += task.wait()
		end

		if track.Length > cachedMaxDuration then
			cachedMaxDuration = track.Length
		end
	end

	cutsceneReady = true
end

local function run_cutscene(): ()
	if running then
		return
	end

	running = true

	local character: Model = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoidRootPart or not humanoidRootPart:IsA("BasePart") then
		running = false
		return
	end

	local originalCharacterCFrame: CFrame = humanoidRootPart.CFrame

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = CUTSCENE_GUI_NAME
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

	local hiddenGuis: {ScreenGui} = {}
	for _, gui: Instance in player.PlayerGui:GetChildren() do
		if gui:IsA("ScreenGui") and gui.Name ~= CUTSCENE_GUI_NAME and gui.Enabled then
			gui.Enabled = false
			hiddenGuis[#hiddenGuis + 1] = gui
		end
	end

	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	end)

	tween_black(blackFrame, 0)

	local hiddenTowers: {Instance} = {}
	local hiddenMobs: {Instance} = {}

	local towersFolder = workspace:FindFirstChild("Towers")
	if towersFolder then
		for _, child: Instance in towersFolder:GetChildren() do
			hiddenTowers[#hiddenTowers + 1] = child
			child.Parent = ReplicatedStorage
		end
	end

	local mobsFolder = workspace:FindFirstChild("Mobs")
	if mobsFolder then
		for _, child: Instance in mobsFolder:GetChildren() do
			hiddenMobs[#hiddenMobs + 1] = child
			child.Parent = ReplicatedStorage
		end
	end

	set_character_visibility(character, false)
	humanoidRootPart.Anchored = true
	character:PivotTo(originalCharacterCFrame * CFrame.new(0, -10, 0))

	if not cutsceneReady then
		preload_cutscene()
	end

	for _, clone: Instance in cachedClones do
		clone.Parent = workspace
		position_clone_at_player(clone, originalCharacterCFrame)
	end

	if cachedCameraRootPart then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = cachedCameraRootPart.CFrame * CFrame.new(0, CAMERA_HEIGHT_OFFSET, 0)
	end

	cameraConnection = RunService.RenderStepped:Connect(function()
		if cachedCameraRootPart and cachedCameraRootPart.Parent then
			camera.CFrame = cachedCameraRootPart.CFrame * CFrame.new(0, CAMERA_HEIGHT_OFFSET, 0)
		end
		camera:ClearAllChildren()
	end)
	
	local sourceFolder = get_cutscene_source_folder()
	sourceFolder.Sound:Play()

	for _, track: AnimationTrack in cachedTracks do
		track:Play(0)
		track.TimePosition = 0.05
	end

	task.wait(0.1)

	task.spawn(function()
		tween_black(blackFrame, 1)
	end)

	if cachedMaxDuration > 0 then
		task.wait(cachedMaxDuration - 0.1)
	else
		task.wait(DEFAULT_FALLBACK_DURATION - 0.1)
	end

	tween_black(blackFrame, 0)

	for _, track: AnimationTrack in cachedTracks do
		track:Stop(0)
	end

	for _, clone: Instance in cachedClones do
		clone.Parent = ReplicatedStorage
	end

	if towersFolder then
		for _, child: Instance in hiddenTowers do
			if child.Parent ~= nil then
				child.Parent = towersFolder
			end
		end
	end

	if mobsFolder then
		for _, child: Instance in hiddenMobs do
			if child.Parent ~= nil then
				child.Parent = mobsFolder
			end
		end
	end

	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end

	camera.CameraType = oldCameraType
	camera.CameraSubject = oldCameraSubject
	camera.CFrame = oldCameraCFrame

	character:PivotTo(originalCharacterCFrame)
	humanoidRootPart.Anchored = false
	set_character_visibility(character, true)

	workspace.Camera:ClearAllChildren()

	for _, gui: ScreenGui in hiddenGuis do
		if gui.Parent then
			gui.Enabled = true
		end
	end

	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	end)

	tween_black(blackFrame, 1)
	screenGui:Destroy()

	running = false
end

task.spawn(function()
	while not get_cutscene_source_folder() do
		task.wait(0.5)
	end
	preload_cutscene()
end)

cutsceneEvent.OnClientEvent:Connect(function()
	run_cutscene()
end)