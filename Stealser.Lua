game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Stealser v0.1", Text = "loading...", Duration = 5})
game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Powered By", Text = "DuckBugs", Duration = 5})
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local pgui = player:WaitForChild("PlayerGui")

local sg = Instance.new("ScreenGui", pgui)
sg.Name = "STELSER_0_1"
sg.IgnoreGuiInset = true

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0,750,0,520)
main.Position = UDim2.new(0.5,-375,0.5,-260)
main.BackgroundColor3 = Color3.new(0,0,0)
main.BorderSizePixel = 0
main.ClipsDescendants = true

local container = Instance.new("Frame", main)
container.Size = UDim2.new(1,-180,1,-60)
container.Position = UDim2.new(0,170,0,50)
container.BackgroundTransparency = 1

local function create_page(name)
    local f = Instance.new("ScrollingFrame", container)
    f.Name = name f.Size = UDim2.new(1,0,1,0) f.BackgroundTransparency = 1
    f.Visible = false f.ScrollBarThickness = 2 f.ScrollBarImageColor3 = Color3.new(0.4,0.4,0.4)
    Instance.new("UIListLayout", f).Padding = UDim.new(0,2)
    return f
end

local pg_loc   = create_page("LOCALS")
local pg_glob  = create_page("GLOBALS")
local pg_ev    = create_page("REMOTES")
local pg_bind  = create_page("BIND")
local pg_attr  = create_page("ATTRS")
local pg_core  = create_page("CORE GUI")
local pg_misc  = create_page("MISC")
pg_loc.Visible = true

local function create_row(p, title, val, mode, ref, key)
    local row = Instance.new("Frame", p)
    row.Size = UDim2.new(1,-10,0,30)
    row.BackgroundColor3 = Color3.fromRGB(5,5,5)
    row.BorderSizePixel = 0
    
    local line = Instance.new("Frame", row)
    line.Size = UDim2.new(1,0,0,1) line.Position = UDim2.new(0,0,1,0)
    line.BackgroundColor3 = Color3.fromRGB(25,25,25)
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.4,0,1,0) lbl.Position = UDim2.new(0,10,0,0)
    lbl.Text = title:upper() lbl.TextColor3 = Color3.new(0.9,0.9,0.9)
    lbl.Font = Enum.Font.Code lbl.TextSize = 9 lbl.TextXAlignment = 0 lbl.BackgroundTransparency = 1
    
    local edit = Instance.new("TextBox", row)
    edit.Size = UDim2.new(0.55,0,0.7,0) edit.Position = UDim2.new(0.42,0,0.15,0)
    edit.BackgroundColor3 = Color3.new(0.03,0.03,0.03) edit.Text = tostring(val)
    edit.TextColor3 = Color3.fromRGB(170,170,170) edit.Font = Enum.Font.Code edit.TextSize = 9
    edit.ClearTextOnFocus = false
    
    edit.FocusLost:Connect(function(enter)
        if not enter then return end
        pcall(function()
            local nv = edit.Text
            if mode == "REMOTE" then
                if ref:IsA("RemoteEvent") then ref:FireServer(nv) else ref:InvokeServer(nv) end
            elseif mode == "LOCAL" then
                local cur = select(2, debug.getupvalue(ref, key))
                local newv = type(cur)=="number" and tonumber(nv) or type(cur)=="boolean" and (nv:lower()=="true") or nv
                debug.setupvalue(ref, key, newv)
            elseif mode == "ATTR" then ref:SetAttribute(key, nv)
            elseif mode == "CORE" then StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[key], nv:lower()=="true")
            elseif mode == "MISC" then
                if key == "FPS" then setfpscap(tonumber(nv) or 9999)
                elseif key == "GRAVITY" then workspace.Gravity = tonumber(nv) or 196.2
                elseif key == "WALKSPEED" then if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.WalkSpeed = tonumber(nv) or 16 end
                elseif key == "JUMPPOWER" then if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.JumpPower = tonumber(nv) or 50 end
                end
            end
        end)
    end)
    
    p.CanvasSize = UDim2.new(0,0,0,p.UIListLayout.AbsoluteContentSize.Y)
end

