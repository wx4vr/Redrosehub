--[[
    Spin to Upgrade - RedRoseHub Advanced Hub (Executor Execution Fix)
    PlaceId: 101054234503030
]]
 
if not game:IsLoaded() then
    game.Loaded:Wait()
end
 
-- Load Rayfield UI dengan proteksi ekstra untuk Executor (Delta/Fluxus/Dll)
local Success, Library = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
 
if not Success or not Library then
    -- Fallback jika link utama gagal di-load oleh executor
    Success, Library = pcall(function()
        return loadstring(game:HttpGet('https://raw.githubusercontent.com/sirius-uc/rayfield/main/source.lua'))()
    end)
end
 
if not Success or not Library then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "RedRoseHub Error",
        Text = "Gagal memuat UI Library! Cek koneksi internet Anda.",
        Duration = 7
    })
    return
end
 
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
 
-- Global Configuration States
_G.AutoClicker = false
_G.ClickSpeed = 0.05
_G.HitRadius = 25
_G.AuraMining = false
_G.InfiniteDamage = false
_G.AutoUpgrade = false
_G.BossKiller = false
_G.TargetPickaxe = ""
_G.AutoFarmZone = false
 
_G.DropBonusEnabled = false
_G.DropBonusMultiplier = 1
_G.AutoSellEnabled = false
 
-- Safe Remote References
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 15)
local Remotes = SharedFolder and SharedFolder:WaitForChild("Remotes", 15)
 
local MineRockEvent = Remotes and Remotes:FindFirstChild("MineRock")
local RockHitEvent = Remotes and Remotes:FindFirstChild("RockHit")
local EquipPickaxeEvent = Remotes and Remotes:FindFirstChild("EquipPickaxe")
local TeleportToZoneEvent = Remotes and Remotes:FindFirstChild("TeleportToZone")
local BuyUpgradeEvent = Remotes and Remotes:FindFirstChild("BuyUpgrade")
local OreDroppedEvent = Remotes and Remotes:FindFirstChild("OreDropped")
local SellOresRemote = Remotes and Remotes:FindFirstChild("SellOres")
 
local ZonesConfig = {}
local EconomyConfig = {}
 
pcall(function()
    ZonesConfig = require(SharedFolder.Config:WaitForChild("Zones"))
end)
 
pcall(function()
    EconomyConfig = require(SharedFolder.Config:WaitForChild("Economy"))
end)
 
-- Helper: Trigger DropBonus Multiplier
local function TriggerDropBonus()
   if _G.DropBonusEnabled and OreDroppedEvent then
      local multiplier = math.clamp(_G.DropBonusMultiplier, 1, 200)
      pcall(function()
         for i = 1, math.min(multiplier, 50) do
            OreDroppedEvent:FireServer(1)
         end
      end)
   end
end
 
-- Create Window (RedRoseHub Theme)
local Window = Library:CreateWindow({
   Name = "Spin to Upgrade | RedRoseHub",
   LoadingTitle = "RedRoseHub Initializing...",
   LoadingSubtitle = "Loaded Successfully!",
   ConfigurationSaving = { Enabled = false, FolderName = "RedRoseHubSpinToUpgrade", FileName = "Config" },
   KeySystem = false,
})
 
-- Tabs Setup
local MiningTab = Window:CreateTab("Mining & Damage", 4483362458)
local BossTab = Window:CreateTab("Boss Killer", 4483362458)
local UpgradeTab = Window:CreateTab("Auto Upgrades", 4483362458)
local ZoneTab = Window:CreateTab("Zones & Teleport", 4483362458)
local EquipmentTab = Window:CreateTab("Equipment & Shop", 4483362458)
 
-- ==========================================
-- TAB 1: MINING & DROPBONUS MULTIPLIER
-- ==========================================
MiningTab:CreateSection("Auto Click & Fast Swing")
 
MiningTab:CreateToggle({
   Name = "Auto Clicker (Fast Swing)",
   CurrentValue = false,
   Callback = function(Value)
      _G.AutoClicker = Value
      task.spawn(function()
         while _G.AutoClicker do
            pcall(function()
               if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                  local hrp = LocalPlayer.Character.HumanoidRootPart
                  for _, obj in ipairs(workspace:GetDescendants()) do
                     if obj.Name == "Rock" then
                        local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                        if part and part:IsA("BasePart") then
                           local distance = (part.Position - hrp.Position).Magnitude
                           if distance <= _G.HitRadius then
                              if MineRockEvent then MineRockEvent:FireServer(obj) end
                              if firesignal and RockHitEvent then
                                 local dmgPayload = _G.InfiniteDamage and 999999999 or 1
                                 firesignal(RockHitEvent.OnClientEvent, part.Position, dmgPayload, false, 999)
                              end
                              TriggerDropBonus()
                              break
                           end
                        end
                     end
                  end
               end
            end)
            task.wait(_G.ClickSpeed)
         end
      end)
   end,
})
 
MiningTab:CreateSlider({
   Name = "Auto Click Speed (Delay)",
   Range = {0.01, 0.5},
   Increment = 0.01,
   CurrentValue = 0.05,
   Callback = function(Value)
      _G.ClickSpeed = Value
   end,
})
 
