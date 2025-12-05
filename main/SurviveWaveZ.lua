--[[
	FINAL SCRIPT: SURVIVE WAVE Z
	Features:
	1. SMART AUTO COLLECT: Hanya ambil Screw, Medkit, & Loot Box. Anti-VFX/Peluru.
	2. AUTO REVIVE V6: Anti-Void, Responsive, & Works on Delta/PC.
	3. SAFE FARM: Bring mobs dengan pcall agar tidak error.
]]

if game:GetService("CoreGui"):FindFirstChild("ToraScript") then
    game:GetService("CoreGui").ToraScript:Destroy()
end

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/liebertsx/Tora-Library/main/src/librarynew", true))()
local win = lib:CreateWindow("Survive Wave Z (Final)")

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
                    for _,z in pairs(workspace.ServerZombies:GetDescendants()) do
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
                for _,z in pairs(workspace.ServerZombies:GetDescendants()) do
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

-- == 3. SMART AUTO COLLECT (Fix VFX & Sampah) == --
local collectOn = false
win:AddToggle({text="Auto Collect (Loot Only)",callback=function(t)
    collectOn = t
    if t then
        spawn(function()
            while collectOn do
                task.wait(0.2)
                pcall(function()
                    -- Scan seluruh workspace
                    for _,p in pairs(Workspace:GetDescendants()) do
                        if not collectOn then break end
                        
                        -- Syarat 1: Harus BasePart dan TIDAK Anchored (Item drop pasti unanchored)
                        if p:IsA("BasePart") and not p.Anchored then
                            
                            -- Syarat 2: Filter Nama (Hanya ambil yang penting)
                            local n = p.Name:lower()
                            local parentN = p.Parent.Name:lower()
                            local isLoot = false

                            -- WHITELIST: Masukkan nama item game disini
                            if n:find("screw") or parentN:find("screw") then isLoot = true end
                            if n:find("coin") or parentN:find("coin") then isLoot = true end
                            if n:find("medkit") or parentN:find("medkit") or n:find("health") then isLoot = true end
                            if n:find("crate") or parentN:find("crate") or n:find("box") then isLoot = true end
                            if n:find("ammo") or parentN:find("ammo") then isLoot = true end
                            
                            -- Jika bukan loot, skip (Ini akan memfilter VFX peluru/darah)
                            if not isLoot then continue end

                            -- Syarat 3: Anti-Magnet (Jangan ambil bagian tubuh Zombie/Player)
                            if p.Parent:FindFirstChild("Humanoid") or p.Parent.Parent:FindFirstChild("Humanoid") then
                                continue 
                            end

                            -- Eksekusi Teleport Item
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

-- == 4. AUTO REVIVE V6 (Final Stable) == --
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
                                    
                                    -- Teleport Anti-Void
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

win:AddLabel({text="Smart Collect + Fixed Revive"})
lib:Init()
