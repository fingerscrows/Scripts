--[[
	FINAL STABLE SCRIPT: SURVIVE WAVE Z
	Executor Status: Works on Delta (Mobile) & Xeno (PC)
	
	CHANGELOG:
	1. Auto Revive: 
	   - Fixed Void/Death Issue: Now uses Position only (ignores Ragdoll rotation).
	   - Added Anti-Fling: Resets velocity on teleport.
	   - Safety Height: Teleports 4 studs above target to prevent clipping.
	2. Auto Collect: Safe Mode (Anti-Magnet Logic retained).
]]

if game:GetService("CoreGui"):FindFirstChild("ToraScript") then
    game:GetService("CoreGui").ToraScript:Destroy()
end

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/liebertsx/Tora-Library/main/src/librarynew", true))()
local win = lib:CreateWindow("Survive Wave Z")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- == 1. ZOMBIE BRING == --
local dist = 6
win:AddSlider({text="Zombie Distance",min=2,max=20,value=6,callback=function(v) dist=v end})

local bringOn = false
win:AddToggle({text="Bring Mobs",callback=function(t)
    bringOn = t
    if t then
        spawn(function()
            while bringOn do
                task.wait()
                pcall(function()
                    for _,z in workspace.ServerZombies:GetDescendants() do
                        if z.Name=="Humanoid" and z.Health>0 and z.RootPart then
                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                -- Teleport Zombie
                                z.RootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,-dist)
                                z.RootPart.Anchored = true
                            end
                        end
                    end
                end)
                task.wait(.15)
            end
            pcall(function()
                for _,z in workspace.ServerZombies:GetDescendants() do
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

-- == 3. AUTO COLLECT (SAFE MODE) == --
local collectOn = false
win:AddToggle({text="Auto Collect Drops",callback=function(t)
    collectOn = t
    if t then
        spawn(function()
            while collectOn do
                task.wait(0.1)
                pcall(function()
                    for _,p in pairs(Workspace:GetDescendants()) do
                        if p:IsA("BasePart") and not p.Anchored then
                            if p.Name == "Terrain" or p.Name == "Baseplate" then continue end
                            
                            -- Filter Anti-Magnet (Ignore Player/Zombie parts)
                            if p.Parent:FindFirstChild("Humanoid") or p.Parent.Parent:FindFirstChild("Humanoid") then
                                continue 
                            end
                            
                            if p.Size.Magnitude > 10 then continue end

                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                p.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                            end
                        end
                    end
                end)
            end
        end)
    end
end})

-- == 4. AUTO REVIVE (ANTI-VOID & PC FIX) == --
local reviveOn = false
win:AddToggle({text="Auto Revive (Safe)", callback=function(t)
    reviveOn = t
    if t then
        spawn(function()
            local lastRevive = 0
            local ReviveRange = 500 -- Infinite range basically
            local DebounceTime = 1.5 -- Sedikit diperlambat agar lebih stabil di PC

            while reviveOn do
                task.wait(0.2) -- Tick rate aman
                
                local char = LocalPlayer.Character
                if not char then continue end
                
                local myRoot = char:FindFirstChild("HumanoidRootPart")
                local myHum = char:FindFirstChild("Humanoid")
                
                if myRoot and myHum and myHum.Health > 0 then
                    for _, plr in pairs(Players:GetPlayers()) do
                        if plr == LocalPlayer then continue end
                        
                        local tChar = plr.Character
                        if not tChar then continue end
                        
                        local tHum = tChar:FindFirstChild("Humanoid")
                        local tHead = tChar:FindFirstChild("Head")
                        local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                        
                        if tHum and tHead and tRoot then
                            -- Cari Prompt Revive
                            local prompt = tHead:FindFirstChild("RevivePrompt")
                            
                            -- Validasi Target
                            if prompt and prompt.Enabled and tHum.Health <= 0 then
                                if tick() - lastRevive >= DebounceTime then
                                    
                                    -- == LOGIKA TELEPORT BARU (ANTI VOID) ==
                                    -- 1. Ambil Posisi Murni (Vector3), buang rotasi ragdoll
                                    local targetPos = tRoot.Position
                                    
                                    -- 2. Teleport tegak lurus, 4 stud di atas mayat
                                    myRoot.CFrame = CFrame.new(targetPos + Vector3.new(0, 4, 0))
                                    
                                    -- 3. Reset Velocity (Agar tidak terpental/flinging)
                                    myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
                                    myRoot.AssemblyAngularVelocity = Vector3.new(0,0,0)
                                    
                                    task.wait(0.15) -- Jeda agar server memproses posisi baru
                                    
                                    -- Eksekusi Revive
                                    fireproximityprompt(prompt)
                                    lastRevive = tick()
                                    
                                    task.wait(0.5)
                                    break -- Fokus revive satu per satu
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end})

-- == 5. EXTRAS == --

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

win:AddLabel({text="Final Fix: Anti-Void Revive"})
lib:Init()
