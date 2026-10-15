local SITE = "https://main.pickazhub.workers.dev"
local SCRIPT_URL = "https://raw.githubusercontent.com/PickasHub/Loader/refs/heads/main/PHLoader.lua"
local KEYLESS = false
local FILE = "PickasHubKey.txt"

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Market = game:GetService("MarketplaceService")
local player = Players.LocalPlayer

local function try(fn, ...)
	local ok, res = pcall(fn, ...)
	if ok then return res end
	return nil
end

local function httpGet(url)
	local body = try(function() return game:HttpGet(url) end)
	if body then return body end
	local r = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
	if r then
		local res = try(r, { Url = url, Method = "GET" })
		if res and res.Body then return res.Body end
	end
	return nil
end

local function enc(s)
	return HttpService:UrlEncode(tostring(s))
end

local gameName = try(function() return Market:GetProductInfo(game.PlaceId).Name end) or "Unknown"
local executor = try(function() return identifyexecutor() end) or "Unknown"

local function verify(key)
	local body = httpGet(SITE .. "/api/verify?key=" .. enc(key) .. "&uid=" .. player.UserId)
	if not body then return nil, "network" end
	local data = try(function() return HttpService:JSONDecode(body) end)
	if not data then return nil, "network" end
	return data
end

local function ping(key)
	local url = SITE .. "/api/executed?uid=" .. player.UserId
		.. "&username=" .. enc(player.Name)
		.. "&display=" .. enc(player.DisplayName)
		.. "&game=" .. enc(gameName)
		.. "&executor=" .. enc(executor)
	if key then url = url .. "&key=" .. enc(key) else url = url .. "&mode=Keyless" end
	task.spawn(httpGet, url)
end

local function run(key, data)
	getgenv().PICK_KEY = key
	getgenv().PICK_PREMIUM = data and data.premium or false
	ping(key)
	loadstring(game:HttpGet(SCRIPT_URL))()
end

local messages = {
	invalid = "Invalid key",
	expired = "This key has expired",
	revoked = "This key was revoked",
	bound_to_another_account = "This key belongs to another account",
	uid_required = "Could not read your account",
	network = "Could not reach the server",
}

if KEYLESS then
	run(nil, nil)
	return
end

local saved = try(function() return isfile(FILE) and readfile(FILE) or nil end)
if saved and saved ~= "" then
	local data = verify(saved)
	if data and data.valid then
		run(saved, data)
		return
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "PickasHubKey"
gui.ResetOnSpawn = false
gui.Parent = try(function() return gethui() end) or CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(320, 200)
frame.Position = UDim2.new(0.5, -160, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(15, 10, 25)
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(155, 109, 255)
stroke.Thickness = 1.5

local function label(text, size, y, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, -24, 0, size + 4)
	l.Position = UDim2.fromOffset(12, y)
	l.Font = Enum.Font.GothamBold
	l.TextSize = size
	l.TextColor3 = color
	l.Text = text
	l.Parent = frame
	return l
end

label("Picka's Hub", 20, 10, Color3.fromRGB(238, 233, 248))
local status = label("Enter your key", 13, 42, Color3.fromRGB(157, 147, 184))

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -24, 0, 38)
box.Position = UDim2.fromOffset(12, 76)
box.BackgroundColor3 = Color3.fromRGB(21, 16, 36)
box.TextColor3 = Color3.fromRGB(238, 233, 248)
box.PlaceholderText = "Paste your key"
box.PlaceholderColor3 = Color3.fromRGB(157, 147, 184)
box.Font = Enum.Font.Code
box.TextSize = 14
box.ClearTextOnFocus = false
box.Text = ""
box.Parent = frame
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

local function button(text, x, fill)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.5, -18, 0, 38)
	b.Position = UDim2.new(x, x == 0 and 12 or 6, 0, 130)
	b.BackgroundColor3 = fill
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = frame
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end

local verifyBtn = button("Verify", 0, Color3.fromRGB(155, 109, 255))
local getBtn = button("Get Key", 0.5, Color3.fromRGB(42, 33, 64))

getBtn.MouseButton1Click:Connect(function()
	local copied = try(function() setclipboard(SITE .. "/getkey") return true end)
	status.Text = copied and "Link copied, open it in your browser" or (SITE .. "/getkey")
end)

local busy = false
verifyBtn.MouseButton1Click:Connect(function()
	if busy then return end
	local key = box.Text:gsub("%s", "")
	if key == "" then status.Text = "Enter your key" return end
	busy = true
	status.Text = "Checking..."
	local data, err = verify(key)
	busy = false
	if not data then status.Text = messages[err] or "Error" return end
	if not data.valid then status.Text = messages[data.reason] or "Invalid key" return end
	try(function() writefile(FILE, key) end)
	gui:Destroy()
	run(key, data)
end)
