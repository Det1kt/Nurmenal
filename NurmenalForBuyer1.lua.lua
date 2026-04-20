--// Admin Panel (LOCAL ONLY) - One Script
--// Put into: StarterPlayer > StarterPlayerScripts > LocalScript
--// IMPORTANT: Fill ADMIN_USER_IDS

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")



-- ==================================== 
-- CONFIG
-- ==================================== 


local NURMENAL_VERSION = "[V 0.11]"
local LOGO_IMAGE = "rbxassetid://117181319122591" -- rbxassetid://96127163983922
local key_for_activate = "xoO7oBKw58wLyNCLIdpZ5gxgk4f3vz"
local USER_NICKNAMES = {
	-- Ники сюда
	"Mishanlend",
	"VovuSCRIPT",
}
local PRODUCT_BUYER_NICK = "VovuSCRIPT"

-- ==================================== 

-- ==================================== 



function isAllowedUser()
	local plr = Players.LocalPlayer
	if not plr then return false end

	local myName = tostring(plr.Name):lower()

	for _, nick in ipairs(USER_NICKNAMES) do
		if myName == tostring(nick):lower() then
			return true
		end
	end

	return false
end

-- ===== BLINK HIGHLIGHT ENGINE =====
local _blinkTokens = {} -- [id] = token
function StopBlink(id) _blinkTokens[id] = nil end
function StartBlinkHighlight(id, hl, color3, minFill, maxFill, speed)
	StopBlink(id)
	local token = {}
	_blinkTokens[id] = token

	hl.FillColor = color3
	hl.OutlineColor = color3
	hl.FillTransparency = maxFill
	hl.OutlineTransparency = 0

	task.spawn(function()
		local t = 0
		while _blinkTokens[id] == token and hl and hl.Parent do
			t += task.wait()
			local a = (math.sin(t * (speed or 4)) + 1) / 2 -- 0..1
			hl.FillTransparency = minFill + (maxFill - minFill) * a
		end
	end)
end

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local mouse = LP:GetMouse()
local fontik = Enum.Font.Code

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------



------------------------------------------------------------
-- HELPERS
------------------------------------------------------------
function getChar() return LP.Character end
function getHumanoid(char) return char and char:FindFirstChildOfClass("Humanoid") or nil end
function getHRP(char) return char and char:FindFirstChild("HumanoidRootPart") or nil end

function getHRPPlayer(plr: Player)
	local ch = plr and plr.Character
	return ch and ch:FindFirstChild("HumanoidRootPart") or nil
end
----------------------------------------------
function getModelRoot(m: Model?)
	if not m then return nil end
	return (m:FindFirstChild("HumanoidRootPart"))
		or (m.PrimaryPart)
		or (m:FindFirstChildWhichIsA("BasePart"))
end

function getTargetModel(target)
	if typeof(target) ~= "Instance" then return nil end
	if target:IsA("Player") then
		return target.Character
	elseif target:IsA("Model") then
		return target
	end
	return nil
end

function getTargetRoot(target)
	local m = getTargetModel(target)
	local root = m and getModelRoot(m)
	if root and root:IsA("BasePart") then return root end
	return nil
end

function getTargetHumanoid(target)
	local m = getTargetModel(target)
	return m and m:FindFirstChildOfClass("Humanoid") or nil
end
------------------------------------------------------------

function isInPlayerCharacter(inst: Instance)
	local m = inst:FindFirstAncestorOfClass("Model")
	if not m then return false end
	return Players:GetPlayerFromCharacter(m) ~= nil
end

function hasEquippedTool()
	local c = getChar()
	return c and (c:FindFirstChildOfClass("Tool") ~= nil) or false
end

function v3round(v: Vector3, d: number)
	local m = 10 ^ (d or 1)
	return Vector3.new(
		math.floor(v.X * m + 0.5) / m,
		math.floor(v.Y * m + 0.5) / m,
		math.floor(v.Z * m + 0.5) / m
	)
end

function normalIdToVec(n: Enum.NormalId)
	if n == Enum.NormalId.Right then return Vector3.new(1,0,0) end
	if n == Enum.NormalId.Left then return Vector3.new(-1,0,0) end
	if n == Enum.NormalId.Top then return Vector3.new(0,1,0) end
	if n == Enum.NormalId.Bottom then return Vector3.new(0,-1,0) end
	if n == Enum.NormalId.Back then return Vector3.new(0,0,1) end
	return Vector3.new(0,0,-1) -- Front
end

function trySendChat(msg: string)
	local ok = pcall(function()
		if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
			local cfg = TextChatService:FindFirstChild("ChatInputBarConfiguration")
			if cfg and cfg.TargetTextChannel then
				cfg.TargetTextChannel:SendAsync(msg)
				return
			end
		end
		error("No TextChat target")
	end)
	if ok then return end

	pcall(function()
		local evFolder = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
		local say = evFolder and evFolder:FindFirstChild("SayMessageRequest")
		if say and say:IsA("RemoteEvent") then
			say:FireServer(msg, "All")
		end
	end)
end












------------------------------------------------------------
-- STATE
------------------------------------------------------------
local state = {
	panelOpen = false,

	-- Settings
	onlyButton = false,
	hideAdminStatic = true, -- default ON

	-- Visual
	detectorOn = false,
	xrayOn = false,
	hitboxSeeOn = false,
	coordsOn = false,
	seeInvisOn = false,
	nightVisionOn = false,
	nightVisionValue = 10,

	freeCamOn = false,


	-- Player
	boostOn = false,        -- Speed+Jump together (G toggle)
	orbitMode = "Orbit",
	speedValue = 50,
	jumpValue = 50,
	invisibleOn = false,

	autoAimOn = false,
	autoGGOn = false,
	flyOn = false,
	noClipOn = false,

	tpOn = false,
	tpMode = "Click", -- "Click" | "Cord"

	adminToolsOn = false,

	-- Create tool mode
	createMode = "Move", -- Move | Scale | Rotate


	tposeOn = false,

	rollbackSeconds = 10,
	flyMode = "Smooth", -- Smooth | Combat

	__PosHistory = {
		buf = {},
		acc = 0,
		step = 0.05,   -- как часто сохраняем
		maxAge = 30,   -- сколько секунд храним
	},

	searchFunctionsOn = true,
}

state.flingOn = state.flingOn or false
state.flingMode = state.flingMode or "Spin" -- "Spin" | "Fling"
state.flingSpeed = state.flingSpeed or 120

state.orbitOn = state.orbitOn or false
state.orbitSpeed = state.orbitSpeed or 25
state.orbitDist = state.orbitDist or 6
state.orbitTargetPlr = state.orbitTargetPlr or nil

------------------------------------------------------------
-- UI BUILD
------------------------------------------------------------
local function mk(instType, props, parent)
	local o = Instance.new(instType)
	for k, v in pairs(props or {}) do o[k] = v end
	o.Parent = parent
	return o
end



local oldGui = PlayerGui:FindFirstChild("AdminPanelGui")
if oldGui then
	oldGui:Destroy()
end


local gui = mk("ScreenGui", {
	Name = "AdminPanelGui",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)


----------------------------------------------------------------------------------------------


local rollbackPanel = mk("Frame", {
	Name = "RollbackPanel",
	Visible = true,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -14, 1, -70),
	Size = UDim2.fromOffset(260, 44),
	BackgroundColor3 = Color3.fromRGB(16,16,18),
	BackgroundTransparency = 0.1,
}, gui)
mk("UICorner", {CornerRadius = UDim.new(0, 12)}, rollbackPanel)
mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(80,80,95), Transparency = 0.35}, rollbackPanel)

refreshRollbackPanel=function()
	if rollbackPanel then
		rollbackPanel.Visible = (state.antiPushOn == true)
	end
end
-------------------------------------------------------------



gui.IgnoreGuiInset = true

pcall(function()
	gui.ScreenInsets = Enum.ScreenInsets.None
end)

-- Menu button (right of center)
local menuBtn = mk("TextButton", {
	Name = "MenuButton",
	Text = "Menu",
	Font = fontik,
	TextSize = 18,
	AutoButtonColor = true,
	Size = UDim2.fromOffset(110, 44),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 300, 0.5, 0),
	BackgroundColor3 = Color3.fromRGB(25, 25, 28),
	TextColor3 = Color3.fromRGB(235, 235, 235),
}, gui)
mk("UICorner", {CornerRadius = UDim.new(0, 10)}, menuBtn)
mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(70, 70, 80), Transparency = 0.2}, menuBtn)

local panel = mk("Frame", {
	Name = "Panel",
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(16, 16, 18),
}, gui)
mk("UICorner", {CornerRadius = UDim.new(0, 14)}, panel)
mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(80, 80, 95), Transparency = 0.25}, panel)

function updatePanelSize()
	local cam = Workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local w = math.clamp(math.floor(vp.X * 0.34), 320, 470)
	local h = math.clamp(math.floor(vp.Y * 0.74), 320, 580)
	panel.Size = UDim2.fromOffset(w, h)
end
updatePanelSize()
if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePanelSize)
end

mk("TextLabel", {
	Text = "Nurmenal Panel "..NURMENAL_VERSION,
	Font = fontik,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(245, 245, 245),
	Size = UDim2.new(1, -24, 0, 28),
	Position = UDim2.fromOffset(12, 10),
}, panel)

local searchBox = mk("TextBox", {
	Name = "FunctionSearch",
	Visible = false,
	ClearTextOnFocus = false,
	Text = "",
	PlaceholderText = "Search function...",
	Font = fontik,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundColor3 = Color3.fromRGB(30, 30, 36),
	TextColor3 = Color3.fromRGB(235, 235, 235),
	Size = UDim2.new(1, -24, 0, 28),
	Position = UDim2.fromOffset(12, 66),
}, panel)
mk("UICorner", {CornerRadius = UDim.new(0, 10)}, searchBox)
mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75, 75, 90), Transparency = 0.45}, searchBox)

local hint = mk("TextLabel", {
	Text = "Hotkeys: F3=Detector | F4=Xray | RightShift=Boost | F2=invis | \nF1=StopOrbit | F5=FreeCam | F6=NightVision | F7=Menu | F8=UnlockMouse",
	Font = fontik,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(170, 170, 170),
	Size = UDim2.new(1, -24, 0, 18),
	Position = UDim2.fromOffset(12, 38),
}, panel)




local scroll = mk("ScrollingFrame", {
	Name = "Scroll",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Size = UDim2.new(1, -24, 1, -70),
	Position = UDim2.fromOffset(12, 60),
	CanvasSize = UDim2.new(0,0,0,0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, panel)

mk("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, scroll)

























function makeSection(titleText)
	local sec = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(22, 22, 26),
		Size = UDim2.new(1, 0, 0, 1),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, scroll)
	mk("UICorner", {CornerRadius = UDim.new(0, 12)}, sec)
	mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(70, 70, 85), Transparency = 0.35}, sec)

	mk("TextLabel", {
		Text = titleText,
		Font = fontik,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(240, 240, 240),
		Size = UDim2.new(1, -20, 0, 24),
		Position = UDim2.fromOffset(10, 8),
	}, sec)

	local wrap = mk("Frame", {
		Name = "Wrap",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 0, 1),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(10, 34),
	}, sec)

	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, wrap)

	mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,8)}, wrap)
	return wrap
end

local function makeButton(parent, text)
	local b = mk("TextButton", {
		Text = text,
		Font = fontik,
		TextSize = 14,
		AutoButtonColor = true,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Color3.fromRGB(30, 30, 36),
		TextColor3 = Color3.fromRGB(235, 235, 235),
	}, parent)
	mk("UICorner", {CornerRadius = UDim.new(0, 10)}, b)
	mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75, 75, 90), Transparency = 0.45}, b)
	return b
end

local function setBtnOn(btn, on)
	btn.BackgroundColor3 = on and Color3.fromRGB(40, 52, 90) or Color3.fromRGB(30, 30, 36)
	btn.TextColor3 = on and Color3.fromRGB(245, 245, 255) or Color3.fromRGB(235, 235, 235)
end

local function makeSlider(parent, titleText, minV, maxV, initialV, scrollFrame)
	local holder = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(30, 30, 36),
		Size = UDim2.new(1, 0, 0, 58),
		ZIndex = 5,
	}, parent)
	mk("UICorner", {CornerRadius = UDim.new(0, 10)}, holder)
	mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75, 75, 90), Transparency = 0.45}, holder)

	mk("TextLabel", {
		Text = titleText,
		Font = fontik,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(235, 235, 235),
		Size = UDim2.new(1, -20, 0, 20),
		Position = UDim2.fromOffset(10, 6),
		ZIndex = 6,
	}, holder)

	local valueLbl = mk("TextLabel", {
		Text = tostring(initialV),
		Font = fontik,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(210, 210, 210),
		Size = UDim2.new(1, -20, 0, 20),
		Position = UDim2.fromOffset(10, 6),
		ZIndex = 6,
	}, holder)

	local track = mk("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(18, 18, 22),
		Size = UDim2.new(1, -20, 0, 14),
		Position = UDim2.fromOffset(10, 34),
		ZIndex = 6,
	}, holder)
	mk("UICorner", {CornerRadius = UDim.new(0, 8)}, track)

	local fill = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(200, 200, 215),
		Size = UDim2.new(0, 0, 1, 0),
		ZIndex = 7,
	}, track)
	mk("UICorner", {CornerRadius = UDim.new(0, 8)}, fill)

	local knob = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(245, 245, 255),
		Size = UDim2.fromOffset(18, 18),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		ZIndex = 8,
	}, track)
	mk("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)
	mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(80, 80, 90), Transparency = 0.3}, knob)

	local current = math.clamp(initialV, minV, maxV)
	local dragging = false
	local moveConn, endConn

	local function setValue(v)
		current = math.clamp(v, minV, maxV)
		valueLbl.Text = tostring(current)
		local a = (current - minV) / math.max((maxV - minV), 1)
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
	end

	local function setFromX(x, absPos, absSize)
		local a = math.clamp((x - absPos) / math.max(absSize, 1), 0, 1)
		local v = math.floor(minV + (maxV - minV) * a + 0.5)
		setValue(v)
	end

	task.defer(function()
		task.wait()
		setValue(current)
	end)

	local function beginDrag(input)
		dragging = true
		if scrollFrame then scrollFrame.ScrollingEnabled = false end

		local absPos = track.AbsolutePosition.X
		local absSize = track.AbsoluteSize.X

		setFromX(input.Position.X, absPos, absSize)

		moveConn = UIS.InputChanged:Connect(function(ch)
			if not dragging then return end
			if ch.UserInputType == Enum.UserInputType.MouseMovement or ch.UserInputType == Enum.UserInputType.Touch then
				setFromX(ch.Position.X, absPos, absSize)
			end
		end)

		endConn = UIS.InputEnded:Connect(function(ended)
			if ended.UserInputType == Enum.UserInputType.MouseButton1 or ended.UserInputType == Enum.UserInputType.Touch then
				dragging = false
				if scrollFrame then scrollFrame.ScrollingEnabled = true end
				if moveConn then moveConn:Disconnect(); moveConn = nil end
				if endConn then endConn:Disconnect(); endConn = nil end
			end
		end)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end)

	return {
		Get = function() return current end,
		Set = function(v) setValue(v) end,
		Holder = holder,
	}
end




------------------------------------------------------------
-- HUD STATUS ("Admin static")
------------------------------------------------------------
local hud = mk("Frame", {
	Name = "StatusHUD",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 12, 1, -12),
	BackgroundColor3 = Color3.fromRGB(16,16,18),
	BackgroundTransparency = 0.15,
	AutomaticSize = Enum.AutomaticSize.Y,
	Size = UDim2.fromOffset(310, 10),
	Visible = not state.hideAdminStatic,
}, gui)
mk("UICorner", {CornerRadius = UDim.new(0, 12)}, hud)
mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(80, 80, 95), Transparency = 0.35}, hud)

mk("TextLabel", {
	Text = "Admin Status",
	Font = fontik,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(240,240,240),
	Size = UDim2.new(1, -16, 0, 18),
	Position = UDim2.fromOffset(8, 6),
}, hud)

local hudList = mk("Frame", {
	BackgroundTransparency = 1,
	AutomaticSize = Enum.AutomaticSize.Y,
	Size = UDim2.new(1, -16, 0, 10),
	Position = UDim2.fromOffset(8, 24),
}, hud)

mk("UIListLayout", {
	Padding = UDim.new(0, 2),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, hudList)




-- Watermark (bottom-left)
local watermark = mk("TextLabel", {
	Name = "Watermark",
	Text = "NURMENAL "..NURMENAL_VERSION,
	Font = fontik, -- хочешь другой шрифт: Enum.Font.GothamBold и т.п.
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextStrokeTransparency = 0.65,

	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 12, 1, -12), -- левый низ
	Size = UDim2.fromOffset(300, 20),

	ZIndex = 999,
}, gui)



local watermarkBy = mk("TextLabel", {
	Name = "WatermarkBy",
	Text = "by Det1kt",
	Font = fontik,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(205, 205, 215),
	TextStrokeTransparency = 0.82,

	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 12, 1, -36), -- выше watermark
	Size = UDim2.fromOffset(200, 14),

	ZIndex = 1000,
}, gui)



local hudLines = {}
function hudLine(key)
	local lbl = mk("TextLabel", {
		Text = key,
		Font = fontik,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(210,210,210),
		Size = UDim2.new(1, 0, 0, 16),
	}, hudList)
	hudLines[key] = lbl
	return lbl
end

local keys = {
	"HideAdminStatic","OnlyButton","Detector","Xray","HitBox See","SeeInvis","Coordinates",
	"Boost (Speed/Jump)","Invisible","AutoAim","AutoGG","Fly","NoClip","TP","Admin Tools",
	"Fling","Orbit","NightVision","FreeCam","AntiPush", "Tpose",
}
for _, k in ipairs(keys) do hudLine(k) end

function onOff(b) return b and "ON" or "OFF" end
function colorize(lbl, b)
	lbl.TextColor3 = b and Color3.fromRGB(210,240,255) or Color3.fromRGB(190,190,190)
end

-- Unfreeze player (HRP)
do
	local hrp = getHRP(getChar())
	if hrp and freeCamFreezeSaved then
		hrp.Anchored = freeCamFreezeSaved.anchored
		hrp.AssemblyLinearVelocity = freeCamFreezeSaved.vel or Vector3.zero
		hrp.AssemblyAngularVelocity = freeCamFreezeSaved.ang or Vector3.zero
	end
	freeCamFreezeSaved = nil
end


function updateHUD()
	hudLines["HideAdminStatic"].Text = ("HideAdminStatic: %s"):format(onOff(state.hideAdminStatic))
	colorize(hudLines["HideAdminStatic"], state.hideAdminStatic)

	hudLines["OnlyButton"].Text = ("OnlyButton: %s"):format(onOff(state.onlyButton))
	colorize(hudLines["OnlyButton"], state.onlyButton)

	hudLines["Detector"].Text = ("Detector: %s"):format(onOff(state.detectorOn))
	colorize(hudLines["Detector"], state.detectorOn)

	hudLines["Xray"].Text = ("Xray: %s"):format(onOff(state.xrayOn))
	colorize(hudLines["Xray"], state.xrayOn)

	hudLines["HitBox See"].Text = ("HitBox See: %s"):format(onOff(state.hitboxSeeOn))
	colorize(hudLines["HitBox See"], state.hitboxSeeOn)

	hudLines["SeeInvis"].Text = ("SeeInvis: %s"):format(onOff(state.seeInvisOn))
	colorize(hudLines["SeeInvis"], state.seeInvisOn)

	hudLines["Tpose"].Text = ("Tpose: %s"):format(onOff(state.tposeOn))
	colorize(hudLines["Tpose"], state.tposeOn)


	hudLines["Coordinates"].Text = ("Coordinates: %s"):format(onOff(state.coordsOn))
	colorize(hudLines["Coordinates"], state.coordsOn)

	hudLines["Boost (Speed/Jump)"].Text =
		("Boost: %s | Speed=%d | Jump=%d"):format(onOff(state.boostOn), state.speedValue, state.jumpValue)
	colorize(hudLines["Boost (Speed/Jump)"], state.boostOn)

	hudLines["Invisible"].Text = ("Invisible: %s"):format(onOff(state.invisibleOn))
	colorize(hudLines["Invisible"], state.invisibleOn)

	hudLines["AutoAim"].Text = ("AutoAim: %s"):format(onOff(state.autoAimOn))
	colorize(hudLines["AutoAim"], state.autoAimOn)

	hudLines["AutoGG"].Text = ("AutoGG: %s"):format(onOff(state.autoGGOn))
	colorize(hudLines["AutoGG"], state.autoGGOn)

	hudLines["Fly"].Text = ("Fly: %s"):format(onOff(state.flyOn))
	colorize(hudLines["Fly"], state.flyOn)

	hudLines["NoClip"].Text = ("NoClip: %s"):format(onOff(state.noClipOn))
	colorize(hudLines["NoClip"], state.noClipOn)

	hudLines["TP"].Text = ("TP: %s | Mode=%s"):format(onOff(state.tpOn), state.tpMode)
	colorize(hudLines["TP"], state.tpOn)

	hudLines["Admin Tools"].Text = ("Admin Tools: %s"):format(onOff(state.adminToolsOn))
	colorize(hudLines["Admin Tools"], state.adminToolsOn)

	hudLines["Fling"].Text = ("Fling: %s | Mode=%s | Speed=%d"):format(onOff(state.flingOn), state.flingMode, state.flingSpeed)
	colorize(hudLines["Fling"], state.flingOn)

	local tgtName = "None"
	if state.orbitTarget then
		if state.orbitTarget:IsA("Player") then
			tgtName = state.orbitTarget.Name
		elseif state.orbitTarget:IsA("Model") then
			tgtName = state.orbitTarget.Name .. " [NPC]"
		end
	end
	hudLines["Orbit"].Text = ("Orbit: %s | Target=%s"):format(onOff(state.orbitOn), tgtName)


	colorize(hudLines["Orbit"], state.orbitOn)

	hudLines["AntiPush"].Text = ("AntiPush: %s"):format(onOff(state.antiPushOn))
	colorize(hudLines["AntiPush"], state.antiPushOn)

end

------------------------------------------------------------
-- COORD BAR (more visible like your screenshot)
------------------------------------------------------------
local coordBar = mk("Frame", {
	Name = "CoordBar",
	Visible = false,
	AnchorPoint = Vector2.new(1,0),
	Position = UDim2.new(1, -10, 0, 10),
	Size = UDim2.fromOffset(420, 56),
	BackgroundColor3 = Color3.fromRGB(15, 15, 18),
	BackgroundTransparency = 0.25,
}, gui)
mk("UICorner", {CornerRadius = UDim.new(0, 10)}, coordBar)
mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(70,70,85), Transparency = 0.4}, coordBar)

local coordLbl = mk("TextLabel", {
	Name = "AdminCoords",
	Visible = true,
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1,0),
	Position = UDim2.new(1, -10, 0, 8),
	Size = UDim2.new(1, -20, 0, 20),
	TextXAlignment = Enum.TextXAlignment.Right,
	Font = fontik,
	TextSize = 16,
	TextColor3 = Color3.fromRGB(255,255,255),
	TextStrokeTransparency = 0.15,
	Text = "XYZ:  N/A",
}, coordBar)

local objCoordLbl = mk("TextLabel", {
	Name = "ObjectCoords",
	Visible = true,
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1,0),
	Position = UDim2.new(1, -10, 0, 30),
	Size = UDim2.new(1, -20, 0, 20),
	TextXAlignment = Enum.TextXAlignment.Right,
	Font = fontik,
	TextSize = 14,
	TextColor3 = Color3.fromRGB(240,240,240),
	TextStrokeTransparency = 0.2,
	Text = "",
}, coordBar)

local coordsTarget: Instance = nil :: any

------------------------------------------------------------
-- VISUAL OVERRIDE SYSTEM (LOCALTransparencyModifier)
------------------------------------------------------------
local baselineLTM = {} :: {[BasePart]: number}
local xrayParts = {} :: {[BasePart]: boolean}
local hitboxParts = {} :: {[BasePart]: boolean}
local deletedParts = {} :: {[BasePart]: boolean}
local deletedCollideSaved = {} :: {[BasePart]: boolean}

function rememberBaseline(part: BasePart)
	if baselineLTM[part] == nil then
		baselineLTM[part] = part.LocalTransparencyModifier
	end
end

function applyVisual(part: BasePart)
	if not part or not part.Parent then return end

	local desired
	if deletedParts[part] then
		desired = 1
	else
		if state.xrayOn and xrayParts[part] then
			desired = 0.5
		elseif state.hitboxSeeOn and hitboxParts[part] then
			desired = 0.5
		end
	end

	if desired ~= nil then
		rememberBaseline(part)
		local lt = math.clamp(desired - part.Transparency, 0, 1)
		part.LocalTransparencyModifier = lt
	else
		if baselineLTM[part] ~= nil then
			part.LocalTransparencyModifier = baselineLTM[part]
			baselineLTM[part] = nil
		end
	end
end

function applyAllXray()
	for _, inst in ipairs(Workspace:GetDescendants()) do
		if inst:IsA("BasePart") and not isInPlayerCharacter(inst) then
			xrayParts[inst] = true
			applyVisual(inst)
		end
	end
end

function clearAllXray()
	for part, _ in pairs(xrayParts) do
		xrayParts[part] = nil
		if part and part.Parent then applyVisual(part) end
	end
end

function applyAllHitbox()
	for _, plr in ipairs(Players:GetPlayers()) do
		local ch = plr.Character
		if ch then
			for _, inst in ipairs(ch:GetDescendants()) do
				if inst:IsA("BasePart") and inst.Transparency >= 0.4 then
					hitboxParts[inst] = true
					applyVisual(inst)
				end
			end
		end
	end
end

function clearAllHitbox()
	for part, _ in pairs(hitboxParts) do
		hitboxParts[part] = nil
		if part and part.Parent then applyVisual(part) end
	end
end

------------------------------------------------------------
-- SECTIONS
------------------------------------------------------------
local settingsWrap = makeSection("Settings")
local visualWrap = makeSection("Visual")
local playerWrap = makeSection("Player")

local btnHideAdminStatic = makeButton(settingsWrap, "HideAdminStatic (hides status HUD) [DEFAULT ON]")
local btnOnlyButton = makeButton(settingsWrap, "OnlyButton (menu-only, hotkeys OFF)")
local btnSearchFunctions = makeButton(settingsWrap, "Function Search")

local btnDetector = makeButton(visualWrap, "Detector (F3 toggle)")
local btnXray = makeButton(visualWrap, "Xray (F4 toggle)")
local btnHitbox = makeButton(visualWrap, "HitBox See (toggle)")
local btnSeeInvis = makeButton(visualWrap, "SeeInvis (toggle)")

local btnNightVision = makeButton(visualWrap, "NightVision (F6 toggle)")
local nightSlider = makeSlider(visualWrap, "NightVision Brightness (1..100)", 1, 100, state.nightVisionValue, scroll)

local btnFreeCam = makeButton(visualWrap, "FreeCam (F5 exit)")



local btnCoords = makeButton(visualWrap, "Coordinates (toggle)")




local btnBoost = makeButton(playerWrap, "SpeedBoost + JumpBoost (RightShift toggle)")
local btnInvisible = makeButton(playerWrap, "Invisible (toggle)")

local speedSlider = makeSlider(playerWrap, "Speed (1..500)", 1, 500, state.speedValue, scroll)
local jumpSlider  = makeSlider(playerWrap, "Jump (1..500)", 1, 500, state.jumpValue, scroll)

local btnFling = makeButton(playerWrap, "Fling")
local btnFlingMode = makeButton(playerWrap, "Mode: "..state.flingMode)
local flingSlider = makeSlider(playerWrap, "Fling Speed (1..2000)", 1, 2000, state.flingSpeed, scroll)

local btnOrbit = makeButton(playerWrap, "Follow (click player)")
local btnOrbitMode = makeButton(playerWrap, "Follow Mode: "..state.orbitMode)

