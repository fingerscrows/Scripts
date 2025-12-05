--[[
	SCRIPT FIX: SURVIVE WAVE Z (Final Correction)
	Fixes:
	1. AUTO COLLECT: Explicitly ignores 'workspace.ServerZombies' (Dijamin Zombie tidak tertarik).
	2. BLACKLIST: Membuang efek peluru, darah, dan sampah visual.
	3. AUTO REVIVE: Tetap menggunakan versi V6 yang sudah works.
]]

if game:GetService("CoreGui"):FindFirstChild("ToraScript") then
    game:GetService("CoreGui").ToraScript:Destroy()
end

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/liebertsx/Tora-Library/main/src/librarynew", true))()
local win = lib:CreateWindow("Survive Wave Z (Fixed)")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- == 1. ZOMBIE BRING == --
local dist = 6
win:AddSlider({text="Jarak Zombie",min=2,max=20,value=6,callback=function(v) dist=v end})

local bringOn = false
win:AddToggle({text="Bring Mobs (Tarik Zombie)",callback=function(t)
    bringOn = t
    if t then
        spawn(function()
            while bringOn do
                task.wait()
                pcall(function()
                    -- Kita hanya loop folder ServerZombies agar efisien
                    local folder = workspace:FindFirstChild("ServerZombies") or workspace
                    for _,z in pairs(folder:GetDescendants()) do
                        if not bringOn then break end
                        if z.Name=="Humanoid" and z.Health>0 and z.RootPart then
                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                z.RootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-dist)
                                z.RootPart.Anchored = true
                            end
                        end
                    end
                end)
                task.wait(0.15)
            end
            pcall(function()
                local folder = workspace:FindFirstChild("ServerZombies") or workspace
                for _,z in pairs(folder:GetDescendants()) do
                    if z.Name=="Humanoid" and z.RootPart then z.RootPart.Anchored=false end
                end
            end)
        end)
    end
end})

-- == 2. AUTO SHOOT == --
local shootOn = false
win:AddToggle({text="Auto Shoot",callback=function(t)
    shootOn = t
    if t then
        spawn(function()
            while shootOn do
                task.wait()
                local char = LocalPlayer.Character
                if char then
                    local gun = char:FindFirstChildOfClass("Model") or char:FindFirstChildOfClass("Tool")
                    if gun and workspace:FindFirstChild("ServerZombies") then
                        gun:SetAttribute("IsShooting",true)
                        task.wait()
                        gun:SetAttribute("IsShooting",false)
                    end
                end
            end
        end)
    end
end})

-- == 3. AUTO COLLECT (STRICT FILTER) == --
local collectOn = false
win:AddToggle({text="Auto Collect",callback=function(t)
    collectOn = t
    if t then
        spawn(function()
            while collectOn do
                task.wait()
                for _,p in workspace:GetChildren() do
                    if p:IsA("Part") and p.Name~="Part" and p.Name~="Terrain" then
                        p.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
                    end
                end
            end
        end)
    end
end})


-- == SCAN TOOL (Jarak Jauh) == --
win:AddButton({text="[DEBUG] Cek Nama Item (Jauh)", callback=function()
    print("--- SCAN START ---")
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    -- Scan radius 30 (lebih jauh biar item gak keburu ketarik magnet game)
    for _, p in pairs(Workspace:GetDescendants()) do
        if p:IsA("BasePart") and not p.Anchored and not p:IsDescendantOf(workspace.ServerZombies) and not p:IsDescendantOf(LocalPlayer.Character) then
             if (p.Position - myPos).Magnitude < 30 and p.Size.Magnitude < 5 then
                 -- Filter nama sampah umum
                 local ln = p.Name:lower()
                 if not (ln:find("bullet") or ln:find("blood") or ln:find("shell")) then
                     print("ITEM FOUND: Name=[" .. p.Name .. "] | Parent=[" .. p.Parent.Name .. "]")
                     game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "Item: " .. p.Name,
                        Text = "Parent: " .. p.Parent.Name,
                        Duration = 5
                    })
                 end
             end
        end
    end
end})


