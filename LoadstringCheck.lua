
task.wait(1)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

local LOGO_IMAGE = "rbxassetid://117181319122591"
local fontik = Enum.Font.Code

local oldGui = PlayerGui:FindFirstChild("NurmenalLoadstringCheckGui")
if oldGui then
	oldGui:Destroy()
end

local function mk(className, props, parent)
	local obj = Instance.new(className)
	for k, v in pairs(props or {}) do
		obj[k] = v
	end
	obj.Parent = parent
	return obj
end

local function tw(obj, timeValue, props, style, direction)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(
			timeValue or 0.18,
			style or Enum.EasingStyle.Quad,
			direction or Enum.EasingDirection.Out
		),
		props
	)
	t:Play()
	return t
end

local gui = mk("ScreenGui", {
	Name = "NurmenalLoadstringCheckGui",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
}, PlayerGui)

pcall(function()
	gui.ScreenInsets = Enum.ScreenInsets.None
end)

local blur = Lighting:FindFirstChild("Nurmenal_LoadstringBlur")
if blur then
	blur:Destroy()
end

blur = Instance.new("BlurEffect")
blur.Name = "Nurmenal_LoadstringBlur"
blur.Size = 0
blur.Parent = Lighting

local root = mk("Frame", {
	Name = "Root",
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 5000,
}, gui)

local card = mk("Frame", {
	Name = "Card",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(500, 285),
	BackgroundColor3 = Color3.fromRGB(16, 16, 20),
	BackgroundTransparency = 1,
	ZIndex = 5001,
}, root)
mk("UICorner", {CornerRadius = UDim.new(0, 18)}, card)

local cardStroke = mk("UIStroke", {
	Thickness = 1,
	Color = Color3.fromRGB(95, 95, 120),
	Transparency = 1,
}, card)

local topLine = mk("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 0),
	Size = UDim2.new(1, -30, 0, 2),
	BackgroundColor3 = Color3.fromRGB(90, 105, 155),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 5002,
}, card)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, topLine)

local logo = mk("ImageLabel", {
	BackgroundTransparency = 1,
	Image = LOGO_IMAGE,
	ImageTransparency = 1,
	Size = UDim2.fromOffset(78, 78),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 18),
	ScaleType = Enum.ScaleType.Fit,
	ZIndex = 5002,
}, card)

local title = mk("TextLabel", {
	BackgroundTransparency = 1,
	Text = "Loadstring Check",
	Font = fontik,
	TextSize = 28,
	TextColor3 = Color3.fromRGB(245, 245, 250),
	TextStrokeTransparency = 1,
	TextTransparency = 1,
	Size = UDim2.new(1, -30, 0, 34),
	Position = UDim2.fromOffset(15, 102),
	ZIndex = 5002,
}, card)

local subtitle = mk("TextLabel", {
	BackgroundTransparency = 1,
	Text = "Everything is fine. You can use Nurmenal.",
	Font = fontik,
	TextSize = 16,
	TextWrapped = true,
	TextColor3 = Color3.fromRGB(220, 220, 228),
	TextTransparency = 1,
	Size = UDim2.new(1, -54, 0, 52),
	Position = UDim2.fromOffset(27, 144),
	ZIndex = 5002,
}, card)

local statusDot = mk("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, -20, 0, 213),
	Size = UDim2.fromOffset(10, 10),
	BackgroundColor3 = Color3.fromRGB(125, 255, 154),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 5002,
}, card)
mk("UICorner", {CornerRadius = UDim.new(1, 0)}, statusDot)

local statusText = mk("TextLabel", {
	BackgroundTransparency = 1,
	Text = "Safe",
	Font = fontik,
	TextSize = 14,
	TextColor3 = Color3.fromRGB(125, 255, 154),
	TextTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.fromOffset(120, 18),
	Position = UDim2.fromOffset(240, 204),
	ZIndex = 5002,
}, card)

local closeBtn = mk("TextButton", {
	Text = "Close",
	Font = fontik,
	TextSize = 15,
	AutoButtonColor = true,
	BackgroundColor3 = Color3.fromRGB(32, 32, 38),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(235, 235, 240),
	TextTransparency = 1,
	Size = UDim2.fromOffset(120, 40),
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	ZIndex = 5003,
}, card)
mk("UICorner", {CornerRadius = UDim.new(0, 12)}, closeBtn)

local closeStroke = mk("UIStroke", {
	Thickness = 1,
	Color = Color3.fromRGB(75, 75, 90),
	Transparency = 1,
}, closeBtn)

local cardScale = Instance.new("UIScale")
cardScale.Scale = 0.92
cardScale.Parent = card

local btnScale = Instance.new("UIScale")
btnScale.Scale = 1
btnScale.Parent = closeBtn

local function animateIn()
	tw(blur, 0.22, {Size = 14})
	tw(root, 0.18, {BackgroundTransparency = 0.30})
	tw(card, 0.20, {BackgroundTransparency = 0.05})
	tw(cardStroke, 0.20, {Transparency = 0.18})
	tw(topLine, 0.20, {BackgroundTransparency = 0.1})
	tw(cardScale, 0.20, {Scale = 1})
	tw(logo, 0.20, {ImageTransparency = 0})
	tw(title, 0.20, {TextTransparency = 0, TextStrokeTransparency = 0.75})
	tw(subtitle, 0.20, {TextTransparency = 0})
	tw(statusDot, 0.20, {BackgroundTransparency = 0})
	tw(statusText, 0.20, {TextTransparency = 0})
	tw(closeBtn, 0.20, {BackgroundTransparency = 0})
	tw(closeBtn, 0.20, {TextTransparency = 0})
	tw(closeStroke, 0.20, {Transparency = 0.30})
end

local closing = false

local function closePanel()
	if closing then return end
	closing = true

	tw(root, 0.18, {BackgroundTransparency = 1})
	tw(card, 0.18, {BackgroundTransparency = 1})
	tw(cardStroke, 0.18, {Transparency = 1})
	tw(topLine, 0.18, {BackgroundTransparency = 1})
	tw(cardScale, 0.18, {Scale = 0.94})
	tw(logo, 0.18, {ImageTransparency = 1})
	tw(title, 0.18, {TextTransparency = 1, TextStrokeTransparency = 1})
	tw(subtitle, 0.18, {TextTransparency = 1})
	tw(statusDot, 0.18, {BackgroundTransparency = 1})
	tw(statusText, 0.18, {TextTransparency = 1})
	tw(closeBtn, 0.18, {BackgroundTransparency = 1})
	tw(closeBtn, 0.18, {TextTransparency = 1})
	tw(closeStroke, 0.18, {Transparency = 1})
	tw(blur, 0.18, {Size = 0})

	task.delay(0.22, function()
		if blur and blur.Parent then
			blur:Destroy()
		end
		if gui and gui.Parent then
			gui:Destroy()
		end
	end)
end

closeBtn.MouseEnter:Connect(function()
	tw(btnScale, 0.08, {Scale = 1.02})
	tw(closeStroke, 0.08, {Transparency = 0.15})
end)

closeBtn.MouseLeave:Connect(function()
	tw(btnScale, 0.10, {Scale = 1.00})
	tw(closeStroke, 0.10, {Transparency = 0.30})
end)

closeBtn.MouseButton1Down:Connect(function()
	tw(btnScale, 0.05, {Scale = 0.97})
end)

closeBtn.MouseButton1Up:Connect(function()
	tw(btnScale, 0.08, {Scale = 1.02})
end)

closeBtn.MouseButton1Click:Connect(closePanel)

animateIn()