btnOrbitMode.MouseButton1Click:Connect(function()
	if state.orbitMode == "Orbit" then
		state.orbitMode = "CrazyOrbit"
	elseif state.orbitMode == "CrazyOrbit" then
		state.orbitMode = "BackFollow"
	elseif state.orbitMode == "BackFollow" then
		state.orbitMode = "UpFollow"
	else
		state.orbitMode = "Orbit"
	end
	btnOrbitMode.Text = "Follow Mode: "..state.orbitMode
	updateHUD()
end)


local orbitSpeedSlider = makeSlider(playerWrap, "Follow Speed (1..500)", 1, 500, state.orbitSpeed, scroll)
local orbitDistSlider  = makeSlider(playerWrap, "Follow Dist (1..500)", 1, 500, state.orbitDist, scroll)

local btnAutoAim = makeButton(playerWrap, "AutoAim (F2 toggle)")
local btnAutoGG = makeButton(playerWrap, "AutoGG")
local btnFly = makeButton(playerWrap, "Fly")
local btnFlyMode = makeButton(playerWrap, "Fly Mode: "..state.flyMode)



btnFlyMode.MouseButton1Click:Connect(function()
	state.flyMode = (state.flyMode == "Smooth") and "Combat" or "Smooth"
	btnFlyMode.Text = "Fly Mode: "..state.flyMode
end)

local btnNoClip = makeButton(playerWrap, "NoClip")
local btnTP = makeButton(playerWrap, "TP")
local btnAdminTools = makeButton(playerWrap, "Admin Tools")

-- TP sub
local tpSub = mk("Frame", {BackgroundTransparency = 1, Visible = false, Size = UDim2.new(1, 0, 0, 34)}, playerWrap)
local tpClickBtn = makeButton(tpSub, "Click TP")
tpClickBtn.Size = UDim2.new(0.5, -4, 0, 34)
tpClickBtn.Position = UDim2.new(0, 0, 0, 0)
local tpCordBtn = makeButton(tpSub, "Cord TP")
tpClickBtn.Size = UDim2.new(0.33, -4, 0, 34)
tpClickBtn.Position = UDim2.new(0, 0, 0, 0)

tpCordBtn.Size = UDim2.new(0.33, -4, 0, 34)
tpCordBtn.Position = UDim2.new(0.33, 4, 0, 0)
local tpPlayerModeBtn = makeButton(tpSub, "Player TP")
tpPlayerModeBtn.Size = UDim2.new(0.33, -4, 0, 34)
tpPlayerModeBtn.Position = UDim2.new(0.66, 8, 0, 0)

-- Cord TP panel
local cordPanel = mk("Frame", {
	Name = "CordTPPanel",
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -90),
	Size = UDim2.fromOffset(340, 70),
	BackgroundColor3 = Color3.fromRGB(16,16,18),
	BackgroundTransparency = 0.1,
}, gui)
mk("UICorner", {CornerRadius = UDim.new(0, 12)}, cordPanel)
mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(80, 80, 95), Transparency = 0.35}, cordPanel)

mk("TextLabel", {
	Text = "Cord TP (x y z)",
	Font = fontik,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(240,240,240),
	Size = UDim2.new(1, -16, 0, 18),
	Position = UDim2.fromOffset(8, 6),
}, cordPanel)

local cordBox = mk("TextBox", {
	ClearTextOnFocus = false,
	Text = "",
	PlaceholderText = "10  25  -40",
	Font = fontik,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundColor3 = Color3.fromRGB(30,30,36),
	TextColor3 = Color3.fromRGB(235,235,235),
	Size = UDim2.new(1, -110, 0, 32),
	Position = UDim2.fromOffset(8, 30),
}, cordPanel)
mk("UICorner", {CornerRadius = UDim.new(0, 10)}, cordBox)
mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75,75,90), Transparency = 0.45}, cordBox)

local cordEnter = mk("TextButton", {
	Text = "Enter",
	Font = fontik,
	TextSize = 14,
	BackgroundColor3 = Color3.fromRGB(40, 52, 90),
	TextColor3 = Color3.fromRGB(245,245,255),
	Size = UDim2.fromOffset(90, 32),
	Position = UDim2.new(1, -98, 0, 30),
}, cordPanel)
mk("UICorner", {CornerRadius = UDim.new(0, 10)}, cordEnter)

-- ✅ NEW: Player TP panel (does NOT mess with tpSub layout)
local playerTPPanel = mk("Frame", {
	Name = "PlayerTPPanel",
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -15),
	Size = UDim2.fromOffset(340, 70),
	BackgroundColor3 = Color3.fromRGB(16,16,18),
	BackgroundTransparency = 0.1,
}, gui)
mk("UICorner", {CornerRadius = UDim.new(0, 12)}, playerTPPanel)
mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(80, 80, 95), Transparency = 0.35}, playerTPPanel)

mk("TextLabel", {
	Text = "TP Behind Player (name)",
	Font = fontik,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(240,240,240),
	Size = UDim2.new(1, -16, 0, 18),
	Position = UDim2.fromOffset(8, 6),
}, playerTPPanel)

local tpPlayerBox = mk("TextBox", {
	ClearTextOnFocus = false,
	Text = "",
	PlaceholderText = "player name...",
	Font = fontik,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundColor3 = Color3.fromRGB(30,30,36),
	TextColor3 = Color3.fromRGB(235,235,235),
	Size = UDim2.new(1, -110, 0, 32),
	Position = UDim2.fromOffset(8, 30),
}, playerTPPanel)
mk("UICorner", {CornerRadius = UDim.new(0, 10)}, tpPlayerBox)
mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75,75,90), Transparency = 0.45}, tpPlayerBox)

local tpPlayerBtn = mk("TextButton", {
	Text = "TP",
	Font = fontik,
	TextSize = 14,
	BackgroundColor3 = Color3.fromRGB(40, 52, 90),
	TextColor3 = Color3.fromRGB(245,245,255),
	Size = UDim2.fromOffset(90, 32),
	Position = UDim2.new(1, -98, 0, 30),
}, playerTPPanel)
mk("UICorner", {CornerRadius = UDim.new(0, 10)}, tpPlayerBtn)

------------------------------------------------------------
-- MENU TOGGLE
------------------------------------------------------------
function setPanelOpen(open)
	state.panelOpen = open
	panel.Visible = open
end


------------------------------------------------------------
-- SETTINGS TOGGLES
------------------------------------------------------------
function toggleOnlyButton()
	state.onlyButton = not state.onlyButton
	setBtnOn(btnOnlyButton, state.onlyButton)
	hint.Text = state.onlyButton and "Hotkeys disabled (menu-only)." or "Hotkeys: F3=Detector | F4=Xray | RightShift=Boost | F2=AutoAim | F5=StopOrbit"
	updateHUD()
end

function toggleHideAdminStatic()
	state.hideAdminStatic = not state.hideAdminStatic
	hud.Visible = not state.hideAdminStatic
	setBtnOn(btnHideAdminStatic, state.hideAdminStatic) -- ON=hide
	updateHUD()
end

function toggleFunctionSearch()
	state.searchFunctionsOn = not state.searchFunctionsOn
	refreshSearchUI()
end

------------------------------------------------------------
-- VISUAL: Detector
------------------------------------------------------------
local detectorHighlights = {} :: {[Player]: Highlight}

function stopDetectorFor(plr)
	local h = detectorHighlights[plr]
	if h then h:Destroy(); detectorHighlights[plr] = nil end
end

function applyDetectorTo(plr)
	if not state.detectorOn then return end
	if plr == LP then return end
	local char = plr.Character
	if not char then return end

	stopDetectorFor(plr)

	local hl = Instance.new("Highlight")
	hl.Name = "AdminDetectorHL"
	hl.FillColor = Color3.new(1,1,1)
	hl.OutlineColor = Color3.new(1,1,1)
	hl.FillTransparency = 0.25
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = char

	detectorHighlights[plr] = hl

	task.spawn(function()
		local t = 0
		while state.detectorOn and detectorHighlights[plr] == hl and hl.Parent do
			t += RunService.Heartbeat:Wait()
			local a = (math.sin(t * 4) + 1) / 2
			hl.FillTransparency = 0.15 + 0.6 * a
		end
	end)
end

function detectorOn()
	state.detectorOn = true
	setBtnOn(btnDetector, true)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP then applyDetectorTo(plr) end
	end
	updateHUD()
end

function detectorOff()
	state.detectorOn = false
	setBtnOn(btnDetector, false)
	for plr, _ in pairs(detectorHighlights) do stopDetectorFor(plr) end
	updateHUD()
end

------------------------------------------------------------
-- VISUAL: Xray (LOCAL)
------------------------------------------------------------
local xrayConnAdded = nil

function xrayOn()
	state.xrayOn = true
	setBtnOn(btnXray, true)

	clearAllXray()
	applyAllXray()

	if xrayConnAdded then xrayConnAdded:Disconnect() end
	xrayConnAdded = Workspace.DescendantAdded:Connect(function(inst)
		task.defer(function()
			if not state.xrayOn then return end
			if inst:IsA("BasePart") and not isInPlayerCharacter(inst) then
				xrayParts[inst] = true
				applyVisual(inst)
			end
		end)
	end)

	updateHUD()
end

function xrayOff()
	state.xrayOn = false
	setBtnOn(btnXray, false)
	if xrayConnAdded then xrayConnAdded:Disconnect(); xrayConnAdded = nil end
	clearAllXray()
	updateHUD()
end

------------------------------------------------------------
-- VISUAL: HitBox See (LOCAL)
------------------------------------------------------------
function hitboxOn()
	state.hitboxSeeOn = true
	setBtnOn(btnHitbox, true)
	clearAllHitbox()
	applyAllHitbox()
	updateHUD()
end

function hitboxOff()
	state.hitboxSeeOn = false
	setBtnOn(btnHitbox, false)
	clearAllHitbox()
	updateHUD()
end

------------------------------------------------------------
-- VISUAL: Coordinates (menu only)
------------------------------------------------------------
function coordsOn()
	state.coordsOn = true
	setBtnOn(btnCoords, true)
	updateHUD()
end

function coordsOff()
	state.coordsOn = false
	setBtnOn(btnCoords, false)
	updateHUD()
end

function toggleCoords()
	if state.coordsOn then coordsOff() else coordsOn() end
end

------------------------------------------------------------
-- PLAYER: Boost (Speed+Jump physics)
------------------------------------------------------------
local boostSpeedConn= nil
local jumpConn= nil

function boostOn()
	state.boostOn = true
	setBtnOn(btnBoost, true)

	if boostSpeedConn then boostSpeedConn:Disconnect() end
	boostSpeedConn = RunService.RenderStepped:Connect(function()
		if not state.boostOn then return end
		if state.flyOn then return end

		local char = getChar()
		local hum = getHumanoid(char)
		local hrp = getHRP(char)
		if not (char and hum and hrp) then return end

		local dir = hum.MoveDirection
		if dir.Magnitude > 0.01 then
			local y = hrp.AssemblyLinearVelocity.Y
			local v = dir.Unit * state.speedValue
			hrp.AssemblyLinearVelocity = Vector3.new(v.X, y, v.Z)
		end
	end)

	if jumpConn then jumpConn:Disconnect() end
	jumpConn = UIS.JumpRequest:Connect(function()
		if not state.boostOn then return end
		local hrp = getHRP(getChar())
		if not hrp then return end
		local vel = hrp.AssemblyLinearVelocity
		hrp.AssemblyLinearVelocity = Vector3.new(vel.X, state.jumpValue, vel.Z)
	end)

	updateHUD()
end

function boostOff()
	state.boostOn = false
	setBtnOn(btnBoost, false)
	if boostSpeedConn then boostSpeedConn:Disconnect(); boostSpeedConn = nil end
	if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
	updateHUD()
end

------------------------------------------------------------
-- PLAYER: AutoAim
------------------------------------------------------------
local aimUpdateConn= nil
local targetModel= nil
local targetHL= nil
local targetBill= nil
local savedAutoRotate= nil

function clearTargetUI()
	if targetHL then targetHL:Destroy(); targetHL = nil end
	if targetBill then targetBill:Destroy(); targetBill = nil end
	targetModel = nil
end

function setTarget(model: Model)
	clearTargetUI()
	targetModel = model

	targetHL = Instance.new("Highlight")
	targetHL.Name = "AutoAimHL"
	targetHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	targetHL.FillTransparency = 0.2
	targetHL.OutlineTransparency = 0
	targetHL.FillColor = Color3.new(1,1,1)
	targetHL.OutlineColor = Color3.new(1,1,1)
	targetHL.Parent = model

	local adornee = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if adornee and adornee:IsA("BasePart") then
		targetBill = Instance.new("BillboardGui")
		targetBill.Name = "TargetedBillboard"
		targetBill.Adornee = adornee
		targetBill.Size = UDim2.fromOffset(140, 40)
		targetBill.StudsOffset = Vector3.new(0, 2.8, 0)
		targetBill.AlwaysOnTop = true
		targetBill.Parent = model

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1,0,1,0)
		lbl.BackgroundTransparency = 1
		lbl.Text = "Targeted"
		lbl.Font = fontik
		lbl.TextSize = 18
		lbl.TextColor3 = Color3.new(1,1,1)
		lbl.TextStrokeTransparency = 0.2
		lbl.Parent = targetBill
	end

	task.spawn(function()
		local toggle = false
		while state.autoAimOn and targetModel == model and targetHL and targetHL.Parent do
			toggle = not toggle
			if toggle then
				targetHL.FillColor = Color3.new(0,0,0)
				targetHL.OutlineColor = Color3.new(0,0,0)
			else
				targetHL.FillColor = Color3.new(1,1,1)
				targetHL.OutlineColor = Color3.new(1,1,1)
			end
			task.wait(0.1)
		end
	end)
end

function autoAimOn()
	state.autoAimOn = true
	setBtnOn(btnAutoAim, true)

	if aimUpdateConn then aimUpdateConn:Disconnect() end
	aimUpdateConn = RunService.RenderStepped:Connect(function()
		if not state.autoAimOn then return end
		if not targetModel then return end

		local char = getChar()
		local hum = getHumanoid(char)
		local hrp = getHRP(char)
		if not (char and hum and hrp) then return end

		local targetRoot = targetModel:FindFirstChild("HumanoidRootPart") or targetModel.PrimaryPart
		if not (targetRoot and targetRoot:IsA("BasePart")) then return end

		if savedAutoRotate == nil then savedAutoRotate = hum.AutoRotate end
		hum.AutoRotate = false

		local pos = hrp.Position
		local tpos = targetRoot.Position
		hrp.CFrame = CFrame.lookAt(pos, Vector3.new(tpos.X, pos.Y, tpos.Z))
	end)

	updateHUD()
end

function autoAimOff()
	state.autoAimOn = false
	setBtnOn(btnAutoAim, false)
	if aimUpdateConn then aimUpdateConn:Disconnect(); aimUpdateConn = nil end
	clearTargetUI()

	local hum = getHumanoid(getChar())
	if hum and savedAutoRotate ~= nil then hum.AutoRotate = savedAutoRotate end
	savedAutoRotate = nil

	updateHUD()
end

------------------------------------------------------------
-- PLAYER: AutoGG
------------------------------------------------------------
local ggLines = {"L","lol","EZ","ez"}
local ggSizeXZ = 29.859
local ggHalf = ggSizeXZ / 2
local ggPart= nil
local ggFollowConn= nil
local ggDeathConns = {} :: {[Player]: RBXScriptConnection}

function ggInZone(otherChar: Model)
	local myHrp = getHRP(getChar())
	local oh = getHRP(otherChar)
	if not (myHrp and oh) then return false end
	local d = (oh.Position - myHrp.Position)
	return math.abs(d.X) <= ggHalf and math.abs(d.Z) <= ggHalf
end

