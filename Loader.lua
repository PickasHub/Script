-- PICKA'S HUB loader (small, safe to paste). Upload PickasHub.lua to your GitHub repo first.
local URL = "https://raw.githubusercontent.com/PickasHub/Script/refs/heads/main/PickasHub.lua"

local function fail(msg)
    msg = "PICKA'S HUB ERROR:\n" .. tostring(msg)
    warn(msg)
    pcall(function() (setclipboard or toclipboard)(msg) end)
    pcall(function()
        local g = Instance.new("ScreenGui") g.Name = "PickasHubError" g.ResetOnSpawn = false g.IgnoreGuiInset = true g.DisplayOrder = 1000
        g.Parent = (gethui and gethui()) or game:GetService("CoreGui")
        local f = Instance.new("Frame") f.Size = UDim2.new(.9, 0, 0, 220) f.Position = UDim2.new(.05, 0, .05, 0) f.BackgroundColor3 = Color3.fromRGB(35, 10, 20) f.Parent = g
        local t = Instance.new("TextLabel") t.Size = UDim2.new(1, -12, 1, -12) t.Position = UDim2.fromOffset(6, 6) t.BackgroundTransparency = 1
        t.TextColor3 = Color3.fromRGB(255, 170, 170) t.TextWrapped = true t.TextSize = 13 t.Font = Enum.Font.Code
        t.TextXAlignment = Enum.TextXAlignment.Left t.TextYAlignment = Enum.TextYAlignment.Top t.Text = msg .. "\n(copied to clipboard)" t.Parent = f
    end)
end

print("[PickasHub] 1/3 downloading...")
local okGet, src = pcall(function() return game:HttpGet(URL) end)
if not okGet or type(src) ~= "string" or #src < 100 then return fail("Download failed. Check the raw link and that the file is uploaded.\n" .. tostring(src)) end

print("[PickasHub] 2/3 compiling... (" .. #src .. " bytes)")
local fn, cerr = loadstring(src)
if not fn then return fail("Compile error: " .. tostring(cerr)) end

print("[PickasHub] 3/3 running...")
local okRun, Library = xpcall(fn, function(e) return tostring(e) .. "\n" .. debug.traceback() end)
if not okRun then return fail("Runtime error: " .. tostring(Library)) end
print("[PickasHub] library v" .. tostring(Library.Version))

---------------------------------------------------------------- your script below
local okM, errM = xpcall(function()
    local Window = Library:CreateWindow({ Title = "Picka's Hub" })

        
    local Main = Window:AddTab({ Title = "Main", Icon = "house" })
    local Farm = Main:AddSubTab({ Title = "Farm", Icon = "sprout" })
    Farm:AddSection({ Title = "Demo" })
    Farm:AddButton({ Title = "Test Notification", ButtonText = "Test", Icon = "bolt", Callback = function()
        Library:Notify({ Title = "Picka's Hub", Content = "It works!", Type = "Success" })
    end })
    Farm:AddToggle({ Title = "Auto Farm", Flag = "AutoFarm", Callback = function(v) print("AutoFarm", v) end })
    Farm:AddSlider({ Title = "Speed", Min = 16, Max = 100, Default = 16, Flag = "Speed" })
    Farm:AddDropdown({ Title = "Targets", Options = { "NPC", "Boss", "Player" }, Multi = true, Flag = "Targets" })
    Library:Notify({ Title = "Loaded", Content = "Picka's Hub is ready.", Type = "Info" })
end, function(e) return tostring(e) .. "\n" .. debug.traceback() end)
if not okM then fail("Script error: " .. tostring(errM)) end
