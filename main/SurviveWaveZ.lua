--[[
	SURVIVE WAVE Z: LEVITATING RAGDOLL (V16)
	
	1. BRING MOBS (FLOATING HEAD-FIRST): 
	   - Zombie diposisikan horizontal (tidur).
	   - Posisi dinaikkan (Floating) agar sejajar dengan senapan.
	   - Kepala menghadap Player.
	   - Unanchored + PlatformStand (Melee Works & Freeze).
	2. AUTO ATTACK: Support Gun & Melee.
	3. AUTO COLLECT: Aggressive Loop (Pilihan User).
	4. AUTO REVIVE: V6 Stable.
]]

if game:GetService("CoreGui"):FindFirstChild("ToraScript") then
    game:GetService("CoreGui").ToraScript:Destroy()
end

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/liebertsx/Tora-Library/main/src/librarynew", true))()
local win = lib:CreateWindow("Survive Wave Z")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- ==========================================
-- 1. BRING MOBS (LEVITATING RAGDOLL)
-- ==========================================
local dist = 3 
local height = 3.5 -- Tinggi levitasi (biar pas di depan senapan)

win:AddSlider({text="Jarak Depan",min=1,max=20,value=3,callback=function(v) dist=v end})
win:AddSlider({text="Tinggi (Levitasi)",min=0,max=10,value=3.5,callback=function(v) height=v end})

local bringOn = false
win:AddToggle({text="Bring Mobs (Floating)",callback=function(t)
    bringOn = t
    if t then
        spawn(function()
            while bringOn do
                task.wait() -- Loop cepat (Magnet)
                pcall(function()
                    local zombieFolder = Workspace:FindFirstChild("ServerZombies") or Workspace
                    
                    for _,z in pairs(zombieFolder:GetDescendants()) do
                        if not bringOn then break end
                        
                        if z.Name=="Humanoid" and z.Health>0 and z.RootPart then
                             if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                local myRoot = LocalPlayer.Character.HumanoidRootPart
                                local zRoot = z.RootPart
                                
                                -- 1. HITUNG POSISI DI DEPAN + KE ATAS (LEVITASI)
                                -- Ditambah Vector3.new(0, height, 0) agar naik ke udara
                                local targetPos = myRoot.CFrame.Position + (myRoot.CFrame.LookVector * dist) + Vector3.new(0, height, 0)
                                
                                -- 2. LOGIKA ROTASI (HEAD FIRST)
                                -- Zombie menghadap kita
                                local facePlayer = CFrame.lookAt(targetPos, myRoot.Position + Vector3.new(0, height, 0))
                                
                                -- Putar -90 derajat (Tidur), Kepala mengarah ke kita
                                zRoot.CFrame = facePlayer * CFrame.Angles(math.rad(-90), 0, 0)
                                
                                -- 3. SETTING FISIKA
                                zRoot.Anchored = false 
                                z.PlatformStand = true -- Lumpuh
                                z:ChangeState(Enum.HumanoidStateType.Physics) -- Ragdoll State
                                
                                -- 4. SAFETY & RESET
                                zRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
                                
                                -- Matikan Tabrakan
                                for _, part in pairs(z.Parent:GetChildren()) do
                                    if part:IsA("BasePart") then
                                        part.CanCollide = false
                                    end
                                end
                            end
                        end
                    end
                end)
            end
            
            -- RESET SAAT MATI
            pcall(function()
                local zombieFolder = Workspace:FindFirstChild("ServerZombies") or Workspace
                for _,z in pairs(zombieFolder:GetDescendants()) do
                    if z.Name=="Humanoid" and z.RootPart then 
                        z.PlatformStand = false
                        z:ChangeState(Enum.HumanoidStateType.GettingUp)
                        for _, part in pairs(z.Parent:GetChildren()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = true
                            end
                        end
                    end
                end
            end)
        end)
    end
end})

-- ==========================================
-- 2. AUTO ATTACK (GUN & MELEE)
-- ==========================================
local shootOn = false
win:AddToggle({text="Auto Attack (Gun/Melee)",callback=function(t)
    shootOn = t
    if t then
        spawn(function()
            while shootOn do
                task.wait()
                local char = LocalPlayer.Character
                if char then
                    local gun = char:FindFirstChildOfClass("Model") or char:FindFirstChildOfClass("Tool")
                    
                    local hasTarget = false
                    if Workspace:FindFirstChild("ServerZombies") and Workspace.ServerZombies:FindFirstChildOfClass("Model") then
                        hasTarget = true
                    end

                    if gun and hasTarget then
                        gun:SetAttribute("IsShooting", true)
                        
                        if gun:FindFirstChild("Activate") then
                             gun:Activate()
                        elseif char:FindFirstChildOfClass("Tool") then
                             char:FindFirstChildOfClass("Tool"):Activate()
                        end
                        
                        task.wait()
                        gun:SetAttribute("IsShooting", false)
                    end
                end
            end
        end)
    end
end})

-- ==========================================
-- 3. AUTO COLLECT (AGGRESSIVE - USER CHOICE)
-- ==========================================
local collectOn = false
win:AddToggle({text="Auto Collect",callback=function(t)
    collectOn = t
    if t then
        spawn(function()
            while collectOn do
                task.wait()
                for _,p in pairs(workspace:GetChildren()) do
                    if not collectOn then break end
                    if p:IsA("Part") and p.Name~="Part" and p.Name~="Terrain" and p.Name~="Baseplate" then
                         pcall(function()
                             if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                p.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                             end
                        end)
                    end
                end
            end
        end)
    end
end})

-- ==========================================
-- 4. AUTO REVIVE (V6 - STABLE)
-- ==========================================
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

-- ==========================================
-- 5. EXTRAS
-- ==========================================
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

win:AddLabel({text="Ragdoll Floating (Gun Ready)"})
lib:Init()