function hookDeath(plr: Player)
	if plr == LP then return end
	local function onChar(char: Model)
		local hum = getHumanoid(char)
		if not hum then return end
		if ggDeathConns[plr] then ggDeathConns[plr]:Disconnect() end
		ggDeathConns[plr] = hum.Died:Connect(function()
			if not state.autoGGOn then return end
			if ggInZone(char) then
				trySendChat(ggLines[math.random(1, #ggLines)])
			end
		end)
	end
	if plr.Character then onChar(plr.Character) end
	plr.CharacterAdded:Connect(function(c)
		task.wait(0.2)
		if state.autoGGOn then onChar(c) end
	end)
end

function autoGGOn()
	state.autoGGOn = true
	setBtnOn(btnAutoGG, true)

	if ggPart then ggPart:Destroy() end
	ggPart = Instance.new("Part")
	ggPart.Name = "AutoGGZone"
	ggPart.Anchored = true
	ggPart.CanCollide = false
	ggPart.Transparency = 1
	ggPart.Size = Vector3.new(ggSizeXZ, 10, ggSizeXZ)
	ggPart.Parent = Workspace

	if ggFollowConn then ggFollowConn:Disconnect() end
	ggFollowConn = RunService.Heartbeat:Connect(function()
		if not state.autoGGOn then return end
		local hrp = getHRP(getChar())
		if hrp and ggPart then ggPart.CFrame = CFrame.new(hrp.Position) end
	end)

	for _, plr in ipairs(Players:GetPlayers()) do hookDeath(plr) end
	updateHUD()
end

function autoGGOff()
	state.autoGGOn = false
	setBtnOn(btnAutoGG, false)
	if ggFollowConn then ggFollowConn:Disconnect(); ggFollowConn = nil end
	if ggPart then ggPart:Destroy(); ggPart = nil end
	for plr, c in pairs(ggDeathConns) do if c then c:Disconnect() end ggDeathConns[plr] = nil end
	updateHUD()
end

Players.PlayerAdded:Connect(function(plr)
	if state.autoGGOn then hookDeath(plr) end
end)

------------------------------------------------------------
-- PLAYER: Fly (DEV V3 PRINCIPLE) [REPLACE YOUR OLD FLY BLOCK]
-- BodyGyro + BodyVelocity + accel + lastctrl + camera cf
-- No collision hacks, no fancy stuff.
------------------------------------------------------------

local FLY_TOGGLE_KEY = Enum.KeyCode.H -- поменяй если хочешь

local flyV3 = {
	conn = nil,
	bg = nil,
	bv = nil,

	speed = 0,
	maxspeed = 50,

	lastctrl = {f=0,b=0,l=0,r=0,u=0,d=0},

	saved = nil,        -- animate + platformstand + autorotate + states
	stateSaved = nil,
	animate = nil,
	body = nil,
}

function fly_getBody(char: Model)
	return char:FindFirstChild("Torso")
		or char:FindFirstChild("UpperTorso")
		or char:FindFirstChild("HumanoidRootPart")
end

function fly_saveStates(hum: Humanoid)
	local list = {
		Enum.HumanoidStateType.Climbing,
		Enum.HumanoidStateType.FallingDown,
		Enum.HumanoidStateType.Flying,
		Enum.HumanoidStateType.Freefall,
		Enum.HumanoidStateType.GettingUp,
		Enum.HumanoidStateType.Jumping,
		Enum.HumanoidStateType.Landed,
		Enum.HumanoidStateType.Physics,
		Enum.HumanoidStateType.PlatformStanding,
		Enum.HumanoidStateType.Ragdoll,
		Enum.HumanoidStateType.Running,
		Enum.HumanoidStateType.RunningNoPhysics,
		Enum.HumanoidStateType.Seated,
		Enum.HumanoidStateType.StrafingNoPhysics,
		Enum.HumanoidStateType.Swimming,
	}
	flyV3.stateSaved = {}
	for _, st in ipairs(list) do
		local ok, old = pcall(function() return hum:GetStateEnabled(st) end)
		if ok then flyV3.stateSaved[st] = old end
	end
end

function fly_disableStates(hum: Humanoid)
	local list = {
		Enum.HumanoidStateType.Climbing,
		Enum.HumanoidStateType.FallingDown,
		Enum.HumanoidStateType.Flying,
		Enum.HumanoidStateType.Freefall,
		Enum.HumanoidStateType.GettingUp,
		Enum.HumanoidStateType.Jumping,
		Enum.HumanoidStateType.Landed,
		Enum.HumanoidStateType.Physics,
		Enum.HumanoidStateType.PlatformStanding,
		Enum.HumanoidStateType.Ragdoll,
		Enum.HumanoidStateType.Running,
		Enum.HumanoidStateType.RunningNoPhysics,
		Enum.HumanoidStateType.Seated,
		Enum.HumanoidStateType.StrafingNoPhysics,
		Enum.HumanoidStateType.Swimming,
	}
	for _, st in ipairs(list) do
		pcall(function() hum:SetStateEnabled(st, false) end)
	end
	pcall(function() hum:ChangeState(Enum.HumanoidStateType.Swimming) end)
end

function fly_restoreStates(hum: Humanoid)
	if not flyV3.stateSaved then return end
	for st, old in pairs(flyV3.stateSaved) do
		pcall(function() hum:SetStateEnabled(st, old) end)
	end
	flyV3.stateSaved = nil
	pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
end

function fly_ctrl()
	-- ctrl как в принципе из скрипта (только считываем клавиши напрямую)
	local f = (UIS:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
	local b = (UIS:IsKeyDown(Enum.KeyCode.S) and -1 or 0)
	local l = (UIS:IsKeyDown(Enum.KeyCode.A) and -1 or 0)
	local r = (UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0)
	local u = (UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or 0)
	local d = (UIS:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0)
	return {f=f, b=b, l=l, r=r, u=u, d=d}
end



local FLY_MODE_CFG = {
	Smooth = {
		accel = 38,
		decel = 26,
		max = 1.0,
	},
	Combat = {
		accel = 90,
		decel = 75,
		max = 1.35,
	},
}



function flyOn()
	if state.flyOn then return end
	state.flyOn = true
	setBtnOn(btnFly, true)

	-- чтобы не конфликтовало
	if state.boostOn then pcall(boostOff) end

	local char = getChar()
	local hum = getHumanoid(char)
	if not (char and hum) then return end

	local body = fly_getBody(char)
	if not (body and body:IsA("BasePart")) then return end
	flyV3.body = body

	-- save basics
	local animate = char:FindFirstChild("Animate")
	flyV3.animate = animate

	flyV3.saved = {
		autoRotate = hum.AutoRotate,
		platformStand = hum.PlatformStand,
		animateWasDisabled = animate and animate.Disabled or nil,
	}
	fly_saveStates(hum)

	-- like script
	if animate then animate.Disabled = true end
	for _, tr in ipairs(hum:GetPlayingAnimationTracks()) do
		pcall(function() tr:AdjustSpeed(0) end)
	end

	hum.AutoRotate = false
	hum.PlatformStand = true

	fly_disableStates(hum)

	-- maxspeed from your Speed slider (но принцип тот же)
	flyV3.maxspeed = math.clamp(tonumber(state.speedValue) or 50, 10, 350)
	flyV3.speed = 0
	flyV3.lastctrl = {f=0,b=0,l=0,r=0,u=0,d=0}

	-- movers (как в скрипте)
	flyV3.bg = Instance.new("BodyGyro")
	flyV3.bg.P = 9e4
	flyV3.bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	flyV3.bg.CFrame = body.CFrame
	flyV3.bg.Parent = body

	flyV3.bv = Instance.new("BodyVelocity")
	flyV3.bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	flyV3.bv.Velocity = Vector3.new(0, 0.1, 0)
	flyV3.bv.Parent = body

	if flyV3.conn then flyV3.conn:Disconnect() end
	flyV3.conn = RunService.RenderStepped:Connect(function(dt)
		if not state.flyOn then return end

		local c = getChar()
		local h = getHumanoid(c)
		local cam = Workspace.CurrentCamera
		if not (c and h and cam and flyV3.body and flyV3.body.Parent) then return end

		-- обновляем maxspeed (если ты двигаешь слайдер)
		flyV3.maxspeed = math.clamp(tonumber(state.speedValue) or flyV3.maxspeed, 10, 350)
		local maxspeed = flyV3.maxspeed

		local ctrl = fly_ctrl()
		local fb = (ctrl.f + ctrl.b)
		local lr = (ctrl.l + ctrl.r)

		local moving = (lr ~= 0) or (fb ~= 0) or (ctrl.u ~= 0) or (ctrl.d ~= 0)

		-- accel/decel как в скрипте (адаптировано под dt)
		local modeCfg = FLY_MODE_CFG[state.flyMode] or FLY_MODE_CFG.Smooth
		local realMax = maxspeed * (modeCfg.max or 1)

		if moving then
			flyV3.speed = flyV3.speed + (modeCfg.accel * dt)
			if flyV3.speed > realMax then
				flyV3.speed = realMax
			end
			flyV3.lastctrl = ctrl
		else
			flyV3.speed = flyV3.speed - (modeCfg.decel * dt)
			if flyV3.speed < 0 then
				flyV3.speed = 0
			end
		end

		local cf = cam.CFrame

		-- формула движения (почти 1-в-1)
		local vel =
			(cf.LookVector * fb) +
			((cf * CFrame.new(lr, fb * 0.2, 0)).Position - cf.Position)

		-- вертикаль Space/Ctrl
		if ctrl.u ~= 0 then vel += Vector3.new(0, 1, 0) end
		if ctrl.d ~= 0 then vel += Vector3.new(0, -1, 0) end

		if vel.Magnitude > 0.001 then
			vel = vel.Unit
			flyV3.bv.Velocity = vel * flyV3.speed
		else
			flyV3.bv.Velocity = Vector3.zero
		end

		-- ориентация как в скрипте (да, тут есть “кивок”)
		local look = cam.CFrame.LookVector

		if look.Magnitude < 0.001 then
			look = Vector3.new(0, 0, -1)
		else
			look = look.Unit
		end

		flyV3.bg.CFrame = CFrame.lookAt(flyV3.body.Position, flyV3.body.Position + look)
	end)

	updateHUD()
end

function flyOff()
	if not state.flyOn then return end
	state.flyOn = false
	setBtnOn(btnFly, false)

	if flyV3.conn then flyV3.conn:Disconnect(); flyV3.conn = nil end
	if flyV3.bg then flyV3.bg:Destroy(); flyV3.bg = nil end
	if flyV3.bv then flyV3.bv:Destroy(); flyV3.bv = nil end

	local char = getChar()
	local hum = getHumanoid(char)
	if hum and flyV3.saved then
		hum.AutoRotate = flyV3.saved.autoRotate
		hum.PlatformStand = flyV3.saved.platformStand

		fly_restoreStates(hum)

		if flyV3.animate then
			flyV3.animate.Disabled = (flyV3.saved.animateWasDisabled == true)
		end
	end

	flyV3.saved = nil
	flyV3.animate = nil
	flyV3.body = nil
	flyV3.speed = 0
	flyV3.lastctrl = {f=0,b=0,l=0,r=0,u=0,d=0}

	updateHUD()
end

-- keybind toggle (как ты просил)
if not state.__FlyV3Keybind then
	state.__FlyV3Keybind = true
	UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		if UIS:GetFocusedTextBox() then return end
		if state.onlyButton then return end
		if input.KeyCode == FLY_TOGGLE_KEY then
			if state.flyOn then flyOff() else flyOn() end
		end
	end)
end
------------------------------------------------------------
-- PLAYER: NoClip
------------------------------------------------------------
local noClipConn= nil
local noClipSaved = {} :: {[BasePart]: boolean}

function noClipOn()
	state.noClipOn = true
	setBtnOn(btnNoClip, true)

	if noClipConn then noClipConn:Disconnect() end
	noClipConn = RunService.RenderStepped:Connect(function()
		if not state.noClipOn then return end
		local char = getChar()
		if not char then return end
		for _, inst in ipairs(char:GetDescendants()) do
			if inst:IsA("BasePart") then
				if noClipSaved[inst] == nil then noClipSaved[inst] = inst.CanCollide end
				inst.CanCollide = false
			end
		end
	end)

	updateHUD()
end

function noClipOff()
	state.noClipOn = false
	setBtnOn(btnNoClip, false)
	if noClipConn then noClipConn:Disconnect(); noClipConn = nil end
	for part, old in pairs(noClipSaved) do
		if part and part.Parent then part.CanCollide = old end
		noClipSaved[part] = nil
	end
	updateHUD()
end

------------------------------------------------------------
-- PLAYER: TP
------------------------------------------------------------
function tpEffect()
	local char = getChar()
	if not char then return end
	local hl = Instance.new("Highlight")
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.FillColor = Color3.new(1,1,1)
	hl.OutlineColor = Color3.new(1,1,1)
	hl.FillTransparency = 0
	hl.OutlineTransparency = 0
	hl.Parent = char

	local tw = TweenService:Create(hl, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FillTransparency = 1, OutlineTransparency = 1,
	})
	tw:Play()
	Debris:AddItem(hl, 3.2)
end

function doTeleport(pos: Vector3)
	local hrp = getHRP(getChar())
	if not hrp then return end
	tpEffect()
	hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
end

function parseCoords(s: string)
	s = s:gsub(",", " ")
	local nums = {}
	for w in s:gmatch("%S+") do
		local n = tonumber(w)
		if n then table.insert(nums, n) end
	end
	if #nums >= 3 then return Vector3.new(nums[1], nums[2], nums[3]) end
	return nil
end

function findPlayerByText(txt)
	txt = (txt or ""):lower():gsub("%s+", "")
	if txt == "" then return nil end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower() == txt then return p end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1, #txt) == txt then return p end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():find(txt, 1, true) then return p end
	end
	return nil
end

function tpBehindPlayer(nameText)
	local targetPlr = findPlayerByText(nameText)
	if not targetPlr or targetPlr == LP then return end

	local myChar = getChar()
	local my = getHRP(myChar)
	local th = getHRPPlayer(targetPlr)
	if not my or not th then return end

	local backDist = 4
	local behindPos = th.Position - th.CFrame.LookVector * backDist + Vector3.new(0, 0.5, 0)
	tpEffect()
	my.CFrame = CFrame.new(behindPos, th.Position)
end

tpPlayerBtn.MouseButton1Click:Connect(function()
	if not state.tpOn then return end
	tpBehindPlayer(tpPlayerBox.Text)
end)
tpPlayerBox.FocusLost:Connect(function(enterPressed)
	if enterPressed and state.tpOn then
		tpBehindPlayer(tpPlayerBox.Text)
	end
end)


function refreshTPUI()
	tpSub.Visible = state.tpOn

	cordPanel.Visible = state.tpOn and state.tpMode == "Cord"
	playerTPPanel.Visible = state.tpOn and state.tpMode == "Player" -- ✅ ТОЛЬКО В ЭТОМ РЕЖИМЕ

	setBtnOn(btnTP, state.tpOn)
	setBtnOn(tpClickBtn, state.tpOn and state.tpMode == "Click")
	setBtnOn(tpCordBtn, state.tpOn and state.tpMode == "Cord")
	setBtnOn(tpPlayerModeBtn, state.tpOn and state.tpMode == "Player")

	updateHUD()
end

function tpOn()
	state.tpOn = true
	refreshTPUI()
end

function tpOff()
	state.tpOn = false
	refreshTPUI()
end

tpClickBtn.MouseButton1Click:Connect(function()
	state.tpMode = "Click"
	refreshTPUI()
end)
tpCordBtn.MouseButton1Click:Connect(function()
	state.tpMode = "Cord"
	refreshTPUI()
end)
cordEnter.MouseButton1Click:Connect(function()
	if not state.tpOn or state.tpMode ~= "Cord" then return end
	local v = parseCoords(cordBox.Text)
	if v then doTeleport(v) end
end)

tpPlayerModeBtn.MouseButton1Click:Connect(function()
	state.tpMode = "Player"
	refreshTPUI()
end)
------------------------------------------------------------
-- ADMIN TOOLS (LOCAL ONLY)
------------------------------------------------------------
local toolCord= nil
local toolDelete= nil
local toolCreate= nil

local cordHL= nil

-- Delete selection
local delSelected= nil
local delHL= nil

function clearDeleteSel()
	StopBlink("DELETE_SELECT")
	if delHL then delHL:Destroy(); delHL = nil end
	delSelected = nil
end

function clearCordHL()
	StopBlink("CORD_SELECT")
	if cordHL then cordHL:Destroy(); cordHL = nil end
end

function setCordHL(targetInst: Instance)
	clearCordHL()
	local parentForHL = targetInst
	local m = targetInst:FindFirstAncestorOfClass("Model")
	if m and m.Parent == Workspace then parentForHL = m end

	cordHL = Instance.new("Highlight")
	cordHL.Name = "CordHL"
	cordHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	cordHL.Parent = parentForHL

	StartBlinkHighlight("CORD_SELECT", cordHL, Color3.fromRGB(80, 200, 255), 0.15, 0.85, 3.5)
end

function localHideInstance(inst: Instance)
	if inst:IsA("BasePart") then
		local part = inst
		deletedParts[part] = true
		if deletedCollideSaved[part] == nil then deletedCollideSaved[part] = part.CanCollide end
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		applyVisual(part)
		return
	end

	local model = inst:IsA("Model") and inst or inst:FindFirstAncestorOfClass("Model")
	if model then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				deletedParts[d] = true
				if deletedCollideSaved[d] == nil then deletedCollideSaved[d] = d.CanCollide end
				d.CanCollide = false
				d.CanTouch = false
				d.CanQuery = false
				applyVisual(d)
			end
		end
	end
end

function makeTool(name: string)
	local t = Instance.new("Tool")
	t.Name = name
	t.RequiresHandle = false
	t.CanBeDropped = false
	t:SetAttribute("AP_AdminTool", true)
	return t
end

function destroyAdminTools()
	local backpack = LP:FindFirstChildOfClass("Backpack")
	local char = getChar()

	local function kill(container)
		if not container then return end
		for _, inst in ipairs(container:GetChildren()) do
			if inst:IsA("Tool") and inst:GetAttribute("AP_AdminTool") == true then
				inst:Destroy()
			end
		end
	end

	kill(backpack)
	kill(char)

	toolCord, toolDelete, toolCreate = nil, nil, nil
	coordsTarget = nil

	clearDeleteSel()
	clearCordHL()
end

----------------------------------------------------------------
-- 🔨CREATE (DIY sliders, NO Handles/ArcHandles)
----------------------------------------------------------------
function AttachCreateTool(backpack, makeTool, mk, setBtnOn, normalIdToVec, gui, mouse, UIS, Workspace)
	local oldPanel = gui:FindFirstChild("AP_CreatePanel")
	if oldPanel then oldPanel:Destroy() end

	local toolEquipped = false
	local mode = "Move" -- Move | Scale | Rotate
	local selected = nil
	local hl = nil

	local dragMoveConn = nil
	local dragEndConn = nil

	local function stopDrag()
		if dragMoveConn then dragMoveConn:Disconnect(); dragMoveConn = nil end
		if dragEndConn then dragEndConn:Disconnect(); dragEndConn = nil end
	end

	local function clearSelection()
		selected = nil
		StopBlink("CREATE_SELECT")
		if hl then hl:Destroy(); hl = nil end
	end

	local function selectPart(p)
		clearSelection()
		if not p then return end
		selected = p

		hl = Instance.new("Highlight")
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = p

		StartBlinkHighlight("CREATE_SELECT", hl, Color3.fromRGB(0, 255, 120), 0.15, 0.80, 3.5)
	end

	local function createBlock()
		local hit = mouse.Hit
		local p = Instance.new("Part")
		p.Name = "AdminCreatedBlock"
		p.Anchored = true
		p.CanCollide = true
		p.Material = Enum.Material.SmoothPlastic
		p.Color = Color3.new(1,1,1)
		p.Transparency = 0
		p.Size = Vector3.new(4,4,4)
		p.CFrame = CFrame.new(hit.Position + Vector3.new(0,2,0))
		p:SetAttribute("AP_LocalCreated", true)
		p.Parent = Workspace
		selectPart(p)
	end

	local panel = mk("Frame", {
		Name = "AP_CreatePanel",
		Visible = false,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -120),
		Size = UDim2.fromOffset(700, 160),
		BackgroundColor3 = Color3.fromRGB(16,16,18),
		BackgroundTransparency = 0.12,
		ZIndex = 100,
	}, gui)
	mk("UICorner", {CornerRadius = UDim.new(0, 12)}, panel)
	mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(80, 80, 95), Transparency = 0.35}, panel)

	local function uiBtn(text, x, y, w, h, specialColor)
		local b = mk("TextButton", {
			Text = text,
			Font = fontik,
			TextSize = 13,
			BackgroundColor3 = specialColor or Color3.fromRGB(30,30,36),
			TextColor3 = Color3.fromRGB(235,235,235),
			AutoButtonColor = true,
			Size = UDim2.fromOffset(w, h),
			Position = UDim2.fromOffset(x, y),
			ZIndex = 102,
		}, panel)
		mk("UICorner", {CornerRadius = UDim.new(0, 10)}, b)
		return b
	end

	local newBtn   = uiBtn("NEW",    10, 10, 110, 34, Color3.fromRGB(40,52,90))
	local moveBtn  = uiBtn("MOVE",  130, 10, 90,  34)
	local scaleBtn = uiBtn("SCALE", 226, 10, 90,  34)
	local rotBtn   = uiBtn("ROTATE",322, 10, 95,  34)

	mk("TextLabel", {
		Text = "Click created block to select. Drag X/Y/Z sliders to edit.",
		Font = fontik,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(190,190,190),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 0, 18),
		Position = UDim2.fromOffset(10, 50),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 102,
	}, panel)

	local sliderWrap = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 0, 60),
		Position = UDim2.fromOffset(10, 72),
		ZIndex = 102,
	}, panel)

	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, sliderWrap)

	local function makeAxisSlider(axisName, rangeValue, applyDelta)
		local row = mk("Frame", {
			BackgroundColor3 = Color3.fromRGB(30,30,36),
			Size = UDim2.new(1, 0, 0, 18),
			ZIndex = 102,
		}, sliderWrap)
		mk("UICorner", {CornerRadius = UDim.new(0, 8)}, row)

		mk("TextLabel", {
			Text = axisName,
			Font = fontik,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(235,235,235),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(18, 18),
			Position = UDim2.fromOffset(6, 0),
			ZIndex = 103,
		}, row)

		local track = mk("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(18,18,22),
			Size = UDim2.new(1, -88, 0, 10),
			Position = UDim2.fromOffset(28, 4),
			ZIndex = 103,
		}, row)
		mk("UICorner", {CornerRadius = UDim.new(0, 8)}, track)

		mk("Frame", {
			BackgroundColor3 = Color3.fromRGB(90,90,100),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.fromOffset(2, 10),
			ZIndex = 104,
		}, track)

		local knob = mk("Frame", {
			BackgroundColor3 = Color3.fromRGB(245,245,255),
			Size = UDim2.fromOffset(14, 14),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			ZIndex = 105,
		}, track)
		mk("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)

		local vLbl = mk("TextLabel", {
			Text = "0",
			Font = fontik,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(210,210,210),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(50, 18),
			Position = UDim2.new(1, -54, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 103,
		}, row)

		local dragging = false
		local lastV = 0

		local function setKnobAlpha(a)
			knob.Position = UDim2.new(a, 0, 0.5, 0)
		end

		local function endDrag()
			dragging = false
			lastV = 0
			vLbl.Text = "0"
			setKnobAlpha(0.5)
			stopDrag()
		end

		local function applyFromX(x, absX, absW)
			local a = math.clamp((x - absX) / math.max(absW, 1), 0, 1)
			setKnobAlpha(a)
			local t = (a - 0.5) * 2 -- -1..1
			local v = t * rangeValue
			v = math.floor(v * 10 + (v >= 0 and 0.5 or -0.5)) / 10
			vLbl.Text = tostring(v)

			local delta = v - lastV
			lastV = v
			if delta ~= 0 then applyDelta(delta) end
		end

		track.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
			if not toolEquipped or not selected then return end

			dragging = true
			stopDrag()

			local absX = track.AbsolutePosition.X
			local absW = track.AbsoluteSize.X

			applyFromX(input.Position.X, absX, absW)

			dragMoveConn = UIS.InputChanged:Connect(function(ch)
				if not dragging then return end
				if ch.UserInputType == Enum.UserInputType.MouseMovement or ch.UserInputType == Enum.UserInputType.Touch then
					applyFromX(ch.Position.X, absX, absW)
				end
			end)

			dragEndConn = UIS.InputEnded:Connect(function(ended)
				if ended.UserInputType == Enum.UserInputType.MouseButton1 or ended.UserInputType == Enum.UserInputType.Touch then
					endDrag()
				end
			end)
		end)
	end

	local function rebuildSliders()
		for _, ch in ipairs(sliderWrap:GetChildren()) do
			if ch:IsA("Frame") then ch:Destroy() end
		end

		if mode == "Move" then
			makeAxisSlider("X", 50, function(d) if selected then selected.CFrame = selected.CFrame + Vector3.new(d,0,0) end end)
			makeAxisSlider("Y", 50, function(d) if selected then selected.CFrame = selected.CFrame + Vector3.new(0,d,0) end end)
			makeAxisSlider("Z", 50, function(d) if selected then selected.CFrame = selected.CFrame + Vector3.new(0,0,d) end end)
		elseif mode == "Scale" then
			makeAxisSlider("X", 50, function(d) if selected then selected.Size = Vector3.new(math.max(0.5, selected.Size.X + d), selected.Size.Y, selected.Size.Z) end end)
			makeAxisSlider("Y", 50, function(d) if selected then selected.Size = Vector3.new(selected.Size.X, math.max(0.5, selected.Size.Y + d), selected.Size.Z) end end)
			makeAxisSlider("Z", 50, function(d) if selected then selected.Size = Vector3.new(selected.Size.X, selected.Size.Y, math.max(0.5, selected.Size.Z + d)) end end)
		else
			makeAxisSlider("X°", 90, function(d) if selected then selected.CFrame = selected.CFrame * CFrame.Angles(math.rad(d), 0, 0) end end)
			makeAxisSlider("Y°", 90, function(d) if selected then selected.CFrame = selected.CFrame * CFrame.Angles(0, math.rad(d), 0) end end)
			makeAxisSlider("Z°", 90, function(d) if selected then selected.CFrame = selected.CFrame * CFrame.Angles(0, 0, math.rad(d)) end end)
		end
	end

	local function setMode(m)
		mode = m
		setBtnOn(moveBtn, mode == "Move")
		setBtnOn(scaleBtn, mode == "Scale")
		setBtnOn(rotBtn, mode == "Rotate")
		rebuildSliders()
	end

	newBtn.MouseButton1Click:Connect(function()
		if toolEquipped then createBlock() end
	end)
	moveBtn.MouseButton1Click:Connect(function() setMode("Move") end)
	scaleBtn.MouseButton1Click:Connect(function() setMode("Scale") end)
	rotBtn.MouseButton1Click:Connect(function() setMode("Rotate") end)

	local toolCreate = makeTool("🔨CREATE")
	toolCreate.Parent = backpack

	toolCreate.Equipped:Connect(function()
		toolEquipped = true
		panel.Visible = true
		setMode(mode)
	end)

	toolCreate.Unequipped:Connect(function()
		toolEquipped = false
		panel.Visible = false
		stopDrag()
		clearSelection()
	end)

	toolCreate.Activated:Connect(function()
		if UIS:GetFocusedTextBox() then return end
		local t = mouse.Target
		if t and t:IsA("BasePart") and t:GetAttribute("AP_LocalCreated") == true then
			selectPart(t)
		else
			clearSelection()
		end
	end)

	return toolCreate
end

function addAdminTools()
	local backpack = LP:WaitForChild("Backpack")

	toolCord = makeTool("🗺️C0RD")
	toolDelete = makeTool("❌DEL3TE")
	toolCreate = AttachCreateTool(backpack, makeTool, mk, setBtnOn, normalIdToVec, gui, mouse, UIS, Workspace)

	toolCord.Parent = backpack
	toolDelete.Parent = backpack

	toolCord.Activated:Connect(function()
		local target = mouse.Target
		if not target then return end
		coordsTarget = target
		setCordHL(target)
	end)

	toolCord.Unequipped:Connect(function()
		coordsTarget = nil
		clearCordHL()
	end)

	toolDelete.Activated:Connect(function()
		local target = mouse.Target
		if not target then return end
		if isInPlayerCharacter(target) then return end

		if delSelected and (target == delSelected or target:IsDescendantOf(delSelected)) then
			localHideInstance(delSelected)
			clearDeleteSel()
			return
		end

		clearDeleteSel()
		local m = target:FindFirstAncestorOfClass("Model")
		if m and m.Parent == Workspace then delSelected = m else delSelected = target end

		delHL = Instance.new("Highlight")
		delHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		delHL.Parent = delSelected

		StartBlinkHighlight("DELETE_SELECT", delHL, Color3.fromRGB(255, 60, 60), 0.15, 0.80, 3.5)
	end)

	toolDelete.Unequipped:Connect(function()
		clearDeleteSel()
	end)
end

function adminToolsOn()
	state.adminToolsOn = true
	setBtnOn(btnAdminTools, true)
	destroyAdminTools()
	addAdminTools()
	updateHUD()
end

function adminToolsOff()
	state.adminToolsOn = false
	setBtnOn(btnAdminTools, false)
	destroyAdminTools()
	updateHUD()
end

------------------------------------------------------------
-- COORDS LOOP (bar visible when coordsOn OR coordsTarget)
------------------------------------------------------------
local lastCoordsUpdate = 0
RunService.RenderStepped:Connect(function()
	local t = time()
	if t - lastCoordsUpdate < 0.1 then return end
	lastCoordsUpdate = t

	local showBar = state.coordsOn or (coordsTarget ~= nil)
	coordBar.Visible = showBar

	if state.coordsOn then
		local hrp = getHRP(getChar())
		if hrp then
			local p = v3round(hrp.Position, 1)
			coordLbl.Text = ("XYZ:  %.1f, %.1f, %.1f"):format(p.X, p.Y, p.Z)
		else
			coordLbl.Text = "XYZ:  N/A"
		end
	else
		coordLbl.Text = "XYZ:  (OFF)"
	end

	if coordsTarget and coordsTarget.Parent then
		local pos= nil
		if coordsTarget:IsA("BasePart") then
			pos = coordsTarget.Position
		else
			local m = coordsTarget:FindFirstAncestorOfClass("Model")
			local pp = m and (m.PrimaryPart or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart"))
			if pp and pp:IsA("BasePart") then pos = pp.Position end
		end

		if pos then
			local p = v3round(pos, 1)
			objCoordLbl.Text = ("Target:  %.1f, %.1f, %.1f"):format(p.X, p.Y, p.Z)
		else
			objCoordLbl.Text = ""
		end
	else
		objCoordLbl.Text = ""
		coordsTarget = nil
	end
end)

------------------------------------------------------------
-- ORBIT v0.03 (4 MODES)
------------------------------------------------------------

-- state additions
state.orbitMode = state.orbitMode or "Orbit"
-- Orbit | CrazyOrbit | BackOrbit | DownOrbit

local orbitConn = nil
local orbitAngle = 0
local orbitNoiseT = 0
local orbitHL = nil
local orbitDiedConn = nil

function stopOrbitHighlight()
	StopBlink("ORBIT_TARGET")
	if orbitHL then orbitHL:Destroy(); orbitHL = nil end
end

function setOrbitHighlight(target)
	stopOrbitHighlight()

	local m = getTargetModel(target)
	if not m then return end

	orbitHL = Instance.new("Highlight")
	orbitHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	orbitHL.Parent = m
	StartBlinkHighlight("ORBIT_TARGET", orbitHL, Color3.fromRGB(175, 70, 255), 0.15, 0.85, 3.5)
end

function Orbit_Set(on)
	state.orbitOn = on
	setBtnOn(btnOrbit, on)
	updateHUD()

	if orbitConn then orbitConn:Disconnect(); orbitConn = nil end
	if orbitDiedConn then orbitDiedConn:Disconnect(); orbitDiedConn = nil end
	stopOrbitHighlight()
	state.orbitTarget = nil

	if not on then return end

	orbitAngle = 0
	orbitNoiseT = math.random() * 10

	orbitConn = RunService.RenderStepped:Connect(function(dt)
		if not state.orbitOn then return end

		local myChar = getChar()
		local me = getHRP(myChar)
		local target = state.orbitTarget
		local th = getTargetRoot(target)
		if not me or not th then return end


		local dist = math.clamp(state.orbitDist, 1, 500)
		local speed = math.clamp(state.orbitSpeed, 1, 500)

		local targetCF
		local center = th.Position

		-- === MODE LOGIC ===

		if state.orbitMode == "Orbit" then
			orbitAngle += speed * dt * 0.2
			local offset = Vector3.new(
				math.cos(orbitAngle) * dist,
				2,
				math.sin(orbitAngle) * dist
			)
			targetCF = CFrame.new(center + offset, center)

		elseif state.orbitMode == "CrazyOrbit" then
			orbitNoiseT += dt * (speed * 0.15)

			local nx = math.noise(orbitNoiseT, 0, 0)
			local ny = math.noise(0, orbitNoiseT, 0)
			local nz = math.noise(0, 0, orbitNoiseT)

			local dir = Vector3.new(nx, ny, nz)
			if dir.Magnitude < 0.01 then return end
			dir = dir.Unit

			local pos = center + dir * dist
			targetCF = CFrame.new(pos, center)

		elseif state.orbitMode == "BackFollow" then
			-- строго за спиной, скорость игнорируем
			local backCF = th.CFrame * CFrame.new(0, 0, dist)
			targetCF = CFrame.new(backCF.Position, center)

		elseif state.orbitMode == "UpFollow" then
			-- под ногами, лицом ВВЕРХ
			local pos = center + Vector3.new(0, dist, 0)
			targetCF = CFrame.lookAt(pos, center, Vector3.new(0, 0, -1))
		end

		if not targetCF then return end

		-- === SMOOTH FOLLOW ===
		local smooth = 18
		local alpha = 1 - math.exp(-smooth * dt)
		me.CFrame = me.CFrame:Lerp(targetCF, alpha)
	end)
end

function resolveTargetFromPart(hitPart: Instance?)
	if not hitPart then return nil, nil, nil end

	local inst: Instance? = hitPart
	while inst and inst ~= Workspace do
		if inst:IsA("Model") then
			local hum = inst:FindFirstChildOfClass("Humanoid")
			if hum then
				-- не даём выбрать самого себя
				if getChar() and inst == getChar() then return nil, nil, nil end

				local plr = Players:GetPlayerFromCharacter(inst)
				if plr and plr ~= LP then
					return plr, inst, hum -- цель = Player
				else
					return inst, inst, hum -- цель = NPC Model
				end
			end
		end
		inst = inst.Parent
	end

	return nil, nil, nil
end


------------------------------------------------------------
-- CLICK ROUTING (TP Click vs Orbit Target vs AutoAim)
------------------------------------------------------------
mouse.Button1Down:Connect(function()
	if UIS:GetFocusedTextBox() then return end
	if hasEquippedTool() then return end

	if state.tpOn and state.tpMode == "Click" then
		local hit = mouse.Hit
		if hit then doTeleport(hit.Position) end
		return
	end

	-- ✅ Orbit target select (FIXED)
	if state.orbitOn then
		local target, model, hum = resolveTargetFromPart(mouse.Target)
		if target then
			state.orbitTarget = target
			setOrbitHighlight(target)

			if orbitDiedConn then orbitDiedConn:Disconnect(); orbitDiedConn = nil end
			orbitDiedConn = hum.HealthChanged:Connect(function(hp)
				if hp <= 0 and state.orbitTarget == target then
					state.orbitTarget = nil
					stopOrbitHighlight()
					updateHUD()
				end
			end)

			updateHUD()
			return
		end
	end



	if state.autoAimOn then
		local hitPart = mouse.Target
		if not hitPart then return end
		local m = hitPart:FindFirstAncestorOfClass("Model")
		if not m then return end
		local hum = m:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		setTarget(m)
	end
end)

------------------------------------------------------------
-- VISUAL: Coordinates toggle
------------------------------------------------------------
function toggleCoords2()
	if state.coordsOn then coordsOff() else coordsOn() end
end

------------------------------------------------------------
-- SeeInvis (local) + Invisible (local)
------------------------------------------------------------
local seeInvisConn= nil
local seeInvisSavedParts = {} :: {[BasePart]: {t:number, ltm:number}}
local seeInvisSavedDecals = {} :: {[Decal]: number}

local invisConn= nil
local invisSavedParts = {} :: {[BasePart]: number}
local invisSavedDecals = {} :: {[Decal]: number}

function isMyCharPart(inst: Instance)
	local ch = getChar()
	return ch and inst:IsDescendantOf(ch)
end

-- SEE INVIS: делаем невидимых игроков видимыми (только у нас)
function seeInvisApplyOnce()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP then
			local ch = plr.Character
			if ch then
				for _, d in ipairs(ch:GetDescendants()) do
					if d:IsA("BasePart") then
						-- считаем "невидимым" если почти прозрачный или LTM почти 1
						if d.Transparency >= 0.95 or d.LocalTransparencyModifier >= 0.95 then
							if not seeInvisSavedParts[d] then
								seeInvisSavedParts[d] = {t = d.Transparency, ltm = d.LocalTransparencyModifier}
							end
							-- делаем видимым
							d.LocalTransparencyModifier = 0
							if d.Transparency > 0.2 then
								d.Transparency = 0.5
							end
						end

					elseif d:IsA("Decal") then
						if d.Transparency >= 0.95 then
							if seeInvisSavedDecals[d] == nil then
								seeInvisSavedDecals[d] = d.Transparency
							end
							d.Transparency = 0
						end
					end
				end
			end
		end
	end
end

function seeInvisRestoreAll()
	if seeInvisConn then seeInvisConn:Disconnect(); seeInvisConn = nil end

	for part, saved in pairs(seeInvisSavedParts) do
		if part and part.Parent then
			part.Transparency = saved.t
			part.LocalTransparencyModifier = saved.ltm
		end
		seeInvisSavedParts[part] = nil
	end

	for decal, t in pairs(seeInvisSavedDecals) do
		if decal and decal.Parent then
			decal.Transparency = t
		end
		seeInvisSavedDecals[decal] = nil
	end
end

function seeInvisOn()
	state.seeInvisOn = true
	setBtnOn(btnSeeInvis, true)
	updateHUD()

	if seeInvisConn then seeInvisConn:Disconnect() end
	local acc = 0
	seeInvisConn = RunService.Heartbeat:Connect(function(dt)
		if not state.seeInvisOn then return end
		acc += dt
		if acc < 0.25 then return end -- 4 раза в сек, норм
		acc = 0
		seeInvisApplyOnce()
	end)

	seeInvisApplyOnce()
end

function seeInvisOff()
	state.seeInvisOn = false
	setBtnOn(btnSeeInvis, false)
	seeInvisRestoreAll()
	updateHUD()
end


-- INVISIBLE: делаем себя невидимым (только у нас)
function invisibleApplyOnce()
	local ch = getChar()
	if not ch then return end

	for _, d in ipairs(ch:GetDescendants()) do
		if d:IsA("BasePart") then
			if invisSavedParts[d] == nil then
				invisSavedParts[d] = d.LocalTransparencyModifier
			end
			d.LocalTransparencyModifier = 1

		elseif d:IsA("Decal") then
			if invisSavedDecals[d] == nil then
				invisSavedDecals[d] = d.Transparency
			end
			d.Transparency = 1
		end
	end
end

function invisibleRestoreAll()
	if invisConn then invisConn:Disconnect(); invisConn = nil end

	for part, oldLTM in pairs(invisSavedParts) do
		if part and part.Parent then
			part.LocalTransparencyModifier = oldLTM
		end
		invisSavedParts[part] = nil
	end

	for decal, oldT in pairs(invisSavedDecals) do
		if decal and decal.Parent then
			decal.Transparency = oldT
		end
		invisSavedDecals[decal] = nil
	end
end

function invisibleOn()
	state.invisibleOn = true
	setBtnOn(btnInvisible, true)
	updateHUD()

	if invisConn then invisConn:Disconnect() end
	local acc = 0
	invisConn = RunService.Heartbeat:Connect(function(dt)
		if not state.invisibleOn then return end
		acc += dt
		if acc < 0.25 then return end
		acc = 0
		invisibleApplyOnce() -- чтобы новые аксессуары/parts тоже прятались
	end)

	invisibleApplyOnce()
end

function invisibleOff()
	state.invisibleOn = false
	setBtnOn(btnInvisible, false)
	invisibleRestoreAll()
	updateHUD()
end

------------------------------------------------------------
-- Visual: NightVision (local Lighting) + ANTI-FOG
------------------------------------------------------------
local nvCC: ColorCorrectionEffect? = nil
local nvSaved = nil
local nvUpdateConn: RBXScriptConnection? = nil

function NightVision_Apply(v)
	v = math.clamp(tonumber(v) or 1, 1, 100)
	state.nightVisionValue = v
	local k = v / 100 -- 0..1

	-- ✅ делаем реально светлее (чтобы НЕ было темно)
	Lighting.Brightness = (nvSaved and nvSaved.brightness or Lighting.Brightness) + (k * 10)           -- было слабее
	Lighting.ExposureCompensation = (nvSaved and nvSaved.exposure or Lighting.ExposureCompensation) + (k * 3.4)

	-- ✅ подсветка теней
	if nvSaved and nvSaved.ambient then
		Lighting.Ambient = nvSaved.ambient:Lerp(Color3.fromRGB(170,170,170), k)
	end
	if nvSaved and nvSaved.oambient then
		Lighting.OutdoorAmbient = nvSaved.oambient:Lerp(Color3.fromRGB(200,200,200), k)
	end

	-- ✅ ColorCorrection (мягко, без “черноты”)
	if nvCC then
		nvCC.Brightness = 0.10 + k * 0.30
		nvCC.Contrast   = 0.02 + k * 0.18
		nvCC.Saturation = -0.05
		nvCC.TintColor  = Color3.fromRGB(235, 255, 235)
	end

	-- ✅ УБРАТЬ ТУМАН Lighting Fog
	Lighting.FogStart = 0
	Lighting.FogEnd = 1e6
	Lighting.FogColor = Color3.fromRGB(255,255,255)

	-- ✅ УБРАТЬ ТУМАН Atmosphere (и запомнить, чтобы вернуть)
	if nvSaved and nvSaved.atm then
		for _, a in ipairs(Lighting:GetChildren()) do
			if a:IsA("Atmosphere") then
				if nvSaved.atm[a] == nil then
					nvSaved.atm[a] = {
						Density = a.Density,
						Haze = a.Haze,
						Glare = a.Glare,
						Color = a.Color,
						Decay = a.Decay,
						Offset = a.Offset,
					}
				end
				a.Density = 0
				a.Haze = 0
				a.Glare = 0
			end
		end
	end

	updateHUD()
end

function nightVisionOn()
	if state.nightVisionOn then return end
	state.nightVisionOn = true
	setBtnOn(btnNightVision, true)

	-- ✅ save baseline (и fog тоже)
	nvSaved = {
		brightness = Lighting.Brightness,
		exposure = Lighting.ExposureCompensation,
		ambient = Lighting.Ambient,
		oambient = Lighting.OutdoorAmbient,

		fogStart = Lighting.FogStart,
		fogEnd = Lighting.FogEnd,
		fogColor = Lighting.FogColor,

		atm = {}, -- сюда запомним все Atmosphere
	}

	-- effect
	nvCC = Lighting:FindFirstChild("AP_NightVisionCC") or Instance.new("ColorCorrectionEffect")
	nvCC.Name = "AP_NightVisionCC"
	nvCC.Parent = Lighting

	NightVision_Apply(state.nightVisionValue)

	-- ✅ пока включено: следим за слайдером + постоянно давим туман (если игра его возвращает)
	if nvUpdateConn then nvUpdateConn:Disconnect() end
	local last = -1
	nvUpdateConn = RunService.Heartbeat:Connect(function()
		if not state.nightVisionOn then return end

		local v = nightSlider.Get()
		if v ~= last then
			last = v
			NightVision_Apply(v)
		else
			-- даже если слайдер не двигаешь — туман может возвращаться, поэтому фиксируем
			Lighting.FogStart = 0
			Lighting.FogEnd = 1e6
			Lighting.FogColor = Color3.fromRGB(255,255,255)

			if nvSaved and nvSaved.atm then
				for _, a in ipairs(Lighting:GetChildren()) do
					if a:IsA("Atmosphere") then
						if nvSaved.atm[a] == nil then
							nvSaved.atm[a] = {
								Density = a.Density,
								Haze = a.Haze,
								Glare = a.Glare,
								Color = a.Color,
								Decay = a.Decay,
								Offset = a.Offset,
							}
						end
						a.Density = 0
						a.Haze = 0
						a.Glare = 0
					end
				end
			end
		end
	end)

	updateHUD()
end

function nightVisionOff()
	if not state.nightVisionOn then return end
	state.nightVisionOn = false
	setBtnOn(btnNightVision, false)

	if nvUpdateConn then nvUpdateConn:Disconnect(); nvUpdateConn = nil end

	-- ✅ restore Lighting + fog
	if nvSaved then
		Lighting.Brightness = nvSaved.brightness
		Lighting.ExposureCompensation = nvSaved.exposure
		Lighting.Ambient = nvSaved.ambient
		Lighting.OutdoorAmbient = nvSaved.oambient

		Lighting.FogStart = nvSaved.fogStart
		Lighting.FogEnd = nvSaved.fogEnd
		Lighting.FogColor = nvSaved.fogColor

		-- ✅ restore Atmosphere
		if nvSaved.atm then
			for a, s in pairs(nvSaved.atm) do
				if a and a.Parent then
					a.Density = s.Density
					a.Haze = s.Haze
					a.Glare = s.Glare
					a.Color = s.Color
					a.Decay = s.Decay
					a.Offset = s.Offset
				end
			end
		end
	end

	if nvCC then nvCC:Destroy(); nvCC = nil end
	nvSaved = nil

	updateHUD()
end



------------------------------------------------------------
-- Visual: FreeCam (local)
------------------------------------------------------------
local freeCamConn= nil
local freeCamMoveConn= nil
local freeCamKeys = {W=false,A=false,S=false,D=false,Q=false,E=false,Shift=false,Ctrl=false}
local freeCamSaved = nil
local freeCamPitch = 0
local freeCamLooking = false
local freeCamYaw = 0


function freeCamOff()
	if not state.freeCamOn then return end
	state.freeCamOn = false
	setBtnOn(btnFreeCam, false)


	-- Force restore movement after FreeCam OFF
	do
		local char = getChar()
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		if hrp then
			hrp.Anchored = false -- <-- главное
			-- на всякий случай убираем "залипшее" вращение/скорость
			hrp.AssemblyAngularVelocity = Vector3.zero
		end

		if hum then
			hum.PlatformStand = false
			hum.AutoRotate = true
			-- иногда помогает "вытолкнуть" из Physics/залипа
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end


	local cam = Workspace.CurrentCamera
	if freeCamConn then freeCamConn:Disconnect(); freeCamConn = nil end
	if freeCamMoveConn then freeCamMoveConn:Disconnect(); freeCamMoveConn = nil end

	UIS.MouseBehavior = Enum.MouseBehavior.Default
	UIS.MouseIconEnabled = true

	if cam and freeCamSaved then
		cam.CameraType = freeCamSaved.camType
		cam.CameraSubject = freeCamSaved.subject
		cam.CFrame = freeCamSaved.cframe
	end

	freeCamLooking = false
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	UIS.MouseIconEnabled = true

	freeCamSaved = nil
	updateHUD()
end

function freeCamOn()
	if state.freeCamOn then return end
	state.freeCamOn = true

	-- Freeze player (HRP)
	do
		local hrp = getHRP(getChar())
		if hrp then
			freeCamFreezeSaved = {
				anchored = hrp.Anchored,
				vel = hrp.AssemblyLinearVelocity,
				ang = hrp.AssemblyAngularVelocity,
			}
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			hrp.Anchored = true
		end
	end

	setBtnOn(btnFreeCam, true)

	local cam = Workspace.CurrentCamera
	if not cam then return end

	freeCamSaved = {
		camType = cam.CameraType,
		subject = cam.CameraSubject,
		cframe = cam.CFrame,
	}

	-- Freeze player (HRP) using freeCamSaved.freeze (no new locals!)
	do
		local hrp = getHRP(getChar())
		if hrp then
			freeCamSaved.freeze = {
				anchored = hrp.Anchored,
				vel = hrp.AssemblyLinearVelocity,
				ang = hrp.AssemblyAngularVelocity,
			}
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			hrp.Anchored = true
		end
	end

	cam.CameraType = Enum.CameraType.Scriptable

	-- стартовые углы из текущей камеры
	local look = cam.CFrame.LookVector
	freeCamYaw = math.atan2(-look.X, -look.Z)
	freeCamPitch = math.asin(math.clamp(look.Y, -0.98, 0.98))

	freeCamLooking = false
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	UIS.MouseIconEnabled = true



	-- мышь: поворот
	freeCamConn = UIS.InputChanged:Connect(function(input, gp)
		if gp then return end
		if not state.freeCamOn then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement and freeCamLooking then
			local dx = input.Delta.X
			local dy = input.Delta.Y
			freeCamYaw -= dx * 0.0022
			freeCamPitch = math.clamp(freeCamPitch - dy * 0.0022, math.rad(-80), math.rad(80))
		end
	end)

	-- движение
	freeCamMoveConn = RunService.RenderStepped:Connect(function(dt)
		if not state.freeCamOn then return end
		if not cam then return end

		local baseSpeed = 60
		if freeCamKeys.Shift then baseSpeed *= 3 end
		if freeCamKeys.Ctrl then baseSpeed *= 0.35 end

		local rot = CFrame.Angles(0, freeCamYaw, 0) * CFrame.Angles(freeCamPitch, 0, 0)
		local cf = CFrame.new(cam.CFrame.Position) * rot

		local move = Vector3.zero
		if freeCamKeys.W then move += cf.LookVector end
		if freeCamKeys.S then move -= cf.LookVector end
		if freeCamKeys.D then move += cf.RightVector end
		if freeCamKeys.A then move -= cf.RightVector end
		if freeCamKeys.E then move += Vector3.new(0,1,0) end
		if freeCamKeys.Q then move -= Vector3.new(0,1,0) end

		local pos = cam.CFrame.Position
		if move.Magnitude > 0 then
			pos += move.Unit * baseSpeed * dt
		end

		cam.CFrame = CFrame.new(pos) * rot
	end)

	updateHUD()
end

------------------------------------------------------------
-- BUTTON WIRING
------------------------------------------------------------
btnHideAdminStatic.MouseButton1Click:Connect(toggleHideAdminStatic)
btnOnlyButton.MouseButton1Click:Connect(toggleOnlyButton)

btnDetector.MouseButton1Click:Connect(function() if state.detectorOn then detectorOff() else detectorOn() end end)
btnXray.MouseButton1Click:Connect(function() if state.xrayOn then xrayOff() else xrayOn() end end)
btnHitbox.MouseButton1Click:Connect(function() if state.hitboxSeeOn then hitboxOff() else hitboxOn() end end)
btnCoords.MouseButton1Click:Connect(toggleCoords)

btnSeeInvis.MouseButton1Click:Connect(function()
	if state.seeInvisOn then seeInvisOff() else seeInvisOn() end
end)

--btnInvisible.MouseButton1Click:Connect(function()
--	if state.invisibleOn then invisibleOff() else invisibleOn() end
--end)

btnSearchFunctions.MouseButton1Click:Connect(toggleFunctionSearch)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	applyFunctionSearch(searchBox.Text)
end)

btnNightVision.MouseButton1Click:Connect(function()
	if state.nightVisionOn then nightVisionOff() else nightVisionOn() end
end)

btnFreeCam.MouseButton1Click:Connect(function()
	if state.freeCamOn then freeCamOff() else freeCamOn() end
end)



btnBoost.MouseButton1Click:Connect(function() if state.boostOn then boostOff() else boostOn() end end)
btnAutoAim.MouseButton1Click:Connect(function() if state.autoAimOn then autoAimOff() else autoAimOn() end end)
btnAutoGG.MouseButton1Click:Connect(function() if state.autoGGOn then autoGGOff() else autoGGOn() end end)
btnFly.MouseButton1Click:Connect(function() if state.flyOn then flyOff() else flyOn() end end)
btnNoClip.MouseButton1Click:Connect(function() if state.noClipOn then noClipOff() else noClipOn() end end)

btnTP.MouseButton1Click:Connect(function()
	if state.tpOn then tpOff() else tpOn() end
end)

btnAdminTools.MouseButton1Click:Connect(function()
	if state.adminToolsOn then adminToolsOff() else adminToolsOn() end
end)

btnFling.MouseButton1Click:Connect(function()
	Fling_Set(not state.flingOn)
end)

btnFlingMode.MouseButton1Click:Connect(function()
	state.flingMode = (state.flingMode == "Spin") and "Fling" or "Spin"
	btnFlingMode.Text = "Mode: "..state.flingMode
	updateHUD()
end)

btnOrbit.MouseButton1Click:Connect(function()
	Orbit_Set(not state.orbitOn)
end)




------------------------------------------------------------
-- HOTKEYS (toggle, blocked by OnlyButton)
------------------------------------------------------------
local okak = 
	{
		NightVisionRegulator = true,
		PanelRegulator = true,
		locked = false,

	}

UIS.InputBegan:Connect(function(input, gp)

	if input.KeyCode == Enum.KeyCode.F7 then
		if okak.PanelRegulator then
			setPanelOpen(true)
		else
			setPanelOpen(false)
		end
		okak.PanelRegulator = not okak.PanelRegulator
	end
	if input.KeyCode == Enum.KeyCode.F8 then
		--if locked then
		--	UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
		--	UIS.MouseIconEnabled = false
		--else
		--	UIS.MouseBehavior = Enum.MouseBehavior.Default
		--	UIS.MouseIconEnabled = true
		--end
		--locked = not locked
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true
	end

	if input.KeyCode == Enum.KeyCode.F2 then
		if okak.locked then

		else

		end
		okak.locked = not okak.locked

	end



	if gp then return end



	if state.onlyButton then return end

	if input.KeyCode == Enum.KeyCode.F3 then
		if state.detectorOn then detectorOff() else detectorOn() end
	elseif input.KeyCode == Enum.KeyCode.F4 then
		if state.xrayOn then xrayOff() else xrayOn() end
	elseif input.KeyCode == Enum.KeyCode.RightShift then
		if state.boostOn then boostOff() else boostOn() end
	elseif input.KeyCode == Enum.KeyCode.F9 then
		if state.autoAimOn then autoAimOff() else autoAimOn() end
	elseif input.KeyCode == Enum.KeyCode.F1 then
		if state.orbitOn then
			state.orbitTarget = nil
			stopOrbitHighlight()
		end
	elseif input.KeyCode == Enum.KeyCode.F5 then
		if state.freeCamOn then
			freeCamOff()
		else
			freeCamOn()
		end
	elseif input.KeyCode == Enum.KeyCode.F6 then
		if okak.NightVisionRegulator then
			nightVisionOn()
		else
			nightVisionOff()
		end
		okak.NightVisionRegulator = not okak.NightVisionRegulator

	elseif input.KeyCode == Enum.KeyCode.F2 then
		-- F2 = Stealth Invis (Proxy Cube)
		-- включится только если "armed" включён через кнопку в меню
		if state.__StealthCube and state.__StealthCube.armed then
			if state.__StealthCube.enabled then
				pcall(function() state.__StealthCube.Disable() end)
			else
				pcall(function() state.__StealthCube.Enable() end)
			end
		else
			-- если не armed, можно просто показать подсказку в output
			game:GetService("StarterGui"):SetCore("SendNotification", { 
				Title = "Nurmenal";
				Text = "First enable 'Invisible (Toggle)' in menu.";
				Icon = "rbxassetid://16913919379"})
			Duration = 5;

		end
	end


	if state.freeCamOn and input.UserInputType == Enum.UserInputType.MouseButton2 then
		freeCamLooking = true
		UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		UIS.MouseIconEnabled = false
	end


	-- StealthCube speed +/-
	if state.__StealthCube and state.__StealthCube.enabled then
		local fast = UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
		local step = fast and 15 or 3

		if input.KeyCode == Enum.KeyCode.Equals or input.KeyCode == Enum.KeyCode.KeypadPlus then
			state.__StealthCube.cfg.MOVE_SPEED = math.clamp((tonumber(state.__StealthCube.cfg.MOVE_SPEED) or 70) + step, 1, 500)
		elseif input.KeyCode == Enum.KeyCode.Minus or input.KeyCode == Enum.KeyCode.KeypadMinus then
			state.__StealthCube.cfg.MOVE_SPEED = math.clamp((tonumber(state.__StealthCube.cfg.MOVE_SPEED) or 70) - step, 1, 500)
		end
	end

	if input.KeyCode == Enum.KeyCode.W then freeCamKeys.W = true end
	if input.KeyCode == Enum.KeyCode.A then freeCamKeys.A = true end
	if input.KeyCode == Enum.KeyCode.S then freeCamKeys.S = true end
	if input.KeyCode == Enum.KeyCode.D then freeCamKeys.D = true end
	if input.KeyCode == Enum.KeyCode.Q then freeCamKeys.Q = true end
	if input.KeyCode == Enum.KeyCode.E then freeCamKeys.E = true end
	if input.KeyCode == Enum.KeyCode.LeftShift then freeCamKeys.Shift = true end
	if input.KeyCode == Enum.KeyCode.LeftControl then freeCamKeys.Ctrl = true end


end)


UIS.InputEnded:Connect(function(input, gp)
	if gp then return end
	--if input.KeyCode == Enum.KeyCode.Space then flyKeys.Space = false end
	--if input.KeyCode == Enum.KeyCode.LeftControl then flyKeys.Ctrl = false end

	if state.freeCamOn and input.UserInputType == Enum.UserInputType.MouseButton2 then
		freeCamLooking = false
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true
	end

	if input.KeyCode == Enum.KeyCode.W then freeCamKeys.W = false end
	if input.KeyCode == Enum.KeyCode.A then freeCamKeys.A = false end
	if input.KeyCode == Enum.KeyCode.S then freeCamKeys.S = false end
	if input.KeyCode == Enum.KeyCode.D then freeCamKeys.D = false end
	if input.KeyCode == Enum.KeyCode.Q then freeCamKeys.Q = false end
	if input.KeyCode == Enum.KeyCode.E then freeCamKeys.E = false end
	if input.KeyCode == Enum.KeyCode.LeftShift then freeCamKeys.Shift = false end
	if input.KeyCode == Enum.KeyCode.LeftControl then freeCamKeys.Ctrl = false end

end)

------------------------------------------------------------
-- Slider reading loop (safe)
------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	state.speedValue = speedSlider.Get()
	state.jumpValue = jumpSlider.Get()
	state.flingSpeed = flingSlider.Get()
	state.orbitSpeed = orbitSpeedSlider.Get()
	state.orbitDist = orbitDistSlider.Get()
end)