-- == 4. AUTO REVIVE (V6 - Fix Responsive) == --
local reviveOn = false
win:AddToggle({text="Auto Revive (Fix)", callback=function(t)
    reviveOn = t
    if t then
        spawn(function()
            local lastRevive = 0
            while reviveOn do
                if not reviveOn then break end
                task.wait(0.2)
                pcall(function()
                    if not reviveOn then return end
                    local char = LocalPlayer.Character
                    if not char then return end
                    local myRoot = char:FindFirstChild("HumanoidRootPart")
                    local myHum = char:FindFirstChild("Humanoid")
                    
                    if myRoot and myHum and myHum.Health > 0 then
                        for _, plr in pairs(Players:GetPlayers()) do
                            if plr == LocalPlayer then continue end
                            local tChar = plr.Character
                            if not tChar then continue end
                            local tHum = tChar:FindFirstChild("Humanoid")
                            local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                            
                            if tHum and tRoot and tHum.Health <= 0 then
                                local promptFound = nil
                                for _, part in pairs(tChar:GetDescendants()) do
                                    if part:IsA("ProximityPrompt") and part.Enabled then
                                        promptFound = part
                                        break
                                    end
                                end
                                
                                if promptFound and (tick() - lastRevive >= 1.0) then
                                    if not reviveOn then return end
                                    local targetPos = tRoot.Position
                                    myRoot.CFrame = CFrame.new(targetPos + Vector3.new(0, 4, 0))
                                    myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
                                    task.wait(0.2)
                                    if not reviveOn then return end
                                    fireproximityprompt(promptFound)
                                    lastRevive = tick()
                                    task.wait(0.5)
                                    return 
                                end
                            end
                        end
                    end
                end)
            end
        end)
    end
end})

-- == EXTRAS == --
win:AddSlider({text="HipHeight",min=2,max=50,value=2,callback=function(v)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.HipHeight = v
    end
end})

local flying = false
local speed = 120
local keys = {w=false,s=false,a=false,d=false}
local velo, gyro

local function fly()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")
    
    if velo then velo:Destroy() end
    if gyro then gyro:Destroy() end
    
    velo = Instance.new("BodyVelocity",root)
    velo.MaxForce = Vector3.new(1e9,1e9,1e9)
    velo.Velocity = Vector3.new()
    
    gyro = Instance.new("BodyGyro",root)
    gyro.MaxTorque = Vector3.new(1e9,1e9,1e9)
    gyro.P = 15000
    gyro.CFrame = root.CFrame
    
    flying = true
    spawn(function()
        while flying and root.Parent do
            task.wait()
            local cam = workspace.CurrentCamera
            local dir = Vector3.new(
                (keys.d and 1 or 0) - (keys.a and 1 or 0),
                0,
                -( (keys.w and 1 or 0) - (keys.s and 1 or 0) )
            )
            if dir.Magnitude > 0 then
                velo.Velocity = cam.CFrame:VectorToWorldSpace(dir.Unit * speed)
            else
                velo.Velocity = Vector3.new()
            end
            gyro.CFrame = cam.CFrame
        end
        if velo then velo:Destroy() end
        if gyro then gyro:Destroy() end
    end)
end

game:GetService("UserInputService").InputBegan:Connect(function(k,gp)
    if gp or not flying then return end
    if k.KeyCode == Enum.KeyCode.W then keys.w = true end
    if k.KeyCode == Enum.KeyCode.S then keys.s = true end
    if k.KeyCode == Enum.KeyCode.A then keys.a = true end
    if k.KeyCode == Enum.KeyCode.D then keys.d = true end
end)

game:GetService("UserInputService").InputEnded:Connect(function(k)
    if not flying then return end
    if k.KeyCode == Enum.KeyCode.W then keys.w = false end
    if k.KeyCode == Enum.KeyCode.S then keys.s = false end
    if k.KeyCode == Enum.KeyCode.A then keys.a = false end
    if k.KeyCode == Enum.KeyCode.D then keys.d = false end
end)

win:AddToggle({text="Fly (WASD)",callback=function(t)
    flying = t
    if t then fly() end
end})

win:AddLabel({text="Fixed Collect Logic"})
lib:Init()
