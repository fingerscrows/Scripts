--[[
	FIXED SCRIPT V5: FINAL STABLE
	Author: AI Assistant
	
	PERBAIKAN UTAMA:
	1. AUTO REVIVE:
	   - Ditambahkan 'pcall' (Anti-Crash): Script tidak akan berhenti jika ada player glitch.
	   - Metode Pencarian: Mencari ProximityPrompt di SELURUH BADAN (bukan cuma kepala).
	   - Anti-Void: Teleport menggunakan Posisi (Vector3), bukan CFrame (Rotasi). Kamu akan selalu berdiri tegak.
	   - Instant Check: Langsung mendeteksi mayat yang SUDAH ADA saat tombol ditekan.
	2. AUTO COLLECT: Safe Mode (Anti-Magnet Player/Zombie).
]]

if game:GetService("CoreGui"):FindFirstChild("ToraScript") then
    game:GetService("CoreGui").ToraScript:Destroy()
end

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/liebertsx/Tora-Library/main/src/librarynew", true))()
local win = lib:CreateWindow("Survive Wave Z (Fixed V5)")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- == 1. ZOMBIE BRING (SAFE) == --
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

-- == 3. AUTO COLLECT (ANTI-MAGNET) == --
local collectOn = false
win:AddToggle({text="Auto Collect Drops",callback=function(t)
    collectOn = t
    if t then
        spawn(function()
            while collectOn do
                task.wait(0.2)
                pcall(function()
                    for _,p in pairs(Workspace:GetDescendants()) do
                        if p:IsA("BasePart") and not p.Anchored then
                            -- Filter Sampah
                            if p.Name == "Terrain" or p.Name == "Baseplate" then continue end
                            
                            -- Filter Anti-Magnet (Cek Humanoid di Parent & Grandparent)
                            local parentHum = p.Parent:FindFirstChild("Humanoid")
                            local grandParentHum = p.Parent.Parent and p.Parent.Parent:FindFirstChild("Humanoid")
                            
                            if parentHum or grandParentHum then continue end -- SKIP jika milik Zombie/Player
                            
                            -- Filter Ukuran (Item drop biasanya kecil)
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

-- == 4. AUTO REVIVE (ANTI-CRASH & ANTI-VOID) == --
local reviveOn = false
win:AddToggle({text="Auto Revive (Fix)", callback=function(t)
    reviveOn = t
    if t then
        spawn(function()
            local lastRevive = 0
            
            while reviveOn do
                task.wait(0.2) -- Loop Check Speed
                
                -- Gunakan pcall agar script tidak mati jika ada error
                pcall(function()
                    local char = LocalPlayer.Character
                    if not char then return end
                    
                    local myRoot = char:FindFirstChild("HumanoidRootPart")
                    local myHum = char:FindFirstChild("Humanoid")
                    
                    -- Pastikan kita hidup
                    if myRoot and myHum and myHum.Health > 0 then
                        
                        -- Loop semua player
                        for _, plr in pairs(Players:GetPlayers()) do
                            if plr == LocalPlayer then continue end
                            
                            local tChar = plr.Character
                            if not tChar then continue end
                            
                            local tHum = tChar:FindFirstChild("Humanoid")
                            local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                            
                            -- Cek apakah player ini Mati/Knocked
                            if tHum and tRoot and tHum.Health <= 0 then
                                
                                -- SCAN MENCARI TOMBOL REVIVE (Di seluruh badan)
                                local promptFound = nil
                                for _, part in pairs(tChar:GetDescendants()) do
                                    if part:IsA("ProximityPrompt") and part.Enabled then
                                        promptFound = part
                                        break
                                    end
                                end
                                
                                -- Jika tombol ketemu & Cooldown aman
                                if promptFound and (tick() - lastRevive >= 1.0) then
                                    
                                    -- == LOGIKA TELEPORT AMAN (ANTI VOID) ==
                                    -- 1. Ambil Posisi Murni mayat (Abaikan rotasi miring/terbalik)
                                    local targetPos = tRoot.Position
                                    
                                    -- 2. Teleport tegak lurus (CFrame.new tanpa rotasi), 4 stud di atasnya
                                    myRoot.CFrame = CFrame.new(targetPos + Vector3.new(0, 4, 0))
                                    
                                    -- 3. Matikan Velocity agar tidak terpental
                                    myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
                                    myRoot.AssemblyAngularVelocity = Vector3.new(0,0,0)
                                    
                                    task.wait(0.2) -- Waktu untuk server sync posisi
                                    
                                    -- 4. Tekan Tombol
                                    fireproximityprompt(promptFound)
                                    lastRevive = tick()
                                    
                                    -- Break loop sebentar (Fokus revive 1 orang dulu)
                                    task.wait(0.5) 
                                    return -- Keluar dari pcall, lanjut loop while
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

win:AddLabel({text="Final Fix: Anti-Crash Logic"})
lib:Init()