------------------------------------------------------------
-- Init visuals & buttons
------------------------------------------------------------
setBtnOn(btnHideAdminStatic, state.hideAdminStatic)
setBtnOn(btnOnlyButton, state.onlyButton)
setBtnOn(btnDetector, false)
setBtnOn(btnXray, false)
setBtnOn(btnHitbox, false)
setBtnOn(btnCoords, false)
setBtnOn(btnBoost, false)
setBtnOn(btnAutoAim, false)
setBtnOn(btnAutoGG, false)
setBtnOn(btnFly, false)
setBtnOn(btnNoClip, false)
setBtnOn(btnTP, false)
setBtnOn(btnAdminTools, false)

setBtnOn(btnSeeInvis, false)
setBtnOn(btnInvisible, false)

setBtnOn(btnFling, state.flingOn)
setBtnOn(btnOrbit, state.orbitOn)

refreshTPUI()
updateHUD()
----------------------------------------------------
----------------------------------------------------
local fling = {
	conn = nil,
	gyro = nil,
	camAnchor = nil,
	prevCamSubject = nil,
	prevAutoRotate = nil,
}

state.__FlingCore = state.__FlingCore or {
	active = false,
	runBaseCF = nil,

	attackSpeed = 180,
	returnSpeed = 220,
	holdRadius = 1.35,
	holdHeight = 0.2,
	repathRate = 0.03,
}

Fling_Set =function(on: boolean)
	state.flingOn = on
	setBtnOn(btnFling, state.flingOn)
	updateHUD()

	if fling.conn then fling.conn:Disconnect(); fling.conn = nil end

	local char = getChar()
	local hum = getHumanoid(char)
	local hrp = getHRP(char)

	if not on then
		if hrp then hrp.AssemblyAngularVelocity = Vector3.zero end
		if fling.gyro then fling.gyro:Destroy(); fling.gyro = nil end

		local cam = Workspace.CurrentCamera
		if cam and fling.prevCamSubject then cam.CameraSubject = fling.prevCamSubject end
		fling.prevCamSubject = nil
		if fling.camAnchor then fling.camAnchor:Destroy(); fling.camAnchor = nil end

		if hum and fling.prevAutoRotate ~= nil then hum.AutoRotate = fling.prevAutoRotate end
		fling.prevAutoRotate = nil
		return
	end

	-- если включаем fling — выключаем orbit, чтобы не конфликтовало
	if state.orbitOn then
		Orbit_Set(false)
	end

	if not (hum and hrp) then return end

	-- стабилизация, чтобы не падать
	fling.prevAutoRotate = hum.AutoRotate
	hum.AutoRotate = false

	fling.gyro = Instance.new("BodyGyro")
	fling.gyro.Name = "FlingStabilizer"
	fling.gyro.MaxTorque = Vector3.new(1e8, 0, 1e8) -- XZ стабилизация, Y не трогаем
	fling.gyro.P = 60000
	fling.gyro.D = 1200
	fling.gyro.Parent = hrp

	-- камера: убираем тряску (следит по позиции, без вращения)
	local cam = Workspace.CurrentCamera
	if cam then
		fling.prevCamSubject = cam.CameraSubject
		fling.CamAnchor = Instance.new("Part")
		fling.CamAnchor.Name = "fling.CamAnchor"
		fling.CamAnchor.Anchored = true
		fling.CamAnchor.CanCollide = false
		fling.CamAnchor.Transparency = 1
		fling.CamAnchor.Size = Vector3.new(1,1,1)
		fling.CamAnchor.Parent = Workspace
		cam.CameraSubject = fling.CamAnchor
	end

	fling.conn = RunService.RenderStepped:Connect(function()
		if not state.flingOn then return end
		local c = getChar()
		local h = getHumanoid(c)
		local r = getHRP(c)
		if not (h and r) then return end

		-- обновляем якорь камеры
		if fling.CamAnchor then
			fling.CamAnchor.CFrame = CFrame.new(r.Position + Vector3.new(0, 2, 0))
		end

		-- держим вертикально (yaw не фиксируем)
		if fling.gyro then
			local _, y, _ = r.CFrame:ToOrientation()
			fling.gyro.CFrame = CFrame.new(r.Position) * CFrame.Angles(0, y, 0)
		end

		local s = math.clamp(tonumber(state.flingSpeed) or 1, 1, 10000)

		-- сильнее и агрессивнее
		local omegaY = s * 3.0
		local omegaXZ = s * 1.0

		if state.flingMode == "Spin" then
			local tt = time()
			local x = math.sin(tt * 9.5) * omegaXZ * 0.35
			local z = math.cos(tt * 8.7) * omegaXZ * 0.35
			r.AssemblyAngularVelocity = Vector3.new(x, omegaY, z)
		else
			local tt = time()
			local x = math.sin(tt * 11.0) * omegaXZ
			local z = math.cos(tt * 10.0) * omegaXZ
			r.AssemblyAngularVelocity = Vector3.new(x, omegaY, z)
		end
	end)
end

------------------------------------------------------------
-- Respawn safety
------------------------------------------------------------
LP.CharacterAdded:Connect(function()
	task.wait(0.2)
	if state.flyOn then flyOff() end
	if state.autoAimOn then autoAimOff() end
	if state.noClipOn then noClipOff() end
	if state.flingOn then Fling_Set(false) end
	if state.orbitOn then Orbit_Set(false) end
	clearDeleteSel()

	if state.invisibleOn then
		task.wait(0.2)
		invisibleApplyOnce()
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	if state.orbitTarget and state.orbitTarget:IsA("Player") and state.orbitTarget == plr then
		state.orbitTarget = nil

		stopOrbitHighlight()
		updateHUD()
	end
	stopDetectorFor(plr)
end)

------------------------------------------------------------
-- AntiPush v2 (NO register spam)
-- Работает так:
--  - пишет историю позиций ~12 сек
--  - если скорость "вспыхнула" >= threshold -> 10-15 сек телепает на позицию 10 сек назад каждые 0.01с
--  - потом резко отпускает, без кд
------------------------------------------------------------

state.antiPushSaveDelay = tonumber(state.antiPushSaveDelay) or 3 -- сек, дефолт 3
-- defaults (не локалы)
state.antiPushOn = state.antiPushOn == true
state.antiPushThreshold = tonumber(state.antiPushThreshold) or 100 -- default low
state.antiPushCycleDur = tonumber(state.antiPushCycleDur) or 2    -- default 10 sec
state.antiPushIndicator = state.antiPushIndicator or "medium"

-- create storage table (не локал)
state.__AP2 = state.__AP2 or {}
state.__AP2.ui = state.__AP2.ui or {}
state.__AP2.hist = state.__AP2.hist or {}
state.__AP2.acc = state.__AP2.acc or 0
state.__AP2.token = state.__AP2.token or 0
state.__AP2.cycling = state.__AP2.cycling or false
state.__AP2.lastSpeed = state.__AP2.lastSpeed or 0
state.__AP2.conn = state.__AP2.conn or nil

-- --- UI (в Player секции) ---
state.__AP2.ui.btn = makeButton(playerWrap, "AntiPush")
state.__AP2.ui.btn.Name = "AP2_Button"

-- mini field maker (в таблицу, чтобы не плодить local)
state.__AP2.MakeField = state.__AP2.MakeField or function(titleText, placeholder, initialText)
	local holder = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(30, 30, 36),
		Size = UDim2.new(1, 0, 0, 58),
		ZIndex = 5,
	}, playerWrap)
	mk("UICorner", {CornerRadius = UDim.new(0, 10)}, holder)
	mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75, 75, 90), Transparency = 0.45}, holder)

	mk("TextLabel", {
		Text = titleText,
		Font = fontik,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(235, 235, 235),
		Size = UDim2.new(1, -20, 0, 20),
		Position = UDim2.fromOffset(10, 6),
		ZIndex = 6,
	}, holder)

	local box = mk("TextBox", {
		ClearTextOnFocus = false,
		Text = tostring(initialText or ""),
		PlaceholderText = placeholder or "",
		Font = fontik,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(18, 18, 22),
		TextColor3 = Color3.fromRGB(235, 235, 235),
		Size = UDim2.new(1, -20, 0, 24),
		Position = UDim2.fromOffset(10, 28),
		ZIndex = 6,
	}, holder)



	mk("UICorner", {CornerRadius = UDim.new(0, 8)}, box)

	return box
end

state.__AP2.ui.thrBox = state.__AP2.MakeField(
	"AntiPush Speed Threshold (start if speed >= this)",
	"example: 100",
	state.antiPushThreshold
)



state.__AP2.ui.durBox = state.__AP2.MakeField(
	"AntiPush Cycle Duration (seconds, default 10)",
	"example: 2",
	state.antiPushCycleDur
)

state.__AP2.ui.indFrame = mk("Frame", {
	BackgroundColor3 = Color3.fromRGB(30, 30, 36),
	Size = UDim2.new(1, 0, 0, 36),
}, playerWrap)


state.__AP2.ui.saveBox = state.__AP2.MakeField(
	"Delay between position saves (seconds, default 3)",
	"example: 3",
	state.antiPushSaveDelay
)

state.__AP2.ui.saveBox.FocusLost:Connect(function(enterPressed)
	if not enterPressed then return end
	state.antiPushSaveDelay = state.__AP2.ClampNum(state.__AP2.ui.saveBox.Text, 0.05, 60, state.antiPushSaveDelay)
	state.__AP2.ui.saveBox.Text = tostring(state.antiPushSaveDelay)
	updateHUD()
end)


