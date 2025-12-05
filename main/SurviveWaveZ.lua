--[[
	SURVIVE WAVE Z: COMPLETE SCRIPT
	Features:
	1. AUTO COLLECT: Menggunakan kode pilihan user (Aggressive Workspace Loop).
	2. SILENT AIM ATTACK: Menarik kepala zombie sejajar dengan senjata (Headshot Guarantee).
	3. AUTO REVIVE: Versi V6 (Anti-Void & Responsive).
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
-- 1. AUTO ATTACK + SILENT AIM (HEAD MAGNET)
-- ==========================================
local dist = 5 -- Jarak zombie dari pemain
local combatOn = false

win:AddSlider({text="Jarak Tembak",min=2,max=20,value=5,callback=function(v) dist=v end})

win:AddToggle({text="Auto Attack (Headshot)",callback=function(t)
    combatOn = t
    if t then
        spawn(function()
            while combatOn do
                task.wait() -- Loop sangat cepat (RenderStepped like)
                
                local char = LocalPlayer.Character
                if not char then continue end
                local myRoot = char:FindFirstChild("HumanoidRootPart")
                
                -- A. LOGIKA AUTO SHOOT
                local gun = char:FindFirstChildOfClass("Model") or char:FindFirstChildOfClass("Tool")
                if gun then
                    gun:SetAttribute("IsShooting",true)
                    -- Tidak perlu wait lama, spam secepat mungkin
                    task.wait() 
                    gun:SetAttribute("IsShooting",false)
                end

                -- B. LOGIKA SILENT AIM (HEAD MAGNET)
                -- Kita tarik zombie agar kepalanya sejajar dengan tembakan kita
                pcall(function()
                    local folder = Workspace:FindFirstChild("ServerZombies") or Workspace
                    for _, z in pairs(folder:GetDescendants()) do
                        if not combatOn then break end
                        
                        -- Validasi Zombie
                        if z.Name == "Humanoid" and z.Health > 0 and z.RootPart and z.Parent:FindFirstChild("Head") then
                            local zModel = z.Parent
                            local zRoot = z.RootPart
                            local zHead = zModel.Head
                            
                            if myRoot then
                                -- Hitung posisi di depan player (sesuai arah pandang)
                                local targetCFrame = myRoot.CFrame * CFrame.new(0, 0, -dist)
                                
                                -- [SILENT AIM TRICK]
                                -- Kita sesuaikan tinggi zombie agar KEPALANYA pas di tengah crosshair/senjata
                                -- Hitung selisih tinggi antara RootPart zombie dan Kepalanya
                                local headOffset = zHead.Position.Y - zRoot.Position.Y
                                
                                -- Geser posisi zombie ke bawah sedikit agar kepalanya sejajar dada/senjata kita
                                -- Kita kurangi Y dengan headOffset
                                local aimPosition = targetCFrame.Position - Vector3.new(0, headOffset - 1, 0) 
                                
                                zRoot.CFrame = CFrame.new(aimPosition, myRoot.Position) -- Hadapkan zombie ke kita
                                zRoot.Anchored = true
                            end
                        end
                    end
                end)
            end
            
            -- Lepas Zombie saat fitur mati
            pcall(function()
                local folder = Workspace:FindFirstChild("ServerZombies") or Workspace
                for _, z in pairs(folder:GetDescendants()) do
                    if z.Name == "Humanoid" and z.RootPart then z.RootPart.Anchored = false end
                end
            end)
        end)
    end
end})


-- ==========================================
-- 2. AUTO COLLECT (KODE PILIHAN KAMU)
-- ==========================================
local collectOn = false
win:AddToggle({text="Auto Collect",callback=function(t)
    collectOn = t
    if t then
        spawn(function()
            while collectOn do
                task.wait()
                -- Ini adalah kode persis yang kamu kirimkan:
                for _,p in workspace:GetChildren() do
                    if p:IsA("Part") and p.Name~="Part" and p.Name~="Terrain" then
                         -- Saya tambahkan pcall kecil agar script tidak stop jika karakter mati
                         pcall(function()
                            if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                p.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
                            end
                         end)
                    end
                end
            end
        end)
    end
end})


-- ==========================================
-- 3. AUTO REVIVE (V6 - STABLE & RESPONSIVE)
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
-- 4. EXTRAS
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

win:AddLabel({text="Silent Aim + Auto Revive Fix"})
lib:Init()