local function scan()
    for _,p in container:GetChildren() do if p:IsA("ScrollingFrame") then p:ClearAllChildren() Instance.new("UIListLayout", p).Padding = UDim.new(0,2) end end
    
    task.spawn(function() for _,e in Enum.CoreGuiType:GetEnumItems() do create_row(pg_core, e.Name, tostring(StarterGui:GetCoreGuiEnabled(e)), "CORE", nil, e.Name) end end)
    
    task.spawn(function()
        for _,o in game:GetDescendants() do
            if o:IsA("RemoteEvent")    then create_row(pg_ev,   o:GetFullName(), "FIRE",   "REMOTE", o) end
            if o:IsA("RemoteFunction") then create_row(pg_ev,   o:GetFullName(), "INVOKE", "REMOTE", o) end
            if o:IsA("BindableEvent")  then create_row(pg_bind, o:GetFullName(), "FIRE",   "REMOTE", o) end
            if o:IsA("BindableFunction")then create_row(pg_bind,o:GetFullName(), "INVOKE", "REMOTE", o) end
            if _ % 180 == 0 then task.wait() end
        end
    end)
    
    task.spawn(function()
        local seen = {}
        for _,f in getgc(true) do
            if type(f)=="function" and islclosure(f) and not seen[f] then
                seen[f] = true
                local info = debug.getinfo(f) or {name="?"}
                local src = (info.short_src or info.source or "?"):gsub("^@",""):match("[^/\\]+$") or "?"
                for i=1,500 do
                    local n,v = debug.getupvalue(f,i)
                    if n and n~="" then create_row(pg_loc, n.." ("..(info.name or src)..":"..i..")", tostring(v), "LOCAL", f, i) end
                end
            end
            task.wait()
        end
    end)
    
    task.spawn(function()
        for k,v in pairs(_G) do if k~="_G" then create_row(pg_glob, tostring(k), tostring(v), "GLOBAL", nil, k) end end
        for k,v in pairs(shared or {}) do create_row(pg_glob, "shared."..tostring(k), tostring(v), "GLOBAL", nil, k) end
    end)
    
    task.spawn(function()
        local roots = {workspace, game.ReplicatedStorage, game.Players, game.Lighting, game.StarterGui, game:GetService("RunService"), game:GetService("ServerStorage"), game:GetService("ServerScriptService")}
        for _,r in roots do for a in r:GetAttributes() do create_row(pg_attr, r.Name.."."..a, tostring(r:GetAttribute(a)), "ATTR", r, a) end end
        for _,o in workspace:GetDescendants() do if next(o:GetAttributes()) then for a in o:GetAttributes() do create_row(pg_attr, o.Name.."."..a, tostring(o:GetAttribute(a)), "ATTR", o, a) end end if _ % 120 == 0 then task.wait() end end
    end)
    
    task.spawn(function()
        create_row(pg_misc, "FPS CAP", "9999", "MISC", nil, "FPS")
        create_row(pg_misc, "GRAVITY", tostring(workspace.Gravity), "MISC", nil, "GRAVITY")
        create_row(pg_misc, "WALKSPEED", tostring(player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.WalkSpeed or 16), "MISC", nil, "WALKSPEED")
        create_row(pg_misc, "JUMPPOWER", tostring(player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.JumpPower or 50), "MISC", nil, "JUMPPOWER")
    end)
end

local side = Instance.new("Frame", main)
side.Size = UDim2.new(0,160,1,0) side.BackgroundColor3 = Color3.fromRGB(5,5,5) side.BorderSizePixel = 0

local line = Instance.new("Frame", side) line.Size = UDim2.new(0,1,1,0) line.BackgroundColor3 = Color3.fromRGB(35,35,35)

local function tab(n, pg, y)
    local b = Instance.new("TextButton", side)
    b.Size = UDim2.new(1,0,0,40) b.Position = UDim2.new(0,0,0,y)
    b.Text = n b.TextColor3 = Color3.new(0.5,0.5,0.5) b.BackgroundTransparency = 1
    b.Font = Enum.Font.RobotoMono b.TextSize = 10
    b.MouseButton1Click:Connect(function()
        for _,p in container:GetChildren() do p.Visible = false end
        pg.Visible = true
        for _,bb in side:GetChildren() do if bb:IsA("TextButton") then bb.TextColor3 = Color3.new(0.5,0.5,0.5) end end
        b.TextColor3 = Color3.new(1,1,1)
    end)
end

tab("LOCALS",     pg_loc,   60)
tab("GLOBALS",    pg_glob, 105)
tab("REMOTES",    pg_ev,   150)
tab("BINDABLES",  pg_bind, 195)
tab("ATTRIBUTES", pg_attr, 240)
tab("CORE GUI",   pg_core, 285)
tab("MISC",       pg_misc, 330)

local scanbtn = Instance.new("TextButton", side)
scanbtn.Size = UDim2.new(0.8,0,0,40) scanbtn.Position = UDim2.new(0.1,0,1,-60)
scanbtn.Text = "SCAN" scanbtn.BackgroundColor3 = Color3.new(0.15,0.15,0.15) scanbtn.TextColor3 = Color3.new(0.9,0.9,0.9)
scanbtn.Font = Enum.Font.RobotoMono scanbtn.TextSize = 11 scanbtn.BorderSizePixel = 0
scanbtn.MouseButton1Click:Connect(scan)

local search = Instance.new("TextBox", main)
search.Size = UDim2.new(1,-190,0,30) search.Position = UDim2.new(0,170,0,10)
search.BackgroundColor3 = Color3.new(0,0,0) search.Text = "" search.PlaceholderText = "SEARCH..."
search.TextColor3 = Color3.new(0.9,0.9,0.9) search.Font = Enum.Font.Code search.TextSize = 11
Instance.new("UIStroke", search).Color = Color3.new(0.3,0.3,0.3)

search:GetPropertyChangedSignal("Text"):Connect(function()
    local t = search.Text:lower()
    for _,p in container:GetChildren() do
        for _,r in p:GetChildren() do
            if r:IsA("Frame") and r:FindFirstChild("TextLabel") then r.Visible = r.TextLabel.Text:lower():find(t) end
        end
    end
end)

local drag, ds, sp
main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=true ds=i.Position sp=main.Position end end)
UIS.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then local d=i.Position-ds main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end end)

local close = Instance.new("TextButton", main)
close.Size = UDim2.new(0,30,0,30) close.Position = UDim2.new(1,-30,0,0)
close.Text = "X" close.TextColor3 = Color3.new(0.7,0.7,0.7) close.BackgroundTransparency = 1 close.Font = Enum.Font.Code close.TextSize = 14
close.MouseButton1Click:Connect(function() sg:Destroy() end)

local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local isOpen = true

UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.F then
        isOpen = not isOpen
        local goal = isOpen and {Size = UDim2.new(0,750,0,520), Position = UDim2.new(0.5,-375,0.5,-260)} or {Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0)}
        TS:Create(main, tweenInfo, goal):Play()
    end
end)

scan()