mk("UICorner", {CornerRadius = UDim.new(0, 10)}, state.__AP2.ui.indFrame)
mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75, 75, 90), Transparency = 0.45}, state.__AP2.ui.indFrame)

state.__AP2.ui.indLbl = mk("TextLabel", {
	Text = "Indicator Height: medium",
	Font = fontik,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(235,235,235),
	Size = UDim2.new(1, -20, 1, 0),
	Position = UDim2.fromOffset(10, 0),
}, state.__AP2.ui.indFrame)

state.__AP2.ClampNum = state.__AP2.ClampNum or function(txt, a, b, fallback)
	local n = tonumber(txt)
	if not n then return fallback end
	return math.clamp(n, a, b)
end



state.__AP2.UpdateIndicator = state.__AP2.UpdateIndicator or function()
	local th = tonumber(state.antiPushThreshold) or 120
	local tag
	-- чем меньше threshold => тем "страшнее"
	if th >= 120 then tag = "low"
	elseif th >= 80 then tag = "medium"
	elseif th >= 50 then tag = "high"
	else tag = "crazy"
	end
	state.antiPushIndicator = tag
	if state.__AP2.ui and state.__AP2.ui.indLbl then
		state.__AP2.ui.indLbl.Text = ("Indicator Height: %s"):format(tag)
	end
end

-- PATCH HUD (один раз)
if not state.__AP2.hudPatched then
	state.__AP2.hudPatched = true
	state.__AP2.oldHUD = updateHUD
	updateHUD = function()
		if state.__AP2.oldHUD then state.__AP2.oldHUD() end
		if hudLines and hudLines["AntiPush"] then
			hudLines["AntiPush"].Text = ("AntiPush: %s | Th=%d | %s | Dur=%.1fs"):format(
				onOff(state.antiPushOn),
				tonumber(state.antiPushThreshold) or 0,
				tostring(state.antiPushIndicator or "low"),
				tonumber(state.antiPushCycleDur) or 0
			)
		end
	end
end

state.__AP2.UpdateIndicator()

-- core helpers
state.__AP2.ClearHist = state.__AP2.ClearHist or function()
	table.clear(state.__AP2.hist)
	state.__AP2.acc = 0
end

state.__AP2.StopCycle = state.__AP2.StopCycle or function()
	state.__AP2.token += 1
	state.__AP2.cycling = false
end

state.__AP2.Find10sCF = state.__AP2.Find10sCF or function()
	local now = os.clock()
	local targetT = now - 3
	local bestCF = nil
	local bestDiff = 1e9

	-- ищем ближайший кадр к 10 сек назад
	for i = #state.__AP2.hist, 1, -1 do
		local e = state.__AP2.hist[i]
		local d = e.t - targetT
		if d < 0 then d = -d end
		if d < bestDiff then
			bestDiff = d
			bestCF = e.cf
		end
		if e.t < targetT - 2 then break end
	end

	return bestCF
end



------------------------------------------------------------
-- POSITION HISTORY CORE
------------------------------------------------------------
function PH_Clear()
	table.clear(state.__PosHistory.buf)
	state.__PosHistory.acc = 0
end

function PH_Push(cf)
	table.insert(state.__PosHistory.buf, {
		t = os.clock(),
		cf = cf,
	})
end

function PH_Prune()
	local cutoff = os.clock() - (state.__PosHistory.maxAge or 30)
	local buf = state.__PosHistory.buf
	while #buf > 0 and buf[1].t < cutoff do
		table.remove(buf, 1)
	end
end

function PH_GetAgo(sec)
	sec = math.max(0, tonumber(sec) or 0)

	local buf = state.__PosHistory.buf
	if #buf == 0 then return nil end

	local targetT = os.clock() - sec
	local best = buf[1]
	local bestDiff = math.abs(best.t - targetT)

	for i = #buf, 1, -1 do
		local e = buf[i]
		local d = math.abs(e.t - targetT)
		if d < bestDiff then
			best = e
			bestDiff = d
		end
		if e.t < targetT then
			break
		end
	end

	return best and best.cf or nil
end


state.__AP2.StartCycle = state.__AP2.StartCycle or function()
	if state.__AP2.cycling then return end

	local cf = state.__AP2.Find10sCF()
	if not cf then return end

	state.__AP2.cycling = true
	state.__AP2.token += 1
	local myToken = state.__AP2.token

	local dur = math.clamp(tonumber(state.antiPushCycleDur) or 10, 0.01, 20)
	local endAt = os.clock() + dur

	task.spawn(function()
		while state.antiPushOn and state.__AP2.cycling and state.__AP2.token == myToken and os.clock() < endAt do
			-- если включили особые режимы — просто отпускаем
			if state.freeCamOn or state.flyOn or state.flingOn or state.orbitOn then
				break
			end

			local hrp = getHRP(getChar())
			if not hrp then break end

			hrp.CFrame = cf + Vector3.new(0, 2.8, 0)
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero

			task.wait(0.01)
		end

		-- резко отпустить (без кд)
		if state.__AP2.token == myToken then
			state.__AP2.cycling = false
		end
	end)
end

state.__AP2.Set = state.__AP2.Set or function(on)
	state.antiPushOn = on == true
	setBtnOn(state.__AP2.ui.btn, state.antiPushOn)
	refreshRollbackPanel()
	-- reset
	if state.__AP2.conn then state.__AP2.conn:Disconnect(); state.__AP2.conn = nil end
	state.__AP2.StopCycle()
	state.__AP2.ClearHist()
	state.__AP2.UpdateIndicator()
	updateHUD()

	if not state.antiPushOn then return end

	state.__AP2.conn = RunService.Heartbeat:Connect(function(dt)
		if not state.antiPushOn then return end
		if state.freeCamOn or state.flyOn or state.flingOn or state.orbitOn then return end

		local hrp = getHRP(getChar())
		if not hrp then return end

		state.__AP2.acc += dt
		if state.__AP2.acc >= (tonumber(state.antiPushSaveDelay) or 3) then
			state.__AP2.acc = 0
			table.insert(state.__AP2.hist, {t = os.clock(), cf = hrp.CFrame})

			-- держим историю дольше, чтобы точно было "10 сек назад"
			local keep = 12 + (tonumber(state.antiPushSaveDelay) or 3) -- запас
			local cutoff = os.clock() - keep
			while #state.__AP2.hist > 0 and state.__AP2.hist[1].t < cutoff do
				table.remove(state.__AP2.hist, 1)
			end
		end

		if state.__AP2.cycling then return end

		-- speed detect (ALWAYS trigger)
		local speed = hrp.AssemblyLinearVelocity.Magnitude
		local th = tonumber(state.antiPushThreshold) or 120

		-- триггерим всегда, как только speed >= threshold
		if speed >= th then
			state.__AP2.StartCycle()
		end



		state.__AP2.lastSpeed = speed
	end)
end

-- wiring
state.__AP2.ui.btn.MouseButton1Click:Connect(function()
	state.__AP2.Set(not state.antiPushOn)
end)

state.__AP2.ui.thrBox.FocusLost:Connect(function(enterPressed)
	if not enterPressed then return end
	state.antiPushThreshold = math.floor(state.__AP2.ClampNum(state.__AP2.ui.thrBox.Text, 1, 10000, state.antiPushThreshold) + 0.5)
	state.__AP2.ui.thrBox.Text = tostring(state.antiPushThreshold)
	state.__AP2.UpdateIndicator()
	updateHUD()
end)

state.__AP2.ui.durBox.FocusLost:Connect(function(enterPressed)
	if not enterPressed then return end
	state.antiPushCycleDur = state.__AP2.ClampNum(state.__AP2.ui.durBox.Text, 0.01, 20, state.antiPushCycleDur)
	state.__AP2.ui.durBox.Text = tostring(state.antiPushCycleDur)
	updateHUD()
end)

-- respawn safety (добавляем без новых local)
LP.CharacterAdded:Connect(function()
	task.wait(0.25)
	state.__AP2.StopCycle()
	state.__AP2.ClearHist()
	if state.antiPushOn then
		state.__AP2.Set(false)
		state.__AP2.Set(true)
	end
end)

-- apply
state.__AP2.Set(state.antiPushOn)
refreshRollbackPanel()
state.__AP2.UpdateIndicator()
updateHUD()



------------------------------------------------------------
-- STEALTH INVIS v3 (Proxy Cube + CameraSubject = Cube)
-- - Камера как у игрока: привязана к кубу (CameraSubject = cube)
-- - Реальный игрок телепается далеко и фиксируется там
-- - При выходе ты появляешься в текущей позиции куба
-- - ВНЕ-меню кнопка появляется только после нажатия кнопки в меню
-- - Управление кубом: WASD + Space вверх + LeftShift вниз
------------------------------------------------------------

state.__StealthCube = state.__StealthCube or {}
state.__StealthCube.enabled = state.__StealthCube.enabled == true
state.__StealthCube.armed = state.__StealthCube.armed == true
state.__StealthCube.cfg = state.__StealthCube.cfg or {
	FAR_POS = Vector3.new(220, -220, 220),
	FIX_DT = 0.03,

	CUBE_SIZE = Vector3.new(3, 3, 3),
	CUBE_ALPHA = 0.55,

	MOVE_SPEED = 70,
}

state.__StealthCube.saved = state.__StealthCube.saved or {}
state.__StealthCube.conns = state.__StealthCube.conns or {}
state.__StealthCube.keys = state.__StealthCube.keys or {W=false,A=false,S=false,D=false,Space=false,LCtrl=false}

state.__StealthCube.cfg.MOVE_SPEED = tonumber(state.__StealthCube.cfg.MOVE_SPEED) or 70


-- helpers
state.__StealthCube._disc = state.__StealthCube._disc or function()
	for k, c in pairs(state.__StealthCube.conns) do
		if c then pcall(function() c:Disconnect() end) end
		state.__StealthCube.conns[k] = nil
	end
end

state.__StealthCube._killCube = state.__StealthCube._killCube or function()
	local p = state.__StealthCube.cube
	if p and p.Parent then pcall(function() p:Destroy() end) end
	state.__StealthCube.cube = nil
end

state.__StealthCube._setFloatBtn = state.__StealthCube._setFloatBtn or function(visible, on)
	local b = state.__StealthCube.floatBtn
	if not b then return end
	b.Visible = visible == true
	if on ~= nil then
		b.BackgroundColor3 = on and Color3.fromRGB(40, 52, 90) or Color3.fromRGB(30, 30, 36)
		b.TextColor3 = on and Color3.fromRGB(245, 245, 255) or Color3.fromRGB(235, 235, 235)
		b.Text = on and "STEALTH: ON" or "STEALTH"
	end
end

-- HUD patch (строка Invisible)
if not state.__StealthCube.hudPatched then
	state.__StealthCube.hudPatched = true
	state.__StealthCube._oldHUD = updateHUD
	updateHUD = function()
		if state.__StealthCube._oldHUD then state.__StealthCube._oldHUD() end
		if hudLines and hudLines["Invisible"] then
			local anyOn = (state.invisibleOn == true) or (state.__StealthCube.enabled == true)
			local mode = state.__StealthCube.enabled and "STEALTH" or (state.invisibleOn and "LOCAL" or "OFF")
			hudLines["Invisible"].Text = ("Invisible: %s [%s]"):format(onOff(anyOn), mode)
			colorize(hudLines["Invisible"], anyOn)
		end
	end
end

------------------------------------------------------------
-- UI: кнопка В МЕНЮ (армит/разармливает вне-меню кнопку)
------------------------------------------------------------
if not state.__StealthCube.menuBtn and playerWrap then
	state.__StealthCube.menuBtn = btnInvisible
end

if state.__StealthCube.menuBtn and not state.__StealthCube.menuBtn:GetAttribute("AP_Wired") then
	state.__StealthCube.menuBtn:SetAttribute("AP_Wired", true)
	state.__StealthCube.menuBtn.MouseButton1Click:Connect(function()
		state.__StealthCube.armed = not state.__StealthCube.armed

		-- если разармил — выключаем режим и прячем кнопку
		if not state.__StealthCube.armed and state.__StealthCube.enabled then
			pcall(function() state.__StealthCube.Disable() end)
		end

		state.__StealthCube._setFloatBtn(state.__StealthCube.armed, state.__StealthCube.enabled)
		updateHUD()
	end)
end

------------------------------------------------------------
-- UI: вне-меню кнопка (создаём 1 раз, показываем только когда armed)
------------------------------------------------------------
if gui and not state.__StealthCube.floatBtn then
	local b = gui:FindFirstChild("AP_StealthCubeBtn")
	if not b then
		b = mk("TextButton", {
			Name = "AP_StealthCubeBtn",
			Text = "STEALTH",
			Font = fontik,
			TextSize = 16,
			AutoButtonColor = true,
			Size = UDim2.fromOffset(150, 44),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 64),
			BackgroundColor3 = Color3.fromRGB(30, 30, 36),
			TextColor3 = Color3.fromRGB(235, 235, 235),
			Visible = false,
		}, gui)
		mk("UICorner", {CornerRadius = UDim.new(0, 10)}, b)
		mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75, 75, 90), Transparency = 0.35}, b)
	end
	state.__StealthCube.floatBtn = b
end

------------------------------------------------------------
-- CORE: enable/disable
------------------------------------------------------------
state.__StealthCube.Enable = state.__StealthCube.Enable or function()
	if state.__StealthCube.enabled then return end
	if not state.__StealthCube.armed then return end

	-- выключаем конфликтующие режимы
	if state.freeCamOn and freeCamOff then pcall(freeCamOff) end
	if state.flyOn and flyOff then pcall(flyOff) end
	if state.orbitOn and Orbit_Set then pcall(function() Orbit_Set(false) end) end
	if state.flingOn and Fling_Set then pcall(function() Fling_Set(false) end) end

	local char = getChar()
	local hum = getHumanoid(char)
	local hrp = getHRP(char)
	local cam = Workspace.CurrentCamera
	if not (char and hum and hrp and cam) then return end

	-- save
	state.__StealthCube.saved = {
		wasWalk = hum.WalkSpeed,
		wasUseJP = hum.UseJumpPower,
		wasJump = (hum.UseJumpPower and hum.JumpPower) or hum.JumpHeight,
		wasAutoRotate = hum.AutoRotate,
		wasPlatformStand = hum.PlatformStand,

		camType = cam.CameraType,
		camSubject = cam.CameraSubject,
	}

	-- create proxy cube at current position
	state.__StealthCube._killCube()
	local cube = Instance.new("Part")
	cube.Name = "AP_StealthCube"
	cube.Anchored = true
	cube.CanCollide = false
	cube.CanTouch = false
	cube.CanQuery = false
	cube.Material = Enum.Material.SmoothPlastic
	cube.Color = Color3.fromRGB(220, 220, 230)
	cube.Transparency = math.clamp(state.__StealthCube.cfg.CUBE_ALPHA, 0, 1)
	cube.Size = state.__StealthCube.cfg.CUBE_SIZE
	cube.CFrame = hrp.CFrame
	cube.Parent = Workspace
	state.__StealthCube.cube = cube

	-- camera behaves like normal (orbit around subject)
	cam.CameraType = Enum.CameraType.Custom
	cam.CameraSubject = cube

	-- lock real body
	hum.AutoRotate = false
	hum.PlatformStand = true
	hum.WalkSpeed = 0
	if hum.UseJumpPower then hum.JumpPower = 0 else hum.JumpHeight = 0 end

	state.__StealthCube.enabled = true
	state.__StealthCube._setFloatBtn(true, true)

	-- keep player far
	local acc = 0
	state.__StealthCube.conns.fix = RunService.Heartbeat:Connect(function(dt)
		if not state.__StealthCube.enabled then return end
		local c2 = getChar()
		local h2 = getHumanoid(c2)
		local r2 = getHRP(c2)
		if not (h2 and r2) then return end

		acc += dt
		if acc < state.__StealthCube.cfg.FIX_DT then return end
		acc = 0

		r2.CFrame = CFrame.new(state.__StealthCube.cfg.FAR_POS)
		r2.AssemblyLinearVelocity = Vector3.zero
		r2.AssemblyAngularVelocity = Vector3.zero
	end)

	-- control cube: WASD + Space up + LeftShift down
	state.__StealthCube.conns.move = RunService.RenderStepped:Connect(function(dt)
		local cam2 = Workspace.CurrentCamera
		local p = state.__StealthCube.cube
		if not (cam2 and p and p.Parent) then return end

		local sp = math.clamp(tonumber(state.__StealthCube.cfg.MOVE_SPEED) or 70, 1, 500)

		-- НАПРАВЛЕНИЯ КАМЕРЫ (с учётом вверх/вниз)
		local look = cam2.CFrame.LookVector
		local right = cam2.CFrame.RightVector
		local up = Vector3.new(0, 1, 0)

		-- WASD = по взгляду (W/S) и по правому вектору (A/D)
		local move = Vector3.zero
		if state.__StealthCube.keys.W then move += look end
		if state.__StealthCube.keys.S then move -= look end
		if state.__StealthCube.keys.D then move += right end
		if state.__StealthCube.keys.A then move -= right end

		-- Исключения: Space/Ctrl (чисто по мировому Y)
		if state.__StealthCube.keys.Space then move += up end
		if state.__StealthCube.keys.LCtrl then move -= up end

		-- позиция
		local newPos = p.Position
		if move.Magnitude > 0.01 then
			newPos = newPos + move.Unit * sp * dt
		end

		-- ориентация куба туда, куда смотрит камера (прям полностью, включая наклон)
		p.CFrame = CFrame.lookAt(newPos, newPos + look)
	end)

	updateHUD()
end

state.__StealthCube.Disable = state.__StealthCube.Disable or function()
	if not state.__StealthCube.enabled then
		state.__StealthCube._setFloatBtn(state.__StealthCube.armed, false)
		return
	end

	state.__StealthCube.enabled = false
	state.__StealthCube._disc()

	local char = getChar()
	local hum = getHumanoid(char)
	local hrp = getHRP(char)
	local cam = Workspace.CurrentCamera

	-- spawn at cube position (ВАЖНО)
	local cube = state.__StealthCube.cube
	local spawnCF = cube and cube.Parent and cube.CFrame or nil

	-- destroy cube after reading spawnCF
	state.__StealthCube._killCube()

	if hrp and spawnCF then
		hrp.CFrame = spawnCF + Vector3.new(0, 3, 0)
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end

	-- restore humanoid
	if hum and state.__StealthCube.saved then
		hum.PlatformStand = state.__StealthCube.saved.wasPlatformStand
		hum.AutoRotate = state.__StealthCube.saved.wasAutoRotate
		hum.WalkSpeed = state.__StealthCube.saved.wasWalk

		hum.UseJumpPower = state.__StealthCube.saved.wasUseJP
		if hum.UseJumpPower then
			hum.JumpPower = state.__StealthCube.saved.wasJump
		else
			hum.JumpHeight = state.__StealthCube.saved.wasJump
		end
	end

	-- restore camera
	if cam and state.__StealthCube.saved then
		cam.CameraType = state.__StealthCube.saved.camType
		cam.CameraSubject = state.__StealthCube.saved.camSubject
	end

	state.__StealthCube.saved = {}
	state.__StealthCube._setFloatBtn(state.__StealthCube.armed, false)
	updateHUD()
end

-- outside button wiring
if state.__StealthCube.floatBtn and not state.__StealthCube.floatBtn:GetAttribute("AP_Wired") then
	state.__StealthCube.floatBtn:SetAttribute("AP_Wired", true)
	state.__StealthCube.floatBtn.MouseButton1Click:Connect(function()
		if state.__StealthCube.enabled then
			state.__StealthCube.Disable()
		else
			state.__StealthCube.Enable()

			-- STREAM FIX: держим карту загруженной вокруг куба (StreamingEnabled)
			if state.__StealthCube.streamLoopToken then
				state.__StealthCube.streamLoopToken = nil
			end
			local token = {}
			state.__StealthCube.streamLoopToken = token

			task.spawn(function()
				while state.__StealthCube.enabled and state.__StealthCube.streamLoopToken == token do
					local p = state.__StealthCube.cube
					if p and p.Parent then
						pcall(function()
							Workspace:RequestStreamAroundAsync(p.Position)
						end)
					end
					task.wait(0.35)
				end
			end)
		end
	end)
end

-- key capture for cube control
if not state.__StealthCube.keyWired then
	state.__StealthCube.keyWired = true

	UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		if not state.__StealthCube.enabled then return end
		if UIS:GetFocusedTextBox() then return end

		if input.KeyCode == Enum.KeyCode.W then state.__StealthCube.keys.W = true end
		if input.KeyCode == Enum.KeyCode.A then state.__StealthCube.keys.A = true end
		if input.KeyCode == Enum.KeyCode.S then state.__StealthCube.keys.S = true end
		if input.KeyCode == Enum.KeyCode.D then state.__StealthCube.keys.D = true end
		if input.KeyCode == Enum.KeyCode.Space then state.__StealthCube.keys.Space = true end
		if input.KeyCode == Enum.KeyCode.LeftControl then state.__StealthCube.keys.LCtrl = true end
	end)

	UIS.InputEnded:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.W then state.__StealthCube.keys.W = false end
		if input.KeyCode == Enum.KeyCode.A then state.__StealthCube.keys.A = false end
		if input.KeyCode == Enum.KeyCode.S then state.__StealthCube.keys.S = false end
		if input.KeyCode == Enum.KeyCode.D then state.__StealthCube.keys.D = false end
		if input.KeyCode == Enum.KeyCode.Space then state.__StealthCube.keys.Space = false end
		if input.KeyCode == Enum.KeyCode.LeftControl then state.__StealthCube.keys.LCtrl = false end
	end)
end





------------------------------------------------------------
-- FOLLOW UPDATE (AllPlayer cycle + Follow by nickname)
-- вставь В КОНЕЦ скрипта
------------------------------------------------------------

state.orbitAllPlayersOn = (state.orbitAllPlayersOn == true)
state.orbitAllPlayersDelay = tonumber(state.orbitAllPlayersDelay) or 1

state.__FollowUpd = state.__FollowUpd or {}
state.__FollowUpd.ui = state.__FollowUpd.ui or {}

-- ========= UI =========
-- Row: AllPlayer toggle + delay box
if playerWrap and not state.__FollowUpd.ui.allRow then
	state.__FollowUpd.ui.allRow = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
	}, playerWrap)

	state.__FollowUpd.ui.allBtn = makeButton(state.__FollowUpd.ui.allRow, "AllPlayer: OFF")
	state.__FollowUpd.ui.allBtn.Size = UDim2.new(0.62, -6, 1, 0)
	state.__FollowUpd.ui.allBtn.Position = UDim2.new(0, 0, 0, 0)

	state.__FollowUpd.ui.delayBox = mk("TextBox", {
		ClearTextOnFocus = false,
		Text = tostring(state.orbitAllPlayersDelay),
		PlaceholderText = "delay",
		Font = fontik,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundColor3 = Color3.fromRGB(30,30,36),
		TextColor3 = Color3.fromRGB(235,235,235),
		Size = UDim2.new(0.38, 0, 1, 0),
		Position = UDim2.new(0.62, 6, 0, 0),
	}, state.__FollowUpd.ui.allRow)
	mk("UICorner", {CornerRadius = UDim.new(0, 10)}, state.__FollowUpd.ui.delayBox)
	mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75,75,90), Transparency = 0.45}, state.__FollowUpd.ui.delayBox)

	state.__FollowUpd.ui.delayHint = mk("TextLabel", {
		BackgroundTransparency = 1,
		Text = "sec",
		Font = fontik,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(170,170,170),
		Size = UDim2.fromOffset(26, 16),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
	}, state.__FollowUpd.ui.delayBox)
end

-- Row: Follow by nickname (box + lock btn)
if playerWrap and not state.__FollowUpd.ui.nameRow then
	state.__FollowUpd.ui.nameRow = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
	}, playerWrap)

	state.__FollowUpd.ui.nameBox = mk("TextBox", {
		ClearTextOnFocus = false,
		Text = "",
		PlaceholderText = "Follow by nickname...",
		Font = fontik,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(30,30,36),
		TextColor3 = Color3.fromRGB(235,235,235),
		Size = UDim2.new(0.70, -6, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
	}, state.__FollowUpd.ui.nameRow)
	mk("UICorner", {CornerRadius = UDim.new(0, 10)}, state.__FollowUpd.ui.nameBox)
	mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75,75,90), Transparency = 0.45}, state.__FollowUpd.ui.nameBox)

	state.__FollowUpd.ui.nameBtn = mk("TextButton", {
		Text = "Enter",
		Font = fontik,
		TextSize = 14,
		AutoButtonColor = true,
		BackgroundColor3 = Color3.fromRGB(40, 52, 90),
		TextColor3 = Color3.fromRGB(245,245,255),
		Size = UDim2.new(0.30, 0, 1, 0),
		Position = UDim2.new(0.70, 6, 0, 0),
	}, state.__FollowUpd.ui.nameRow)
	mk("UICorner", {CornerRadius = UDim.new(0, 10)}, state.__FollowUpd.ui.nameBtn)
	mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75,75,90), Transparency = 0.25}, state.__FollowUpd.ui.nameBtn)
end

-- UI refresh
state.__FollowUpd.RefreshUI = state.__FollowUpd.RefreshUI or function()
	if state.__FollowUpd.ui.allBtn then
		state.__FollowUpd.ui.allBtn.Text = state.orbitAllPlayersOn and ("AllPlayer: ON") or ("AllPlayer: OFF")
		setBtnOn(state.__FollowUpd.ui.allBtn, state.orbitAllPlayersOn)
	end
	if state.__FollowUpd.ui.delayBox then
		state.__FollowUpd.ui.delayBox.Text = tostring(state.orbitAllPlayersDelay)
	end
end

-- clamp helper (без новых функций в глобале)
state.__FollowUpd.Clamp = state.__FollowUpd.Clamp or function(v, mn, mx, fallback)
	v = tonumber(v)
	if not v then return fallback end
	if v < mn then v = mn end
	if v > mx then v = mx end
	return v
end

-- ========= Core cycle =========
state.__FollowUpd.StopCycle = state.__FollowUpd.StopCycle or function()
	state.__FollowUpd.cycleToken = nil
end