MiningTab:CreateSection("DropBonus & Sell Multipliers")
 
MiningTab:CreateToggle({
   Name = "Enable DropBonus Multiplier",
   CurrentValue = false,
   Callback = function(Value)
      _G.DropBonusEnabled = Value
      Library:Notify({Title = "DropBonus", Content = Value and "DropBonus Diaktifkan!" or "DropBonus Dimatikan.", Duration = 2})
   end,
})
 
MiningTab:CreateSlider({
   Name = "DropBonus Multiplier (1x - 200x)",
   Range = {1, 200},
   Increment = 1,
   CurrentValue = 10,
   Callback = function(Value)
      _G.DropBonusMultiplier = Value
   end,
})
 
MiningTab:CreateToggle({
   Name = "Auto Sell Ores (Loop)",
   CurrentValue = false,
   Callback = function(Value)
      _G.AutoSellEnabled = Value
      task.spawn(function()
         while _G.AutoSellEnabled do
            pcall(function()
               if SellOresRemote then
                  SellOresRemote:InvokeServer("All")
               end
            end)
            task.wait(3)
         end
      end)
   end,
})
 
MiningTab:CreateButton({
   Name = "Instant Sell All Ores Once",
   Callback = function()
      pcall(function()
         if SellOresRemote then
            SellOresRemote:InvokeServer("All")
            Library:Notify({Title = "Sell Ores", Content = "Berhasil menjual seluruh ore!", Duration = 2})
         end
      end)
   end,
})
 
MiningTab:CreateSection("Zone Hit Aura & Infinite Damage")
 
MiningTab:CreateToggle({
   Name = "Enable Zone Hit Aura (Optimized)",
   CurrentValue = false,
   Callback = function(Value)
      _G.AuraMining = Value
      task.spawn(function()
         while _G.AuraMining do
            pcall(function()
               if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                  local hrp = LocalPlayer.Character.HumanoidRootPart
                  local zonesFolder = workspace:FindFirstChild("Zones")
                  if zonesFolder then
                     for _, zoneData in ipairs(ZonesConfig) do
                        local zoneFolder = zonesFolder:FindFirstChild(zoneData.Id)
                        if zoneFolder then
                           local rockSpawns = zoneFolder:FindFirstChild("RockSpawns") or zoneFolder
                           for _, obj in ipairs(rockSpawns:GetDescendants()) do
                              if obj.Name == "Rock" then
                                 local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                                 if part and part:IsA("BasePart") then
                                    local distance = (part.Position - hrp.Position).Magnitude
                                    if distance <= _G.HitRadius then
                                       if MineRockEvent then MineRockEvent:FireServer(obj) end
                                       if firesignal and RockHitEvent then
                                          local dmgPayload = _G.InfiniteDamage and 999999999 or 1
                                          firesignal(RockHitEvent.OnClientEvent, part.Position, dmgPayload, false, 999)
                                       end
                                       TriggerDropBonus()
                                    end
                                 end
                              end
                           end
                        end
                     end
                  end
               end
            end)
            task.wait(0.1)
         end
      end)
   end,
})
 
MiningTab:CreateToggle({
   Name = "Enable Infinite / Huge Damage",
   CurrentValue = false,
   Callback = function(Value)
      _G.InfiniteDamage = Value
      Library:Notify({Title = "Damage Mode", Content = Value and "Infinite Damage Aktif!" or "Damage Normal.", Duration = 2})
   end,
})
 
MiningTab:CreateSlider({
   Name = "Hit & Click Aura Radius Size",
   Range = {10, 150},
   Increment = 5,
   CurrentValue = 25,
   Callback = function(Value)
      _G.HitRadius = Value
   end,
})
 
-- ==========================================
-- TAB 2: BOSS KILLER
-- ==========================================
BossTab:CreateSection("Event Boss Automation")
 
BossTab:CreateToggle({
   Name = "Auto Kill Event Boss (Instant Hit)",
   CurrentValue = false,
   Callback = function(Value)
      _G.BossKiller = Value
      task.spawn(function()
         while _G.BossKiller do
            pcall(function()
               if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                  local hrp = LocalPlayer.Character.HumanoidRootPart
                  for _, obj in ipairs(workspace:GetDescendants()) do
                     local nameLower = string.lower(obj.Name)
                     if string.find(nameLower, "boss") or string.find(nameLower, "lucky") or string.find(nameLower, "event") then
                        local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                        if part and part:IsA("BasePart") then
                           if MineRockEvent then MineRockEvent:FireServer(obj) end
                           if firesignal and RockHitEvent then
                              firesignal(RockHitEvent.OnClientEvent, part.Position, 999999999, false, 999)
                           end
                           TriggerDropBonus()
                        end
                     end
                  end
               end
            end)
            task.wait(0.1)
         end
      end)
   end,
})
 
-- ==========================================
-- TAB 3: AUTO UPGRADES
-- ==========================================
UpgradeTab:CreateSection("Automated Upgrades Board")
 
