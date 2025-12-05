--[[
	SCRIPT KHUSUS: MAGNET DROP COLLECTOR
	Logika Baru:
	1. Hanya mengambil benda yang DIAM (Velocity 0). Peluru/VFX bergerak, jadi tidak akan terambil.
	2. Hanya mengambil benda KECIL (Size < 5).
	3. Aman dari Map & Zombie.
]]

if game:GetService("CoreGui"):FindFirstChild("ToraScript") then
    game:GetService("CoreGui").ToraScript:Destroy()
end

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/liebertsx/Tora-Library/main/src/librarynew", true))()
local win = lib:CreateWindow("Survive Wave Z (Magnet)")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- == 1. ZOMBIE BRING == --
local dist = 6
win:AddSlider({text="Jarak Zombie",min=2,max=20,value=6,callback=function(v) dist=v end})

local bringOn = false
win:AddToggle({text="Tarik Zombie (Bring)",callback=function(t)
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
            -- Lepas zombie saat fitur mati
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

-- == 3. AUTO COLLECT (MAGNET SYSTEM) == --
local collectOn = false
win:AddToggle({text="Auto Collect (Magnet)",callback=function(t)
    collectOn = t
    if t then
        spawn(function()
            while collectOn do
                task.wait(0.1) -- Cek sangat cepat
                pcall(function()
                    for _,p in pairs(Workspace:GetDescendants()) do
                        if not collectOn then break end
                        
                        -- SYARAT 1: Benda Fisik, Tidak Anchored, Bukan Terrain
                        if p:IsA("BasePart") and not p.Anchored and p.Name ~= "Terrain" then
                            
                            -- SYARAT 2: UKURAN (Item drop pasti kecil)
                            if p.Size.Magnitude > 6 then continue end -- Jangan ambil benda besar

                            -- SYARAT 3: ANTI-MAKHLUK HIDUP (Jangan ambil tangan/kaki zombie/player)
                            if p.Parent:FindFirstChild("Humanoid") or p.Parent.Parent:FindFirstChild("Humanoid") then
                                continue 
                            end

                            -- SYARAT 4 (KUNCI): KECEPATAN (Velocity)
                            -- Item Drop itu DIAM di tanah. Peluru/VFX itu BERGERAK CEPAT.
                            -- Jika kecepatan benda mendekati 0, berarti itu ITEM.
                            if p.AssemblyLinearVelocity.Magnitude < 1.0 then 
                                
                                -- TELEPORT ITEM KE BADAN KITA (Efek Magnet Instan)
                                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                    p.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                                    
                                    -- Reset velocity biar itemnya gak mental
                                    p.AssemblyLinearVelocity = Vector3.new(0,0,0) 
                                end
                            end
                        end
                    end
                end)
            end
        end)
    end
end})

-- == FITUR BANTUAN: SCAN NAMA ITEM == --
-- Gunakan ini kalau masih bingung item apa yang belum keambil
win:AddButton({text="[SCAN] Cek Nama Item Dekat", callback=function()
    local found = false
    print("--- MULAI SCAN ---")
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        for _, p in pairs(Workspace:GetDescendants()) do
            if p:IsA("BasePart") and not p.Anchored and p.Name ~= "Terrain" then
                -- Cari benda kecil unanchored dalam radius 10 meter
                if (p.Position - myPos).Magnitude < 15 and p.Size.Magnitude < 6 then
                    if not p.Parent:FindFirstChild("Humanoid") then
                         -- Kirim Notifikasi ke Layar
                         game:GetService("StarterGui"):SetCore("SendNotification", {
                            Title = "Item Ditemukan!",
                            Text = "Nama: " .. p.Name .. " | Parent: " .. p.Parent.Name,
                            Duration = 5
                        })
                        print("ITEM: " .. p.Name .. " (di dalam folder: " .. p.Parent.Name .. ")")
                        found = true
                    end
                end
            end
        end
    end
    if not found then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Scan Selesai",
            Text = "Tidak ada item drop di dekatmu.",
            Duration = 3
        })
    end
end})

-- == 4. AUTO REVIVE V6 (Final Responsive) == --
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

win:AddLabel({text="Magnet Collect + Fix Revive"})
lib:Init()