state.__FollowUpd.StartCycle = state.__FollowUpd.StartCycle or function()
	-- перезапуск
	state.__FollowUpd.cycleToken = {}
	local token = state.__FollowUpd.cycleToken
	state.__FollowUpd.cycleIndex = state.__FollowUpd.cycleIndex or 0

	task.spawn(function()
		while state.orbitOn and state.orbitAllPlayersOn and state.__FollowUpd.cycleToken == token do
			local list = Players:GetPlayers()
			local others = {}
			for _, p in ipairs(list) do
				if p ~= LP then
					table.insert(others, p)
				end
			end

			if #others == 0 then
				task.wait(0.3)
			else
				state.__FollowUpd.cycleIndex = (state.__FollowUpd.cycleIndex % #others) + 1
				local tgt = others[state.__FollowUpd.cycleIndex]

				-- валидность цели
				local ch = tgt and tgt.Character
				local hum = ch and ch:FindFirstChildOfClass("Humanoid")
				local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
				if hum and hrp and hum.Health > 0 then
					state.orbitTarget = tgt
					setOrbitHighlight(tgt)
					updateHUD()
				end

				local d = state.__FollowUpd.Clamp(state.orbitAllPlayersDelay, 0.05, 30, 1)
				task.wait(d)
			end
		end
	end)
end

-- ========= Patch Orbit_Set (чтобы цикл стартовал/останавливался автоматически) =========
if not state.__FollowUpd.patchedOrbitSet then
	state.__FollowUpd.patchedOrbitSet = true
	state.__FollowUpd._oldOrbitSet = state.__FollowUpd._oldOrbitSet or Orbit_Set

	Orbit_Set = function(on)
		-- вызываем оригинал
		state.__FollowUpd._oldOrbitSet(on)

		-- управляем циклом
		if on and state.orbitAllPlayersOn then
			state.__FollowUpd.StartCycle()
		else
			state.__FollowUpd.StopCycle()
		end
	end
end

-- ========= Actions =========
state.__FollowUpd.LockByName = state.__FollowUpd.LockByName or function(txt)
	local pl = findPlayerByText(txt)
	if not pl or pl == LP then return end

	-- выключаем allplayer (иначе оно перетрёт цель)
	state.orbitAllPlayersOn = false
	state.__FollowUpd.StopCycle()
	state.__FollowUpd.RefreshUI()

	if not state.orbitOn then
		Orbit_Set(true)
	end

	state.orbitTarget = pl
	setOrbitHighlight(pl)
	updateHUD()
end

-- AllPlayer toggle
if state.__FollowUpd.ui.allBtn and not state.__FollowUpd.ui.allBtn:GetAttribute("AP_Wired") then
	state.__FollowUpd.ui.allBtn:SetAttribute("AP_Wired", true)
	state.__FollowUpd.ui.allBtn.MouseButton1Click:Connect(function()
		state.orbitAllPlayersOn = not state.orbitAllPlayersOn
		state.__FollowUpd.RefreshUI()

		if state.orbitAllPlayersOn then
			-- включаем follow, если выключен
			if not state.orbitOn then
				Orbit_Set(true)
			end
			state.__FollowUpd.StartCycle()
		else
			state.__FollowUpd.StopCycle()
		end

		updateHUD()
	end)
end

-- Delay box apply
if state.__FollowUpd.ui.delayBox and not state.__FollowUpd.ui.delayBox:GetAttribute("AP_Wired") then
	state.__FollowUpd.ui.delayBox:SetAttribute("AP_Wired", true)
	state.__FollowUpd.ui.delayBox.FocusLost:Connect(function(enterPressed)
		if not enterPressed then return end
		state.orbitAllPlayersDelay = state.__FollowUpd.Clamp(state.__FollowUpd.ui.delayBox.Text, 0.05, 30, state.orbitAllPlayersDelay)
		state.__FollowUpd.RefreshUI()
		updateHUD()
	end)
end

-- Name lock button + Enter
if state.__FollowUpd.ui.nameBtn and not state.__FollowUpd.ui.nameBtn:GetAttribute("AP_Wired") then
	state.__FollowUpd.ui.nameBtn:SetAttribute("AP_Wired", true)
	state.__FollowUpd.ui.nameBtn.MouseButton1Click:Connect(function()
		state.__FollowUpd.LockByName(state.__FollowUpd.ui.nameBox and state.__FollowUpd.ui.nameBox.Text or "")
	end)
end

if state.__FollowUpd.ui.nameBox and not state.__FollowUpd.ui.nameBox:GetAttribute("AP_Wired") then
	state.__FollowUpd.ui.nameBox:SetAttribute("AP_Wired", true)
	state.__FollowUpd.ui.nameBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			state.__FollowUpd.LockByName(state.__FollowUpd.ui.nameBox.Text or "")
		end
	end)
end

-- HUD улучшение (чтобы Orbit строка показывала AllPlayer/Delay)
if not state.__FollowUpd.patchedHUD then
	state.__FollowUpd.patchedHUD = true
	state.__FollowUpd._oldHUD = state.__FollowUpd._oldHUD or updateHUD

	updateHUD = function()
		state.__FollowUpd._oldHUD()

		if hudLines and hudLines["Orbit"] then
			local tgtName = "None"
			if state.orbitTarget then
				if state.orbitTarget:IsA("Player") then
					tgtName = state.orbitTarget.Name
				elseif state.orbitTarget:IsA("Model") then
					tgtName = state.orbitTarget.Name .. " [NPC]"
				end
			end

			local ap = state.orbitAllPlayersOn and "ON" or "OFF"
			local d = tonumber(state.orbitAllPlayersDelay) or 1
			hudLines["Orbit"].Text = ("Orbit: %s | Target=%s | AllPlayer=%s | Delay=%.2fs"):format(onOff(state.orbitOn), tgtName, ap, d)
			colorize(hudLines["Orbit"], state.orbitOn)
		end
	end
end

-- init
state.__FollowUpd.RefreshUI()
updateHUD()



-- поднять Follow-настройки выше (перед остальными кнопками Player)
do
	local n = -60 -- отрицательные = выше тех, у кого 0

	if btnOrbit then btnOrbit.LayoutOrder = n; n += 1 end
	if btnOrbitMode then btnOrbitMode.LayoutOrder = n; n += 1 end

	if orbitSpeedSlider and orbitSpeedSlider.Holder then orbitSpeedSlider.Holder.LayoutOrder = n; n += 1 end
	if orbitDistSlider  and orbitDistSlider.Holder  then orbitDistSlider.Holder.LayoutOrder  = n; n += 1 end

	if state.__FollowUpd and state.__FollowUpd.ui then
		if state.__FollowUpd.ui.allRow then state.__FollowUpd.ui.allRow.LayoutOrder = n; n += 1 end
		if state.__FollowUpd.ui.nameRow then state.__FollowUpd.ui.nameRow.LayoutOrder = n; n += 1 end
	end
end













--========================================================
-- CLICKFLING + NICKFLING + TABLEPLAYERS (SAFE, NO LAYOUTORDER)
--========================================================

state.__AP_CF = state.__AP_CF or {}
local CF = state.__AP_CF

CF.mode = CF.mode or "OFF" -- OFF | Players | All
CF.dur = tonumber(CF.dur) or 0.8



CF.baseCF = CF.baseCF or nil -- фиксируется ТОЛЬКО при включении режима
CF.running = CF.running == true
CF.token = CF.token or nil

CF.ui = CF.ui or {}
CF.tpui = CF.tpui or {}





CF.moveLeadMinSpeed = tonumber(CF.moveLeadMinSpeed) or 1.0

CF.moveLeadFlat = tonumber(CF.moveLeadFlat) or 6   -- вперёд/вбок
CF.moveLeadUp = tonumber(CF.moveLeadUp) or 6       -- если цель летит вверх
CF.moveLeadDown = tonumber(CF.moveLeadDown) or 5   -- если цель падает вниз

CF.moveLeadYThreshold = tonumber(CF.moveLeadYThreshold) or 1.0




-- ---------- helpers ----------
function CF_parseNum(s)
	s = tostring(s or ""):gsub(",", ".")
	return tonumber(s)
end

function CF_getDur()
	if CF.ui.durBox then
		local txt = tostring(CF.ui.durBox.Text or ""):lower():gsub("%s+", "")

		if txt == "inf" or txt == "infinity" or txt == "беск" or txt == "infinite" then
			CF.dur = math.huge
		else
			local v = tonumber(txt)
			if v then
				CF.dur = v
			end
		end
	end

	if CF.dur ~= math.huge then
		CF.dur = math.max(0.05, tonumber(CF.dur) or 0.18)
	end

	if CF.ui.durBox then
		CF.ui.durBox.Text = (CF.dur == math.huge) and "INF" or tostring(CF.dur)
	end

	return CF.dur
end

function CF_setModeText()
	if CF.ui.modeBtn then
		CF.ui.modeBtn.Text = ("ClickFling Mode: %s"):format(CF.mode)
		setBtnOn(CF.ui.modeBtn, CF.mode ~= "OFF")
	end
end

function CF_fillNick(nick)
	nick = tostring(nick or "")

	-- TP panel (если есть)
	if tpPlayerBox then tpPlayerBox.Text = nick end

	-- Follow patch (если есть)
	if state.__FollowUpd and state.__FollowUpd.ui and state.__FollowUpd.ui.nameBox then
		state.__FollowUpd.ui.nameBox.Text = nick
	end

	-- NickFling box
	if CF.ui.nickBox then CF.ui.nickBox.Text = nick end
end

function CF_getPlayerFromPart(part)
	if not part then return nil end
	local m = part:FindFirstAncestorOfClass("Model")
	if not m then return nil end
	return Players:GetPlayerFromCharacter(m)
end

function CF_getTargetPos_All(targetPart, fallbackPos)
	-- пытаемся получить "живую" позицию цели
	if targetPart and targetPart.Parent then
		if targetPart:IsA("BasePart") then
			return targetPart.Position
		end
		local m = targetPart:FindFirstAncestorOfClass("Model")
		if m then
			local r = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
			if r and r:IsA("BasePart") then
				return r.Position
			end
		end
	end
	return fallbackPos
end

function CF_stop()
	CF.token = nil
	CF.running = false
	CF_restoreConflicts()
end

-- отключаем штуки, которые часто мешают флингу/контакту
function CF_disableConflicts()
	CF._restore = CF._restore or {}

	-- NoClip мешает контакту
	CF._restore.noClip = (state.noClipOn == true)
	if CF._restore.noClip and noClipOff then
		pcall(noClipOff)
	end

	-- AntiPush выключаем ТОЛЬКО на время реального ClickFling-запуска
	CF._restore.antiPush = (state.antiPushOn == true)
	if CF._restore.antiPush and state.__AP2 and state.__AP2.Set then
		pcall(function()
			state.__AP2.Set(false)
		end)
	end
end

CF_restoreConflicts=function()
	if not CF._restore then return end

	if CF._restore.noClip and noClipOn then
		pcall(noClipOn)
	end

	if CF._restore.antiPush and state.__AP2 and state.__AP2.Set then
		pcall(function()
			state.__AP2.Set(true)
		end)
	end

	CF._restore = nil
end

function CF_start(getPosFn, getVelFn)
	if CF.running then return end

	local hrp = getHRP(getChar())
	local hum = getHumanoid(getChar())
	if not (hrp and hum) then return end

	local runBase = hrp.CFrame
	CF.runBaseCF = runBase

	local dur = CF_getDur()

	CF_disableConflicts()

	CF.running = true
	local token = {}
	CF.token = token

	local t0 = time()

	local ring = {
		Vector3.new( 0.10, 0.00,  0.00),
		Vector3.new(-0.10, 0.00,  0.00),
		Vector3.new( 0.00, 0.00,  0.10),
		Vector3.new( 0.00, 0.00, -0.10),
		Vector3.new( 0.06, 0.12,  0.06),
		Vector3.new(-0.06, 0.12, -0.06),
		Vector3.new( 0.00, 0.20,  0.00),
	}

	local idx = 0
	local snapAcc = 0

	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if CF.token ~= token then
			if conn then conn:Disconnect() end
			CF_stop()
			return
		end

		local r = getHRP(getChar())
		if not r then return end

		local pos = getPosFn and getPosFn() or nil
		local vel = getVelFn and getVelFn() or Vector3.zero

		if pos then
			local predicted = pos

			if vel.Magnitude >= (CF.moveLeadMinSpeed or 1.0) then
				local flat = Vector3.new(vel.X, 0, vel.Z)
				local flatOffset = Vector3.zero

				if flat.Magnitude > 0.001 then
					local extra = math.clamp(flat.Magnitude * 0.03, 0, 2.5)
					flatOffset = flat.Unit * ((CF.moveLeadFlat or 2.5) + extra)
				end

				local yOffset = 0
				if vel.Y > (CF.moveLeadYThreshold or 1.0) then
					yOffset = (CF.moveLeadUp or 2.0)
				elseif vel.Y < -(CF.moveLeadYThreshold or 1.0) then
					yOffset = -(CF.moveLeadDown or 3.0)
				end

				predicted = pos + flatOffset + Vector3.new(0, yOffset, 0)
			end

			idx = (idx % #ring) + 1
			local off = ring[idx]

			local j = 0.015
			off = off + Vector3.new((math.random() - 0.5) * j, (math.random() - 0.5) * j, (math.random() - 0.5) * j)

			local attackPos = predicted + off
			local toAttack = attackPos - r.Position
			local lookCF = CFrame.lookAt(attackPos, predicted)

			local s = math.clamp(tonumber(state.flingSpeed) or 300, 1, 10000)
			local attackVel = math.clamp(s * 3.3, 180, 1200)
			local spinY = math.clamp(s * 2.8, 140, 35000)
			local spinXZ = math.clamp(s * 0.65, 0, 9000)

			-- не спамим CFrame каждый тик, чтобы сервер успевал видеть контакт
			snapAcc += dt
			if snapAcc >= (CF.snapDt or 0.03) then
				snapAcc = 0
				r.CFrame = lookCF * CFrame.Angles(0, 0, math.rad(90))
			end

			if toAttack.Magnitude > 0.001 then
				r.AssemblyLinearVelocity = toAttack.Unit * attackVel
			end

			r.AssemblyAngularVelocity = Vector3.new(spinXZ, spinY, spinXZ)
		end

		if (time() - t0) >= dur then
			if conn then conn:Disconnect() end
			CF_stop()
			CF_restoreConflicts()

			local r2 = getHRP(getChar())
			if r2 then
				r2.CFrame = runBase
				r2.AssemblyLinearVelocity = Vector3.zero
				r2.AssemblyAngularVelocity = Vector3.zero
			end

			local h2 = getHumanoid(getChar())
			if h2 then
				pcall(function()
					h2:ChangeState(Enum.HumanoidStateType.GettingUp)
				end)
			end
		end
	end)
end

function CF_activateMode(nextMode)
	CF.mode = nextMode

	if CF.mode == "OFF" then
		CF_stop()
	end

	CF_setModeText()
	CF_getDur()
	updateHUD()
end

--========================================================
-- UI (в Player секции) — НИЧЕГО НЕ ДВИГАЕМ LayoutOrder
--========================================================

-- cleanup старых дублей если вдруг были
do
	if playerWrap then
		local a = playerWrap:FindFirstChild("AP_ClickFlingRow")
		local b = playerWrap:FindFirstChild("AP_NickFlingRow")
		if a then a:Destroy() end
		if b then b:Destroy() end
	end
end

if playerWrap then
	-- Row 1: Mode + Dur
	local row1 = mk("Frame", {Name="AP_ClickFlingRow", BackgroundTransparency=1, Size=UDim2.new(1,0,0,34)}, playerWrap)
	CF.ui.rowMode = row1

	CF.ui.modeBtn = makeButton(row1, "ClickFling Mode: OFF")
	CF.ui.modeBtn.Size = UDim2.new(0.70, -6, 1, 0)
	CF.ui.modeBtn.Position = UDim2.new(0,0,0,0)

	CF.ui.durBox = mk("TextBox", {
		ClearTextOnFocus = false,
		Text = tostring(CF.dur),
		PlaceholderText = "sec (0.5)",
		Font = fontik,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundColor3 = Color3.fromRGB(30,30,36),
		TextColor3 = Color3.fromRGB(235,235,235),
		Size = UDim2.new(0.30, 0, 1, 0),
		Position = UDim2.new(0.70, 6, 0, 0),
	}, row1)
	mk("UICorner", {CornerRadius = UDim.new(0, 10)}, CF.ui.durBox)
	mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75,75,90), Transparency = 0.45}, CF.ui.durBox)

	-- Row 2: Nick + GO
	local row2 = mk("Frame", {Name="AP_NickFlingRow", BackgroundTransparency=1, Size=UDim2.new(1,0,0,34)}, playerWrap)
	CF.ui.rowNick = row2

	CF.ui.nickBox = mk("TextBox", {
		ClearTextOnFocus = false,
		Text = "",
		PlaceholderText = "Nick fling...",
		Font = fontik,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(30,30,36),
		TextColor3 = Color3.fromRGB(235,235,235),
		Size = UDim2.new(0.70, -6, 1, 0),
		Position = UDim2.new(0,0,0,0),
	}, row2)
	mk("UICorner", {CornerRadius = UDim.new(0, 10)}, CF.ui.nickBox)
	mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75,75,90), Transparency = 0.45}, CF.ui.nickBox)

	CF.ui.goBtn = mk("TextButton", {
		Text = "Enter",
		Font = fontik,
		TextSize = 14,
		AutoButtonColor = true,
		BackgroundColor3 = Color3.fromRGB(40,52,90),
		TextColor3 = Color3.fromRGB(245,245,255),
		Size = UDim2.new(0.30, 0, 1, 0),
		Position = UDim2.new(0.70, 6, 0, 0),
	}, row2)
	mk("UICorner", {CornerRadius = UDim.new(0, 10)}, CF.ui.goBtn)
	mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75,75,90), Transparency = 0.25}, CF.ui.goBtn)
end

-- wiring UI (важно: dur парсим ВСЕГДА на FocusLost, не только Enter)
if CF.ui.modeBtn and not CF.ui.modeBtn:GetAttribute("AP_Wired") then
	CF.ui.modeBtn:SetAttribute("AP_Wired", true)
	CF.ui.modeBtn.MouseButton1Click:Connect(function()
		if CF.mode == "OFF" then
			CF_activateMode("Players")
		elseif CF.mode == "Players" then
			CF_activateMode("All")
		else
			CF_activateMode("OFF")
		end
	end)
end

if CF.ui.durBox and not CF.ui.durBox:GetAttribute("AP_Wired") then
	CF.ui.durBox:SetAttribute("AP_Wired", true)
	CF.ui.durBox.FocusLost:Connect(function()
		CF_getDur()
	end)
end

function CF_goNick()
	CF_getDur()

	local name = CF.ui.nickBox and CF.ui.nickBox.Text or ""
	local pl = findPlayerByText(name)
	if not pl or pl == LP then return end
	CF_fillNick(pl.Name)

	local function getPos()
		local th = getHRPPlayer(pl)
		return th and th.Position or nil
	end

	local function getVel()
		local th = getHRPPlayer(pl)
		return th and th.AssemblyLinearVelocity or Vector3.zero
	end

	CF_start(getPos, getVel)
end

if CF.ui.goBtn and not CF.ui.goBtn:GetAttribute("AP_Wired") then
	CF.ui.goBtn:SetAttribute("AP_Wired", true)
	CF.ui.goBtn.MouseButton1Click:Connect(CF_goNick)
end
if CF.ui.nickBox and not CF.ui.nickBox:GetAttribute("AP_Wired") then
	CF.ui.nickBox:SetAttribute("AP_Wired", true)
	CF.ui.nickBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then CF_goNick() end
	end)
end

CF_setModeText()
CF_getDur()

--========================================================
-- Click handler (Players/All) — не конфликтуем с твоим TP Click
--========================================================
if not CF.clickWired then
	CF.clickWired = true

	mouse.Button1Down:Connect(function()
		if UIS:GetFocusedTextBox() then return end
		if hasEquippedTool() then return end
		if CF.mode == "OFF" then return end
		if CF.running then return end

		-- если включён Click TP — не мешаем
		if state.tpOn and state.tpMode == "Click" then return end

		CF_getDur()

		local t = mouse.Target
		if not t then return end

		if CF.mode == "Players" then
			local pl = CF_getPlayerFromPart(t)
			if not pl or pl == LP then return end

			CF_fillNick(pl.Name)

			local function getPos()
				local th = getHRPPlayer(pl)
				return th and th.Position or nil
			end

			local function getVel()
				local th = getHRPPlayer(pl)
				return th and th.AssemblyLinearVelocity or Vector3.zero
			end

			CF_start(getPos, getVel)
			return
		end

		if CF.mode == "All" then
			local hit = mouse.Hit
			local fallbackPos = hit and hit.Position or nil
			local function getPos()
				return CF_getTargetPos_All(t, fallbackPos)
			end

			local function getVel()
				if t and t.Parent then
					if t:IsA("BasePart") then
						return t.AssemblyLinearVelocity
					end

					local m = t:FindFirstAncestorOfClass("Model")
					if m then
						local r = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
						if r and r:IsA("BasePart") then
							return r.AssemblyLinearVelocity
						end
					end
				end
				return Vector3.zero
			end

			CF_start(getPos, getVel)
			return
		end
	end)
end

--========================================================
-- TABLEPLAYERS (не трогаем LayoutOrder, только создаём панель)
--========================================================
state.tablePlayersOn = (state.tablePlayersOn == true)
state.__AP_TP = state.__AP_TP or {}
local TP = state.__AP_TP
TP.ui = TP.ui or {}

-- cleanup old panel duplicates
do
	if gui then
		local old = gui:FindFirstChild("AP_TablePlayersPanel_SAFE")
		if old then old:Destroy() end
	end
end

if settingsWrap and not TP.ui.btn then
	TP.ui.btn = makeButton(settingsWrap, "TablePlayers (toggle)")
end

if gui and not TP.ui.panel then
	TP.ui.panel = mk("Frame", {
		Name = "AP_TablePlayersPanel_SAFE",
		Visible = false,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(270, 380),
		BackgroundColor3 = Color3.fromRGB(16,16,18),
		BackgroundTransparency = 0.12,
	}, gui)
	mk("UICorner", {CornerRadius = UDim.new(0, 12)}, TP.ui.panel)
	mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(80,80,95), Transparency = 0.35}, TP.ui.panel)

	mk("TextLabel", {
		Text = "Players",
		Font = fontik,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(240,240,240),
		Size = UDim2.new(1, -16, 0, 22),
		Position = UDim2.fromOffset(8, 8),
	}, TP.ui.panel)

	TP.ui.scroll = mk("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Size = UDim2.new(1, -16, 1, -40),
		Position = UDim2.fromOffset(8, 32),
		CanvasSize = UDim2.new(0,0,0,0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, TP.ui.panel)

	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, TP.ui.scroll)
end

function TP_refresh()
	local sc = TP.ui.scroll
	if not sc then return end

	for _, ch in ipairs(sc:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end

	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= LP then
			local row = mk("Frame", {
				BackgroundColor3 = Color3.fromRGB(30,30,36),
				Size = UDim2.new(1, 0, 0, 42),
			}, sc)
			mk("UICorner", {CornerRadius = UDim.new(0, 10)}, row)
			mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75,75,90), Transparency = 0.45}, row)

			local img = mk("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(36, 36),
				Position = UDim2.fromOffset(6, 3),
				Image = "",
			}, row)
			mk("UICorner", {CornerRadius = UDim.new(1, 0)}, img)

			local btn = mk("TextButton", {
				BackgroundTransparency = 1,
				Text = pl.Name,
				Font = fontik,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Color3.fromRGB(235,235,235),
				Size = UDim2.new(1, -54, 1, 0),
				Position = UDim2.fromOffset(48, 0),
			}, row)

			task.spawn(function()
				local ok, thumb = pcall(function()
					return Players:GetUserThumbnailAsync(pl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
				end)
				if ok and img and img.Parent then img.Image = thumb end

				local isFriend = false
				pcall(function() isFriend = LP:IsFriendsWith(pl.UserId) end)
				if btn and btn.Parent then
					btn.TextColor3 = isFriend and Color3.fromRGB(120,255,140) or Color3.fromRGB(235,235,235)
				end
			end)

			btn.MouseButton1Click:Connect(function()
				CF_fillNick(pl.Name)
			end)
		end
	end
end

if TP.ui.btn and not TP.ui.btn:GetAttribute("AP_Wired") then
	TP.ui.btn:SetAttribute("AP_Wired", true)
	TP.ui.btn.MouseButton1Click:Connect(function()
		state.tablePlayersOn = not state.tablePlayersOn

		setBtnOn(TP.ui.btn, state.tablePlayersOn)

		if TP.ui.panel then
			TP.ui.panel.Visible = state.tablePlayersOn
		end

		if state.tablePlayersOn then
			TP_refresh()
		end
	end)
end

Players.PlayerAdded:Connect(function()
	if state.tablePlayersOn then task.delay(0.2, TP_refresh) end
end)
Players.PlayerRemoving:Connect(function()
	if state.tablePlayersOn then task.delay(0.2, TP_refresh) end
end)

if TP.ui.panel then
	TP.ui.panel.Visible = state.tablePlayersOn
end
if state.tablePlayersOn then
	task.defer(TP_refresh)
end





task.defer(function()
	task.wait(0.25) -- даём UI построиться

	-- поднимаем ТОЛЬКО элементы флинга
	local n = -220
	local function bump(obj)
		if obj and obj:IsA("GuiObject") then
			obj.LayoutOrder = n
			n += 1
		end
	end

	-- твои существующие элементы флинга
	bump(btnFling)
	bump(btnFlingMode)
	if flingSlider and flingSlider.Holder then
		bump(flingSlider.Holder)
	end

	-- новые строки из моего "чистого" патча
	if state.__AP_CF and state.__AP_CF.ui then
		bump(state.__AP_CF.ui.rowMode) -- AP_ClickFlingRow
		bump(state.__AP_CF.ui.rowNick) -- AP_NickFlingRow
	end
end)













------------------------------------------------------------
-- ClickFling target highlight (Players + All) + auto clear after return
-- Uses your StartBlinkHighlight / StopBlink
------------------------------------------------------------
do
	local CF = state.__AP_CF
	if not CF then return end

	CF.__hl = CF.__hl or {inst=nil, obj=nil}

	local function CF_ClearHL()
		pcall(function() StopBlink("CF_TARGET") end)
		if CF.__hl.inst then pcall(function() CF.__hl.inst:Destroy() end) end
		CF.__hl.inst = nil
		CF.__hl.obj = nil
	end

	local function CF_SetHL(targetInst: Instance)
		CF_ClearHL()
		if not targetInst then return end

		-- подсвечиваем модель, если есть (для блоков/моделей), иначе сам part
		local parentForHL = targetInst
		if targetInst:IsA("BasePart") then
			local m = targetInst:FindFirstAncestorOfClass("Model")
			-- не подсвечиваем игрока через "модель мира" (у игрока есть PlayerFromCharacter)
			if m and m.Parent == Workspace and Players:GetPlayerFromCharacter(m) == nil then
				parentForHL = m
			end
		elseif targetInst:IsA("Model") then
			parentForHL = targetInst
		end

		local hl = Instance.new("Highlight")
		hl.Name = "CF_TargetHL"
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = parentForHL

		-- кислотно-зелёный (обводка) + мигающая заливка
		hl.OutlineTransparency = 0
		hl.FillTransparency = 0.85

		local acid = Color3.fromRGB(120, 255, 80)
		hl.FillColor = acid
		hl.OutlineColor = acid

		if StartBlinkHighlight then
			StartBlinkHighlight("CF_TARGET", hl, acid, 0.12, 0.88, 6)
		end

		CF.__hl.inst = hl
		CF.__hl.obj = parentForHL
	end

	-- 1) Подсветка при клике по цели
	if not CF.__hlClickWired then
		CF.__hlClickWired = true
		mouse.Button1Down:Connect(function()
			if UIS:GetFocusedTextBox() then return end
			if hasEquippedTool() then return end
			if not CF or CF.mode == "OFF" then return end

			local t = mouse.Target
			if not t then return end

			if CF.mode == "Players" then
				local m = t:FindFirstAncestorOfClass("Model")
				local pl = m and Players:GetPlayerFromCharacter(m) or nil
				if pl and pl ~= LP and pl.Character then
					CF_SetHL(pl.Character) -- подсветить персонажа
				end
			elseif CF.mode == "All" then
				CF_SetHL(t) -- подсветить блок/модель
			end
		end)
	end

	-- 2) Подсветка при NickFling (GO / Enter)
	function hlFromNick()
		if not (CF.ui and CF.ui.nickBox) then return end
		local name = CF.ui.nickBox.Text or ""
		local pl = findPlayerByText(name)
		if pl and pl ~= LP and pl.Character then
			CF_SetHL(pl.Character)
		end
	end

	if CF.ui and CF.ui.goBtn and not CF.ui.goBtn:GetAttribute("CF_HL_WIRED") then
		CF.ui.goBtn:SetAttribute("CF_HL_WIRED", true)
		CF.ui.goBtn.MouseButton1Click:Connect(function()
			task.defer(hlFromNick)
		end)
	end

	if CF.ui and CF.ui.nickBox and not CF.ui.nickBox:GetAttribute("CF_HL_WIRED") then
		CF.ui.nickBox:SetAttribute("CF_HL_WIRED", true)
		CF.ui.nickBox.FocusLost:Connect(function(enterPressed)
			if enterPressed then task.defer(hlFromNick) end
		end)
	end

	-- 3) Авто-очистка после возврата (когда цикл закончился)
	if not CF.__hlAutoClearWired then
		CF.__hlAutoClearWired = true
		local wasRunning = CF.running == true
		RunService.Heartbeat:Connect(function()
			local nowRunning = CF.running == true

			-- закончили флинг-цикл -> убрать подсветку
			if wasRunning and (not nowRunning) then
				CF_ClearHL()
			end

			-- если режим OFF и не бежит цикл -> тоже чистим
			if (CF.mode == "OFF") and (not nowRunning) and CF.__hl.inst then
				CF_ClearHL()
			end

			wasRunning = nowRunning
		end)
	end