UpgradeTab:CreateToggle({
   Name = "Auto-Buy All Available Upgrades",
   CurrentValue = false,
   Callback = function(Value)
      _G.AutoUpgrade = Value
      task.spawn(function()
         while _G.AutoUpgrade do
            pcall(function()
               if EconomyConfig and EconomyConfig.Upgrades and BuyUpgradeEvent then
                  for _, upgradeData in ipairs(EconomyConfig.Upgrades) do
                     if upgradeData and upgradeData.Id then
                        BuyUpgradeEvent:InvokeServer(upgradeData.Id)
                        task.wait(0.1)
                     end
                  end
               end
            end)
            task.wait(1)
         end
      end)
   end,
})
 
UpgradeTab:CreateButton({
   Name = "Instant Buy All Upgrades Once",
   Callback = function()
      pcall(function()
         if EconomyConfig and EconomyConfig.Upgrades and BuyUpgradeEvent then
            for _, upgradeData in ipairs(EconomyConfig.Upgrades) do
               if upgradeData and upgradeData.Id then
                  BuyUpgradeEvent:InvokeServer(upgradeData.Id)
               end
            end
            Library:Notify({Title = "Upgrades", Content = "Memicu pembelian semua upgrade sekaligus.", Duration = 3})
         end
      end)
   end,
})
 
-- ==========================================
-- TAB 4: ZONES & AUTO-FARM TELEPORT
-- ==========================================
ZoneTab:CreateSection("Auto Farm & Zone Teleportation")
 
ZoneTab:CreateToggle({
   Name = "Auto Farm Best Zone (Teleport & Mine)",
   CurrentValue = false,
   Callback = function(Value)
      _G.AutoFarmZone = Value
      task.spawn(function()
         while _G.AutoFarmZone do
            pcall(function()
               if TeleportToZoneEvent then
                  TeleportToZoneEvent:FireServer("Best")
               end
               
               if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                  local hrp = LocalPlayer.Character.HumanoidRootPart
                  local zonesFolder = workspace:FindFirstChild("Zones")
                  if zonesFolder then
                     for _, zoneData in ipairs(ZonesConfig) do
                        local zoneFolder = zonesFolder:FindFirstChild(zoneData.Id)
                        if zoneFolder then
                           local rockSpawns = zoneFolder:FindFirstChild("RockSpawns") or zoneFolder
                           for _, obj in ipairs(rockSpawns:GetDescendants()) do
                              if obj.Name == "Rock" then
                                 local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                                 if part and part:IsA("BasePart") and (part.Position - hrp.Position).Magnitude <= _G.HitRadius then
                                    if MineRockEvent then MineRockEvent:FireServer(obj) end
                                    if firesignal and RockHitEvent then
                                       local dmgPayload = _G.InfiniteDamage and 999999999 or 1
                                       firesignal(RockHitEvent.OnClientEvent, part.Position, dmgPayload, false, 999)
                                    end
                                    TriggerDropBonus()
                                 end
                              end
                           end
                        end
                     end
                  end
               end
            end)
            task.wait(0.2)
         end
      end)
   end,
})
 
ZoneTab:CreateDropdown({
   Name = "Select Specific Zone to Farm",
   Options = {"Mine1", "Grotto", "Mine2", "Tomb", "Mine3", "Mine4", "Toxic", "Sky", "Mine5", "Moon", "Mine6", "Glacier", "Atlantis", "Dragon", "Neon", "BlackHole", "Clockwork", "Glitch"},
   CurrentOption = "Mine1",
   Callback = function(Option)
      pcall(function()
         if TeleportTab then end
         if TeleportToZoneEvent then
            TeleportToZoneEvent:FireServer(Option)
            Library:Notify({Title = "Zone Teleport", Content = "Berpindah ke zona: " .. Option, Duration = 2})
         end
      end)
   end,
})
 
-- ==========================================
-- TAB 5: EQUIPMENT & PICKAXE GIVER
-- ==========================================
EquipmentTab:CreateSection("Pickaxe Giver & Bypass")
 
EquipmentTab:CreateInput({
   Name = "Pickaxe Name / ID",
   PlaceholderText = "Contoh: StonePickaxe, DiamondPickaxe",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      _G.TargetPickaxe = Text
   end,
})
 
EquipmentTab:CreateButton({
   Name = "Equip / Give Selected Pickaxe",
   Callback = function()
      if _G.TargetPickaxe and _G.TargetPickaxe ~= "" then
         pcall(function()
            if EquipPickaxeEvent then
               EquipPickaxeEvent:FireServer(_G.TargetPickaxe)
            end
            Library:Notify({Title = "Pickaxe Bypass", Content = "Permintaan equip dikirim: " .. _G.TargetPickaxe, Duration = 3})
         end)
      else
         Library:Notify({Title = "Peringatan", Content = "Masukkan nama pickaxe terlebih dahulu!", Duration = 3})
      end
   end,
})
 
Library:Notify({
   Title = "RedRoseHub Loaded",
   Content = "Script berhasil dimuat dan siap digunakan!",
   Duration = 5
})
 