end
















local btnTPose = makeButton(playerWrap, "Tpose")











--========================================================
-- BIG UPDATE PATCH (SAFE)
-- UI: categories + draggable + hover/click tweens + splash
-- PHYS: NoImpact during Fly/Spin/Fling (no collision/touch), but not during ClickFling runs
--========================================================

function AP_BigUpdate()
	------------------------------------------------------------
	-- 0) Splash loading (one-time)
	------------------------------------------------------------
	do
		if gui and not gui:GetAttribute("AP_SplashDone") then
			gui:SetAttribute("AP_SplashDone", true)

			-- hide menu during splash
			if menuBtn then menuBtn.Visible = false end
			if panel then panel.Visible = false end
			if hud then hud.Visible = false end
			if watermark then watermark.Visible = false end
			if coordBar then coordBar.Visible = false end

			local splash = Instance.new("Frame")
			splash.Name = "AP_Splash"
			splash.BackgroundColor3 = Color3.fromRGB(0,0,0)
			splash.BackgroundTransparency = 0.35
			splash.Size = UDim2.fromScale(1,1)
			splash.Parent = gui

			local logo = Instance.new("ImageLabel")
			logo.Name = "SplashLogo"
			logo.BackgroundTransparency = 1
			logo.Image = LOGO_IMAGE
			logo.AnchorPoint = Vector2.new(0.5, 0.5)
			logo.Position = UDim2.fromScale(0.5, 0.36)
			logo.Size = UDim2.fromOffset(140, 140)
			logo.ScaleType = Enum.ScaleType.Fit
			logo.Parent = splash

			local logoText = Instance.new("TextLabel")
			logoText.BackgroundTransparency = 1
			logoText.Text = "NURMENAL"
			logoText.Font = fontik
			logoText.TextSize = 30
			logoText.TextColor3 = Color3.fromRGB(245,245,255)
			logoText.TextStrokeTransparency = 0.65
			logoText.AnchorPoint = Vector2.new(0.5, 0.5)
			logoText.Position = UDim2.fromScale(0.5, 0.50)
			logoText.Size = UDim2.fromOffset(260, 40)
			logoText.Parent = splash

			local barBack = Instance.new("Frame")
			barBack.BackgroundColor3 = Color3.fromRGB(20,20,24)
			barBack.BackgroundTransparency = 0.15
			barBack.AnchorPoint = Vector2.new(0.5, 0.5)
			barBack.Position = UDim2.fromScale(0.5, 0.56)
			barBack.Size = UDim2.fromOffset(360, 12)
			barBack.Parent = splash
			Instance.new("UICorner", barBack).CornerRadius = UDim.new(0, 8)

			local barFill = Instance.new("Frame")
			barFill.BackgroundColor3 = Color3.fromRGB(200,200,215)
			barFill.Size = UDim2.new(0,0,1,0)
			barFill.Parent = barBack
			Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 8)

			local function tw(o, ti, props)
				local t = TweenService:Create(o, ti, props)
				t:Play()
				return t
			end

			-- quick load fill
			tw(barFill, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1,0,1,0)})

			-- fade out splash
			task.delay(0.90, function()
				if not splash.Parent then return end
				tw(splash, TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
				tw(logo, TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 1})
				tw(logoText, TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1, TextStrokeTransparency = 1})
				tw(barBack, TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
				tw(barFill, TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})

				task.delay(0.32, function()
					if splash then splash:Destroy() end

					if menuBtn then menuBtn.Visible = true end
					if watermark then watermark.Visible = true end
					if hud then hud.Visible = not state.hideAdminStatic end
					-- panel остаётся как было (по клику)
				end)
			end)
		end
	end

	------------------------------------------------------------
	-- 1) Panel wider + viewport-safe sizing (doesn't touch old updatePanelSize)
	------------------------------------------------------------
	do
		local function applySize()
			if not panel then return end
			local cam = Workspace.CurrentCamera
			local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
			local w = math.clamp(math.floor(vp.X * 0.42), 360, 560)
			local h = math.clamp(math.floor(vp.Y * 0.74), 320, 620)
			panel.Size = UDim2.fromOffset(w, h)
		end
		applySize()
		if Workspace.CurrentCamera then
			Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				task.defer(applySize) -- чтобы наш размер победил, если старый коллбек тоже сработает
			end)
		end
	end

	------------------------------------------------------------
	-- 2) Hover/Click animations for buttons (UIScale tween)
	------------------------------------------------------------
	do
		local function applyFX(btn)
			if not btn:IsA("TextButton") then return end
			if btn:GetAttribute("AP_FX") then return end
			btn:SetAttribute("AP_FX", true)

			local sc = Instance.new("UIScale")
			sc.Scale = 1
			sc.Parent = btn

			local baseStroke = btn:FindFirstChildOfClass("UIStroke")
			local function twScale(v, t)
				TweenService:Create(sc, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = v}):Play()
			end

			btn.MouseEnter:Connect(function()
				twScale(1.02, 0.10)
				if baseStroke then
					TweenService:Create(baseStroke, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.25}):Play()
				end
			end)
			btn.MouseLeave:Connect(function()
				twScale(1.00, 0.12)
				if baseStroke then
					TweenService:Create(baseStroke, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.45}):Play()
				end
			end)
			btn.MouseButton1Down:Connect(function()
				twScale(0.97, 0.06)
			end)
			btn.MouseButton1Up:Connect(function()
				twScale(1.02, 0.10)
			end)
		end

		if gui then
			for _, inst in ipairs(gui:GetDescendants()) do
				if inst:IsA("TextButton") then
					applyFX(inst)
				end
			end
		end
	end

	------------------------------------------------------------
	-- 3) Draggable panel (drag by header zone)
	------------------------------------------------------------
	do
		if panel and not panel:GetAttribute("AP_Draggable") then
			panel:SetAttribute("AP_Draggable", true)

			local dragZone = Instance.new("Frame")
			dragZone.Name = "AP_DragZone"
			dragZone.BackgroundTransparency = 1
			dragZone.Size = UDim2.new(1, 0, 0, 54)
			dragZone.Position = UDim2.fromOffset(0, 0)
			dragZone.Parent = panel

			local dragging = false
			local startMouse = Vector2.zero
			local startCenter = Vector2.zero

			local function getCenterUDim()
				-- panel.Position у тебя AnchorPoint 0.5,0.5
				local vp = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
				local pos = panel.Position
				local cx = pos.X.Scale * vp.X + pos.X.Offset
				local cy = pos.Y.Scale * vp.Y + pos.Y.Offset
				return Vector2.new(cx, cy)
			end

			local function setCenter(center)
				local vp = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
				local half = panel.AbsoluteSize * 0.5
				local cx = math.clamp(center.X, half.X + 8, vp.X - half.X - 8)
				local cy = math.clamp(center.Y, half.Y + 8, vp.Y - half.Y - 8)
				panel.Position = UDim2.fromOffset(cx, cy)
			end

			dragZone.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
				dragging = true
				startMouse = input.Position
				startCenter = getCenterUDim()
			end)

			UIS.InputChanged:Connect(function(input)
				if not dragging then return end
				if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
				local delta = input.Position - startMouse
				setCenter(startCenter + Vector2.new(delta.X, delta.Y))
			end)

			UIS.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
		end
	end

	------------------------------------------------------------
	-- 4) Categories inside PlayerWrap (Fling / Follow / TP / Movement / Tools / Misc)
	-- No LayoutOrder hacks: просто группировка в контейнеры
	------------------------------------------------------------
	do
		if not (playerWrap and mk and makeButton) then return end
		if playerWrap:FindFirstChild("AP_CategoriesRoot") then return end

		local root = Instance.new("Frame")
		root.Name = "AP_CategoriesRoot"
		root.BackgroundTransparency = 1
		root.Size = UDim2.new(1, 0, 0, 1)
		root.AutomaticSize = Enum.AutomaticSize.Y
		root.Parent = playerWrap

		-- переносим старые элементы в root, НО layout не трогаем
		for _, ch in ipairs(playerWrap:GetChildren()) do
			if ch ~= root and not ch:IsA("UIListLayout") then
				ch.Parent = root
			end
		end

		-- ВАЖНО: новый UIListLayout НЕ создаём,
		-- потому что он уже есть в playerWrap

		local function makeCat(title)
			local cat = Instance.new("Frame")
			cat.BackgroundColor3 = Color3.fromRGB(22,22,26)
			cat.Size = UDim2.new(1, 0, 0, 1)
			cat.AutomaticSize = Enum.AutomaticSize.Y
			cat.Parent = playerWrap
			Instance.new("UICorner", cat).CornerRadius = UDim.new(0, 12)
			local st = Instance.new("UIStroke", cat)
			st.Thickness = 1
			st.Color = Color3.fromRGB(70,70,85)
			st.Transparency = 0.35

			local head = Instance.new("TextButton")
			head.Text = "▼  "..title
			head.Font = fontik
			head.TextSize = 15
			head.TextXAlignment = Enum.TextXAlignment.Left
			head.AutoButtonColor = true
			head.BackgroundColor3 = Color3.fromRGB(30,30,36)
			head.TextColor3 = Color3.fromRGB(235,235,235)
			head.Size = UDim2.new(1, -16, 0, 34)
			head.Position = UDim2.fromOffset(8, 8)
			head.Parent = cat
			Instance.new("UICorner", head).CornerRadius = UDim.new(0, 10)
			local st2 = Instance.new("UIStroke", head)
			st2.Thickness = 1
			st2.Color = Color3.fromRGB(75,75,90)
			st2.Transparency = 0.45

			local content = Instance.new("Frame")
			content.Name = "Content"
			content.BackgroundTransparency = 1
			content.Position = UDim2.fromOffset(8, 46)
			content.Size = UDim2.new(1, -16, 0, 1)
			content.AutomaticSize = Enum.AutomaticSize.Y
			content.Parent = cat

			local ll = Instance.new("UIListLayout")
			ll.Padding = UDim.new(0, 6)
			ll.SortOrder = Enum.SortOrder.LayoutOrder
			ll.Parent = content

			local opened = true
			head.MouseButton1Click:Connect(function()
				opened = not opened
				content.Visible = opened
				head.Text = (opened and "▼  " or "►  ")..title
			end)

			-- применим FX на header
			if head and head:IsA("TextButton") and not head:GetAttribute("AP_FX") then
				-- reuse global FX via descendants pass (already ran), but just in case:
				head:SetAttribute("AP_FX", true)
				local sc = Instance.new("UIScale", head); sc.Scale = 1
				head.MouseEnter:Connect(function() TweenService:Create(sc, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale=1.02}):Play() end)
				head.MouseLeave:Connect(function() TweenService:Create(sc, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale=1.00}):Play() end)
				head.MouseButton1Down:Connect(function() TweenService:Create(sc, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale=0.98}):Play() end)
				head.MouseButton1Up:Connect(function() TweenService:Create(sc, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale=1.02}):Play() end)
			end

			return content
		end

		local C_MOVE   = makeCat("Movement")
		local C_TP     = makeCat("Teleport")
		local C_FOLLOW = makeCat("Follow")
		local C_FLING  = makeCat("Fling")
		local C_TOOLS  = makeCat("Tools")
		local C_MISC   = makeCat("Misc")

		local function moveInto(cat, obj)
			if obj and obj.Parent then obj.Parent = cat end
		end


		-- Movement
		moveInto(C_MOVE, btnBoost)
		moveInto(C_MOVE, (speedSlider and speedSlider.Holder))
		moveInto(C_MOVE, (jumpSlider and jumpSlider.Holder))
		moveInto(C_MOVE, btnFly)
		moveInto(C_MOVE, btnFlyMode)
		moveInto(C_MOVE, btnNoClip)


		-- AntiPush: кнопка + ВСЕ его настройки
		if state.__AP2 and state.__AP2.ui then
			moveInto(C_MOVE, state.__AP2.ui.btn)

			if state.__AP2.ui.thrBox and state.__AP2.ui.thrBox.Parent then
				moveInto(C_MOVE, state.__AP2.ui.thrBox.Parent)
			end

			if state.__AP2.ui.durBox and state.__AP2.ui.durBox.Parent then
				moveInto(C_MOVE, state.__AP2.ui.durBox.Parent)
			end

			if state.__AP2.ui.saveBox and state.__AP2.ui.saveBox.Parent then
				moveInto(C_MOVE, state.__AP2.ui.saveBox.Parent)
			end

			if state.__AP2.ui.indFrame then
				moveInto(C_MOVE, state.__AP2.ui.indFrame)
			end
		end

		-- Teleport
		moveInto(C_TP, btnTP)
		moveInto(C_TP, tpSub)

		-- Follow
		moveInto(C_MISC, btnTPose)
		moveInto(C_FOLLOW, btnOrbit)
		moveInto(C_FOLLOW, btnOrbitMode)
		moveInto(C_FOLLOW, (orbitSpeedSlider and orbitSpeedSlider.Holder))
		moveInto(C_FOLLOW, (orbitDistSlider and orbitDistSlider.Holder))
		if state.__FollowUpd and state.__FollowUpd.ui then
			moveInto(C_FOLLOW, state.__FollowUpd.ui.allRow)
			moveInto(C_FOLLOW, state.__FollowUpd.ui.nameRow)
		end

		-- Fling
		moveInto(C_FLING, btnFling)
		moveInto(C_FLING, btnFlingMode)
		moveInto(C_FLING, (flingSlider and flingSlider.Holder))
		if state.__AP_CF and state.__AP_CF.ui then
			-- твои ClickFling/NickFling строки (если есть)
			moveInto(C_FLING, state.__AP_CF.ui.rowMode)
			moveInto(C_FLING, state.__AP_CF.ui.rowNick)
		end

		-- Tools
		moveInto(C_TOOLS, btnAdminTools)

		-- Misc
		moveInto(C_MISC, btnAutoAim)
		moveInto(C_MISC, btnAutoGG)
		moveInto(C_MISC, btnInvisible)
	end

	------------------------------------------------------------
	-- 5) NO IMPACT (cannot fling/push others) during Fly & manual Spin/Fling
	------------------------------------------------------------
	do
		state.__NoImpact = state.__NoImpact or {}
		local NI = state.__NoImpact
		NI.on = NI.on == true
		NI.saved = NI.saved or {} -- [part] = {c,t,q}
		NI.conn = NI.conn
		NI.charConn = NI.charConn

		local function applyToPart(p, on)
			if not p:IsA("BasePart") then return end
			if on then
				if not NI.saved[p] then
					NI.saved[p] = {c=p.CanCollide, t=p.CanTouch, q=p.CanQuery}
				end
				p.CanCollide = false
				p.CanTouch = false
				p.CanQuery = false
			else
				local s = NI.saved[p]
				if s then
					-- если NoClip включён, collision оставляем false
					p.CanCollide = (state.noClipOn and false) or s.c
					p.CanTouch = s.t
					p.CanQuery = s.q
					NI.saved[p] = nil
				end
			end
		end

		local function setOn(on)
			on = (on == true)
			if NI.on == on then return end
			NI.on = on

			local ch = getChar()
			if ch then
				for _, d in ipairs(ch:GetDescendants()) do
					if d:IsA("BasePart") then
						applyToPart(d, on)
					end
				end
			end

			if NI.conn then NI.conn:Disconnect(); NI.conn = nil end
			if NI.charConn then NI.charConn:Disconnect(); NI.charConn = nil end

			if on then
				NI.charConn = (getChar() and getChar().DescendantAdded:Connect(function(d)
					if d:IsA("BasePart") and NI.on then
						task.defer(function()
							if NI.on and d and d.Parent then
								applyToPart(d, true)
							end
						end)
					end
				end)) or nil
			end
		end

		-- decide desired state:
		-- Fly => NoImpact ON
		-- FlingOn (manual spin/fling) => NoImpact ON
		-- BUT: if ClickFling/NickFling run is active (state.__AP_CF.running) => allow impact (OFF)
		local function updateDesired()
			local clickFlingRunning = (state.__AP_CF and state.__AP_CF.running == true)
			local want =
				(state.flyOn == true)
				or ((state.flingOn == true) and (not clickFlingRunning))

			setOn(want)
		end

		-- hook: wrap flyOn/flyOff and Fling_Set (без правки основного кода)
		if not NI.patched then
			NI.patched = true

			-- wrap fly
			if flyOn and not NI._flyOn then
				NI._flyOn = flyOn
				flyOn = function(...)
					NI._flyOn(...)
					task.defer(updateDesired)
				end
			end
			if flyOff and not NI._flyOff then
				NI._flyOff = flyOff
				flyOff = function(...)
					NI._flyOff(...)
					task.defer(updateDesired)
				end
			end

			-- wrap fling set
			if Fling_Set and not NI._flingSet then
				NI._flingSet = Fling_Set
				Fling_Set = function(on, ...)
					NI._flingSet(on, ...)
					task.defer(updateDesired)
				end
			end

			-- keep updated (если где-то включили/выключили режимы не через наши обёртки)
			NI.conn = RunService.Heartbeat:Connect(function()
				updateDesired()
			end)

			-- respawn safety
			LP.CharacterAdded:Connect(function()
				task.wait(0.25)
				NI.saved = {}
				updateDesired()
			end)
		end

		updateDesired()
	end
end

task.defer(AP_BigUpdate)


spawn(function() 
	task.wait(1)
	game:GetService("StarterGui"):SetCore("SendNotification", { 
		Title = "Nurmenal";
		Text = "Welcome, "..game.Players.LocalPlayer.DisplayName;
		Icon = "rbxassetid://134341920489415"})
	Duration = 5;
end)


















------------------------------------------------------------
-- PLAYER: Tpose (single safe block)
------------------------------------------------------------
local tposeData = {
	conn = nil,
	token = 0,
	savedMotors = nil,
	animateWasDisabled = nil,
}

function stopAllAnimations(hum)
	if not hum then return end
	for _, tr in ipairs(hum:GetPlayingAnimationTracks()) do
		pcall(function()
			tr:Stop(0)
		end)
	end
end

function TPOSE_Save(char)
	tposeData.savedMotors = {}
	for _, m in ipairs(char:GetDescendants()) do
		if m:IsA("Motor6D") then
			tposeData.savedMotors[m] = {
				C0 = m.C0,
				C1 = m.C1,
				Transform = m.Transform,
				DesiredAngle = m.DesiredAngle,
				MaxVelocity = m.MaxVelocity,
			}
		end
	end
end

function TPOSE_Apply(char)
	local hum = getHumanoid(char)
	if not hum then return end

	local animate = char:FindFirstChild("Animate")
	if animate then
		animate.Disabled = true
	end

	stopAllAnimations(hum)
	hum.AutoRotate = true

	if hum.RigType == Enum.HumanoidRigType.R6 then
		local torso = char:FindFirstChild("Torso")
		local rs = torso and torso:FindFirstChild("Right Shoulder")
		local ls = torso and torso:FindFirstChild("Left Shoulder")

		if rs and ls and tposeData.savedMotors and tposeData.savedMotors[rs] and tposeData.savedMotors[ls] then
			rs.C0 = tposeData.savedMotors[rs].C0 * CFrame.Angles(0, 0, math.rad(90))
			ls.C0 = tposeData.savedMotors[ls].C0 * CFrame.Angles(0, 0, math.rad(-90))
		end
	else
		local upper = char:FindFirstChild("UpperTorso")
		local rs = upper and upper:FindFirstChild("RightShoulder")
		local ls = upper and upper:FindFirstChild("LeftShoulder")

		local rua = char:FindFirstChild("RightUpperArm")
		local lua = char:FindFirstChild("LeftUpperArm")
		local re = rua and rua:FindFirstChild("RightElbow")
		local le = lua and lua:FindFirstChild("LeftElbow")

		if rs then rs.Transform = CFrame.Angles(0, 0, math.rad(90)) end
		if ls then ls.Transform = CFrame.Angles(0, 0, math.rad(-90)) end
		if re then re.Transform = CFrame.new() end
		if le then le.Transform = CFrame.new() end
	end
end

function tposeOn()
	if state.tposeOn then return end
	state.tposeOn = true
	setBtnOn(btnTPose, true)

	tposeData.token += 1
	local myToken = tposeData.token

	if tposeData.conn then
		tposeData.conn:Disconnect()
		tposeData.conn = nil
	end

	local char = getChar()
	if not char then return end

	local animate = char:FindFirstChild("Animate")
	tposeData.animateWasDisabled = animate and animate.Disabled or nil

	TPOSE_Save(char)
	TPOSE_Apply(char)

	tposeData.conn = RunService.Heartbeat:Connect(function()
		if not state.tposeOn then return end
		if myToken ~= tposeData.token then return end

		local c = getChar()
		if c then
			TPOSE_Apply(c)
		end
	end)

	updateHUD()
end

function tposeOff()
	if not state.tposeOn then return end
	state.tposeOn = false
	setBtnOn(btnTPose, false)

	tposeData.token += 1

	if tposeData.conn then
		tposeData.conn:Disconnect()
		tposeData.conn = nil
	end

	local char = getChar()
	if char and tposeData.savedMotors then
		for m, s in pairs(tposeData.savedMotors) do
			if m and m.Parent then
				m.C0 = s.C0
				m.C1 = s.C1
				m.Transform = s.Transform
				m.DesiredAngle = s.DesiredAngle
				m.MaxVelocity = s.MaxVelocity
			end
		end

		local animate = char:FindFirstChild("Animate")
		if animate then
			if tposeData.animateWasDisabled ~= nil then
				animate.Disabled = tposeData.animateWasDisabled
			else
				animate.Disabled = false
			end
		end

		local hum = getHumanoid(char)
		if hum then
			hum.AutoRotate = true
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end

	tposeData.savedMotors = nil
	tposeData.animateWasDisabled = nil
	updateHUD()
end













RunService.Heartbeat:Connect(function(dt)
	local hrp = getHRP(getChar())
	if not hrp then return end

	state.__PosHistory.acc += dt
	if state.__PosHistory.acc >= (state.__PosHistory.step or 0.05) then
		state.__PosHistory.acc = 0
		PH_Push(hrp.CFrame)
		PH_Prune()
	end
end)




local rollbackBox = mk("TextBox", {
	ClearTextOnFocus = false,
	Text = tostring(state.rollbackSeconds),
	PlaceholderText = "seconds",
	Font = fontik,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Center,
	BackgroundColor3 = Color3.fromRGB(30,30,36),
	TextColor3 = Color3.fromRGB(235,235,235),
	Size = UDim2.fromOffset(90, 30),
	Position = UDim2.fromOffset(8, 7),
}, rollbackPanel)
mk("UICorner", {CornerRadius = UDim.new(0, 10)}, rollbackBox)
mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75,75,90), Transparency = 0.45}, rollbackBox)

local rollbackBtn = mk("TextButton", {
	Text = "Rollback",
	Font = fontik,
	TextSize = 14,
	BackgroundColor3 = Color3.fromRGB(40,52,90),
	TextColor3 = Color3.fromRGB(245,245,255),
	Size = UDim2.fromOffset(146, 30),
	Position = UDim2.fromOffset(106, 7),
}, rollbackPanel)
mk("UICorner", {CornerRadius = UDim.new(0, 10)}, rollbackBtn)


function doRollback(sec)
	local hrp = getHRP(getChar())
	if not hrp then return end

	local cf = PH_GetAgo(sec)

	-- если не нашли точку на столько секунд назад -> берём самую старую
	if not cf then
		local buf = state.__PosHistory.buf
		if #buf > 0 then
			cf = buf[1].cf
		end
	end

	if not cf then return end

	hrp.CFrame = cf
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
end


rollbackBox.FocusLost:Connect(function(enterPressed)
	if not enterPressed then return end
	local n = tonumber(rollbackBox.Text)
	if n then
		state.rollbackSeconds = math.clamp(n, 0, state.__PosHistory.maxAge or 30)
	end
	rollbackBox.Text = tostring(state.rollbackSeconds)
end)

rollbackBtn.MouseButton1Click:Connect(function()
	doRollback(state.rollbackSeconds)
end)









function getSearchText(item)
	local parts = {}

	if item:IsA("TextButton") or item:IsA("TextLabel") then
		if item.Text and item.Text ~= "" then
			table.insert(parts, item.Text)
		end
	end

	for _, d in ipairs(item:GetDescendants()) do
		if d:IsA("TextButton") or d:IsA("TextLabel") then
			if d.Text and d.Text ~= "" then
				table.insert(parts, d.Text)
			end
		end
	end

	return table.concat(parts, " "):lower()
end

applyFunctionSearch=function(query)
	query = (query or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

	for _, sec in ipairs(scroll:GetChildren()) do
		if sec:IsA("Frame") then
			local wrap = sec:FindFirstChild("Wrap")
			local anyVisible = false

			if wrap then
				for _, item in ipairs(wrap:GetChildren()) do
					if not item:IsA("UIListLayout") then
						local baseVisible = item:GetAttribute("AP_BaseVisible")
						if baseVisible == nil then
							baseVisible = item.Visible
							item:SetAttribute("AP_BaseVisible", baseVisible)
						end

						local show = baseVisible

						if query ~= "" and baseVisible then
							local text = getSearchText(item)
							show = (text:find(query, 1, true) ~= nil)
						end

						item.Visible = show
						if show then
							anyVisible = true
						end
					end
				end
			end

			sec.Visible = (query == "") or anyVisible
		end
	end
end

refreshSearchUI=function()
	searchBox.Visible = state.searchFunctionsOn
	setBtnOn(btnSearchFunctions, state.searchFunctionsOn)

	if state.searchFunctionsOn then
		scroll.Position = UDim2.fromOffset(12, 100)
		scroll.Size = UDim2.new(1, -24, 1, -110)
	else
		scroll.Position = UDim2.fromOffset(12, 60)
		scroll.Size = UDim2.new(1, -24, 1, -70)
		searchBox.Text = ""
		applyFunctionSearch("")
	end
end


btnTPose.MouseButton1Click:Connect(function()
	if state.tposeOn then
		tposeOff()
	else
		tposeOn()
	end
end)















--========================================================
-- ACCESS KEY + UI SFX + DRAG MENU BUTTON (LOCAL ONLY)
-- ВСТАВЬ В САМЫЙ КОНЕЦ СКРИПТА
--========================================================

do
	local SoundService = game:GetService("SoundService")
	local StarterGui = game:GetService("StarterGui")

	------------------------------------------------------------
	-- CONFIG
	------------------------------------------------------------
	state.__AccessPatch = state.__AccessPatch or {}
	local AP = state.__AccessPatch

	-- LOCAL KEY
	AP.KEY = AP.KEY or key_for_activate

	-- локальный флаг активации на текущую сессию
	AP.ATTR_NAME = "NurmenalActivatedLocalSession"

	AP.locked = true
	AP.prevOnlyButton = state.onlyButton
	AP.ui = AP.ui or {}
	AP.forceCloseConn = nil

	AP.SFX = AP.SFX or {
		CLICK   = "rbxassetid://139719503904449",
		HOVER   = "rbxassetid://138744734909383",
		SUCCESS = "rbxassetid://0",
		ERROR   = "rbxassetid://0",
		NOTIFY  = "rbxassetid://0",
		DRAG    = "rbxassetid://0",
	}
	
	AP.LINKS = AP.LINKS or {
		"YOUR_LINK_1",
		"YOUR_LINK_2",
	}

	------------------------------------------------------------
	-- HELPERS
	------------------------------------------------------------
	local function AP_PlaySound(soundId, volume, playbackSpeed)
		if not soundId or soundId == "" or soundId == "rbxassetid://0" then
			return
		end

		local s = Instance.new("Sound")
		s.SoundId = soundId
		s.Volume = volume or 0.6
		s.PlaybackSpeed = playbackSpeed or 1
		s.RollOffMaxDistance = 10000
		s.Name = "AP_LocalUISound"
		s.Parent = SoundService

		pcall(function()
			s:Play()
		end)

		Debris:AddItem(s, 3)
	end

	local function AP_Notify(text, kind)
		local icon = LOGO_IMAGE
		local title = "Nurmenal"

		if kind == "success" then
			AP_PlaySound(AP.SFX.SUCCESS, 0.45, 1)
			title = "Nurmenal • Success"
		elseif kind == "error" then
			AP_PlaySound(AP.SFX.ERROR, 0.5, 1)
			title = "Nurmenal • Error"
		else
			AP_PlaySound(AP.SFX.NOTIFY, 0.35, 1)
		end

		pcall(function()
			StarterGui:SetCore("SendNotification", {
				Title = title,
				Text = text,
				Icon = icon,
				Duration = 4,
			})
		end)
	end

	local function AP_Tween(o, t, props, style, dir)
		local tw = TweenService:Create(
			o,
			TweenInfo.new(
				t or 0.18,
				style or Enum.EasingStyle.Quad,
				dir or Enum.EasingDirection.Out
			),
			props
		)
		tw:Play()
		return tw
	end

	local function AP_MakeInput(parent, placeholder, defaultText)
		local box = mk("TextBox", {
			ClearTextOnFocus = false,
			Text = defaultText or "",
			PlaceholderText = placeholder or "",
			Font = fontik,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = Color3.fromRGB(28, 28, 34),
			TextColor3 = Color3.fromRGB(240, 240, 245),
			Size = UDim2.new(1, 0, 0, 42),
		}, parent)

		mk("UICorner", {CornerRadius = UDim.new(0, 12)}, box)
		mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75, 75, 95), Transparency = 0.35}, box)

		return box
	end

	local function AP_ApplyButtonFX(btn)
		if not btn or not btn:IsA("TextButton") then return end
		if btn:GetAttribute("AP_KeyFxWired") then return end
		btn:SetAttribute("AP_KeyFxWired", true)

		local sc = btn:FindFirstChildOfClass("UIScale")
		if not sc then
			sc = Instance.new("UIScale")
			sc.Scale = 1
			sc.Parent = btn
		end

		local stroke = btn:FindFirstChildOfClass("UIStroke")

		btn.MouseEnter:Connect(function()
			AP_PlaySound(AP.SFX.HOVER, 0.4, 1.03)
			AP_Tween(sc, 0.08, {Scale = 1.02})
			if stroke then
				AP_Tween(stroke, 0.08, {Transparency = 0.15})
			end
		end)

		btn.MouseLeave:Connect(function()
			AP_Tween(sc, 0.10, {Scale = 1.00})
			if stroke then
				AP_Tween(stroke, 0.10, {Transparency = 0.35})
			end
		end)

		btn.MouseButton1Down:Connect(function()
			AP_PlaySound(AP.SFX.CLICK, 0.7, 1)
			AP_Tween(sc, 0.05, {Scale = 0.97})
		end)

		btn.MouseButton1Up:Connect(function()
			AP_Tween(sc, 0.08, {Scale = 1.02})
		end)
	end

	local function AP_WireAllUISounds()
		if not gui then return end

		for _, inst in ipairs(gui:GetDescendants()) do
			if inst:IsA("TextButton") then
				AP_ApplyButtonFX(inst)
			elseif inst:IsA("TextBox") and not inst:GetAttribute("AP_TextBoxSfx") then
				inst:SetAttribute("AP_TextBoxSfx", true)

				inst.Focused:Connect(function()
					AP_PlaySound(AP.SFX.HOVER, 0.11, 1.02)
				end)

				inst.FocusLost:Connect(function(enterPressed)
					if enterPressed then
						AP_PlaySound(AP.SFX.CLICK, 0.18, 1.05)
					end
				end)
			end
		end

		gui.DescendantAdded:Connect(function(inst)
			if inst:IsA("TextButton") then
				task.defer(function()
					AP_ApplyButtonFX(inst)
				end)
			elseif inst:IsA("TextBox") and not inst:GetAttribute("AP_TextBoxSfx") then
				inst:SetAttribute("AP_TextBoxSfx", true)

				inst.Focused:Connect(function()
					AP_PlaySound(AP.SFX.HOVER, 0.11, 1.02)
				end)

				inst.FocusLost:Connect(function(enterPressed)
					if enterPressed then
						AP_PlaySound(AP.SFX.CLICK, 0.18, 1.05)
					end
				end)
			end
		end)
	end

	local function AP_IsActivated()
		return LP:GetAttribute(AP.ATTR_NAME) == true
	end

	local function AP_SetActivated(v)
		LP:SetAttribute(AP.ATTR_NAME, v == true)
	end

	------------------------------------------------------------
	-- LOCK / UNLOCK
	------------------------------------------------------------
	local function AP_HideMainUI()
		if menuBtn then
			menuBtn.Visible = false
			menuBtn.Active = false
			menuBtn.AutoButtonColor = false
		end
		if panel then
			panel.Visible = false
		end
	end

	local function AP_ShowMainUI()
		if menuBtn then
			menuBtn.Visible = true
			menuBtn.Active = true
			menuBtn.AutoButtonColor = true
		end
	end

	local function AP_SetLocked(on)
		AP.locked = (on == true)

		if AP.locked then
			AP.prevOnlyButton = state.onlyButton
			state.onlyButton = true
			AP_HideMainUI()

			if AP.forceCloseConn then
				AP.forceCloseConn:Disconnect()
				AP.forceCloseConn = nil
			end

			AP.forceCloseConn = RunService.RenderStepped:Connect(function()
				if panel then panel.Visible = false end
				state.panelOpen = false
			end)
		else
			state.onlyButton = AP.prevOnlyButton

			if AP.forceCloseConn then
				AP.forceCloseConn:Disconnect()
				AP.forceCloseConn = nil
			end

			AP_ShowMainUI()
		end

		updateHUD()
	end

	AP_SetLocked(true)

	------------------------------------------------------------
	-- MENU DRAG
	------------------------------------------------------------
	local function AP_EnableMenuDrag()
		if not menuBtn then return end

		if not menuBtn:GetAttribute("AP_DragCloneReady") then
			local oldBtn = menuBtn
			local newBtn = oldBtn:Clone()
			newBtn:SetAttribute("AP_DragCloneReady", true)
			newBtn.Parent = oldBtn.Parent
			newBtn.ZIndex = oldBtn.ZIndex
			oldBtn:Destroy()
			menuBtn = newBtn
		end

		if menuBtn:GetAttribute("AP_MenuDragWired") then return end
		menuBtn:SetAttribute("AP_MenuDragWired", true)

		menuBtn.AnchorPoint = Vector2.new(0.5, 0.5)

		local dragging = false
		local dragMoved = false
		local dragStartMouse = Vector2.zero
		local dragSoundCooldown = 0
		local dragConn = nil

		local CURSOR_VISUAL_OFFSET = Vector2.new(0, 0)

		local function getViewport()
			local c = Workspace.CurrentCamera
			return c and c.ViewportSize or Vector2.new(1280, 720)
		end

		local function getCursorPos()
			local p = UIS:GetMouseLocation()
			return Vector2.new(p.X, p.Y) + CURSOR_VISUAL_OFFSET
		end

		local function setMenuCenterToCursor(mousePos)
			local vp = getViewport()
			local half = menuBtn.AbsoluteSize * 0.5

			local x = math.clamp(mousePos.X, half.X, vp.X - half.X)
			local y = math.clamp(mousePos.Y, half.Y, vp.Y - half.Y)

			menuBtn.Position = UDim2.fromOffset(x, y)
		end

		menuBtn.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			if AP.locked then return end

			dragging = true
			dragMoved = false
			dragStartMouse = getCursorPos()

			setMenuCenterToCursor(dragStartMouse)
			AP_PlaySound(AP.SFX.DRAG, 0.16, 1)

			if dragConn then
				dragConn:Disconnect()
				dragConn = nil
			end

			dragConn = RunService.RenderStepped:Connect(function()
				if not dragging then return end

				local mousePos = getCursorPos()

				if (mousePos - dragStartMouse).Magnitude >= 2 then
					dragMoved = true
				end

				setMenuCenterToCursor(mousePos)

				dragSoundCooldown += 1
				if dragSoundCooldown >= 10 then
					dragSoundCooldown = 0
					AP_PlaySound(AP.SFX.HOVER, 0.04, 1.08)
				end
			end)
		end)

		UIS.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				if dragging then
					AP_PlaySound(AP.SFX.CLICK, 0.18, 1.04)
				end

				dragging = false
				dragSoundCooldown = 0

				if dragConn then
					dragConn:Disconnect()
					dragConn = nil
				end
			end
		end)

		menuBtn.MouseButton1Click:Connect(function()
			if AP.locked then return end
			if dragMoved then
				dragMoved = false
				return
			end
			setPanelOpen(not state.panelOpen)
		end)
	end

	AP_EnableMenuDrag()

	------------------------------------------------------------
	-- ACTIVATION UI
	------------------------------------------------------------
	local function AP_BuildAccessUI()
		if not gui then return end
		if AP.ui.root and AP.ui.root.Parent then return end

		local root = mk("Frame", {
			Name = "AP_AccessRoot",
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.28,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 5000,
		}, gui)

		local blur = Lighting:FindFirstChild("AP_AccessBlur")
		if not blur then
			blur = Instance.new("BlurEffect")
			blur.Name = "AP_AccessBlur"
			blur.Size = 0
			blur.Parent = Lighting
		end
		AP_Tween(blur, 0.25, {Size = 14})

		local card = mk("Frame", {
			Name = "AP_AccessCard",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(470, 270),
			BackgroundColor3 = Color3.fromRGB(16, 16, 20),
			BackgroundTransparency = 0.08,
			ZIndex = 5001,
		}, root)
		mk("UICorner", {CornerRadius = UDim.new(0, 18)}, card)
		mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(95, 95, 120), Transparency = 0.18}, card)

		local logo = mk("ImageLabel", {
			BackgroundTransparency = 1,
			Image = LOGO_IMAGE,
			Size = UDim2.fromOffset(74, 74),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 18),
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 5002,
		}, card)

		local title = mk("TextLabel", {
			BackgroundTransparency = 1,
			Text = "Nurmenal Access",
			Font = fontik,
			TextSize = 28,
			TextColor3 = Color3.fromRGB(245, 245, 250),
			TextStrokeTransparency = 0.75,
			Size = UDim2.new(1, -30, 0, 34),
			Position = UDim2.fromOffset(15, 96),
			ZIndex = 5002,
		}, card)

		local sub = mk("TextLabel", {
			BackgroundTransparency = 1,
			Text = "Enter activation key to unlock the panel",
			Font = fontik,
			TextSize = 15,
			TextColor3 = Color3.fromRGB(175, 175, 190),
			Size = UDim2.new(1, -34, 0, 24),
			Position = UDim2.fromOffset(17, 126),
			ZIndex = 5002,
		}, card)

		local boxWrap = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -38, 0, 42),
			Position = UDim2.fromOffset(19, 160),
			ZIndex = 5002,
		}, card)

		local keyBox = AP_MakeInput(boxWrap, "Activation key...", "")
		keyBox.Size = UDim2.new(1, 0, 1, 0)
		keyBox.ZIndex = 5003

		local statusLbl = mk("TextLabel", {
			BackgroundTransparency = 1,
			Text = "Locked",
			Font = fontik,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(255, 205, 120),
			Size = UDim2.new(1, -38, 0, 18),
			Position = UDim2.fromOffset(19, 206),
			ZIndex = 5002,
		}, card)

		local row = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -38, 0, 42),
			Position = UDim2.fromOffset(19, 224),
			ZIndex = 5002,
		}, card)

		local unlockBtn = mk("TextButton", {
			Text = "Unlock",
			Font = fontik,
			TextSize = 16,
			AutoButtonColor = true,
			BackgroundColor3 = Color3.fromRGB(40, 52, 90),
			TextColor3 = Color3.fromRGB(245, 245, 255),
			Size = UDim2.new(0.62, -5, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			ZIndex = 5003,
		}, row)
		mk("UICorner", {CornerRadius = UDim.new(0, 12)}, unlockBtn)
		mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(90, 105, 155), Transparency = 0.15}, unlockBtn)

		local closeBtn = mk("TextButton", {
			Text = "Close Panel",
			Font = fontik,
			TextSize = 15,
			AutoButtonColor = true,
			BackgroundColor3 = Color3.fromRGB(32, 32, 38),
			TextColor3 = Color3.fromRGB(235, 235, 240),
			Size = UDim2.new(0.38, 0, 1, 0),
			Position = UDim2.new(0.62, 5, 0, 0),
			ZIndex = 5003,
		}, row)
		mk("UICorner", {CornerRadius = UDim.new(0, 12)}, closeBtn)
		mk("UIStroke", {Thickness = 1, Color = Color3.fromRGB(75, 75, 90), Transparency = 0.30}, closeBtn)

		local cardScale = Instance.new("UIScale")
		cardScale.Scale = 0.92
		cardScale.Parent = card

		card.BackgroundTransparency = 1
		title.TextTransparency = 1
		sub.TextTransparency = 1
		statusLbl.TextTransparency = 1
		logo.ImageTransparency = 1

		AP_Tween(root, 0.18, {BackgroundTransparency = 0.28})
		AP_Tween(card, 0.20, {BackgroundTransparency = 0.08})
		AP_Tween(cardScale, 0.20, {Scale = 1})
		AP_Tween(title, 0.20, {TextTransparency = 0})
		AP_Tween(sub, 0.20, {TextTransparency = 0})
		AP_Tween(statusLbl, 0.20, {TextTransparency = 0})
		AP_Tween(logo, 0.20, {ImageTransparency = 0})

		AP_ApplyButtonFX(unlockBtn)
		AP_ApplyButtonFX(closeBtn)

		local function shakeCard()
			local orig = card.Position

			task.spawn(function()
				for _, dx in ipairs({-8, 8, -6, 6, -3, 3, 0}) do
					card.Position = orig + UDim2.fromOffset(dx, 0)
					task.wait(0.025)
				end
				card.Position = orig
			end)
		end

		local function closeAccessUI()
			AP_Tween(cardScale, 0.14, {Scale = 0.97})
			task.delay(0.10, function()
				AP_Tween(root, 0.18, {BackgroundTransparency = 1})
				AP_Tween(card, 0.18, {BackgroundTransparency = 1})
				AP_Tween(cardScale, 0.18, {Scale = 0.92})
				AP_Tween(title, 0.18, {TextTransparency = 1})
				AP_Tween(sub, 0.18, {TextTransparency = 1})
				AP_Tween(statusLbl, 0.18, {TextTransparency = 1})
				AP_Tween(logo, 0.18, {ImageTransparency = 1})

				local blurObj = Lighting:FindFirstChild("AP_AccessBlur")
				if blurObj then
					AP_Tween(blurObj, 0.18, {Size = 0})
				end

				task.delay(0.20, function()
					if root then root:Destroy() end
					local b = Lighting:FindFirstChild("AP_AccessBlur")
					if b then b:Destroy() end
				end)
			end)
		end

		local function unlock()
			local typed = tostring(keyBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")

			if typed == "" then
				keyBox.Text = ""
				statusLbl.Text = "Enter key first"
				statusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
				AP_Notify("Enter activation key first.", "error")
				shakeCard()
				return
			end

			if typed == AP.KEY then
				AP_SetActivated(true)

				statusLbl.Text = "Access granted"
				statusLbl.TextColor3 = Color3.fromRGB(145, 255, 165)

				AP_SetLocked(false)
				AP_Notify("Panel unlocked successfully.", "success")
				closeAccessUI()
			else
				keyBox.Text = ""
				statusLbl.Text = "Wrong key"
				statusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
				AP_Notify("Wrong activation key.", "error")
				shakeCard()
			end
		end

		unlockBtn.MouseButton1Click:Connect(unlock)
		keyBox.FocusLost:Connect(function(enterPressed)
			if enterPressed then
				unlock()
			end
		end)

		closeBtn.MouseButton1Click:Connect(function()
			AP_SetDismissed("access", true)

			AP_CloseOverlay(root, card, cardScale, {
				title, sub, statusLbl, logo
			})

			AP_Notify("Access window was closed for this session.", "notify")
		end)

		AP.ui.root = root
		AP.ui.card = card
		AP.ui.keyBox = keyBox
		AP.ui.statusLbl = statusLbl

		task.delay(0.15, function()
			if keyBox and keyBox.Parent then
				pcall(function()
					keyBox:CaptureFocus()
				end)
			end
		end)
	end








	
	
	
	
	


	local function AP_IsDismissed(tag)
		return LP:GetAttribute("NurmenalDismissed_" .. tostring(tag)) == true
	end

	AP_SetDismissed=function(tag, value)
		LP:SetAttribute("NurmenalDismissed_" .. tostring(tag), value == true)
	end

	AP_CloseOverlay=function(root, card, cardScale, fadeObjects)
		fadeObjects = fadeObjects or {}

		AP_Tween(root, 0.18, {BackgroundTransparency = 1})
		AP_Tween(card, 0.18, {BackgroundTransparency = 1})

		if cardScale then
			AP_Tween(cardScale, 0.18, {Scale = 0.94})
		end

		for _, obj in ipairs(fadeObjects) do
			if obj and obj.Parent then
				if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
					pcall(function() AP_Tween(obj, 0.18, {TextTransparency = 1}) end)
					pcall(function() AP_Tween(obj, 0.18, {BackgroundTransparency = 1}) end)
				elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
					pcall(function() AP_Tween(obj, 0.18, {ImageTransparency = 1}) end)
					pcall(function() AP_Tween(obj, 0.18, {BackgroundTransparency = 1}) end)
				elseif obj:IsA("Frame") then
					pcall(function() AP_Tween(obj, 0.18, {BackgroundTransparency = 1}) end)
				elseif obj:IsA("UIStroke") then
					pcall(function() AP_Tween(obj, 0.18, {Transparency = 1}) end)
				end
			end
		end

		local blurObj = Lighting:FindFirstChild("AP_AccessBlur")
		if blurObj then
			AP_Tween(blurObj, 0.18, {Size = 0})
		end

		task.delay(0.22, function()
			if root and root.Parent then
				root:Destroy()
			end

			local b = Lighting:FindFirstChild("AP_AccessBlur")
			if b then
				b:Destroy()
			end
		end)
	end
	
	
	local function AP_BuildBlockedUI()
		if not gui then return end
		if AP_IsDismissed("blocked") then return end
		if AP.ui.blockRoot and AP.ui.blockRoot.Parent then return end

		local root = mk("Frame", {
			Name = "AP_BlockedRoot",
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.30,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 5100,
		}, gui)

		local blur = Lighting:FindFirstChild("AP_AccessBlur")
		if not blur then
			blur = Instance.new("BlurEffect")
			blur.Name = "AP_AccessBlur"
			blur.Size = 0
			blur.Parent = Lighting
		end
		AP_Tween(blur, 0.22, {Size = 14})

		local card = mk("Frame", {
			Name = "AP_BlockedCard",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(520, 374),
			BackgroundColor3 = Color3.fromRGB(16, 16, 20),
			BackgroundTransparency = 0.05,
			ZIndex = 5101,
		}, root)
		mk("UICorner", {CornerRadius = UDim.new(0, 18)}, card)

		local cardStroke = mk("UIStroke", {
			Thickness = 1,
			Color = Color3.fromRGB(95, 95, 120),
			Transparency = 0.18,
		}, card)

		local logo = mk("ImageLabel", {
			BackgroundTransparency = 1,
			Image = LOGO_IMAGE,
			Size = UDim2.fromOffset(72, 72),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 18),
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 5102,
		}, card)

		local title = mk("TextLabel", {
			BackgroundTransparency = 1,
			Text = "ACCESS RESTRICTED",
			Font = fontik,
			TextSize = 28,
			TextColor3 = Color3.fromRGB(255, 95, 95),
			TextStrokeTransparency = 0.78,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, -34, 0, 34),
			Position = UDim2.fromOffset(17, 98),
			ZIndex = 5102,
		}, card)

		local body = mk("TextLabel", {
			BackgroundTransparency = 1,
			Text = "You are not recognized as a customer of this product, so access has been blocked. You can purchase it using the links below.",
			Font = fontik,
			TextSize = 15,
			TextWrapped = true,
			TextColor3 = Color3.fromRGB(220, 220, 228),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top,
			Size = UDim2.new(1, -64, 0, 72),
			Position = UDim2.fromOffset(32, 142),
			ZIndex = 5102,
		}, card)

		local buyerLbl = mk("TextLabel", {
			BackgroundTransparency = 1,
			RichText = true,
			Text = 'This copy currently belongs to <font color="#7DFF9A">' .. tostring(PRODUCT_BUYER_NICK) .. '</font>.',
			Font = fontik,
			TextSize = 15,
			TextWrapped = true,
			TextColor3 = Color3.fromRGB(220, 220, 228),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top,
			Size = UDim2.new(1, -64, 0, 24),
			Position = UDim2.fromOffset(32, 218),
			ZIndex = 5102,
		}, card)

		local byLbl = mk("TextLabel", {
			BackgroundTransparency = 1,
			Text = "",
			Font = fontik,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(140, 140, 150),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 18, 1, -12),
			Size = UDim2.fromOffset(120, 16),
			ZIndex = 5102,
		}, card)

		local linksFrame = mk("Frame", {
			Name = "AP_BlockedLinksFrame",
			BackgroundColor3 = Color3.fromRGB(24, 24, 30),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Size = UDim2.new(1, -64, 0, 0),
			Position = UDim2.fromOffset(32, 248),
			ZIndex = 5102,
		}, card)
		mk("UICorner", {CornerRadius = UDim.new(0, 12)}, linksFrame)

		local linksStroke = mk("UIStroke", {
			Thickness = 1,
			Color = Color3.fromRGB(75, 75, 95),
			Transparency = 1,
		}, linksFrame)

		local linksText = table.concat(AP.LINKS or {}, "\n")
		local linksLbl = mk("TextLabel", {
			BackgroundTransparency = 1,
			Text = linksText ~= "" and linksText or "No links have been added yet.",
			Font = fontik,
			TextSize = 14,
			TextWrapped = true,
			TextColor3 = Color3.fromRGB(190, 200, 255),
			TextTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Size = UDim2.new(1, -18, 1, -12),
			Position = UDim2.fromOffset(9, 6),
			ZIndex = 5103,
		}, linksFrame)

		local row = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -64, 0, 42),
			Position = UDim2.fromOffset(32, 266),
			ZIndex = 5102,
		}, card)

		local linksBtn = mk("TextButton", {
			Text = "Links",
			Font = fontik,
			TextSize = 16,
			AutoButtonColor = true,
			BackgroundColor3 = Color3.fromRGB(40, 52, 90),
			TextColor3 = Color3.fromRGB(245, 245, 255),
			Size = UDim2.new(0.5, -6, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			ZIndex = 5103,
		}, row)
		mk("UICorner", {CornerRadius = UDim.new(0, 12)}, linksBtn)

		local linksBtnStroke = mk("UIStroke", {
			Thickness = 1,
			Color = Color3.fromRGB(90, 105, 155),
			Transparency = 0.15,
		}, linksBtn)

		local closeBtn = mk("TextButton", {
			Text = "Close",
			Font = fontik,
			TextSize = 16,
			AutoButtonColor = true,
			BackgroundColor3 = Color3.fromRGB(32, 32, 38),
			TextColor3 = Color3.fromRGB(235, 235, 240),
			Size = UDim2.new(0.5, -6, 1, 0),
			Position = UDim2.new(0.5, 6, 0, 0),
			ZIndex = 5103,
		}, row)
		mk("UICorner", {CornerRadius = UDim.new(0, 12)}, closeBtn)

		local closeBtnStroke = mk("UIStroke", {
			Thickness = 1,
			Color = Color3.fromRGB(75, 75, 90),
			Transparency = 0.30,
		}, closeBtn)

		local cardScale = Instance.new("UIScale")
		cardScale.Scale = 0.92
		cardScale.Parent = card

		card.BackgroundTransparency = 1
		title.TextTransparency = 1
		body.TextTransparency = 1
		buyerLbl.TextTransparency = 1
		byLbl.TextTransparency = 1
		logo.ImageTransparency = 1

		AP_Tween(root, 0.18, {BackgroundTransparency = 0.30})
		AP_Tween(card, 0.20, {BackgroundTransparency = 0.05})
		AP_Tween(cardScale, 0.20, {Scale = 1})
		AP_Tween(title, 0.20, {TextTransparency = 0})
		AP_Tween(body, 0.20, {TextTransparency = 0})
		AP_Tween(buyerLbl, 0.20, {TextTransparency = 0})
		AP_Tween(byLbl, 0.20, {TextTransparency = 0})
		AP_Tween(logo, 0.20, {ImageTransparency = 0})

		AP_ApplyButtonFX(linksBtn)
		AP_ApplyButtonFX(closeBtn)

		local linksOpen = false

		local function setLinksOpen(open)
			linksOpen = open

			if linksOpen then
				linksBtn.Text = "Hide Links"

				AP_Tween(card, 0.18, {Size = UDim2.fromOffset(520, 468)})
				AP_Tween(linksFrame, 0.18, {
					Size = UDim2.new(1, -64, 0, 94),
					BackgroundTransparency = 0.06
				})
				AP_Tween(linksStroke, 0.18, {Transparency = 0.25})
				AP_Tween(linksLbl, 0.18, {TextTransparency = 0})
				AP_Tween(row, 0.18, {Position = UDim2.fromOffset(32, 364)})
			else
				linksBtn.Text = "Links"

				AP_Tween(card, 0.18, {Size = UDim2.fromOffset(520, 374)})
				AP_Tween(linksFrame, 0.18, {
					Size = UDim2.new(1, -64, 0, 0),
					BackgroundTransparency = 1
				})
				AP_Tween(linksStroke, 0.18, {Transparency = 1})
				AP_Tween(linksLbl, 0.18, {TextTransparency = 1})
				AP_Tween(row, 0.18, {Position = UDim2.fromOffset(32, 266)})
			end
		end

		linksBtn.MouseButton1Click:Connect(function()
			setLinksOpen(not linksOpen)
		end)

		closeBtn.MouseButton1Click:Connect(function()
			AP_SetDismissed("blocked", true)
			AP_SetDismissed("access", true)

			AP_CloseOverlay(root, card, cardScale, {
				title, body, buyerLbl, byLbl, logo, row, linksFrame,
				linksLbl, linksStroke, cardStroke, linksBtnStroke, closeBtnStroke
			})
		end)

		AP.ui.blockRoot = root
		AP.ui.blockCard = card
	end




	------------------------------------------------------------
	-- WAIT FOR SPLASH, THEN CHECK LOCAL SESSION ACTIVATION
	------------------------------------------------------------
	task.spawn(function()
		local timeout = os.clock() + 8

		while os.clock() < timeout do
			if not gui then break end

			local splash = gui:FindFirstChild("AP_Splash")
			local splashDone = gui:GetAttribute("AP_SplashDone") == true

			if splashDone and not splash then
				break
			end

			task.wait(0.08)
		end

		if AP_IsActivated() then
			AP_SetLocked(false)
		else
			AP_SetLocked(true)

			if isAllowedUser() then
				if not AP_IsDismissed("access") then
					AP_BuildAccessUI()
					AP_Notify("Enter activation key to unlock Nurmenal.", "notify")
				end
			else
				if not AP_IsDismissed("blocked") then
					AP_BuildBlockedUI()
					AP_Notify("Access restricted.", "error")
				end
			end
		end
	end)
	------------------------------------------------------------
	-- EXTRA: wire sounds on whole gui
	------------------------------------------------------------
	task.defer(AP_WireAllUISounds)
end
















-- respawn safety
LP.CharacterAdded:Connect(function()
	task.wait(0.2)
	if state.__StealthCube.enabled then
		pcall(function() state.__StealthCube.Disable() end)
	end
end)

-- init button state
state.__StealthCube._setFloatBtn(state.__StealthCube.armed, state.__StealthCube.enabled)
updateHUD()

setBtnOn(btnSearchFunctions, state.searchFunctionsOn)
refreshSearchUI()