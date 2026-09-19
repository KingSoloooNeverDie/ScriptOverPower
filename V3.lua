local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local c = player
local displayName = c.DisplayName

local leaderstats = c:WaitForChild("leaderstats")
local startRebirths = leaderstats:WaitForChild("Rebirths").Value
local petsFolder = c:WaitForChild("petsFolder")
local rEvents = ReplicatedStorage:WaitForChild("rEvents")
local tradingEvent = rEvents:WaitForChild("tradingEvent")

local TargetStrength = 0
local selectedPetName = ""
local selectedPlayer = nil
local autoTradeToSelected = false
local autoTradeToAll = false
local PET_COUNT = 6
local repCount = 1

local function parseInput(text)
    local result = text:lower():gsub(",", "")
    local multiplier = 1
    if result:find("k") then multiplier = 1000
    elseif result:find("m") then multiplier = 1000000
    elseif result:find("b") then multiplier = 1000000000
    elseif result:find("t") then multiplier = 1000000000000
    end
    local num = tonumber(result:match("[%d%.]+"))
    return num and (num * multiplier) or 0
end

local function equipTool(toolName)
    local backpack = player:FindFirstChild("Backpack")
    local char = player.Character
    if backpack and char and char:FindFirstChild("Humanoid") then
        local tool = backpack:FindFirstChild(toolName)
        if tool then char.Humanoid:EquipTool(tool) end
    end
end

local function unequipTool(toolName)
    local char = player.Character
    if char and char:FindFirstChild(toolName) then
        char[toolName].Parent = player.Backpack
    end
end

local function startAutoRep(flagName, toolName)
    task.spawn(function()
        while _G[flagName] do
            local char = player.Character
            if not char or not char:FindFirstChild("Humanoid") then task.wait(0.5) continue end
            if not char:FindFirstChild(toolName) then equipTool(toolName) end
            if player:FindFirstChild("muscleEvent") then player.muscleEvent:FireServer("rep") end
            task.wait(0.3)
        end
    end)
end

local ModernV2 = loadstring(game:HttpGet("https://raw.githubusercontent.com/KingSoloooNeverDie/ScriptOverPower/refs/heads/main/Ui%20Library.lua"))()

ModernV2:AddTheme({
    Name = "Putih Hitam",
    Accent = Color3.fromRGB(0, 0, 0),
    Background = Color3.fromRGB(245, 245, 245),
    Outline = Color3.fromRGB(50, 50, 50),
    Placeholder = Color3.fromRGB(150, 150, 150),
})

ModernV2.Scales = {
    Small   = UDim2.fromOffset(420, 290),
    Compact = UDim2.fromOffset(600, 380),
    Mobile  = UDim2.fromOffset(640, 385),
    Default = UDim2.fromOffset(640, 480),
    Large   = UDim2.fromOffset(800, 600),
}

local MenuIcon = ModernV2:CreateMenuIcon({
    Image = "rbxassetid://91981940230704",
    Size = 48,
    IconColor = Color3.fromRGB(255, 255, 255),
    BGColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeThick = 0.05,
    Draggable = true,
})

local window = ModernV2:Window({
    Title = "V̬uz͠o̵ Zilu͢x",
    Content = "      By ZorVex",
    Image = "91981940230704",
    Color = Color3.fromRGB(0, 0, 0),
    Uitransparent = 0.18,
    ShowUser = true,
    Size = ModernV2.IsMobile and ModernV2.Scales.Small,
    Search = false,
    ConfigEnabled = true,
    NotifyOnCallbackError = false,
    Loadingscreen = false,
    Enable3DRenderer = false,
    Keybind = "RightControl",
    Config = {
        ConfigFolder = "VuzoZiluxHub/musclelegends",
        AutoSaveFile = "Default",
        AutoSave = false,
        AutoLoad = true,
        Overwrite = true,
        Format = "JSON",
        ShowAutoSaveToggle = true,
        TextGradient = false,
    },
})

window:AttachMenuIcon(MenuIcon)
window:OnDestroy(function() end)

window:SetAccount({
    Username = player.DisplayName,
    Profile = ModernV2.UserProfile,
    Expires = "Welcome",
})

local flagCounter = 0
local function genFlag()
    flagCounter = flagCounter + 1
    return "ZorVexFlag_" .. flagCounter
end

do
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local VirtualUser = game:GetService("VirtualUser")

    local statsTab = window:AddTab({
        Name = "Stats",
        Icon = "lucide:trending-up",
        Type = "Single",
    })

    local statsSystem = {
        UseCompact = true,
        StartTime = tick(),
        PlayerOriginalStats = {},
        SelectedPlayer = player,
        IsDropdownOpen = false
    }

    function statsSystem:FormatNumber(n)
        n = tonumber(n) or 0
        if not self.UseCompact then
            local formatted = tostring(math.floor(n))
            while true do
                local k
                formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
                if (k == 0) then break end
            end
            return formatted
        end
        if n < 1000 then return tostring(math.floor(n)) end
        local symbols = {"", "k", "M", "B", "T", "Qa", "Qi"}
        local symbolIndex = math.min(math.floor(math.log10(n) / 3), #symbols - 1)
        local value = math.floor((n / 10^(symbolIndex * 3)) * 10) / 10
        return string.format("%.1f", value):gsub("%.0$", "") .. symbols[symbolIndex + 1]
    end

    function statsSystem:FindStat(plr, name)
        if not plr then return nil end
        local nameLower = name:lower()
        for _, obj in ipairs(plr:GetChildren()) do
            if obj.Name:lower() == nameLower and (obj:IsA("NumberValue") or obj:IsA("IntValue")) then
                return obj
            end
        end
        local ls = plr:FindFirstChild("leaderstats")
        if ls then
            for _, obj in ipairs(ls:GetChildren()) do
                if obj.Name:lower() == nameLower then return obj end
            end
        end
        local dataFolder = plr:FindFirstChild("Data") or plr:FindFirstChild("Stats")
        if dataFolder then
            for _, obj in ipairs(dataFolder:GetChildren()) do
                if obj.Name:lower() == nameLower then return obj end
            end
        end
        return nil
    end

    function statsSystem:StoreOriginalStats(plr)
        if not plr or self.PlayerOriginalStats[plr] then return end
        local statsTable = {}
        local trackList = {"Rebirths", "Strength", "Durability", "Kills", "evilKarma", "goodKarma", "Agility", "Brawl", "Brawls", "BrawlStats"}
        for _, name in ipairs(trackList) do
            local obj = self:FindStat(plr, name)
            if obj then statsTable[name] = obj.Value or 0 end
        end
        self.PlayerOriginalStats[plr] = statsTable
    end

    function statsSystem:GetPlayerNames()
        local names = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            table.insert(names, plr.DisplayName)
        end
        return names
    end

    local viewPlayerSection = statsTab:AddSection({ Name = "View Stats Player" })

    local targetPlayerDropdown = viewPlayerSection:AddDropdown({
        Name = "Select Player Target",
        Values = statsSystem:GetPlayerNames(),
        OptionsProvider = function()
            return statsSystem:GetPlayerNames()
        end,
        RefreshInterval = 2,
        Default = player.DisplayName,
        Flag = genFlag(),
        Callback = function(v)
            local cleanName = v:gsub("<[^>]*>", ""):gsub(" %(Left%)", "")
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.DisplayName == cleanName then
                    statsSystem.SelectedPlayer = plr
                    return
                end
            end
            statsSystem.SelectedPlayer = nil
        end
    })

    viewPlayerSection:AddToggle({
        Name = "Compact Stats View",
        Default = true,
        Flag = genFlag(),
        Callback = function(state) statsSystem.UseCompact = state end
    })

    local statsPara = viewPlayerSection:AddParagraph({
        Name = "Stats",
        Content = "Loading...",
        RichText = true,
    })

    local gainedPara = viewPlayerSection:AddParagraph({
        Name = "Stats Gained",
        Content = "Loading...",
        RichText = true,
    })

    local timerPara = viewPlayerSection:AddParagraph({
        Name = "AFK Timer",
        Content = "AFK TIME: 00:00:00",
        RichText = true,
    })

    for _, p in ipairs(Players:GetPlayers()) do
        statsSystem:StoreOriginalStats(p)
    end

    Players.PlayerAdded:Connect(function(plr)
        statsSystem:StoreOriginalStats(plr)

        if targetPlayerDropdown and targetPlayerDropdown.SetValues then
            targetPlayerDropdown:SetValues(statsSystem:GetPlayerNames())
        end
    end)

    Players.PlayerRemoving:Connect(function(plr)
        if targetPlayerDropdown and targetPlayerDropdown.SetValues then
            targetPlayerDropdown:SetValues(statsSystem:GetPlayerNames())
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.2)

            local target = (statsSystem.SelectedPlayer and statsSystem.SelectedPlayer.Parent) and statsSystem.SelectedPlayer or player
            local statsParts = {}
            local gainedParts = {}
            local orderedStats = {
                {I = "Rebirths", D = "Rebirth"},
                {I = "Strength", D = "Strength"},
                {I = "Durability", D = "Durability"},
                {I = "Kills", D = "Kill"},
                {I = "evilKarma", D = "Evil Karma"},
                {I = "goodKarma", D = "Good Karma"},
                {I = "Agility", D = "Agility"},
                {I = "Brawl", D = "Brawl"}
            }

            for _, s in ipairs(orderedStats) do
                local obj = statsSystem:FindStat(target, s.I)
                if not obj and s.I == "Brawl" then
                    obj = statsSystem:FindStat(target, "Brawls") or statsSystem:FindStat(target, "BrawlStats")
                end
                
                local val = obj and obj.Value or 0

                local orig = val
                if statsSystem.PlayerOriginalStats[target] then
                    local pStats = statsSystem.PlayerOriginalStats[target]
                    orig = pStats[s.I] or (s.I == "Brawl" and (pStats["Brawls"] or pStats["BrawlStats"])) or val
                end
                
                table.insert(statsParts, s.D .. ": " .. statsSystem:FormatNumber(val))
                table.insert(gainedParts, s.D .. ": +" .. statsSystem:FormatNumber(val - orig))
            end

            statsPara:SetContent(table.concat(statsParts, "\n"))
            gainedPara:SetContent(table.concat(gainedParts, "\n"))

            local elapsed = tick() - statsSystem.StartTime
            local timeStr = string.format("%02d:%02d:%02d", math.floor(elapsed/3600), math.floor((elapsed%3600)/60), math.floor(elapsed%60))
            timerPara:SetContent("AFK TIME: " .. timeStr)
        end
    end)

    pcall(function() 
        if getconnections then 
            for _, v in pairs(getconnections(player.Idled)) do 
                if v.Disable then v:Disable() elseif v.Disconnect then v:Disconnect() end 
            end 
        end 
    end)

    player.Idled:Connect(function() 
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new()) 
    end)
end

do
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer

    local farmingTab = window:AddTab({
        Name = "Farming",
        Icon = "lucide:cpu",
        Type = "Single",
    })

    local farmingTabbox1 = farmingTab:AddTabbox({ Name = "Farming 1", Position = "center" })

    local vipTab = farmingTabbox1:AddTab("Vip", "lucide:crown")
    vipTab:AddDivider({ Text = "Vip Mode" })
    vipTab:AddTextInput({
        Name = "Set Repetition",
        Placeholder = "Set Fast Strength",
        Default = "",
        Callback = function(text)
            local num = tonumber(text)
            if num then repCount = num end
        end
    })

    vipTab:AddToggle({
        Name = "Push Strength",
        Default = false,
        Flag = genFlag(),
        Callback = function(l)
            getgenv().PushStrengthEnabled = l
            if l then
                local equipPet = function(petName)
                    local pets = player:FindFirstChild("petsFolder") and player.petsFolder:FindFirstChild("Unique")
                    if pets then
                        for _, n in pairs(pets:GetChildren()) do
                            if n.Name == petName then
                                ReplicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", n)
                            end
                        end
                    end
                end
                task.spawn(function()
                    while getgenv().PushStrengthEnabled do
                        equipPet("Swift Samurai")
                        for y = 1, (repCount or 1) do
                            if not getgenv().PushStrengthEnabled then break end
                            if player:FindFirstChild("muscleEvent") then player.muscleEvent:FireServer("rep") end
                        end
                        task.wait()
                    end
                end)
            end
        end
    })

    local strengthTab = farmingTabbox1:AddTab("Strength", "lucide:trending-up")
    strengthTab:AddDivider({ Text = "Stop Strength" })
    strengthTab:AddTextInput({
        Name = "Target For Strength",
        Placeholder = "Enter Strength target",
        Default = "",
        Callback = function(text) TargetStrength = parseInput(text) end
    })

    strengthTab:AddToggle({
        Name = "Auto Rep Using All tools",
        Default = false,
        Flag = genFlag(),
        Callback = function(state)
            getgenv().AutoPush = state
            if state then
                task.spawn(function()
                    while getgenv().AutoPush do
                        local strength = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Strength")
                        if TargetStrength and TargetStrength > 0 and strength and strength.Value >= TargetStrength then
                            getgenv().AutoPush = false
                            break
                        end
                        if player:FindFirstChild("muscleEvent") then player.muscleEvent:FireServer("rep") end
                        task.wait(0.3)
                    end
                end)
            end
        end
    })

    local toolsTab = farmingTabbox1:AddTab("Tools", "lucide:wrench")
    toolsTab:AddDivider({ Text = "Farm Tools" })
    toolsTab:AddButton({
        Name = "Unlock Gamepass AutoLift",
        Callback = function()
            local gamepassFolder = ReplicatedStorage:FindFirstChild("gamepassIds")
            local ownedFolder = player:FindFirstChild("ownedGamepasses")
            if gamepassFolder and ownedFolder then
                for _, gamepass in pairs(gamepassFolder:GetChildren()) do
                    if not ownedFolder:FindFirstChild(gamepass.Name) then
                        local value = Instance.new("IntValue")
                        value.Name = gamepass.Name
                        value.Value = gamepass.Value
                        value.Parent = ownedFolder
                    end
                end
                window:Notify({ Title = "Success", Content = "AutoLift Gamepass Unlocked!" })
            end
        end
    })

    local toolConfigs = {
        {"Auto Weight", "AutoWeight", "Weight"},
        {"Auto Push Ups", "AutoPushups", "Pushups"},
        {"Auto Hand Stands", "AutoHandstands", "Handstands"},
        {"Auto Sit Ups", "AutoSitups", "Situps"}
    }
    for _, tool in ipairs(toolConfigs) do
        toolsTab:AddToggle({
            Name = tool[1],
            Default = false,
            Flag = genFlag(),
            Callback = function(Value)
                _G[tool[2]] = Value
                if Value then
                    equipTool(tool[3])
                    startAutoRep(tool[2], tool[3])
                else
                    unequipTool(tool[3])
                end
            end
        })
    end

    local farmingTabbox2 = farmingTab:AddTabbox({ Name = "Combos", Position = "center" })
    local comboTab = farmingTabbox2:AddTab("Combos", "lucide:rocket")

    local function toggleAnimation(Value)
        if Value then
            local blockedAnimations = {["rbxassetid://3638729053"] = true, ["rbxassetid://3638767427"] = true}
            local function setupAnimationBlocking()
                local char = player.Character
                local humanoid = char and char:FindFirstChild("Humanoid")
                if not humanoid then return end
                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                    local anim = track.Animation
                    local name = track.Name:lower()
                    if anim and (blockedAnimations[anim.AnimationId] or name:match("punch") or name:match("attack") or name:match("right")) then
                        track:Stop()
                    end
                end
                if not _G.AnimBlockConnection then
                    _G.AnimBlockConnection = humanoid.AnimationPlayed:Connect(function(track)
                        local anim = track.Animation
                        local name = track.Name:lower()
                        if anim and (blockedAnimations[anim.AnimationId] or name:match("punch") or name:match("attack") or name:match("right")) then
                            track:Stop()
                        end
                    end)
                end
            end
            local function overrideToolActivation()
                _G.ToolConnections = _G.ToolConnections or {}
                local function processTool(tool)
                    if tool and (tool.Name == "Punch" or tool.Name:match("Attack") or tool.Name:match("Right")) and not tool:GetAttribute("ActivatedOverride") then
                        tool:SetAttribute("ActivatedOverride", true)
                        _G.ToolConnections[tool] = tool.Activated:Connect(function()
                            task.wait(0.05)
                            local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                            if humanoid then
                                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                                    local anim = track.Animation
                                    local name = track.Name:lower()
                                    if anim and (blockedAnimations[anim.AnimationId] or name:match("punch") or name:match("attack") or name:match("right")) then
                                        track:Stop()
                                    end
                                end
                            end
                        end)
                    end
                end
                local function watchTools(container)
                    for _, tool in pairs(container:GetChildren()) do processTool(tool) end
                    return container.ChildAdded:Connect(function(tool) task.wait(0.1) processTool(tool) end)
                end
                _G.ToolConnections.Backpack = watchTools(player.Backpack)
                if player.Character then _G.ToolConnections.Character = watchTools(player.Character) end
            end
            setupAnimationBlocking()
            overrideToolActivation()
            if not _G.AnimMonitorConnection then
                _G.AnimMonitorConnection = RunService.Heartbeat:Connect(function()
                    local char = player.Character
                    local humanoid = char and char:FindFirstChild("Humanoid")
                    if humanoid and tick() % 0.5 < 0.01 then
                        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                            local anim = track.Animation
                            local name = track.Name:lower()
                            if anim and (blockedAnimations[anim.AnimationId] or name:match("punch") or name:match("attack") or name:match("right")) then
                                track:Stop()
                            end
                        end
                    end
                end)
            end
        else
            if _G.AnimBlockConnection then _G.AnimBlockConnection:Disconnect(); _G.AnimBlockConnection = nil end
            if _G.AnimMonitorConnection then _G.AnimMonitorConnection:Disconnect(); _G.AnimMonitorConnection = nil end
            if _G.ToolConnections then
                for _, v in pairs(_G.ToolConnections) do if v.Disconnect then v:Disconnect() end end
                _G.ToolConnections = nil
            end
        end
    end

    local rocks = {
        {"Industrial Rock", 25000000},
        {"Jungle Rock", 10000000},
        {"Muscle King Rock", 5000000},
        {"Legend Rock", 1000000},
        {"Eternal Rock", 750000},
        {"Mythical Rock", 400000},
        {"Frozen Rock", 150000},
        {"Golden Rock", 5000},
        {"Starter Rock", 100},
        {"Tiny Rock", 0}
    }

    for _, rockData in ipairs(rocks) do
        local sectionTitle = "Combo " .. rockData[1]
        local durNeeded = rockData[2]
        comboTab:AddDivider({ Text = sectionTitle })

        local state = { push = false, sit = false, hand = false }
        local hasNotified = false

        local function updateCombo()
            local active = state.push or state.sit or state.hand
            toggleAnimation(active)
            if not active then
                hasNotified = false
            end
        end

        local function punchRock()
            local char = player.Character
            local bp = player:FindFirstChild("Backpack")
            if char and bp and char:FindFirstChild("Humanoid") then
                local punch = bp:FindFirstChild("Punch") or char:FindFirstChild("Punch")
                if punch then
                    if punch.Parent == bp then char.Humanoid:EquipTool(punch) end
                    local at = punch:FindFirstChild("attackTime")
                    if at then at.Value = 0.0001 end
                    if player:FindFirstChild("muscleEvent") then
                        player.muscleEvent:FireServer("punch", "rightHand")
                        player.muscleEvent:FireServer("punch", "leftHand")
                    end
                    punch:Activate()
                end
            end
        end

        local function tryRockTouch()
            local char = player.Character
            local dur = player:FindFirstChild("Durability")
            
            if dur and dur.Value < durNeeded then
                if not hasNotified then
                    window:Notify({ Title = "Durability Not enough", Content = "Will Do Normal Farming" })
                    hasNotified = true
                end
                return false
            end
            
            if dur and dur.Value >= durNeeded then
                local machines = workspace:FindFirstChild("machinesFolder")
                if machines then
                    for _, v in pairs(machines:GetDescendants()) do
                        if v.Name == "neededDurability" and v.Value == durNeeded then
                            local rock = v.Parent:FindFirstChild("Rock")
                            if rock and char then
                                local rh = char:FindFirstChild("RightHand")
                                local lh = char:FindFirstChild("LeftHand")
                                if rh and lh then
                                    firetouchinterest(rock, rh, 0)
                                    firetouchinterest(rock, rh, 1)
                                    firetouchinterest(rock, lh, 0)
                                    firetouchinterest(rock, lh, 1)
                                    punchRock()
                                end
                            end
                        end
                    end
                end
            end
        end

        local function doRep(toolName)
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                if not char:FindFirstChild(toolName) then equipTool(toolName) end
                if player:FindFirstChild("muscleEvent") then player.muscleEvent:FireServer("rep") end
            end
        end

        task.spawn(function()
            while true do
                if state.push then doRep("Pushups") tryRockTouch() end
                if state.sit then doRep("Situps") tryRockTouch() end
                if state.hand then doRep("Handstands") tryRockTouch() end
                task.wait(0.1)
            end
        end)

        local cleanTitle = sectionTitle:gsub("Combo ", "")
        comboTab:AddToggle({
            Name = "Push Ups + " .. cleanTitle,
            Default = false,
            Flag = genFlag(),
            Callback = function(s) state.push = s; updateCombo() end
        })
        comboTab:AddToggle({
            Name = "Sit Ups + " .. cleanTitle,
            Default = false,
            Flag = genFlag(),
            Callback = function(s) state.sit = s; updateCombo() end
        })
        comboTab:AddToggle({
            Name = "Hand Stands + " .. cleanTitle,
            Default = false,
            Flag = genFlag(),
            Callback = function(s) state.hand = s; updateCombo() end
        })
    end
end

do
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    local rockFarmTab = window:AddTab({
        Name = "Rock Farm",
        Icon = "lucide:shield-check",
        Type = "Single",
    })

    local rockFarmTabbox = rockFarmTab:AddTabbox({ Name = "Rock Farm", Position = "center" })

    local rockData = {
        {"Industrial Rock", 25000000, CFrame.new(-4488.8, 61.1, 5375.6, -0.89, 0.00, -0.45, 0.00, 1.00, 0.00, 0.45, 0.00, -0.89)},
        {"Jungle Rock", 10000000, CFrame.new(-7666.7, 6.8, 2831.0, -0.69, 0, -0.72, 0, 1, 0, 0.72, 0, -0.69)},
        {"Muscle King Rock", 5000000, CFrame.new(-9039.3, 9.2, -6051.5, 0.31, 0, -0.94, 0, 1, 0, 0.94, 0, 0.31)},
        {"Legend Rock", 1000000, CFrame.new(4146.9, 991.5, -4030.8, 0.98, 0, 0.16, 0, 1, 0, -0.16, 0, 0.98)},
        {"Eternal Rock", 750000, CFrame.new(-7289.6, 7.6, -1290.4, -0.60, 0, -0.79, 0, 1, 0, 0.79, 0, -0.60)},
        {"Mythical Rock", 400000, CFrame.new(2181.2, 7.3, 1207.8, -0.99, 0, -0.13, 0, 1, 0, 0.13, 0, -0.99)},
        {"Frozen Rock", 150000, CFrame.new(-2520.7, 7.9, -218.4, 0.51, 0, 0.85, 0, 1, 0, -0.85, 0, 0.51)},
        {"Golden Rock", 5000, CFrame.new(302.0, 7.3, -622.9, -0.94, 0, -0.33, 0, 1, 0, 0.33, 0, -0.94)},
        {"Starter Rock", 100, CFrame.new(158.0, 7.3, -164.0, -0.80, 0, -0.59, 0, 1, 0, 0.59, 0, -0.80)},
        {"Tiny Rock", 0, CFrame.new(8.4, 4.3, 2101.2, -0.27, 0, -0.96, 0, 1, 0, 0.96, 0, -0.27)}
    }

    local activeRock, curDur, targetCF, selectedEmoteName = nil, 0, nil, nil
    local animPlayedConn = nil

    local function stopFastPunch()
        _G.FastPunch = false
        local bp = player:FindFirstChild("Backpack")
        local p1 = player.Character and player.Character:FindFirstChild("Punch")
        local p2 = bp and bp:FindFirstChild("Punch")
        if p1 and p1:FindFirstChild("attackTime") then p1.attackTime.Value = 0.35 end
        if p2 and p2:FindFirstChild("attackTime") then p2.attackTime.Value = 0.35 end
    end

    local function startFastPunch()
        if _G.FastPunchActive then return end
        _G.FastPunchActive = true
        task.spawn(function()
            while _G.FastPunch do
                local char = player.Character
                local bp = player:FindFirstChild("Backpack")
                if char then
                    local p = char:FindFirstChild("Punch") or (bp and bp:FindFirstChild("Punch"))
                    if p then
                        if p:FindFirstChild("attackTime") then p.attackTime.Value = 0 end
                        if not char:FindFirstChild("Punch") and char:FindFirstChild("Humanoid") then
                            char.Humanoid:EquipTool(p)
                        end
                    end
                end
                task.wait(0.0001)
            end
            _G.FastPunchActive = false
        end)
        task.spawn(function()
            while _G.FastPunch do
                local char, ev = player.Character, player:FindFirstChild("muscleEvent")
                if ev then
                    ev:FireServer("punch", "rightHand")
                    ev:FireServer("punch", "leftHand")
                end
                if char and char:FindFirstChild("Punch") then
                    char.Punch:Activate()
                end
                task.wait()
            end
        end)
    end

    local function useTool()
        local char = player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local bp = player:FindFirstChild("Backpack")
        local p = bp and bp:FindFirstChild("Punch") or char and char:FindFirstChild("Punch")
        if hum and p then
            if p.Parent == bp then hum:EquipTool(p) end
            if p:FindFirstChild("attackTime") then p.attackTime.Value = 0.001 end
        end
        local ev = player:FindFirstChild("muscleEvent")
        if ev then
            ev:FireServer("punch", "leftHand")
            ev:FireServer("punch", "rightHand")
        end
    end

    local function startFarm(mode)
        task.spawn(function()
            local hasNotified = false
            local dur = player:FindFirstChild("Durability")
            if dur and dur.Value < curDur then
                if not hasNotified then
                    window:Notify({ Title = "Durability Not Enough", Content = "Please Increase Your Durability " })
                    hasNotified = true
                end
                if mode == 1 or mode == 3 then getgenv().autoFarm = false end
                if mode == 2 then getgenv().autoFarmV2 = false end
                return
            end
            
            if mode == 3 then
                local function applyAgressiveStop()
                    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
                    if not hum then return end
                    local blockedAnimations = {["rbxassetid://3638729053"] = true, ["rbxassetid://3638767427"] = true}
                    for _, t in pairs(hum:GetPlayingAnimationTracks()) do
                        local anim, name = t.Animation, t.Name:lower()
                        if anim and (blockedAnimations[anim.AnimationId] or name:match("punch") or name:match("attack") or name:match("right")) then
                            t:Stop()
                        end
                    end
                    if not animPlayedConn then
                        animPlayedConn = hum.AnimationPlayed:Connect(function(t)
                            local anim, name = t.Animation, t.Name:lower()
                            if anim and (blockedAnimations[anim.AnimationId] or name:match("punch") or name:match("attack") or name:match("right")) then
                                t:Stop()
                            end
                        end)
                    end
                end
                applyAgressiveStop()
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                local desc = hum and hum:FindFirstChildOfClass("HumanoidDescription")
                if desc and selectedEmoteName then
                    local emoteList = {
                        ["Superman Fly"] = 106493972274585,
                        ["Shadow Boxing"] = 126681258672147,
                        ["BlockyKick Dance"] = 97629500912487,
                        ["GOD Floating"]  = 81359407734079,
                        ["Boxing"] = 117648669357990,
                        ["Punching Armstrong"] = 115203580644128,
                        ["Aura Sit"] = 136914725915863,
                        ["Wall Lean Idle"] = 110537281410647,
                        ["Nonchalant Aura"] = 80035199697503,
                        ["Levitating"] = 101372455609544,
                        ["Aura Floating"] = 106470054474362,
                        ["Aura Loss"] = 134328477655650,
                        ["Floating Aura Xin"] = 75881569780412,
                        ["Floating World"] = 75180908790955,
                        ["Ascend Aura Pose"] = 83502723504906,
                        ["Aura Gainer"] = 125717501705233,
                        ["AFK Aura Farm"] = 124573843932871,
                        ["I WANNA RUN AWAY"] = 96361347184349,
                        ["Sonic"] = 132168791204839,
                        ["Headless Endless"] = 105850826781635,
                        ["Godly Aura Fly"] = 114244857354338,
                        ["ffortless Pumpkin King"] = 87394801171279,
                        ["Coin Flipper!"] = 119241467010575,
                        ["The Flash"] = 89650706104144
                    }

                    desc:SetEmotes({[selectedEmoteName] = {emoteList[selectedEmoteName]}})
                    pcall(function()
                        hum:PlayEmote(selectedEmoteName)
                        for _, t in pairs(hum:FindFirstChildOfClass("Animator"):GetPlayingAnimationTracks()) do
                            t.Priority = Enum.AnimationPriority.Action4
                            t.Looped = true
                        end
                    end)
                end
                task.wait(0.5)
            end

            if mode == 1 or mode == 2 then
                _G.FastPunch = true
                startFastPunch()
            end

            while (mode == 1 and getgenv().autoFarm) or (mode == 2 and getgenv().autoFarmV2) or (mode == 3 and getgenv().autoFarm) do
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local dur = player:FindFirstChild("Durability")
                if mode == 3 then
                    local hum = char and char:FindFirstChild("Humanoid")
                    if hum then
                        for _, t in pairs(hum:GetPlayingAnimationTracks()) do
                            if t.Animation and (t.Animation.AnimationId == "rbxassetid://3638729053" or t.Animation.AnimationId == "rbxassetid://3638767427" or t.Name:lower():match("punch") or t.Name:lower():match("attack") or t.Name:lower():match("right")) then
                                t:Stop()
                            end
                        end
                    end
                end

                if hrp and dur and dur.Value >= curDur then
                    if mode == 2 and targetCF then
                        hrp.CFrame = targetCF
                        hrp.Velocity = Vector3.new(0, 0, 0)
                    end

                    local machines = workspace:FindFirstChild("machinesFolder")
                    if machines then
                        for _, obj in pairs(machines:GetDescendants()) do
                            if obj.Name == "neededDurability" and obj.Value == curDur then
                                local rock = obj.Parent:FindFirstChild("Rock")
                                local lh = char:FindFirstChild("LeftHand")
                                local rh = char:FindFirstChild("RightHand")
                                if rock and rh then
                                    firetouchinterest(rock, rh, 0)
                                    firetouchinterest(rock, rh, 1)
                                    if mode ~= 3 and lh then
                                        firetouchinterest(rock, lh, 0)
                                        firetouchinterest(rock, lh, 1)
                                    end
                                    useTool()
                                end
                                break
                            end
                        end
                    end
                end
                task.wait(mode == 1 and 0.001 or 0.05)
            end

            if mode == 3 then
                if animPlayedConn then animPlayedConn:Disconnect(); animPlayedConn = nil end
            end
            stopFastPunch()
        end)
    end

    local ghostTab = rockFarmTabbox:AddTab("Ghost", "lucide:ghost")
    for _, r in ipairs(rockData) do
        ghostTab:AddToggle({
            Name = "Ghost " .. r[1],
            Default = false,
            Flag = genFlag(),
            Callback = function(v)
                activeRock, curDur, getgenv().autoFarm = r[1], r[2], v
                if v then startFarm(1) else stopFastPunch() end
            end
        })
    end

    local teleportRockTab = rockFarmTabbox:AddTab("Teleport", "lucide:map-pin")
    for _, r in ipairs(rockData) do
        teleportRockTab:AddToggle({
            Name = "TP " .. r[1],
            Default = false,
            Flag = genFlag(),
            Callback = function(v)
                activeRock, curDur, targetCF, getgenv().autoFarmV2 = r[1], r[2], r[3], v
                if v then startFarm(2) else stopFastPunch() end
            end
        })
    end

    local emoteRockTab = rockFarmTabbox:AddTab("Emote", "lucide:smile")
    emoteRockTab:AddDivider({ Text = "Select Emote" })
    emoteRockTab:AddDropdown({
        Name = "Select Emote",
        Values = {"Superman Fly", "Shadow Boxing", "BlockyKick Dance", "GOD Floating", "Boxing", "Punching Armstrong", "Aura Sit", "Wall Lean Idle", "Nonchalant Aura", "Levitating", "Aura Floating", "Aura Loss", "Floating Aura Xin", "Floating World", "Ascend Aura Pose", "Aura Gainer", "AFK Aura Farm", "I WANNA RUN AWAY", "Sonic", "Headless Endless", "Godly Aura Fly", "ffortless Pumpkin King", "Coin Flipper!", "The Flash"},
        Default = "Superman Fly",
        Flag = genFlag(),
        Callback = function(v) selectedEmoteName = v end
    })
    for _, r in ipairs(rockData) do
        emoteRockTab:AddToggle({
            Name = "Emote " .. r[1],
            Default = false,
            Flag = genFlag(),
            Callback = function(v)
                if v and not selectedEmoteName then
                    window:Notify({ Title = "Warning", Content = "Select an emote first!", Duration = 2 })
                    return
                end
                activeRock, curDur, getgenv().autoFarm = r[1], r[2], v
                if v then startFarm(3) else if animPlayedConn then animPlayedConn:Disconnect(); animPlayedConn = nil end end
            end
        })
    end
end

do
    local Players = game:GetService("Players")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local player = Players.LocalPlayer

    local gymTab = window:AddTab({
        Name = "Gym Farm",
        Icon = "lucide:dumbbell",
        Type = "Single",
    })

    local gymTabbox1 = gymTab:AddTabbox({ Name = "Gym 1", Position = "center" })

    local function CreateGymToggle(parent, title, name, pos)
        parent:AddToggle({
            Name = title,
            Default = false,
            Flag = genFlag(),
            Callback = function(bool)
                if getgenv().working and not bool then getgenv().working = false return end
                getgenv().working = bool
                if bool then
                    local function pressE()
                        VirtualInputManager:SendKeyEvent(true, "E", false, game)
                        task.wait(0.1)
                        VirtualInputManager:SendKeyEvent(false, "E", false, game)
                    end
                    local function autoLift()
                        while getgenv().working do
                            if player:FindFirstChild("muscleEvent") then
                                player.muscleEvent:FireServer("rep")
                            end
                            task.wait(0.3)
                        end
                    end
                    local Character = player.Character
                    if Character and Character:FindFirstChild("HumanoidRootPart") then
                        for i = 1, 9 do
                            Character.HumanoidRootPart.CFrame = pos
                            task.wait(0.01)
                            pressE()
                            task.spawn(autoLift)
                        end
                    end
                end
            end
        })
    end

    local frostGymTab = gymTabbox1:AddTab("Frost", "lucide:snowflake")
    frostGymTab:AddDivider({ Text = "Farm ( Frost Gym )" })
    CreateGymToggle(frostGymTab, "Frost Press V1", "Frost Press", CFrame.new(-3008.66, 61.61, -337.74, -0.006, 0, -0.999, 0, 1, 0, 0.999, 0, -0.006))
    CreateGymToggle(frostGymTab, "Frost Press V2", "Frost Press", CFrame.new(-2748.75, 22.52, -181.81, -1, 0, 0, 0, 1, 0, 0, 0, -1))
    CreateGymToggle(frostGymTab, "Frost Lifting", "Frost Lift", CFrame.new(-2917.47, 58.21, -209.56, -1, 0, 0, 0, 1, 0, 0, 0, -1))
    CreateGymToggle(frostGymTab, "Frost Squat", "Frost Squat", CFrame.new(-2720.05, 50.42, -591.25, -1, 0, 0, 0, 1, 0, 0, 0, -1))

    local mythicalGymTab = gymTabbox1:AddTab("Mythical", "lucide:wand")
    mythicalGymTab:AddDivider({ Text = "Farm ( Mythical Gym )" })
    CreateGymToggle(mythicalGymTab, "Mythical Press", "Bench Press", CFrame.new(2369.7, 38.55, 1243.02, -1, 0, 0, 0, 1, 0, 0, 0, -1))
    CreateGymToggle(mythicalGymTab, "Mythical Pull Ups", "Pull Up", CFrame.new(2487.12, 29.9, 848.28, -1, 0, 0, 0, 1, 0, 0, 0, -1))
    CreateGymToggle(mythicalGymTab, "Mythical Boulder", "Boulder", CFrame.new(2667.74, 46.02, 1203.33, -1, 0, 0, 0, 1, 0, 0, 0, -1))

    local infernoGymTab = gymTabbox1:AddTab("Inferno", "lucide:flame")
    infernoGymTab:AddDivider({ Text = "Farm ( Inferno Gym )" })
    CreateGymToggle(infernoGymTab, "Inferno Press", "Bench Press", CFrame.new(-7173.34, 44.73, -1105.02, -1, 0, 0, 0, 1, 0, 0, 0, -1))

    local gymTabbox2 = gymTab:AddTabbox({ Name = "Gym 2", Position = "center" })
    local legendsGymTab = gymTabbox2:AddTab("Legends", "lucide:star")
    legendsGymTab:AddDivider({ Text = "Farm ( Legends Gym )" })
    CreateGymToggle(legendsGymTab, "Legends Press", "Bench Press", CFrame.new(4109.91, 1019.8, -3802.15, -1, 0, 0, 0, 1, 0, 0, 0, -1))
    CreateGymToggle(legendsGymTab, "Legends Squat", "Squat", CFrame.new(4439.77, 1019.3, -4058.48, -1, 0, 0, 0, 1, 0, 0, 0, -1))
    CreateGymToggle(legendsGymTab, "Legends Lifting", "Squat", CFrame.new(4532.21, 1023.0, -4002.71, -1, 0, 0, 0, 1, 0, 0, 0, -1))
    CreateGymToggle(legendsGymTab, "Legends Pull Ups", "Pull Up", CFrame.new(4304.02, 1020.0, -4122.27, -1, 0, 0, 0, 1, 0, 0, 0, -1))
    CreateGymToggle(legendsGymTab, "Legends Boulder", "Boulder", CFrame.new(4189.96, 1010.2, -3903.01, -1, 0, 0, 0, 1, 0, 0, 0, -1))

    local muscleKingGymTab = gymTabbox2:AddTab("King", "lucide:crown")
    muscleKingGymTab:AddDivider({ Text = "Farm ( Muscle King )" })
    CreateGymToggle(muscleKingGymTab, "Muscle King Press", "Bench Press", CFrame.new(-8590.23, 51, -6044.59, -1, 0, 0, 0, 1, 0, 0, 0, -1))
    CreateGymToggle(muscleKingGymTab, "Muscle King Squat", "Squat", CFrame.new(-8758.44, 44.14, -6043.06, -1, 0, 0, 0, 1, 0, 0, 0, -1))
    CreateGymToggle(muscleKingGymTab, "Muscle King Lifting", "Pull Up", CFrame.new(-8772.97, 49.73, -5663.56, -1, 0, 0, 0, 1, 0, 0, 0, -1))
    CreateGymToggle(muscleKingGymTab, "Muscle King Boulder", "Boulder", CFrame.new(-8942.12, 49.60, -5691.63, -1, 0, 0, 0, 1, 0, 0, 0, -1))

    local gymTabbox3 = gymTab:AddTabbox({ Name = "Gym 3", Position = "center" })
    local jungleGymTab = gymTabbox3:AddTab("Jungle", "lucide:tree-pine")
    jungleGymTab:AddDivider({ Text = "Jungle Bench" })
    CreateGymToggle(jungleGymTab, "Bench | Need 100k", "Bench Press", CFrame.new(-8176.22, 66.38, 1911.30))
    CreateGymToggle(jungleGymTab, "Bench | Need 50k", "Bench Press", CFrame.new(-8435.61, 50.13, 1904.73))
    CreateGymToggle(jungleGymTab, "Bench | Need 25k", "Bench Press", CFrame.new(-8627.64, 38.78, 1893.75))
    jungleGymTab:AddDivider({ Text = "Jungle Bar lift" })
    CreateGymToggle(jungleGymTab, "Lift | Need 100k", "Jungle Bar Lift", CFrame.new(-8656.46, 7.38, 2089.28))
    jungleGymTab:AddDivider({ Text = "Jungle Boulder" })
    CreateGymToggle(jungleGymTab, "Boulder | Need 75k", "Boulder", CFrame.new(-8618.98, 8.16, 2677.43))
    jungleGymTab:AddDivider({ Text = "Jungle Squat" })
    CreateGymToggle(jungleGymTab, "Squat | Need 125k", "Squat", CFrame.new(-8373.36, 9.06, 2873.44))
    CreateGymToggle(jungleGymTab, "Squat | Need 50k", "Squat", CFrame.new(-8581.55, 9.40, 2889.29))

    local IndustrialGymTab = gymTabbox3:AddTab("Industrial", "lucide:flame")
    IndustrialGymTab:AddDivider({ Text = "Industrial Bench" })
    CreateGymToggle(IndustrialGymTab, "Bench | Need 250k", "Industrial Bench", CFrame.new(-5012.87, 117.92, 4461.31))
    CreateGymToggle(IndustrialGymTab, "Bench | Need 125k", "Industrial Bench", CFrame.new(-5267.20, 103.97, 4450.38))
    CreateGymToggle(IndustrialGymTab, "Bench | Need 62.5k", "Industrial Bench", CFrame.new(-5468.74, 94.01, 4453.04))
    IndustrialGymTab:AddDivider({ Text = "Industrial Boulder" })
    CreateGymToggle(IndustrialGymTab, "Boulder | Need 187.5k", "Industrial Boulder", CFrame.new(-5462.87, 61.06, 5235.52))
    IndustrialGymTab:AddDivider({ Text = "Industrial Squat" })
    CreateGymToggle(IndustrialGymTab, "Squat | Need 312.5k", "Industrial Squat", CFrame.new(-5218.79, 61.06, 5415.13))
    CreateGymToggle(IndustrialGymTab, "Squat | Need 125k", "Industrial Squat", CFrame.new(-5419.86, 61.06, 5445.52))
end

do
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local player = Players.LocalPlayer
    local rEvents = ReplicatedStorage:WaitForChild("rEvents")
    local petsFolder = player:FindFirstChild("petsFolder") or player:WaitForChild("petsFolder", 5)
    local tradingEvent = rEvents:FindFirstChild("tradingEvent")

    local crystalTab = window:AddTab({
        Name = "Crystal",
        Icon = "lucide:gem",
        Type = "Single",
    })

    local crystalTabbox1 = crystalTab:AddTabbox({ Name = "Crystal 1", Position = "center" })

    local petPacksList = {"[ ☠️--PET PACKS--☠️ ]", "Tribal Overlord", "Swift Samurai", "Mighty Monster", "Wild Wizard"}
    local petOptions = {
        "[🟡--UNIQUE--🟡]", "Apex Overlord", "Reactor Beast", "Plasma Ravager", "Titan Reactor", "Neon Guardian", "Muscle Sensei", "Cybernetic Showdown Dragon", "Darkstar Hunter",
        "Ultra Birdie", "Magic Butterfly", "Infernal Dragon", "[🟣--EPIC--🟣]", "Core Pup", "Volt Talon", "Golden Viking", "Lightning Strike Phantom", "Dark Legends Manticore", "White Pheonix", "Golden Pheonix",
        "Red Firecaster", "Green Firecaster", "Blue Firecaster", "Blue Phoenix", "[🔵--RARE--🔵]",
        "Eternal Strike Leviathan", "White Pegasus", "Purple Falcon", "Red Dragon", "Phantom Genesis Dragon",
        "Orange Pegasus", "Purple Dragon", "Crimson Falcon", "[🟢--COMMON--🟢]", "Yellow Butterfly",
        "Green Butterfly", "Dark Golem", "Dark Vampy", "Silver Dog", "Blue Bunny", "Blue Birdie",
        "Red Kitty", "Orange Hedgehog"
    }
    local aurasList = {
        "Astral Electro", "Azure Tundra", "Blue Aura", "Dark Electro",
        "Dark Lightning", "Dark Storm", "Electro", "Enchanted Mirage",
        "Entropic Blast", "Eternal Megastrike", "Grand Supernova", "Green Aura",
        "Inferno", "Lightning", "Muscle King", "Power Lightning",
        "Purple Aura", "Purple Nova", "Red Aura", "Supernova",
        "Ultra Inferno", "Ultra Mirage", "Unstable Mirage", "Yellow Aura"
    }
    local crystalNames = {"Blue Crystal", "Green Crystal", "Frozen Crystal", "Mythical Crystal", "Inferno Crystal", "Legends Crystal", "Muscle Elite Crystal", "Galaxy Oracle Crystal", "Jungle Crystal", "Industrial Crystal"}
    local crystalLocations = {
        ["Blue Crystal"] = CFrame.new(146.02, 13.71, 442.12, -0.99, 0, 0, 0, 1, 0, 0, 0, -0.99),
        ["Green Crystal"] = CFrame.new(401.80, 12.89, -199.83, -0.99, 0, -0.03, 0, 1, 0, 0.03, 0, -0.99),
        ["Frozen Crystal"] = CFrame.new(-2826.17, 12.44, -136.56, -0.99, 0, -0.001, 0, 1, 0, 0.001, 0, -0.99),
        ["Mythical Crystal"] = CFrame.new(2740.39, 12.46, 1160.81, -0.009, 0, -0.99, 0, 1, 0, 0.99, 0, -0.009),
        ["Inferno Crystal"] = CFrame.new(-6896.38, 11.78, -1544.02, 0.99, 0, -0.03, 0, 1, 0, 0.03, 0, 0.99),
        ["Legends Crystal"] = CFrame.new(4089.46, 1001.05, -3561.76, -0.76, 0, 0.63, 0, 1, 0, -0.63, 0, -0.76),
        ["Muscle Elite Crystal"] = CFrame.new(3821.68, 1000.93, -4075.16),
        ["Galaxy Oracle Crystal"] = CFrame.new(-9025.96, 27.11, -5866.43, 0, 0, 1, 0, 1, 0, -1, 0, 0),
        ["Jungle Crystal"] = CFrame.new(-7521.36, 19.35, 2394.26, -0.01, 0, -0.99, 0, 1, 0, 0.99, 0, -0.01),
        ["Industrial Crystal"] = CFrame.new(-4339.15, 81.13, 4942.87)
    }

    local selectedCrystal = "Galaxy Oracle Crystal"
    local autoCrystalRunning = false
    local autoOpen3Running = false
    local autoOpen10Running = false
    local selectedPack = ""
    local currentSelectedPet = ""
    local currentSelectedAura = ""

    local function getPlayerDisplay(plr)
        return (plr.DisplayName and plr.DisplayName ~= "") and plr.DisplayName or plr.Name
    end

    local function buildPlayerDisplayList()
        local l = {}
        if not player then return {"None"} end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then table.insert(l, getPlayerDisplay(p)) end
        end
        if #l == 0 then table.insert(l, "None") end
        return l
    end

    local function getPetInstances(petName, n)
        local pets = {}
        if not player then return pets end
        local pf = player:FindFirstChild("petsFolder")
        if pf then
            for _, f in ipairs(pf:GetChildren()) do
                if f:IsA("Folder") then
                    for _, p in ipairs(f:GetChildren()) do
                        if p.Name == petName then
                            table.insert(pets, p)
                            if #pets >= n then return pets end
                        end
                    end
                end
            end
        end
        return pets
    end

    local function isTradePending()
        return player and player:FindFirstChild("CurrentTrade") ~= nil
    end

    local function isTradeAccepted()
        if not player then return false end
        local ct = player:FindFirstChild("CurrentTrade")
        return ct and ct:FindFirstChild("Accepted") and ct.Accepted.Value or false
    end

    local function mainTradeLoop()
        while true do
            if autoTradeToSelected and selectedPetName and selectedPlayer and tradingEvent and not isTradePending() then
                local pets = getPetInstances(selectedPetName, PET_COUNT or 1)
                if pets and #pets > 0 then
                    pcall(function() tradingEvent:FireServer("sendTradeRequest", selectedPlayer) end)
                    task.wait(0.3)
                    
                    for _, p in ipairs(pets) do
                        pcall(function() tradingEvent:FireServer("offerItem", p) end)
                        task.wait(0.05)
                    end
                    
                    task.wait(0.2)
                    pcall(function() tradingEvent:FireServer("confirmTrade") end)
                    pcall(function() tradingEvent:FireServer("acceptTrade") end)
                end
            end

            if autoTradeToAll and selectedPetName and tradingEvent and not isTradePending() then
                local pets = getPetInstances(selectedPetName, PET_COUNT or 1)
                if pets and #pets > 0 then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= player then
                            pcall(function() tradingEvent:FireServer("sendTradeRequest", plr) end)
                            task.wait(0.05)
                        end
                    end
                    
                    for _, p in ipairs(pets) do
                        pcall(function() tradingEvent:FireServer("offerItem", p) end)
                        task.wait()
                    end
                    
                    if not isTradeAccepted() then
                        pcall(function() tradingEvent:FireServer("confirmTrade") end)
                        pcall(function() tradingEvent:FireServer("acceptTrade") end)
                    end
                    task.wait(0.01)
                end
            end

            local ct = player and player:FindFirstChild("CurrentTrade")
            if ct and tradingEvent then
                pcall(function() tradingEvent:FireServer("acceptTrade") end)
                task.wait(0.1)
                local ti
                local ts = tick()
                repeat
                    task.wait()
                    ti = ct:FindFirstChild("OfferedItems")
                until (ti and #ti:GetChildren() > 0) or (tick() - ts > 8)
                
                pcall(function() tradingEvent:FireServer("confirmTrade") end)
                pcall(function() tradingEvent:FireServer("acceptTrade") end)
            end
            
            task.wait(0.01)
        end
    end

    local petPacksTab = crystalTabbox1:AddTab("Pet Packs", "lucide:package")
    petPacksTab:AddDivider({ Text = "Pet Packs" })
    petPacksTab:AddDropdown({
        Name = "Select Pet Pack",
        Values = petPacksList,
        Default = petPacksList[1],
        Flag = genFlag(),
        Callback = function(v) selectedPack = v end
    })
    petPacksTab:AddButton({
        Name = "Equip Pet Pack",
        Icon = "lucide:check",
        Callback = function()
            if selectedPack == "" then
                window:Notify({ Title = "Error", Content = "Select a pet pack first!" })
                return
            end
            if petsFolder then
                for _, f in pairs(petsFolder:GetChildren()) do
                    if f:IsA("Folder") then
                        for _, p in pairs(f:GetChildren()) do
                            rEvents.equipPetEvent:FireServer("unequipPet", p)
                        end
                    end
                end
                task.wait(0.3)
                local tf = petsFolder:FindFirstChild("Unique")
                if tf then
                    local found = false
                    for _, p in pairs(tf:GetChildren()) do
                        if p.Name == selectedPack then
                            rEvents.equipPetEvent:FireServer("equipPet", p)
                            found = true
                        end
                    end
                    if found then
                        window:Notify({ Title = "Success", Content = "Equipped: " .. selectedPack })
                    else
                        window:Notify({ Title = "Not Found", Content = "You don't have: " .. selectedPack })
                    end
                end
            end
        end
    })

    local autoPetTab = crystalTabbox1:AddTab("Auto Pet", "lucide:bot")
    autoPetTab:AddDivider({ Text = "Auto All Pet" })
    autoPetTab:AddDropdown({
        Name = "Select Pet",
        Values = petOptions,
        Default = petOptions[1],
        Flag = genFlag(),
        Callback = function(v) currentSelectedPet = v end
    })
    autoPetTab:AddDropdown({
        Name = "Select Aura",
        Values = aurasList,
        Default = aurasList[1],
        Flag = genFlag(),
        Callback = function(v) 
            currentSelectedAura = v 
        end
    })
    autoPetTab:AddButton({
        Name = "Equip Selected Pet",
        Callback = function()
            if currentSelectedPet ~= "" then
                for _, f in pairs(petsFolder:GetChildren()) do
                    if f:IsA("Folder") then
                        for _, p in pairs(f:GetChildren()) do
                            rEvents.equipPetEvent:FireServer("unequipPet", p)
                        end
                    end
                end
                task.wait(0.3)
                for _, f in pairs(petsFolder:GetChildren()) do
                    if f:IsA("Folder") then
                        for _, p in pairs(f:GetChildren()) do
                            if p.Name == currentSelectedPet then
                                rEvents.equipPetEvent:FireServer("equipPet", p)
                            end
                        end
                    end
                end
            end
        end
    })

    autoPetTab:AddButton({
        Name = "Unequip All Pets",
        Callback = function()
            if petsFolder then
                for _, f in pairs(petsFolder:GetChildren()) do
                    if f:IsA("Folder") then
                        for _, p in pairs(f:GetChildren()) do
                            rEvents.equipPetEvent:FireServer("unequipPet", p)
                        end
                    end
                end
            end
        end
    })

    autoPetTab:AddDivider({ Text = "Auto Buy" })
    autoPetTab:AddToggle({
        Name = "Auto Buy Pet",
        Default = false,
        Flag = genFlag(),
        Callback = function(s)
            getgenv().AutoBuy = s
            task.spawn(function()
                while getgenv().AutoBuy do
                    if currentSelectedPet ~= "" then
                        local petFolder = ReplicatedStorage:WaitForChild("shared", 3) and ReplicatedStorage.shared:WaitForChild("runtime", 3) and ReplicatedStorage.shared.runtime:FindFirstChild("cPetShopFolder")
                        local remote = ReplicatedStorage:WaitForChild("rEvents", 3) and ReplicatedStorage.rEvents:FindFirstChild("cPetShopRemote")
                        
                        if petFolder and remote then
                            local po = petFolder:FindFirstChild(currentSelectedPet)
                            if po then
                                remote:InvokeServer(po)
                            end
                        end
                    end
                    task.wait()
                end
            end)
        end
    })
    autoPetTab:AddToggle({
        Name = "Auto Buy Aura",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            _G.AutoHatchAura = bool
     
            if bool then
                task.spawn(function()
                    while _G.AutoHatchAura and currentSelectedAura ~= "" do
                        local shopFolder = ReplicatedStorage:WaitForChild("shared", 3) and ReplicatedStorage.shared:WaitForChild("runtime", 3) and ReplicatedStorage.shared.runtime:FindFirstChild("cPetShopFolder")
                        local remote = ReplicatedStorage:WaitForChild("rEvents", 3) and ReplicatedStorage.rEvents:FindFirstChild("cPetShopRemote")
                        
                        if shopFolder and remote then
                            local auraToOpen = shopFolder:FindFirstChild(currentSelectedAura)
                            if auraToOpen then
                                remote:InvokeServer(auraToOpen)
                            end
                        end
                        task.wait()
                    end
                end)
            end
        end
    })
    autoPetTab:AddDivider({ Text = "Auto Sell" })
    autoPetTab:AddToggle({
        Name = "Auto Sell Pet",
        Default = false,
        Flag = genFlag(),
        Callback = function(s)
            getgenv().AutoSellPet = s

            local RS = game:GetService("ReplicatedStorage")
            local LP = game:GetService("Players").LocalPlayer
            local Event = RS:FindFirstChild("rEvents") and RS.rEvents:FindFirstChild("sellPetEvent")

            local function getPet(petName)
                if not petName or petName == "" then return nil end

                for _, child in pairs(LP:GetDescendants()) do
                    if child.Name == petName then
                        return child
                    end
                end

                if getnilinstances then
                    for _, child in pairs(getnilinstances()) do
                        if child.Name == petName then
                            return child
                        end
                    end
                end

                return nil
            end

            task.spawn(function()
                while getgenv().AutoSellPet do
                    if currentSelectedPet ~= "" and Event then
                        local petToSell = getPet(currentSelectedPet)
                        if petToSell then
                            Event:FireServer("sellPet", petToSell)
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    })

    autoPetTab:AddToggle({
        Name = "Auto Sell Aura",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            getgenv().AutoSellAura = bool

            local RS = game:GetService("ReplicatedStorage")
            local LP = game:GetService("Players").LocalPlayer
            local Event = RS:FindFirstChild("rEvents") and RS.rEvents:FindFirstChild("sellPowerUpEvent")

            local function getAura(auraName)
                if not auraName or auraName == "" then return nil end

                for _, child in pairs(LP:GetDescendants()) do
                    if child.Name == auraName then
                        return child
                    end
                end

                if getnilinstances then
                    for _, child in pairs(getnilinstances()) do
                        if child.Name == auraName then
                            return child
                        end
                    end
                end

                return nil
            end

            task.spawn(function()
                while getgenv().AutoSellAura do
                    if currentSelectedAura ~= "" and Event then
                        local auraToSell = getAura(currentSelectedAura)
                        if auraToSell then
                            Event:FireServer("sellPowerUp", auraToSell)
                        end
                    end
                    task.wait(0.3)
                end
            end)
        end
    })

    autoPetTab:AddDivider({ Text = "Auto Evolved" })
    autoPetTab:AddToggle({
        Name = "Auto Evolve Pet",
        Default = false,
        Flag = genFlag(),
        Callback = function(s)
            getgenv().AutoEvolve = s
            task.spawn(function()
                while getgenv().AutoEvolve do
                    if currentSelectedPet ~= "" and rEvents:FindFirstChild("petEvolveEvent") then
                        rEvents.petEvolveEvent:FireServer("evolvePet", currentSelectedPet)
                    end
                    task.wait()
                end
            end)
        end
    })

    local crystalTabbox2 = crystalTab:AddTabbox({ Name = "Crystal 2", Position = "center" })
    local crystalOpenTab = crystalTabbox2:AddTab("Open Crystal", "lucide:gem")
    crystalOpenTab:AddDivider({ Text = "Open Crystal" })
    crystalOpenTab:AddDropdown({
        Name = "Select Crystal",
        Values = crystalNames,
        Default = selectedCrystal,
        Flag = genFlag(),
        Callback = function(t) selectedCrystal = t end
    })
    crystalOpenTab:AddToggle({
        Name = "Auto Crystal 1x",
        Default = false,
        Flag = genFlag(),
        Callback = function(s)
            autoCrystalRunning = s
            if autoCrystalRunning then
                task.spawn(function()
                    while autoCrystalRunning do
                        local r = ReplicatedStorage:FindFirstChild("rEvents")
                        if r and r:FindFirstChild("openCrystalRemote") then
                            pcall(function()
                                r.openCrystalRemote:InvokeServer("openCrystal", selectedCrystal)
                            end)
                        end
                        task.wait(0.1)
                    end
                end)
            end
        end
    })
    crystalOpenTab:AddToggle({
        Name = "Auto Crystal 3x",
        Default = false,
        Flag = genFlag(),
        Callback = function(s)
            autoOpen3Running = s
            if autoOpen3Running then
                task.spawn(function()
                    while autoOpen3Running do
                        local r = ReplicatedStorage:FindFirstChild("rEvents")
                        if r and r:FindFirstChild("openCrystalRemote") then
                            pcall(function()
                                r.openCrystalRemote:InvokeServer("openCrystalBulk", selectedCrystal, 3)
                            end)
                        end
                        task.wait(0.2)
                    end
                end)
            end
        end
    })
    crystalOpenTab:AddToggle({
        Name = "Auto Crystal 10x",
        Default = false,
        Flag = genFlag(),
        Callback = function(s)
            autoOpen10Running = s
            if autoOpen10Running then
                task.spawn(function()
                    while autoOpen10Running do
                        local r = ReplicatedStorage:FindFirstChild("rEvents")
                        if r and r:FindFirstChild("openCrystalRemote") then
                            pcall(function()
                                r.openCrystalRemote:InvokeServer("openCrystalBulk", selectedCrystal, 10)
                            end)
                        end
                        task.wait(0.2)
                    end
                end)
            end
        end
    })

    crystalOpenTab:AddButton({
        Name = "Teleport To Crystal",
        Callback = function()
            local tp = crystalLocations[selectedCrystal]
            if tp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = tp
            end
        end
    })
end

do
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local player = Players.LocalPlayer

    local selectedPetName = ""
    local selectedPlayer = nil
    local autoTradeToSelected = false
    local autoTradeToAll = false

    local function getPlayerDisplay(plr)
        return (plr.DisplayName and plr.DisplayName ~= "") and plr.DisplayName or plr.Name
    end

    local function buildPlayerDisplayList()
        local l = {}
        if not player then return {"None"} end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then table.insert(l, getPlayerDisplay(p)) end
        end
        if #l == 0 then table.insert(l, "None") end
        return l
    end

    local giftTab = window:AddTab({
        Name = "Gift",
        Icon = "lucide:gift",
        Type = "Single",
    })
    local giftedTab = giftTab:AddTabbox({ Name = "Feature", Position = "center" })

    local autoTradeTab = giftedTab:AddTab("Auto Trade", "lucide:repeat")
    autoTradeTab:AddDivider({ Text = "Auto Trade" })
    autoTradeTab:AddDropdown({
        Name = "Select Pet",
        Values = {"[🟡--UNIQUE--🟡]", "Apex Overlord", "Reactor Beast", "Plasma Ravager", "Titan Reactor", "Neon Guardian", "Muscle Sensei", "Gold Warrior", "Cool Guy Larry", "Hank", "Sky Hawk",
            "Cybernetic Showdown Dragon", "Darkstar Hunter", "Ultra Birdie", "Magic Butterfly", "Infernal Dragon",
            "[🟣--EPIC--🟣]", "Core Pup", "Volt Talon", "Golden Viking", "Lightning Strike Phantom", "Phantom Genesis Dragon", "White Pheonix",
            "Golden Pheonix", "Red Firecaster", "Green Firecaster", "Blue Firecaster", "Blue Phoenix",
            "[🔵--RARE--🔵]", "Eternal Strike Leviathan", "White Pegasus", "Purple Falcon", "Red Dragon",
            "Dark Legends Manticore", "Orange Pegasus", "Purple Dragon", "Crimson Falcon",
            "[🟢--COMMON--🟢]", "Yellow Butterfly", "Green Butterfly", "Dark Golem", "Dark Vampy", "Silver Dog",
            "Blue Bunny", "Blue Birdie", "Red Kitty", "Orange Hedgehog"},
        Default = "",
        Flag = genFlag(),
        Callback = function(p) selectedPetName = p end
    })
    autoTradeTab:AddDropdown({
        Name = "Select Player",
        Values = buildPlayerDisplayList(),
        Default = buildPlayerDisplayList()[1] or "None",
        Flag = genFlag(),
        Callback = function(sd)
            selectedPlayer = nil
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and getPlayerDisplay(p) == sd then
                    selectedPlayer = p
                    break
                end
            end
        end
    })
    autoTradeTab:AddToggle({
        Name = "Trade Select Player",
        Default = false,
        Flag = genFlag(),
        Callback = function(s) autoTradeToSelected = s end
    })
    autoTradeTab:AddToggle({
        Name = "Trade All Player",
        Default = false,
        Flag = genFlag(),
        Callback = function(s) autoTradeToAll = s end
    })

    if typeof(mainTradeLoop) == "function" then
        task.spawn(mainTradeLoop)
    end

    local autogiftTab = giftedTab:AddTab("Gift Egg", "lucide:repeat")

    local TARGET = ""
    local ITEM = "Protein Egg"
    local ITEM2 = "Tropical Shake"
    local eggAmountInput = 1
    local autoGiftRunning = false

    local function getDisplayList()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                table.insert(list, p.DisplayName .. "  [ " .. p.Name .. " ]")
            end
        end
        return list
    end

    local function getName(text)
        return text and text:match("%[%s*(.-)%s*%]$")
    end

    local giftDropdown = autogiftTab:AddDropdown({
        Name = "Select Player",
        Values = getDisplayList(),
        Default = "",
        Flag = genFlag(),
        Callback = function(v)
            TARGET = getName(v) or ""
        end
    })

    autogiftTab:AddTextInput({
        Name = "Number of Eggs",
        Placeholder = "Enter the amount",
        Flag = genFlag(),
        Callback = function(text)
            eggAmountInput = tonumber(text) or 1
        end
    })

    autogiftTab:AddButton({
        Name = "Refresh Player Target",
        Callback = function() 
            giftDropdown:SetValues(getDisplayList()) 
        end
    })

    autogiftTab:AddToggle({
        Name = "Auto Gift Egg",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            autoGiftRunning = bool
            if autoGiftRunning then
                task.spawn(function()
                    local count = 0
                    while autoGiftRunning and (eggAmountInput <= 0 or count < eggAmountInput) do
                        local targetPlayer = Players:FindFirstChild(TARGET)
                        local consumables = player:FindFirstChild("consumablesFolder")
                        local itemObj = consumables and consumables:FindFirstChild(ITEM)

                        if not targetPlayer or not itemObj then 
                            break 
                        end

                        local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
                        local giftRemote = rEvents and rEvents:FindFirstChild("giftRemote")

                        if giftRemote then
                            local success, result = pcall(function()
                                return giftRemote:InvokeServer("giftRequest", targetPlayer, itemObj)
                            end)

                            if not success or not result then 
                                break 
                            end

                            count = count + 1
                            window:Notify({ Title = "Success Gift", Content = count .. " Egg successfully sent" })
                        else
                            break
                        end
                        task.wait(1)
                    end
                end)
            end
        end
    })
end

do
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local player = Players.LocalPlayer

    local genFlag = genFlag or function()
        return "Flag_" .. tostring(math.random(100000, 999999))
    end

    local killerTab = window:AddTab({
        Name = "Killer",
        Icon = "lucide:locate-fixed",
        Type = "Single",
    })

    local killerTabbox1 = killerTab:AddTabbox({ Name = "Killer 1", Position = "center" })

    local animationTab = killerTabbox1:AddTab("Animation", "lucide:film")
    animationTab:AddDivider({ Text = "Animation" })

    local removeAnimationEnabled = false

    local function processAnimation(humanoid, blockedAnimations)
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            local anim, name = track.Animation, track.Name:lower()
            if anim and (blockedAnimations[anim.AnimationId] or name:match("punch") or name:match("attack") or name:match("right")) then 
                track:Stop() 
            end
        end
    end

    animationTab:AddToggle({
        Name = "Remove Attack Animations",
        Default = false,
        Callback = function(state)
            removeAnimationEnabled = state
            local blockedAnimations = {["rbxassetid://3638729053"] = true, ["rbxassetid://3638767427"] = true}
            
            if removeAnimationEnabled then
                local function setupAnimationBlocking()
                    local char = player.Character
                    local humanoid = char and char:FindFirstChild("Humanoid")
                    if not humanoid then return end
                    
                    processAnimation(humanoid, blockedAnimations)
                    
                    if not _G.AnimBlockConnection then
                        _G.AnimBlockConnection = humanoid.AnimationPlayed:Connect(function(track)
                            if not removeAnimationEnabled then return end
                            local anim, name = track.Animation, track.Name:lower()
                            if anim and (blockedAnimations[anim.AnimationId] or name:match("punch") or name:match("attack") or name:match("right")) then 
                                track:Stop() 
                            end
                        end)
                    end
                end

                local function overrideToolActivation()
                    _G.ToolConnections = _G.ToolConnections or {}
                    local function processTool(tool)
                        if tool and (tool.Name == "Punch" or tool.Name:match("Attack") or tool.Name:match("Right")) and not tool:GetAttribute("ActivatedOverride") then
                            tool:SetAttribute("ActivatedOverride", true)
                            _G.ToolConnections[tool] = tool.Activated:Connect(function()
                                if not removeAnimationEnabled then return end
                                task.wait(0.05)
                                local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                                if humanoid then
                                    processAnimation(humanoid, blockedAnimations)
                                end
                            end)
                        end
                    end
                    
                    local function watchTools(container)
                        for _, tool in pairs(container:GetChildren()) do processTool(tool) end
                        return container.ChildAdded:Connect(function(tool) task.wait(0.1) processTool(tool) end)
                    end
                    
                    _G.ToolConnections.Backpack = watchTools(player.Backpack)
                    if player.Character then 
                        _G.ToolConnections.Character = watchTools(player.Character) 
                    end
                end

                setupAnimationBlocking() 
                overrideToolActivation()

                if not _G.AnimMonitorConnection then
                    _G.AnimMonitorConnection = RunService.Heartbeat:Connect(function()
                        if not removeAnimationEnabled then return end
                        local char = player.Character
                        local humanoid = char and char:FindFirstChild("Humanoid")
                        if humanoid and tick() % 0.5 < 0.01 then
                            processAnimation(humanoid, blockedAnimations)
                        end
                    end)
                end

                window:Notify({ Title = "Success", Content = "Attack animations removed" })
            else
                if _G.AnimBlockConnection then
                    _G.AnimBlockConnection:Disconnect()
                    _G.AnimBlockConnection = nil
                end
                
                if _G.AnimMonitorConnection then
                    _G.AnimMonitorConnection:Disconnect()
                    _G.AnimMonitorConnection = nil
                end

                if _G.ToolConnections then
                    if _G.ToolConnections.Backpack then _G.ToolConnections.Backpack:Disconnect() end
                    if _G.ToolConnections.Character then _G.ToolConnections.Character:Disconnect() end
                    _G.ToolConnections = nil
                end

                window:Notify({ Title = "Disabled", Content = "Animations restored" })
            end
        end
    })

    _G.ToggleFastPunch = function(bool)
        _G.FastPunch = bool
        if bool then
            task.spawn(function()
                while _G.FastPunch do
                    local character = player.Character
                    if character then
                        local punch = character:FindFirstChild("Punch") or player.Backpack:FindFirstChild("Punch")
                        if punch then
                            if punch:FindFirstChild("attackTime") then punch.attackTime.Value = 0 end
                            if punch.Parent ~= character and character:FindFirstChild("Humanoid") then
                                character.Humanoid:EquipTool(punch)
                            end
                            punch:Activate()
                        end
                    end
                    task.wait()
                end
            end)
            task.spawn(function()
                while _G.FastPunch do
                    local muscleEvent = player:FindFirstChild("muscleEvent") or ReplicatedStorage:FindFirstChild("muscleEvent")
                    if muscleEvent then
                        muscleEvent:FireServer("punch", "rightHand")
                        muscleEvent:FireServer("punch", "leftHand")
                    end
                    task.wait()
                end
            end)
        else
            local punch = player.Character and (player.Character:FindFirstChild("Punch") or player.Backpack:FindFirstChild("Punch"))
            if punch and punch:FindFirstChild("attackTime") then 
                punch.attackTime.Value = 0.35 
            end
        end
    end

    animationTab:AddToggle({
        Name = "Fast Punch",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            _G.ToggleFastPunch(bool)
        end
    })

    local autoKillerTab = killerTabbox1:AddTab("Auto Killer", "lucide:crosshair")
    autoKillerTab:AddDivider({ Text = "Auto Killer" })

    local SNAP_OFFSET = 6
    local DURATION_PER_PLAYER = 0.3
    local TELEPORT_INTERVAL = 0.01
    local manualWhitelist = {}

    local autoGoodKarma = false
    local autoEvilKarma = false

    local function getDisplayList()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                table.insert(list, p.DisplayName .. "  [ " .. p.Name .. " ]")
            end
        end
        return list
    end

    local function getName(text)
        return text and text:match("%[%s*(.-)%s*%]$")
    end

    local whitelistDropdown = autoKillerTab:AddDropdown({
        Name = "Whitelist Players",
        Multi = true,
        Values = getDisplayList(),
        Default = {},
        Flag = genFlag(),
        Callback = function(v)
            table.clear(manualWhitelist)
            for index, value in pairs(v) do
                local targetName = nil
                if type(index) == "string" and value == true then
                    targetName = getName(index)
                elseif type(value) == "string" then
                    targetName = getName(value)
                end
                if targetName then
                    local targetPlayer = Players:FindFirstChild(targetName)
                    if targetPlayer then
                        manualWhitelist[targetPlayer.UserId] = true
                    end
                end
            end
        end
    })

    autoKillerTab:AddButton({
        Name = "Refresh Whitelist",
        Callback = function() 
            whitelistDropdown:SetValues(getDisplayList()) 
        end
    })

    local function hasProtection(tChar)
        if not tChar then return true end
        if tChar:FindFirstChild("spawnProtectionHighlight") then return true end
        local head = tChar:FindFirstChild("Head")
        if head and head:FindFirstChild("spawnProtectionGui") then return true end
        return false
    end

    local function isInBossArena(tChar)
        if not tChar then return false end
        local bossArena = Workspace:FindFirstChild("BossArena", true)
        if not bossArena then return false end
        if tChar:IsDescendantOf(bossArena) then
            return true
        end
        local trp = tChar:FindFirstChild("HumanoidRootPart")
        if not trp then return false end
        for _, arena in ipairs(bossArena:GetChildren()) do
            if arena:IsA("Model") then
                local cf, size = arena:GetBoundingBox()
                if cf and size then
                    local localPos = cf:PointToObjectSpace(trp.Position)
                    if math.abs(localPos.X) <= size.X / 2 and
                       math.abs(localPos.Y) <= size.Y / 2 + 15 and
                       math.abs(localPos.Z) <= size.Z / 2 then
                        return true
                    end
                end
            elseif arena:IsA("BasePart") then
                local dist = (trp.Position - arena.Position).Magnitude
                if dist <= (arena.Size.X / 2 + 10) then
                    return true
                end
            end
        end
        return false
    end

    local function checkKarma(target, karmaMode)
        if not karmaMode then return true end
        local evil = target:FindFirstChild("evilKarma")
        local good = target:FindFirstChild("goodKarma")
        if not evil or not good then return false end
        if karmaMode == "Good" then
            return evil.Value > good.Value
        elseif karmaMode == "Evil" then
            return good.Value > evil.Value
        end
        return true
    end

    local function canTarget(target, karmaMode)
        if target == player then return false end
        if manualWhitelist[target.UserId] then return false end
        if not checkKarma(target, karmaMode) then return false end
        local tChar = target.Character
        if not tChar then return false end
        if tChar:FindFirstChildOfClass("ForceField") then return false end
        if hasProtection(tChar) then return false end
        if isInBossArena(tChar) then return false end
        local hum = tChar:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        return true
    end

    local function attackTarget(target, isToggleActive, karmaMode)
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local tChar = target.Character
        local trp = tChar and tChar:FindFirstChild("HumanoidRootPart")
        if not root or not trp then return end

        local startTime = tick()
        while tick() - startTime < DURATION_PER_PLAYER do
            if not isToggleActive() or not canTarget(target, karmaMode) then break end
            char = player.Character
            root = char and char:FindFirstChild("HumanoidRootPart")
            tChar = target.Character
            trp = tChar and tChar:FindFirstChild("HumanoidRootPart")

            if root and trp then
                root.CFrame = trp.CFrame * CFrame.new(0, 0, SNAP_OFFSET)
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                for _, handName in ipairs({"RightHand", "LeftHand", "Right Arm", "Left Arm"}) do
                    local hand = char:FindFirstChild(handName)
                    if hand then
                        firetouchinterest(hand, trp, 1)
                        firetouchinterest(hand, trp, 0)
                    end
                end
            else
                break
            end
            task.wait(TELEPORT_INTERVAL)
        end
    end

    autoKillerTab:AddToggle({
        Name = "Auto Kill All Players",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            _G.GhostKill = bool
            if typeof(_G.ToggleFastPunch) == "function" then
                pcall(_G.ToggleFastPunch, bool)
            end
            if bool then
                task.spawn(function()
                    while _G.GhostKill do
                        local attackedAny = false
                        for _, target in ipairs(Players:GetPlayers()) do
                            if not _G.GhostKill then break end
                            if canTarget(target, nil) then
                                attackedAny = true
                                attackTarget(target, function() return _G.GhostKill end, nil)
                            end
                        end
                        if not attackedAny then
                            task.wait(0.05)
                        end
                    end
                end)
            end
        end
    })

    autoKillerTab:AddToggle({
        Name = "Auto Good Karma",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            autoGoodKarma = bool
            if typeof(_G.ToggleFastPunch) == "function" then
                pcall(_G.ToggleFastPunch, bool)
            end
            if bool then
                task.spawn(function()
                    while autoGoodKarma do
                        local attackedAny = false
                        for _, target in ipairs(Players:GetPlayers()) do
                            if not autoGoodKarma then break end
                            if canTarget(target, "Good") then
                                attackedAny = true
                                attackTarget(target, function() return autoGoodKarma end, "Good")
                            end
                        end
                        if not attackedAny then
                            task.wait(0.05)
                        end
                    end
                end)
            end
        end
    })

    autoKillerTab:AddToggle({
        Name = "Auto Evil Karma",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            autoEvilKarma = bool
            if typeof(_G.ToggleFastPunch) == "function" then
                pcall(_G.ToggleFastPunch, bool)
            end
            if bool then
                task.spawn(function()
                    while autoEvilKarma do
                        local attackedAny = false
                        for _, target in ipairs(Players:GetPlayers()) do
                            if not autoEvilKarma then break end
                            if canTarget(target, "Evil") then
                                attackedAny = true
                                attackTarget(target, function() return autoEvilKarma end, "Evil")
                            end
                        end
                        if not attackedAny then
                            task.wait(0.05)
                        end
                    end
                end)
            end
        end
    })

    local playerTargetTab = killerTabbox1:AddTab("Player Target", "lucide:target")
    playerTargetTab:AddDivider({ Text = "Player Target" })

    local selectedSpyName = ""
    local spyDropdown = playerTargetTab:AddDropdown({
        Name = "Spectate Player",
        Values = getDisplayList(),
        Default = getDisplayList()[1] or "",
        Flag = genFlag(),
        Callback = function(v) selectedSpyName = getName(v) or "" end
    })

    playerTargetTab:AddButton({
        Name = "Refresh Spectate List",
        Callback = function() spyDropdown:SetValues(getDisplayList()) end
    })

    local spyingEnabled = false
    playerTargetTab:AddToggle({
        Name = "Spectate Player",
        Default = false,
        Flag = genFlag(),
        Callback = function(v)
            spyingEnabled = v
            if not v then
                Workspace.CurrentCamera.CameraSubject = player.Character and player.Character:FindFirstChild("Humanoid")
            else
                task.spawn(function()
                    while spyingEnabled do
                        local t = selectedSpyName and Players:FindFirstChild(selectedSpyName)
                        if t and t.Character and t.Character:FindFirstChild("Humanoid") then
                            Workspace.CurrentCamera.CameraSubject = t.Character.Humanoid
                        end
                        task.wait(0.1)
                    end
                end)
            end
        end
    })

    local killTargets = {}

    local targetDropdown = playerTargetTab:AddDropdown({
        Name = "Target Killer",
        Values = getDisplayList(),
        Default = getDisplayList()[1] or "",
        Flag = genFlag(),
        Callback = function(v) killTargets = {getName(v)} end
    })

    playerTargetTab:AddButton({
        Name = "Refresh Player Target",
        Callback = function() targetDropdown:SetValues(getDisplayList()) end
    })

    local function canTargetLock(target)
        if not target or target == player then return false end
        local tChar = target.Character
        if not tChar then return false end
        local hum = tChar:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        return true
    end

    local autoKillEnabled = false
    playerTargetTab:AddToggle({
        Name = "Kill Target",
        Default = false,
        Flag = genFlag(),
        Callback = function(v)
            autoKillEnabled = v
            if typeof(_G.ToggleFastPunch) == "function" then
                pcall(_G.ToggleFastPunch, v)
            end
            if v then
                task.spawn(function()
                    while autoKillEnabled do
                        if #killTargets > 0 then
                            local t = Players:FindFirstChild(killTargets[1])
                            if t and canTargetLock(t) then
                                local char = player.Character
                                local root = char and char:FindFirstChild("HumanoidRootPart")
                                local tChar = t.Character
                                local trp = tChar and tChar:FindFirstChild("HumanoidRootPart")

                                if root and trp then
                                    local startTime = tick()
                                    while tick() - startTime < DURATION_PER_PLAYER do
                                        if not autoKillEnabled or not canTargetLock(t) then break end
                                        char = player.Character
                                        root = char and char:FindFirstChild("HumanoidRootPart")
                                        tChar = t.Character
                                        trp = tChar and tChar:FindFirstChild("HumanoidRootPart")

                                        if root and trp then
                                            root.CFrame = trp.CFrame * CFrame.new(0, 0, SNAP_OFFSET)
                                            root.AssemblyLinearVelocity = Vector3.zero
                                            root.AssemblyAngularVelocity = Vector3.zero

                                            for _, handName in ipairs({"RightHand", "LeftHand", "Right Arm", "Left Arm"}) do
                                                local hand = char:FindFirstChild(handName)
                                                if hand then
                                                    firetouchinterest(hand, trp, 1)
                                                    firetouchinterest(hand, trp, 0)
                                                end
                                            end
                                        else
                                            break
                                        end
                                        task.wait(TELEPORT_INTERVAL)
                                    end
                                end
                            else
                                task.wait(0.05)
                            end
                        else
                            task.wait(0.1)
                        end
                    end
                end)
            end
        end
    })

    local killerTabbox2 = killerTab:AddTabbox({ Name = "Killer 2", Position = "center" })

    local teleportPlayerTab = killerTabbox2:AddTab("Teleport Player", "lucide:send")
    teleportPlayerTab:AddDivider({ Text = "Teleport Player" })

    local selectedTpName = ""
    local tpDropdown = teleportPlayerTab:AddDropdown({
        Name = "Select Teleport Target",
        Values = getDisplayList(),
        Default = getDisplayList()[1] or "",
        Flag = genFlag(),
        Callback = function(v) selectedTpName = getName(v) or "" end
    })

    teleportPlayerTab:AddButton({
        Name = "Refresh TP List",
        Callback = function() tpDropdown:SetValues(getDisplayList()) end
    })

    local tpToTargetEnabled = false
    teleportPlayerTab:AddToggle({
        Name = "Teleport to Player",
        Default = false,
        Flag = genFlag(),
        Callback = function(v)
            tpToTargetEnabled = v
            while tpToTargetEnabled do
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local t = selectedTpName and Players:FindFirstChild(selectedTpName)
                local thrp = t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")
                if hrp and thrp then
                    hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, 3)
                end
                task.wait(0.1)
            end
        end
    })

    local domainKillerTab = killerTabbox2:AddTab("Domain Killer", "lucide:circle")
    domainKillerTab:AddDivider({ Text = "Domain Killer" })

    local currentRadius = 20
    local runAura = false
    local auraConn = nil
    local radiusVisuals = {}

    local function updateVisual(radius)
        for _, v in ipairs(radiusVisuals) do v:Destroy() end
        radiusVisuals = {}
        local d = Instance.new("Part", Workspace)
        d.Name = "AuraDomain"
        d.Shape = Enum.PartType.Ball
        d.Anchored = true
        d.CanCollide = false
        d.CastShadow = false
        d.Transparency = (_G.DomainTransparent and 1 or 0.7)
        d.Material = Enum.Material.ForceField
        d.Color = Color3.new(0, 0, 0)
        d.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
        radiusVisuals[1] = d
    end

    domainKillerTab:AddTextInput({
        Name = "Set Domain Size",
        Placeholder = "Size...",
        Default = "20",
        Locked = true,
        Callback = function(v)
            currentRadius = tonumber(v) or 20
            if runAura then updateVisual(currentRadius) end
        end
    })

    local domainWhitelistDropdown = domainKillerTab:AddDropdown({
        Name = "Whitelist Players",
        Multi = true,
        Values = getDisplayList(),
        Default = {},
        Flag = genFlag(),
        Callback = function(v)
            table.clear(manualWhitelist)
            for index, value in pairs(v) do
                local targetName = nil
                if type(index) == "string" and value == true then
                    targetName = getName(index)
                elseif type(value) == "string" then
                    targetName = getName(value)
                end
                
                if targetName then
                    local targetPlayer = Players:FindFirstChild(targetName)
                    if targetPlayer then
                        manualWhitelist[targetPlayer.UserId] = true
                    end
                end
            end
        end
    })

    domainKillerTab:AddButton({
        Name = "Player Refresh",
        Callback = function() domainWhitelistDropdown:SetValues(getDisplayList()) end
    })

    domainKillerTab:AddToggle({
        Name = "Active Domain Killer",
        Default = false,
        Flag = genFlag(),
        Callback = function(v)
            runAura = v
            _G.ToggleFastPunch(v)

            removeAnimationEnabled = v
            local blockedAnimations = {["rbxassetid://3638729053"] = true, ["rbxassetid://3638767427"] = true}
            
            if v then
                local char = player.Character
                local humanoid = char and char:FindFirstChild("Humanoid")
                if humanoid then
                    processAnimation(humanoid, blockedAnimations)
                    if not _G.AnimBlockConnection then
                        _G.AnimBlockConnection = humanoid.AnimationPlayed:Connect(function(track)
                            if not removeAnimationEnabled then return end
                            local anim, name = track.Animation, track.Name:lower()
                            if anim and (blockedAnimations[anim.AnimationId] or name:match("punch") or name:match("attack") or name:match("right")) then 
                                track:Stop() 
                            end
                        end)
                    end
                end

                if not _G.AnimMonitorConnection then
                    _G.AnimMonitorConnection = RunService.Heartbeat:Connect(function()
                        if not removeAnimationEnabled then return end
                        local currentHumanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                        if currentHumanoid and tick() % 0.5 < 0.01 then
                            processAnimation(currentHumanoid, blockedAnimations)
                        end
                    end)
                end
            else
                if _G.AnimBlockConnection then
                    _G.AnimBlockConnection:Disconnect()
                    _G.AnimBlockConnection = nil
                end
                if _G.AnimMonitorConnection then
                    _G.AnimMonitorConnection:Disconnect()
                    _G.AnimMonitorConnection = nil
                end
            end
            
            if auraConn then auraConn:Disconnect() end
            for _, vis in ipairs(radiusVisuals) do vis:Destroy() end
            radiusVisuals = {}

            if v then
                updateVisual(currentRadius)
                auraConn = RunService.Heartbeat:Connect(function()
                    local c = player.Character
                    local hrp = c and c:FindFirstChild("HumanoidRootPart")
                    local rh = c and c:FindFirstChild("RightHand")
                    local lh = c and c:FindFirstChild("LeftHand")
                    if hrp and rh and lh then
                        if radiusVisuals[1] then radiusVisuals[1].CFrame = hrp.CFrame end
                        for _, p in ipairs(Players:GetPlayers()) do
                            local e = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                            if p ~= player and not manualWhitelist[p.UserId] and e and (e.Position - hrp.Position).Magnitude <= currentRadius and p.Character.Humanoid.Health > 0 then
                                firetouchinterest(rh, e, 1)
                                firetouchinterest(rh, e, 0)
                                firetouchinterest(lh, e, 1)
                                firetouchinterest(lh, e, 0)
                            end
                        end
                    end
                end)
            end
        end
    })

    domainKillerTab:AddToggle({
        Name = "Invisible Domain",
        Default = false,
        Flag = genFlag(),
        Callback = function(v)
            _G.DomainTransparent = v
            if radiusVisuals[1] then radiusVisuals[1].Transparency = v and 1 or 0.7 end
        end
    })
end


do
    local Players = game:GetService("Players")
    local workspace = game:GetService("Workspace")
    local player = Players.LocalPlayer

    local genFlag = genFlag or function()
        return "Flag_" .. tostring(math.random(100000, 999999))
    end
    local wasFlying = false
    local antiKbEnabled = antiKbEnabled or false

    local bossTab = window:AddTab({
        Name = "Boss",
        Icon = "lucide:skull",
        Type = "Single",
    })

    local bossTabbox1 = bossTab:AddTabbox({ Name = "Status Boss", Position = "center" })
    local bossStatusTab = bossTabbox1:AddTab("..Waiting Boss..", "lucide:activity")
    local bossDivider = bossStatusTab:AddDivider({ Text = "Health: ..........." })

    local screenGui = nil
    local monitorLoop = nil

    bossStatusTab:AddToggle({
        Name = "Show Status Boss",
        Default = false,
        Flag = genFlag(),
        Callback = function(state)
            if state then
                local playerGui = player:WaitForChild("PlayerGui")
                local uiName = "ZorVexBossMonitor"
                if playerGui:FindFirstChild(uiName) then playerGui[uiName]:Destroy() end

                screenGui = Instance.new("ScreenGui")
                screenGui.Name = uiName
                screenGui.ResetOnSpawn = false
                screenGui.Parent = playerGui

                local mainFrame = Instance.new("Frame")
                mainFrame.Name = "MainFrame"
                mainFrame.Size = UDim2.new(0, 156, 0, 45)
                mainFrame.Position = UDim2.new(0.5, -78, 0, 20)
                mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                mainFrame.BackgroundTransparency = 0.1
                mainFrame.BorderSizePixel = 0
                mainFrame.Parent = screenGui

                local mainCorner = Instance.new("UICorner")
                mainCorner.CornerRadius = UDim.new(0, 8)
                mainCorner.Parent = mainFrame

                local function createShadow(thickness, transparency)
                    local stroke = Instance.new("UIStroke")
                    stroke.Thickness = thickness
                    stroke.Transparency = transparency
                    stroke.Color = Color3.fromRGB(0, 0, 0)
                    stroke.Parent = mainFrame
                    return stroke
                end

                createShadow(4.0, 0.900)
                createShadow(3.0, 0.900)
                createShadow(2.0, 0.900)

                local titleLabel = Instance.new("TextLabel")
                titleLabel.Name = "TitleLabel"
                titleLabel.Size = UDim2.new(1, -16, 0, 16)
                titleLabel.Position = UDim2.new(0, 8, 0, 7)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Font = Enum.Font.GothamBold
                titleLabel.Text = "Waiting For The Boss"
                titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                titleLabel.TextSize = 9
                titleLabel.TextXAlignment = Enum.TextXAlignment.Center
                titleLabel.Parent = mainFrame

                local titleStroke = Instance.new("UIStroke")
                titleStroke.Name = "TitleStroke"
                titleStroke.Thickness = 1.0
                titleStroke.Color = Color3.fromRGB(255, 255, 255)
                titleStroke.Transparency = 1
                titleStroke.Parent = titleLabel

                local hpText = Instance.new("TextLabel")
                hpText.Name = "HpText"
                hpText.Size = UDim2.new(1, -16, 0, 14)
                hpText.Position = UDim2.new(0, 8, 0, 23)
                hpText.BackgroundTransparency = 1
                hpText.Font = Enum.Font.GothamBold
                hpText.Text = "..........."
                hpText.TextColor3 = Color3.fromRGB(200, 200, 200)
                hpText.TextSize = 8
                hpText.TextXAlignment = Enum.TextXAlignment.Center
                hpText.Parent = mainFrame

                local bossConfig = {
                    [1] = { name = "Common Boss", color = Color3.fromRGB(160, 160, 160), hasOutline = true },
                    [2] = { name = "Rare Boss", color = Color3.fromRGB(52, 152, 219), hasOutline = false },
                    [3] = { name = "Epic Boss", color = Color3.fromRGB(155, 89, 182), hasOutline = false },
                    [4] = { name = "Legendary Boss", color = Color3.fromRGB(241, 196, 15), hasOutline = false },
                    [5] = { name = "Mythic Boss", color = Color3.fromRGB(146, 0, 0), hasOutline = false },
                    ["bossrainbow"] = { name = "Rainbow Boss", color = Color3.fromRGB(255, 0, 255), hasOutline = true }
                }

                monitorLoop = task.spawn(function()
                    while screenGui and screenGui.Parent do
                        task.wait(0.2)
                        local bossArena = workspace:FindFirstChild("Events") and workspace.Events:FindFirstChild("BossArena")
                        local activeBossObj = nil
                        
                        if bossArena then
                            local bossList = {"Boss1", "Boss2", "Boss3", "Boss4", "Boss5", "bossrainbow"}
                            for _, bName in ipairs(bossList) do
                                local boss = bossArena:FindFirstChild(bName)
                                if boss then
                                    local health = tonumber(boss:GetAttribute("Health")) or 0
                                    if health > 0 then
                                        activeBossObj = boss
                                        break
                                    end
                                end
                            end
                        end
                        
                        if activeBossObj then
                            local key = activeBossObj.Name:lower()
                            local config = bossConfig[key] or bossConfig[tonumber(key:match("%d+"))] or { name = activeBossObj.Name, color = Color3.fromRGB(255,255,255), hasOutline = false }
                            local health = tonumber(activeBossObj:GetAttribute("Health")) or 0
                            local maxHealth = tonumber(activeBossObj:GetAttribute("MaxHealth")) or 100
                            if maxHealth <= 0 then maxHealth = 1 end
                            
                            titleLabel.Text = config.name
                            titleLabel.TextColor3 = config.color
                            titleStroke.Transparency = config.hasOutline and 0 or 1
                            
                            hpText.Text = string.format("%d / %d", health, maxHealth)
                            hpText.TextColor3 = config.color
                        else
                            titleLabel.Text = "Waiting For The Boss"
                            titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                            titleStroke.Transparency = 1
                            hpText.Text = "..........."
                            hpText.TextColor3 = Color3.fromRGB(200, 200, 200)
                        end
                    end
                end)
            else
                if screenGui then screenGui:Destroy() screenGui = nil end
                monitorLoop = nil
            end
        end
    })

    local bossConfigDivider = {
        [1] = { name = "Common Boss" }, [2] = { name = "Rare Boss" },
        [3] = { name = "Epic Boss" }, [4] = { name = "Legendary Boss" },
        [5] = { name = "Mythic Boss" }, ["bossrainbow"] = { name = "Rainbow Boss" }
    }

    task.spawn(function()
        while true do
            task.wait(0.3)
            local bossArena = workspace:FindFirstChild("Events") and workspace.Events:FindFirstChild("BossArena")
            local activeBossObj = nil
            
            if bossArena then
                local bossList = {"Boss1", "Boss2", "Boss3", "Boss4", "Boss5", "bossrainbow"}
                for _, bName in ipairs(bossList) do
                    local boss = bossArena:FindFirstChild(bName)
                    if boss and (tonumber(boss:GetAttribute("Health")) or 0) > 0 then
                        activeBossObj = boss
                        break
                    end
                end
            end
            
            if activeBossObj then
                local key = activeBossObj.Name:lower()
                local cfg = bossConfigDivider[key] or bossConfigDivider[tonumber(key:match("%d+"))] or { name = activeBossObj.Name }
                local health = tonumber(activeBossObj:GetAttribute("Health")) or 0
                
                if bossStatusTab.SetName then bossStatusTab:SetName(cfg.name)
                elseif bossStatusTab.SetText then bossStatusTab:SetText(cfg.name) end
                bossDivider:SetText("Health: " .. math.floor(health))
            else
                if bossStatusTab.SetName then bossStatusTab:SetName("..Waiting Boss..")
                elseif bossStatusTab.SetText then bossStatusTab:SetText("..Waiting Boss..") end
                bossDivider:SetText("Health: ...........")
            end
        end
    end)

    local bossTabbox2 = bossTab:AddTabbox({ Name = "Boss Killer", Position = "center" })
    local bossFarmTab = bossTabbox2:AddTab("Auto Kill Boss", "lucide:activity")

    local SEARCH_KEYWORDS = {"boss1", "boss2", "boss3", "boss4", "boss5", "bossrainbow"} 
    local WAIT_POSITION = CFrame.new(-1.89, 35.90, -1006.04)

    local isFarmingActive = false
    local isClaimingActive = false

    local currentMode = "IDLE"

    local bossFarmToggleRef = nil
    local bossClaimToggleRef = nil

    local function getCharacterParts()
        local char = player.Character
        if not char then return nil, nil, nil end
        return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChild("Humanoid")
    end

    local bossFlyBV = nil
    local bossFlyBG = nil
    local emoteIdleName, emoteIdleId = "GodlikeIdle", 81359407734079 

    local function playBossEmote(hum, name)
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then return end
        pcall(function() 
            hum:PlayEmote(name)
            task.delay(0.05, function() 
                for _, track in pairs(animator:GetPlayingAnimationTracks()) do 
                    if track.IsPlaying then 
                        track.Priority = Enum.AnimationPriority.Action4
                        track.Looped = true
                        track:AdjustSpeed(1) 
                    end 
                end 
            end) 
        end)
    end

    local function setBossFlying(enabled, hrp, hum)
        if not hrp or not hum then return end
        
        local desc = hum:FindFirstChildOfClass("HumanoidDescription")
        if desc then
            pcall(function() 
                desc:SetEmotes({
                    [emoteIdleName] = {emoteIdleId},
                    ["FlyingMove"] = {106493972274585}
                }) 
            end)
        end

        if enabled then
            wasFlying = true
            hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
            hum:ChangeState(Enum.HumanoidStateType.Physics)
            
            if not bossFlyBV or bossFlyBV.Parent ~= hrp then
                bossFlyBV = Instance.new("BodyVelocity")
                bossFlyBV.Name = "BossFlyBV"
                bossFlyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bossFlyBV.Velocity = Vector3.zero
                bossFlyBV.Parent = hrp
            end
            
            if not bossFlyBG or bossFlyBG.Parent ~= hrp then
                bossFlyBG = Instance.new("BodyGyro")
                bossFlyBG.Name = "BossFlyBG"
                bossFlyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                bossFlyBG.P = 5000
                bossFlyBG.Parent = hrp
            end
        else
            if wasFlying then
                wasFlying = false
                if bossFlyBV then bossFlyBV:Destroy() bossFlyBV = nil end
                if bossFlyBG then bossFlyBG:Destroy() bossFlyBG = nil end
                hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end

    task.spawn(function()
        while true do
            if currentMode == "CLAIM" and (isFarmingActive or isClaimingActive) then
                local _, hrp = getCharacterParts()
                if hrp then
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if currentMode ~= "CLAIM" then break end
                        if obj.Name:find("BossChest") or obj.Name:lower():find("chest_base") then
                            pcall(function()
                                if obj:IsA("Model") then
                                    for _, part in ipairs(obj:GetDescendants()) do
                                        if part:IsA("BasePart") then
                                            firetouchinterest(hrp, part, 0)
                                            firetouchinterest(hrp, part, 1)
                                        end
                                        local prompt = part:FindFirstChildOfClass("ProximityPrompt")
                                        if prompt then fireproximityprompt(prompt) end
                                    end
                                elseif obj:IsA("BasePart") then
                                    firetouchinterest(hrp, obj, 0)
                                    firetouchinterest(hrp, obj, 1)
                                    local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                                    if prompt then fireproximityprompt(prompt) end
                                end
                            end)
                        end
                    end
                end
            end
            task.wait(0.2)
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.1)

            if not isFarmingActive and not isClaimingActive then
                currentMode = "IDLE"
                local _, hrp, hum = getCharacterParts()
                if hrp and hum then setBossFlying(false, hrp, hum) end
                continue
            end

            if currentMode == "IDLE" then
                currentMode = isFarmingActive and "KILL" or "CLAIM"
            end

            if currentMode == "KILL" and isFarmingActive then
                local _, hrp, hum = getCharacterParts()
                if not hrp or not hum then task.wait(0.5) continue end

                setBossFlying(false, hrp, hum)
                hrp.CFrame = WAIT_POSITION

                local activeBossModel = nil
                
                if _G.ToggleFastPunch then _G.ToggleFastPunch(false) end

                while isFarmingActive and currentMode == "KILL" do
                    for _, keyword in ipairs(SEARCH_KEYWORDS) do
                        local bossArena = workspace:FindFirstChild("Events") and workspace.Events:FindFirstChild("BossArena")
                        if bossArena then
                            local b = bossArena:FindFirstChild(keyword) or bossArena:FindFirstChild(keyword:upper())
                            if b and (tonumber(b:GetAttribute("Health")) or 0) > 0 then
                                activeBossModel = b
                                break
                            end
                        end
                    end

                    if not activeBossModel then
                        for _, obj in ipairs(workspace:GetDescendants()) do
                            if obj:IsA("Model") and Players:GetPlayerFromCharacter(obj) == nil then
                                local nameLower = obj.Name:lower()
                                for _, kw in ipairs(SEARCH_KEYWORDS) do
                                    if nameLower:find(kw) then
                                        if (tonumber(obj:GetAttribute("Health")) or 1) > 0 then
                                            activeBossModel = obj
                                            break
                                        end
                                    end
                                end
                            end
                            if activeBossModel then break end
                        end
                    end

                    if activeBossModel then break end
                    task.wait(0.5)
                end

                if activeBossModel and isFarmingActive and currentMode == "KILL" then
                    setBossFlying(true, hrp, hum)
                    playBossEmote(hum, emoteIdleName)
                    
                    task.wait(2)
                    
                    if _G.ToggleFastPunch then
                        _G.ToggleFastPunch(true)
                    end

                    local activeNameLower = activeBossModel.Name:lower()
                    local offsetX, offsetY, offsetZ = 0, 0, 0

                    if activeNameLower:find("boss1") or activeNameLower:find("boss2") or activeNameLower:find("boss3") then
                        offsetX, offsetY, offsetZ = 0, 100, 0
                    elseif activeNameLower:find("boss4") or activeNameLower:find("boss5") or activeNameLower:find("bossrainbow") then
                        offsetX, offsetY, offsetZ = 0, 145, 0
                    end

                    while isFarmingActive and currentMode == "KILL" and activeBossModel and activeBossModel.Parent do
                        local hp = tonumber(activeBossModel:GetAttribute("Health")) or 0
                        if hp <= 0 then break end

                        local rootPart = activeBossModel:FindFirstChild("HumanoidRootPart") or activeBossModel:FindFirstChild("Head") or activeBossModel.PrimaryPart
                        local targetCF = rootPart and rootPart.CFrame or activeBossModel:GetPivot()

                        if targetCF and bossFlyBV and bossFlyBG and hrp then
                            local destCF = targetCF * CFrame.new(offsetX, offsetY, offsetZ)
                            local dir = (destCF.Position - hrp.Position)
                            
                            if dir.Magnitude > 3 then
                                bossFlyBV.Velocity = dir.Unit * 180
                            else
                                bossFlyBV.Velocity = Vector3.zero
                            end
                            
                            local lookAtPos = Vector3.new(targetCF.Position.X, hrp.Position.Y, targetCF.Position.Z)
                            bossFlyBG.CFrame = CFrame.lookAt(hrp.Position, lookAtPos)
                        end

                        pcall(function()
                            for _, part in ipairs(activeBossModel:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    for _, cPart in ipairs(player.Character:GetDescendants()) do
                                        if cPart:IsA("BasePart") then
                                            firetouchinterest(cPart, part, 0)
                                            firetouchinterest(cPart, part, 1)
                                        end
                                    end
                                end
                            end
                        end)
                        task.wait(0.1)
                    end
                end

                if _G.ToggleFastPunch then
                    _G.ToggleFastPunch(false)
                end

                setBossFlying(false, hrp, hum)
                task.wait(0.2)

                if isClaimingActive then
                    currentMode = "CLAIM"
                else
                    currentMode = "WAIT"
                end

            elseif currentMode == "CLAIM" then
                local _, hrp = getCharacterParts()
                if hrp then
                    local chestFound = false
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj.Name:lower():find("chest_base") or obj.Name:find("BossChest") then
                            local pos = obj:IsA("Model") and obj:GetPivot().Position or (obj:IsA("BasePart") and obj.Position)
                            if pos then
                                hrp.CFrame = CFrame.lookAt(pos + Vector3.new(-15, 7, 0), pos)
                                chestFound = true
                                break
                            end
                        end
                    end
                end

                local startT = tick()
                while (tick() - startT < 4) and (isFarmingActive or isClaimingActive) do
                    task.wait(0.2)
                end

                currentMode = "WAIT"

            elseif currentMode == "WAIT" then
                local _, hrp, hum = getCharacterParts()
                if hrp and hum then
                    setBossFlying(false, hrp, hum)
                    hrp.CFrame = WAIT_POSITION
                end
                task.wait(0.5)

                if isFarmingActive then
                    currentMode = "KILL"
                elseif isClaimingActive then
                    currentMode = "CLAIM"
                else
                    currentMode = "IDLE"
                end
            end
        end
    end)

    bossFarmToggleRef = bossFarmTab:AddToggle({
        Name = "Kill All Boss",
        Default = false,
        Flag = genFlag(),
        Callback = function(state)
            if state then
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if antiKbEnabled or (hrp and hrp:FindFirstChild("AntiKbBV_1")) then
                    window:Notify({ 
                        Title = "Failed To activate!!!", 
                        Content = "Turn off Anti Knockback First " 
                    })
                    bossFarmToggleRef:Set(false)
                    return
                end
            end

            isFarmingActive = state
            if state and currentMode == "IDLE" then
                currentMode = "KILL"
            elseif not state then
                if _G.ToggleFastPunch then _G.ToggleFastPunch(false) end
            end
        end
    })

    bossClaimToggleRef = bossFarmTab:AddToggle({
        Name = "Claim All Boss Chests",
        Default = false,
        Flag = genFlag(),
        Callback = function(state)
            isClaimingActive = state
            if state and currentMode == "IDLE" then
                currentMode = "CLAIM"
            end
        end
    })
end

do
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local workspace = game:GetService("Workspace")
    local player = Players.LocalPlayer

    local genFlag = genFlag or function()
        return "Flag_" .. tostring(math.random(100000, 999999))
    end
    local isTeleporting = false

    local rebirthTab = window:AddTab({
        Name = "Rebirth",
        Icon = "lucide:refresh-cw",
        Type = "Single",
    })

    local rebirthTabbox1 = rebirthTab:AddTabbox({ Name = "Rebirth 1", Position = "center" })

    local fastRebirthTab = rebirthTabbox1:AddTab("Fast Rebirth", "lucide:zap")
    fastRebirthTab:AddDivider({ Text = "Fast Rebirth" })
    fastRebirthTab:AddToggle({
        Name = "Auto Farm Rebirth",
        Default = false,
        Flag = genFlag(),
        Callback = function(state)
            getgenv().IsAutoFarming = state

            local a = ReplicatedStorage
            local b = Players
            local c = b.LocalPlayer

            local DURASI_SIZE_TOTAL = 300
            local SPEED_SIZE = 0.01
            local DURASI_WEIGHT_TOTAL = 20
            local SPEED_WEIGHT = 0.1
            local JEDA_RESPAWN = 3

            local respawnConn
            local currentProcessThread
            local sizeThread
            local autoFarmThread

            local function stopAllProcesses()
                if currentProcessThread then task.cancel(currentProcessThread); currentProcessThread = nil end
                if sizeThread then task.cancel(sizeThread); sizeThread = nil end
                if autoFarmThread then task.cancel(autoFarmThread); autoFarmThread = nil end
            end

            local function runAutoFarmLoop()
                if autoFarmThread then task.cancel(autoFarmThread) end
                autoFarmThread = task.spawn(function()
                    local d = function()
                        local f = c.petsFolder
                        for g, h in pairs(f:GetChildren()) do
                            if h:IsA("Folder") then
                                for i, j in pairs(h:GetChildren()) do
                                    a.rEvents.equipPetEvent:FireServer("unequipPet", j)
                                end
                            end
                        end
                        task.wait(.1)
                    end

                    local k = function(l)
                        d()
                        task.wait(.01)
                        for m, n in pairs(c.petsFolder.Unique:GetChildren()) do
                            if n.Name == l then
                                a.rEvents.equipPetEvent:FireServer("equipPet", n)
                            end
                        end
                    end

                    while getgenv().IsAutoFarming do
                        local v = c.leaderstats.Rebirths.Value
                        local w = 10000 + (5000 * v)
                        if c.ultimatesFolder:FindFirstChild("Golden Rebirth") then
                            local x = c.ultimatesFolder["Golden Rebirth"].Value
                            w = math.floor(w * (1 - (x * 0.1)))
                        end

                        d()
                        task.wait(.1)
                        k("Swift Samurai")
                        while c.leaderstats.Strength.Value < w and getgenv().IsAutoFarming do
                            for y = 1, 15 do
                                if c:FindFirstChild("muscleEvent") then c.muscleEvent:FireServer("rep") end
                            end
                            task.wait()
                        end

                        if not getgenv().IsAutoFarming then break end

                        d()
                        task.wait(.1)
                        k("Tribal Overlord")
                        local A = c.leaderstats.Rebirths.Value
                        repeat
                            a.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
                            task.wait(.1)
                            if not getgenv().IsAutoFarming then break end
                        until c.leaderstats.Rebirths.Value > A
                        task.wait()
                    end
                end)
            end

            local function startFullProcess(character)
                stopAllProcesses()
                if not getgenv().IsAutoFarming then return end

                sizeThread = task.spawn(function()
                    local startTime = tick()
                    while (tick() - startTime) < DURASI_SIZE_TOTAL and getgenv().IsAutoFarming do
                        pcall(function() a.rEvents.changeSpeedSizeRemote:InvokeServer("changeSize", 2) end)
                        task.wait(SPEED_SIZE)
                    end
                end)

                currentProcessThread = task.spawn(function()
                    task.wait(JEDA_RESPAWN)

                    local backpack = c:WaitForChild("Backpack")
                    local humanoid = character:WaitForChild("Humanoid")
                    local weightItem = backpack:FindFirstChild("Weight") or character:FindFirstChild("Weight")

                    if weightItem and getgenv().IsAutoFarming then
                        humanoid:EquipTool(weightItem)
                        local weightStartTime = tick()
                        while (tick() - weightStartTime) < DURASI_WEIGHT_TOTAL and getgenv().IsAutoFarming do
                            if not character or not character.Parent then break end
                            pcall(function() weightItem:Activate() end)
                            task.wait(SPEED_WEIGHT)
                        end
                    end

                    if not getgenv().IsAutoFarming then return end

                    local o = function(p)
                        local q = workspace.machinesFolder:FindFirstChild(p)
                        if not q then
                            for r, s in pairs(workspace:GetChildren()) do
                                if s:IsA("Folder") and s.Name:find("machines") then
                                    q = s:FindFirstChild(p)
                                    if q then break end
                                end
                            end
                        end
                        return q
                    end
                    local t = function()
                        local u = VirtualInputManager
                        u:SendKeyEvent(true, "E", false, game)
                        task.wait(.1)
                        u:SendKeyEvent(false, "E", false, game)
                    end

                    local z = o("Jungle Bar Lift")
                    if z and z:FindFirstChild("interactSeat") and character:FindFirstChild("HumanoidRootPart") then
                        for i = 1, 3 do
                            if not getgenv().IsAutoFarming then break end
                            character.HumanoidRootPart.CFrame = z.interactSeat.CFrame * CFrame.new(0, 3, 0)
                            task.wait(.01)
                            t()
                            task.wait(.1)
                        end
                    end

                    runAutoFarmLoop()
                end)
            end

            if state then
                if c.Character then
                    task.spawn(function()
                        stopAllProcesses()

                        sizeThread = task.spawn(function()
                            local startTime = tick()
                            while (tick() - startTime) < DURASI_SIZE_TOTAL and getgenv().IsAutoFarming do
                                pcall(function() a.rEvents.changeSpeedSizeRemote:InvokeServer("changeSize", 2) end)
                                task.wait(SPEED_SIZE)
                            end
                        end)

                        local o = function(p)
                            local q = workspace.machinesFolder:FindFirstChild(p)
                            if not q then
                                for r, s in pairs(workspace:GetChildren()) do
                                    if s:IsA("Folder") and s.Name:find("machines") then q = s:FindFirstChild(p) if q then break end end
                                end
                            end
                            return q
                        end
                        local t = function()
                            local u = VirtualInputManager
                            u:SendKeyEvent(true, "E", false, game)
                            task.wait(.1)
                            u:SendKeyEvent(false, "E", false, game)
                        end

                        local z = o("Jungle Bar Lift")
                        if z and z:FindFirstChild("interactSeat") and c.Character:FindFirstChild("HumanoidRootPart") then
                            for i = 1, 3 do
                                c.Character.HumanoidRootPart.CFrame = z.interactSeat.CFrame * CFrame.new(0, 3, 0)
                                task.wait(.01)
                                t()
                                task.wait(.1)
                            end
                        end
                        runAutoFarmLoop()
                    end)
                end

                respawnConn = c.CharacterAdded:Connect(function(newChar)
                    startFullProcess(newChar)
                end)
            else
                stopAllProcesses()
                if respawnConn then respawnConn:Disconnect(); respawnConn = nil end
            end
        end
    })

    local infinityTab = rebirthTabbox1:AddTab("Infinity", "lucide:infinity")
    infinityTab:AddDivider({ Text = "Rebirth Infinity" })
    local autoRebirthActive = false
    infinityTab:AddToggle({
        Name = "Auto Rebirth Infinity",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            autoRebirthActive = bool
            if autoRebirthActive then
                task.spawn(function()
                    while autoRebirthActive do
                        ReplicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
                        task.wait(0.1)
                    end
                end)
            end
        end
    })

    local targetRebirthTab = rebirthTabbox1:AddTab("Target", "lucide:target")
    targetRebirthTab:AddDivider({ Text = "Rebirth Target" })
    local rebirthTarget = 0
    local rebirthingToTarget = false
    targetRebirthTab:AddTextInput({
        Name = "Rebirth Target",
        Placeholder = "Enter target rebirths",
        Default = "0",
        Callback = function(text) rebirthTarget = tonumber(text) or 0 end
    })
    targetRebirthTab:AddToggle({
        Name = "Auto Rebirth",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            rebirthingToTarget = bool
            if bool then
                task.spawn(function()
                    while rebirthingToTarget do
                        local leaderstats = player:FindFirstChild("leaderstats")
                        local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
                        if rebirths and rebirthTarget > 0 and rebirths.Value >= rebirthTarget then
                            rebirthingToTarget = false
                            break
                        end
                        ReplicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
                        task.wait(0.1)
                    end
                end)
            end
        end
    })

    local sizeValue = 2
    _G.autoSizeActive = false
    targetRebirthTab:AddTextInput({
        Name = "Set Size",
        Placeholder = "Size default 2",
        Default = "2",
        Callback = function(text) sizeValue = tonumber(text) or 2 end
    })
    targetRebirthTab:AddToggle({
        Name = "Auto Size",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            _G.autoSizeActive = bool
            if bool then
                task.spawn(function()
                    while _G.autoSizeActive do
                        ReplicatedStorage.rEvents.changeSpeedSizeRemote:InvokeServer("changeSize", sizeValue)
                        task.wait(0.5)
                    end
                end)
            end
        end
    })

    local rebirthTabbox2 = rebirthTab:AddTabbox({ Name = "Rebirth 2", Position = "center" })
    local farmingRebirthTab = rebirthTabbox2:AddTab("Farming", "lucide:factory")
    farmingRebirthTab:AddDivider({ Text = "Farming" })
    farmingRebirthTab:AddToggle({
        Name = "Auto Weight",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            _G.FastWeight = bool
            if bool then
                task.spawn(function()
                    while _G.FastWeight do
                        local char = player.Character
                        if char then
                            local weight = char:FindFirstChild("Weight") or player.Backpack:FindFirstChild("Weight")
                            if weight then
                                if weight:FindFirstChild("repTime") then weight.repTime.Value = 0 end
                                if weight.Parent ~= char then char.Humanoid:EquipTool(weight) end
                            end
                        end
                        task.wait(0.5)
                    end
                end)
                task.spawn(function()
                    while _G.FastWeight do
                        local event = player:FindFirstChild("muscleEvent") or ReplicatedStorage:FindFirstChild("muscleEvent")
                        if event then event:FireServer("rep") end
                        task.wait(0.5)
                    end
                end)
            else
                local weight = (player.Character and player.Character:FindFirstChild("Weight")) or player.Backpack:FindFirstChild("Weight")
                if weight and weight:FindFirstChild("repTime") then weight.repTime.Value = 1 end
            end
        end
    })

    farmingRebirthTab:AddToggle({
        Name = "Teleport To King",
        Default = false,
        Flag = genFlag(),
        Callback = function(Value)
            isTeleporting = Value
            local targetCFrame = CFrame.new(-8747.59, 124.82, -5858.37)
            if Value then
                task.spawn(function()
                    while isTeleporting do
                        local char = player.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        if root then root.CFrame = targetCFrame end
                        task.wait(0.1)
                    end
                end)
            end
        end
    })

    local ultimateOptions = {
        "+1 Daily Spin", "+1 Pet Slot", "+10 Item Capacity", "+5% Rep Speed",
        "Demon Damage", "Galaxy Gains", "Golden Rebirth", "Jungle Swift",
        "Muscle Mind", "x2 Chest Rewards", "Infernal Health", "x2 Quest Rewards"
    }
    local autoBuyAll = false
    farmingRebirthTab:AddToggle({
        Name = "Upgrade All Ultimates",
        Default = false,
        Flag = genFlag(),
        Callback = function(state)
            autoBuyAll = state
            if state then
                task.spawn(function()
                    while autoBuyAll do
                        for _, ultimate in ipairs(ultimateOptions) do
                            if not autoBuyAll then break end
                            pcall(function()
                                ReplicatedStorage.rEvents.ultimatesRemote:InvokeServer("upgradeUltimate", ultimate)
                            end)
                        end
                        task.wait(1)
                    end
                end)
            end
        end
    })

    farmingRebirthTab:AddDivider({ Text = "Teleport To Save Zone" })
    local teleportLocations = {
        {"Save Zone V1", CFrame.new(-16000, 12135.4023, -16847.418, -0.999634326, -1.30947875e-09, 0.0270406175, -1.66118291e-12, 1, 4.83649494e-08, -0.0270406175, 4.83472213e-08, -0.999634326)},
        {"Save Zone V2", CFrame.new(-12000, 12135.4023, -16847.418, -0.999634326, -1.30947875e-09, 0.0270406175, -1.66118291e-12, 1, 4.83649494e-08, -0.0270406175, 4.83472213e-08, -0.999634326)},
        {"Save Zone V3", CFrame.new(-8000, 12135.4023, -16847.418, -0.999634326, -1.30947875e-09, 0.0270406175, -1.66118291e-12, 1, 4.83649494e-08, -0.0270406175, 4.83472213e-08, -0.999634326)},
        {"Save Zone V4", CFrame.new(-4000, 12135.4023, -16847.418, -0.999634326, -1.30947875e-09, 0.0270406175, -1.66118291e-12, 1, 4.83649494e-08, -0.0270406175, 4.83472213e-08, -0.999634326)},
        {"Save Zone V5", CFrame.new(0, 12135.4023, -16847.418, -0.999634326, -1.30947875e-09, 0.0270406175, -1.66118291e-12, 1, 4.83649494e-08, -0.0270406175, 4.83472213e-08, -0.999634326)},
        {"Save Zone V6", CFrame.new(4000, 12135.4023, -16847.418, -0.999634326, -1.30947875e-09, 0.0270406175, -1.66118291e-12, 1, 4.83649494e-08, -0.0270406175, 4.83472213e-08, -0.999634326)},
        {"Save Zone V7", CFrame.new(8000, 12135.4023, -16847.418, -0.999634326, -1.30947875e-09, 0.0270406175, -1.66118291e-12, 1, 4.83649494e-08, -0.0270406175, 4.83472213e-08, -0.999634326)}
    }
    local activeLoops = {}
    for _, location in ipairs(teleportLocations) do
        local locName = location[1]
        local locCFrame = location[2]
        farmingRebirthTab:AddToggle({
            Name = locName,
            Default = false,
            Flag = genFlag(),
            Callback = function(Value)
                activeLoops[locName] = Value
                if Value then
                    task.spawn(function()
                        while activeLoops[locName] do
                            local char = player.Character
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            if root then root.CFrame = locCFrame end
                            task.wait(0.001)
                        end
                    end)
                end
            end
        })
    end

    local upgradeUltiTab = rebirthTabbox2:AddTab("Ultimate", "lucide:factory")

    upgradeUltiTab:AddDivider({ Text = "Upgrade Ultimate V2" })
    local autoUltimateToggles = {}
    for _, ultimate in ipairs(ultimateOptions) do
        autoUltimateToggles[ultimate] = false
        upgradeUltiTab:AddToggle({
            Name = "Upgrade " .. ultimate,
            Default = false,
            Flag = genFlag(),
            Callback = function(state)
                autoUltimateToggles[ultimate] = state
                if state then
                    task.spawn(function()
                        while autoUltimateToggles[ultimate] do
                            pcall(function()
                                ReplicatedStorage.rEvents.ultimatesRemote:InvokeServer("upgradeUltimate", ultimate)
                            end)
                            task.wait(1)
                        end
                    end)
                end
            end
        })
    end
end

do
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    local genFlag = genFlag or function()
        return "Flag_" .. tostring(math.random(100000, 999999))
    end

    local teleportTab = window:AddTab({
        Name = "Teleport",
        Icon = "lucide:map-pin",
        Type = "Single",
    })

    local teleportTabbox = teleportTab:AddTabbox({ Name = "Teleport", Position = "center" })

    local customTeleportTab = teleportTabbox:AddTab("Custom", "lucide:map")
    customTeleportTab:AddDivider({ Text = "Teleport Custom" })
    local CustomPosInput = "0, 0, 0"
    local LockCustomPos = false

    customTeleportTab:AddTextInput({
        Name = "Target Position",
        Placeholder = "Enter position (x, y, z)",
        Default = "0, 0, 0",
        Callback = function(text) CustomPosInput = text end
    })

    customTeleportTab:AddButton({
        Name = "Get Your Position",
        Callback = function()
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local pos = root.Position
                local formattedPos = string.format("%.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z)
                setclipboard(formattedPos)
                window:Notify({ Title = "Position Copied", Content = "Position copied to clipboard", Duration = 1 })
            end
        end
    })

    customTeleportTab:AddButton({
        Name = "Teleport to Position",
        Callback = function()
            local coords = {}
            for val in string.gmatch(CustomPosInput, "[^,]+") do
                table.insert(coords, tonumber(val))
            end
            if #coords >= 3 then
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    root.CFrame = CFrame.new(coords[1], coords[2], coords[3])
                end
            else
                window:Notify({ Title = "Error", Content = "Invalid coordinates format. Use x, y, z" })
            end
        end
    })

    customTeleportTab:AddToggle({
        Name = "Lock Position (Continuous)",
        Default = false,
        Flag = genFlag(),
        Callback = function(state)
            LockCustomPos = state
            if state then
                task.spawn(function()
                    while LockCustomPos do
                        local coords = {}
                        for val in string.gmatch(CustomPosInput, "[^,]+") do
                            table.insert(coords, tonumber(val))
                        end
                        if #coords >= 3 then
                            local char = player.Character
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            if root then
                                root.CFrame = CFrame.new(coords[1], coords[2], coords[3])
                            end
                        end
                        task.wait(0.005)
                    end
                end)
            end
        end
    })

    local portalTeleportTab = teleportTabbox:AddTab("Portal", "lucide:portal")
    portalTeleportTab:AddDivider({ Text = "Teleport Mode" })
    local CurrentVersion = "Portal Teleport"
    local TeleportData = {
        ["Portal Teleport"] = {
            {"Spawn", CFrame.new(2, 8, 115)},
            {"Secret Area", CFrame.new(1947, 2, 6191)},
            {"Tiny Island", CFrame.new(-34, 7, 1903)},
            {"Frozen", CFrame.new(-2600, 3, -403)},
            {"Mythical", CFrame.new(2255, 7, 1071)},
            {"Inferno", CFrame.new(-6768, 7, -1287)},
            {"Legend", CFrame.new(4604, 991, -3887)},
            {"Muscle King", CFrame.new(-8646, 17, -5738)},
            {"Jungle", CFrame.new(-8659, 6, 2384)},
            {"Industrial Gym", CFrame.new(-5538.42, 61.06, 4943.22)}
        },
        ["Industrial"] = {
            {"Industrial V1", CFrame.new(-5538.42, 61.06, 4943.22)},
            {"Industrial V2", CFrame.new(-5400.00, 61.06, 4800.00)},
            {"Industrial V3", CFrame.new(-5200.00, 61.06, 4600.00)},
            {"Industrial V4", CFrame.new(-5000.00, 61.06, 4400.00)},
            {"Industrial V5", CFrame.new(-4800.00, 61.06, 4200.00)},
            {"Industrial V6", CFrame.new(-4600.00, 61.06, 4000.00)},
            {"Industrial V7", CFrame.new(-4400.00, 61.06, 3800.00)},
            {"Industrial V8", CFrame.new(-4200.00, 61.06, 3600.00)},
            {"Industrial V9", CFrame.new(-4000.00, 61.06, 3400.00)},
            {"Industrial V10", CFrame.new(-3800.00, 61.06, 3200.00)}
        },
        ["Area Spawn"] = {
            {"Area Spawn V1", CFrame.new(-288.63, 34.37, -1242.75)},
            {"Area Spawn V2", CFrame.new(198.11, 43.87, -1281.25)},
            {"Area Spawn V3", CFrame.new(753.85, 37.22, -953.21)},
            {"Area Spawn V4", CFrame.new(867.29, 36.51, -153.79)},
            {"Area Spawn V5", CFrame.new(911.35, 41.67, 328.53)},
            {"Area Spawn V6", CFrame.new(176.71, 34.37, 678.06)},
            {"Area Spawn V7", CFrame.new(-278.76, 41.67, 803.21)},
            {"Area Spawn V8", CFrame.new(-820.03, 34.37, 323.52)},
            {"Area Spawn V9", CFrame.new(-864.29, 41.67, -148.20)},
            {"Area Spawn V10", CFrame.new(-500.00, 35.00, -500.00)}
        },
        ["Area Frost"] = {
            {"Frost V1", CFrame.new(-3632.78, 41.67, -611.01)},
            {"Frost V2", CFrame.new(-3018.51, 34.37, -1133.93)},
            {"Frost V3", CFrame.new(-2540.17, 41.67, -1139.82)},
            {"Frost V4", CFrame.new(-2076.97, 34.37, -572.28)},
            {"Frost V5", CFrame.new(-2030.41, 41.67, -99.55)},
            {"Frost V6", CFrame.new(-2549.26, 34.37, 314.38)},
            {"Frost V7", CFrame.new(-3024.51, 41.67, 322.30)},
            {"Frost V8", CFrame.new(-3666.25, 34.37, -136.61)},
            {"Frost V9", CFrame.new(-2846.15, 89.44, -406.46)},
            {"Frost V10", CFrame.new(-2500.00, 40.00, -200.00)}
        },
        ["Area Mythical"] = {
            {"Mythical V1", CFrame.new(1611.91, 41.67, 831.43)},
            {"Mythical V2", CFrame.new(2231.55, 34.37, 307.55)},
            {"Mythical V3", CFrame.new(2702.26, 41.67, 299.23)},
            {"Mythical V4", CFrame.new(3168.63, 34.37, 869.02)},
            {"Mythical V5", CFrame.new(3216.70, 41.67, 1340.99)},
            {"Mythical V6", CFrame.new(2697.76, 34.37, 1756.94)},
            {"Mythical V7", CFrame.new(2219.95, 41.67, 1765.28)},
            {"Mythical V8", CFrame.new(1580.94, 34.37, 1304.18)},
            {"Mythical V9", CFrame.new(1613.45, 41.67, 834.61)},
            {"Mythical V10", CFrame.new(2000.00, 40.00, 1000.00)}
        },
        ["Area Inferno"] = {
            {"Inferno V1", CFrame.new(-6171.77, 41.67, -980.01)},
            {"Inferno V2", CFrame.new(-6694.84, 34.37, -564.37)},
            {"Inferno V3", CFrame.new(-7168.48, 41.67, -555.94)},
            {"Inferno V4", CFrame.new(-7808.35, 34.37, -998.05)},
            {"Inferno V5", CFrame.new(-7775.84, 41.67, -1485.05)},
            {"Inferno V6", CFrame.new(-7158.84, 34.37, -2013.57)},
            {"Inferno V7", CFrame.new(-6685.91, 41.67, -2022.32)},
            {"Inferno V8", CFrame.new(-6223.72, 34.37, -1448.29)},
            {"Inferno V9", CFrame.new(-6986.32, 89.65, -1287.44)},
            {"Inferno V10", CFrame.new(-6500.00, 40.00, -1000.00)}
        },
        ["Area Jungle"] = {
            {"jungle V1", CFrame.new(-7429.39, 137.64, 3539.27)},
            {"jungle V2", CFrame.new(-7111.83, 137.06, 3076.58)},
            {"jungle V3", CFrame.new(-7055.04, 102.05, 2162.77)},
            {"jungle V4", CFrame.new(-7733.45, 55.73, 1369.46)},
            {"jungle V5", CFrame.new(-8480.99, 134.16, 1414.67)},
            {"jungle V6", CFrame.new(-9138.68, 149.24, 1827.94)},
            {"jungle V7", CFrame.new(-9430.28, 53.89, 2438.14)},
            {"jungle V8", CFrame.new(-8183.44, 76.41, 1383.64)},
            {"jungle V9", CFrame.new(-8116.44, 223.95, 2397.24)},
            {"jungle V10", CFrame.new(-8000.00, 100.00, 2000.00)}
        },
        ["Void Brawl"] = {
            {"Void Brawl V1", CFrame.new(3674.49, 36.89, -8295.16)},
            {"Void Brawl V2", CFrame.new(3493.97, 43.50, -9086.34)},
            {"Void Brawl V3", CFrame.new(3738.08, 44.34, -9585.31)},
            {"Void Brawl V4", CFrame.new(4338.64, 34.36, -9808.24)},
            {"Void Brawl V5", CFrame.new(4930.11, 41.82, -9722.39)},
            {"Void Brawl V6", CFrame.new(5391.56, 34.33, -9308.55)},
            {"Void Brawl V7", CFrame.new(5442.33, 41.82, -8625.02)},
            {"Void Brawl V8", CFrame.new(5197.84, 41.72, -8176.37)},
            {"Void Brawl V9", CFrame.new(4725.28, 37.66, -7899.02)},
            {"Void Brawl V10", CFrame.new(4500.00, 40.00, -8500.00)}
        },
        ["Desert Brawl"] = {
            {"Desert Brawl V1", CFrame.new(1931.75, 40.69, -7161.35)},
            {"Desert Brawl V2", CFrame.new(1684.34, 36.89, -6721.88)},
            {"Desert Brawl V3", CFrame.new(1219.53, 33.80, -6438.87)},
            {"Desert Brawl V4", CFrame.new(720.85, 41.19, -6453.78)},
            {"Desert Brawl V5", CFrame.new(164.57, 36.33, -6832.94)},
            {"Desert Brawl V6", CFrame.new(-20.00, 42.37, -7631.01)},
            {"Desert Brawl V7", CFrame.new(232.82, 43.22, -8137.93)},
            {"Desert Brawl V8", CFrame.new(819.16, 35.41, -8351.83)},
            {"Desert Brawl V9", CFrame.new(1420.26, 39.57, -8256.59)},
            {"Desert Brawl V10", CFrame.new(1000.00, 40.00, -7500.00)}
        },
        ["Ori Brawl"] = {
            {"Ori Brawl V1", CFrame.new(-1139.72, 40.46, -5530.67)},
            {"Ori Brawl V2", CFrame.new(-1606.91, 31.70, -5256.56)},
            {"Ori Brawl V3", CFrame.new(-2098.54, 45.80, -5250.18)},
            {"Ori Brawl V4", CFrame.new(-2655.81, 32.86, -5641.19)},
            {"Ori Brawl V5", CFrame.new(-2826.76, 40.16, -6442.06)},
            {"Ori Brawl V6", CFrame.new(-2599.99, 40.03, -6931.56)},
            {"Ori Brawl V7", CFrame.new(-1389.05, 38.73, -7072.45)},
            {"Ori Brawl V8", CFrame.new(-940.97, 36.17, -6660.76)},
            {"Ori Brawl V9", CFrame.new(-1403.06, 39.54, -7063.23)},
            {"Ori Brawl V10", CFrame.new(-2000.00, 40.00, -6000.00)}
        }
    }

    local selectedTeleportName = TeleportData[CurrentVersion][1][1]
    local locationDropdown

    local function refreshLocationDropdown()
        local locations = TeleportData[CurrentVersion]
        if not locations then return end
        local names = {}
        for _, v in ipairs(locations) do
            table.insert(names, v[1])
        end
        if locationDropdown then
            locationDropdown:SetValues(names)
            locationDropdown:SetValue(names[1])
        end
    end

    portalTeleportTab:AddDropdown({
        Name = "Change Teleport Version",
        Values = {"Portal Teleport", "Area Spawn", "Area Frost", "Area Mythical", "Area Inferno", "Area Jungle", "Industrial Gym", "Void Brawl", "Desert Brawl", "Ori Brawl"},
        Default = "Portal Teleport",
        Flag = genFlag(),
        Callback = function(v)
            CurrentVersion = v
            refreshLocationDropdown()
        end
    })

    locationDropdown = portalTeleportTab:AddDropdown({
        Name = "Select Location",
        Values = {},
        Default = "",
        Flag = genFlag(),
        Callback = function(v) selectedTeleportName = v end
    })

    portalTeleportTab:AddButton({
        Name = "Teleport",
        Callback = function()
            local locations = TeleportData[CurrentVersion]
            if locations then
                for _, data in ipairs(locations) do
                    if data[1] == selectedTeleportName then
                        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if root then
                            root.CFrame = data[2]
                            window:Notify({ Title = "Teleported", Content = selectedTeleportName, Duration = 1 })
                        end
                        break
                    end
                end
            end
        end
    })

    refreshLocationDropdown()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

local miscTab = window:AddTab({
    Name = "Misc",
    Icon = "lucide:settings",
    Type = "Single",
})

local miscTabbox = miscTab:AddTabbox({ Name = "Misc", Position = "center" })

local playersMiscTab = miscTabbox:AddTab("Players", "lucide:users")
playersMiscTab:AddDivider({ Text = "Players" })

do
    local lockCustomPos = false
    playersMiscTab:AddToggle({
        Name = "Lock Position",
        Default = false,
        Flag = genFlag(),
        Callback = function(state)
            lockCustomPos = state
            if not state then return end
            
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            
            local lockedCFrame = root.CFrame
            task.spawn(function()
                while lockCustomPos do
                    if root and root.Parent then 
                        root.CFrame = lockedCFrame 
                    else 
                        root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") 
                    end
                    task.wait()
                end
            end)
        end
    })
end

do
    local hbUtama = nil
    local hbCadangan = nil
    local antiKbEnabled = false

    local function ApplyAntiKb(state)
        if hbUtama then hbUtama:Disconnect() hbUtama = nil end
        if hbCadangan then hbCadangan:Disconnect() hbCadangan = nil end
        
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        local hum = char:WaitForChild("Humanoid", 5)
        
        if not hrp or not hum then return end
        
        if hrp:FindFirstChild("AntiKbBV_1") then hrp.AntiKbBV_1:Destroy() end
        if hrp:FindFirstChild("AntiKbBG_1") then hrp.AntiKbBG_1:Destroy() end
        if hrp:FindFirstChild("AntiKbBV_2") then hrp.AntiKbBV_2:Destroy() end
        if hrp:FindFirstChild("AntiKbBG_2") then hrp.AntiKbBG_2:Destroy() end
        
        if state then
            local bv1 = Instance.new("BodyVelocity")
            local bg1 = Instance.new("BodyGyro")
            bv1.Name, bg1.Name = "AntiKbBV_1", "AntiKbBG_1"
            bv1.Parent, bg1.Parent = hrp, hrp
            
            bg1.P, bg1.D, bg1.MaxTorque = 30000, 400, Vector3.new(1e7, 1e7, 1e7)
            
            local bv2 = Instance.new("BodyVelocity")
            local bg2 = Instance.new("BodyGyro")
            bv2.Name, bg2.Name = "AntiKbBV_2", "AntiKbBG_2"
            bv2.Parent, bg2.Parent = hrp, hrp
            
            bg2.P, bg2.D, bg2.MaxTorque = 30000, 400, Vector3.new(1e7, 1e7, 1e7)
            
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            
            hbUtama = RunService.Heartbeat:Connect(function()
                if not hrp.Parent or not hum.Parent then hbUtama:Disconnect() return end
                local moveDir = hum.MoveDirection
                if moveDir.Magnitude > 0 then
                    bv1.MaxForce = Vector3.new(0, 0, 0)
                    bg1.CFrame = bg1.CFrame:Lerp(CFrame.lookAt(hrp.Position, hrp.Position + moveDir), 0.25)
                else
                    bv1.MaxForce = Vector3.new(1e7, 0, 1e7)
                    bv1.Velocity = Vector3.new(0, 0, 0)
                    bg1.CFrame = bg1.CFrame:Lerp(CFrame.lookAt(hrp.Position, hrp.Position + hrp.CFrame.LookVector), 0.25)
                end
            end)
            
            hbCadangan = RunService.Heartbeat:Connect(function()
                if not hrp.Parent or not hum.Parent then hbCadangan:Disconnect() return end
                local moveDir = hum.MoveDirection
                if moveDir.Magnitude > 0 then
                    bv2.MaxForce = Vector3.new(0, 0, 0)
                    bg2.CFrame = bg2.CFrame:Lerp(CFrame.lookAt(hrp.Position, hrp.Position + moveDir), 0.25)
                else
                    bv2.MaxForce = Vector3.new(1e7, 0, 1e7)
                    bv2.Velocity = Vector3.new(0, 0, 0)
                    bg2.CFrame = bg2.CFrame:Lerp(CFrame.lookAt(hrp.Position, hrp.Position + hrp.CFrame.LookVector), 0.25)
                end
            end)
        else
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end
    end

    local antiKbToggle = playersMiscTab:AddToggle({
        Name = "Anti Knockback",
        Default = true,
        Flag = genFlag(),
        Callback = function(state)
            antiKbEnabled = state
            ApplyAntiKb(state)
        end
    })

    player.CharacterAdded:Connect(function() 
        if antiKbEnabled then 
            task.wait(0.5) 
            ApplyAntiKb(true) 
        end 
    end)

    task.spawn(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        local hum = char:WaitForChild("Humanoid", 5)
        
        if hrp and hum then
            antiKbEnabled = true
            ApplyAntiKb(true)
            pcall(function() antiKbToggle:Set(true) end)
        end
    end)

    Players.PlayerAdded:Connect(function(newPlayer)
        task.wait(0.1) 
        
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        
        if hrp and hum and hrp:FindFirstChild("AntiKbBV_1") then
            if hbCadangan then hbCadangan:Disconnect() hbCadangan = nil end
            if hrp:FindFirstChild("AntiKbBV_2") then hrp.AntiKbBV_2:Destroy() end
            if hrp:FindFirstChild("AntiKbBG_2") then hrp.AntiKbBG_2:Destroy() end
            
            task.wait(1) 
            
            if not hrp.Parent or not hrp:FindFirstChild("AntiKbBV_1") then return end
            
            local bv2 = Instance.new("BodyVelocity")
            local bg2 = Instance.new("BodyGyro")
            bv2.Name, bg2.Name = "AntiKbBV_2", "AntiKbBG_2"
            bv2.Parent, bg2.Parent = hrp, hrp
            bg2.P, bg2.D, bg2.MaxTorque = 30000, 400, Vector3.new(1e7, 1e7, 1e7)
            
            hbCadangan = RunService.Heartbeat:Connect(function()
                if not hrp.Parent or not hum.Parent then hbCadangan:Disconnect() return end
                local moveDir = hum.MoveDirection
                if moveDir.Magnitude > 0 then
                    bv2.MaxForce = Vector3.new(0, 0, 0)
                    bg2.CFrame = bg2.CFrame:Lerp(CFrame.lookAt(hrp.Position, hrp.Position + moveDir), 0.25)
                else
                    bv2.MaxForce = Vector3.new(1e7, 0, 1e7)
                    bv2.Velocity = Vector3.new(0, 0, 0)
                    bg2.CFrame = bg2.CFrame:Lerp(CFrame.lookAt(hrp.Position, hrp.Position + hrp.CFrame.LookVector), 0.25)
                end
            end)
        end
    end)
end

do
    local flymode = playersMiscTab:AddToggle({
        Name = "Fly Mode",
        Default = false,
        Flag = genFlag(),
        Callback = function(Value)
            if Value then
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                
                if hrp and hrp:FindFirstChild("AntiKbBV_1") then
                    window:Notify({ 
                        Title = "WARNING!!!", 
                        Content = "Turn off Anti Knockback First " 
                    })
                    return
                end
            end
            
            _G.FlyEnabled = Value
            local char = player.Character or player.CharacterAdded:Wait()
            local hum = char:WaitForChild("Humanoid")
            local hrp = char:WaitForChild("HumanoidRootPart")
            local desc = hum:WaitForChild("HumanoidDescription")
            
            _G.FlySpeed = 70
            local normalSpeed, boostSpeed = 70, 300
            local isDraining, canBoost = false, true
            local emoteIdleName, emoteIdleId = "GodlikeIdle", 81359407734079
            local emoteMoveName, emoteMoveId = "FlyingMove", 106493972274585
            
            local function createBlackHole(part)
                local DIRECTION = Enum.NormalId.Bottom
                local BOOST_SPEED = NumberRange.new(20, 40)
                local BOOST_ACCEL = Vector3.new(0, -25, 0)
                local SPREAD = Vector2.new(15, 15)
                local INHERIT, DRAG = 0.9, 1.2     

                local blackHoleCore = Instance.new("ParticleEmitter")
                blackHoleCore.Name = "BlackHoleCore"
                blackHoleCore.Parent = part
                blackHoleCore.Texture = "rbxasset://textures/particles/smoke_main.dds"
                blackHoleCore.LockedToPart = false
                blackHoleCore.VelocityInheritance = INHERIT
                blackHoleCore.Drag = DRAG
                blackHoleCore.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(70, 0, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 0, 0))
                })
                blackHoleCore.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.3, 1.5),
                    NumberSequenceKeypoint.new(1, 2.5)
                })
                blackHoleCore.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.2, 0.1),
                    NumberSequenceKeypoint.new(0.8, 0.4),
                    NumberSequenceKeypoint.new(1, 1)
                })
                blackHoleCore.Lifetime = NumberRange.new(0.4, 0.7)
                blackHoleCore.Rate = 450
                blackHoleCore.Speed = BOOST_SPEED
                blackHoleCore.SpreadAngle = SPREAD
                blackHoleCore.ZOffset = -1
                blackHoleCore.EmissionDirection = DIRECTION
                blackHoleCore.Acceleration = BOOST_ACCEL

                local redFlame = Instance.new("ParticleEmitter")
                redFlame.Name = "RedFlame"
                redFlame.Parent = part
                redFlame.Texture = "rbxasset://textures/particles/fire_main.dds"
                redFlame.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 0, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 0))
                })
                redFlame.Size = NumberSequence.new(1.5, 0.3)
                redFlame.Lifetime = NumberRange.new(0.3, 0.5)
                redFlame.Rate = 300
                redFlame.LightEmission = 1
                redFlame.ZOffset = 2
                redFlame.EmissionDirection = DIRECTION
                redFlame.Speed = BOOST_SPEED
                redFlame.Acceleration = BOOST_ACCEL

                local darkSmoke = Instance.new("ParticleEmitter")
                darkSmoke.Name = "DarkSmoke"
                darkSmoke.Parent = part
                darkSmoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
                darkSmoke.Color = ColorSequence.new(Color3.fromRGB(100, 0, 0), Color3.fromRGB(0, 0, 0))
                darkSmoke.Size = NumberSequence.new(1.2, 2.5)
                darkSmoke.Transparency = NumberSequence.new(0.4, 1)
                darkSmoke.Lifetime = NumberRange.new(0.5, 0.9)
                darkSmoke.Rate = 450
                darkSmoke.EmissionDirection = DIRECTION
                darkSmoke.Speed = BOOST_SPEED
                darkSmoke.Acceleration = BOOST_ACCEL

                local energySparks = Instance.new("ParticleEmitter")
                energySparks.Name = "EnergySparks"
                energySparks.Parent = part
                energySparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
                energySparks.Color = ColorSequence.new(Color3.fromRGB(255, 100, 100), Color3.fromRGB(255, 0, 0))
                energySparks.Size = NumberSequence.new(0.4, 0)
                energySparks.Lifetime = NumberRange.new(0.4, 0.7)
                energySparks.Rate = 150
                energySparks.LightEmission = 1
                energySparks.ZOffset = 3
                energySparks.EmissionDirection = DIRECTION
                energySparks.Speed = BOOST_SPEED
                energySparks.Acceleration = BOOST_ACCEL

                local redLight = Instance.new("PointLight")
                redLight.Name = "BlackHoleGlow"
                redLight.Parent = part
                redLight.Color = Color3.fromRGB(255, 0, 0)
                redLight.Brightness = 8
                redLight.Range = 10
                redLight.Shadows = false
            end

            local function clearEffects()
                local targetNames = {"BlackHoleCore", "RedFlame", "DarkSmoke", "EnergySparks", "BlackHoleGlow"}
                for _, v in pairs(char:GetDescendants()) do
                    for _, name in pairs(targetNames) do
                        if v.Name == name then v:Destroy() end
                    end
                end
            end

            if playerGui:FindFirstChild("SwordBoosterUI_Final_v2") then 
                playerGui.SwordBoosterUI_Final_v2:Destroy() 
            end
            clearEffects()

            if _G.FlyEnabled then
                local feet = {"LeftFoot", "RightFoot", "Left Leg", "Right Leg"}
                for _, footName in pairs(feet) do
                    local f = char:FindFirstChild(footName)
                    if f then createBlackHole(f); createBlackHole(f) end
                end

                local screenGui = Instance.new("ScreenGui")
                screenGui.Name = "SwordBoosterUI_Final_v2"
                screenGui.Parent = playerGui
                screenGui.ResetOnSpawn = false
                screenGui.IgnoreGuiInset = true 

                local container = Instance.new("Frame")
                container.Size = UDim2.new(0.2, 0, 0.08, 0)
                container.Position = UDim2.new(0.5, 0, 0.8, 0)
                container.AnchorPoint = Vector2.new(0.5, 0.5)
                container.BackgroundTransparency = 1
                container.Parent = screenGui

                local energyBg = Instance.new("Frame")
                energyBg.Size = UDim2.new(1.2, 0, 0.35, 0)
                energyBg.Position = UDim2.new(0.5, 0, 0.5, 0)
                energyBg.AnchorPoint = Vector2.new(0.5, 0.5)
                energyBg.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
                energyBg.BorderSizePixel = 0
                energyBg.Visible = false
                energyBg.Parent = container

                local function createSharpTip(side)
                    local tip = Instance.new("Frame")
                    tip.SizeConstraint = Enum.SizeConstraint.RelativeYY
                    tip.Size = UDim2.new(1, 0, 1, 0)
                    tip.Rotation = 45
                    tip.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
                    tip.BorderSizePixel = 0
                    tip.Position = (side == "Left") and UDim2.new(0, 0, 0.5, 0) or UDim2.new(1, 0, 0.5, 0)
                    tip.AnchorPoint = Vector2.new(0.5, 0.5)
                    tip.Parent = energyBg
                    Instance.new("UIStroke", tip).Thickness = 1
                    tip.UIStroke.Color = Color3.fromRGB(255, 0, 0)
                end
                createSharpTip("Left"); createSharpTip("Right")

                Instance.new("UIStroke", energyBg).Thickness = 1
                energyBg.UIStroke.Color = Color3.fromRGB(255, 0, 0)

                local energyFill = Instance.new("Frame")
                energyFill.Size = UDim2.new(1, 0, 1, 0)
                energyFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                energyFill.ZIndex = 2
                energyFill.Parent = energyBg

                local fireGradient = Instance.new("UIGradient")
                fireGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 0, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                })
                fireGradient.Parent = energyFill

                local boostBtn = Instance.new("TextButton")
                boostBtn.Size = UDim2.new(0.50, 0, 0.50, 0)
                boostBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
                boostBtn.AnchorPoint = Vector2.new(0.5, 0.5)
                boostBtn.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
                boostBtn.Text = "BOOSTER"
                boostBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
                boostBtn.TextScaled = true
                boostBtn.Font = Enum.Font.GothamBold
                boostBtn.Parent = container
                Instance.new("UICorner", boostBtn).CornerRadius = UDim.new(0.15, 0)

                local bs = Instance.new("UIStroke", boostBtn)
                bs.Thickness = 1.3
                bs.Color = Color3.fromRGB(255, 0, 0)
                bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

                local function createErodeParticle()
                    local p = Instance.new("Frame")
                    local progress = energyFill.Size.X.Scale
                    p.Size = UDim2.new(0.18, 0, 0.18, 0)
                    p.SizeConstraint = Enum.SizeConstraint.RelativeYY
                    p.Rotation = math.random(0, 360)
                    p.BackgroundColor3 = Color3.fromRGB(255, math.random(0, 70), 0)
                    p.Position = UDim2.new(progress, 0, 0.5, 0)
                    p.AnchorPoint = Vector2.new(0.5, 0.5)
                    p.Parent = energyBg
                    
                    TweenService:Create(p, TweenInfo.new(0.6), {
                        Position = UDim2.new(progress + (math.random(-30, 10)/100), 0, math.random(-5, 6), 0),
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 0, 0, 0)
                    }):Play()
                    task.delay(0.6, function() p:Destroy() end)
                end

                boostBtn.MouseButton1Click:Connect(function()
                    if not canBoost then return end
                    canBoost, boostBtn.Visible, energyBg.Visible, isDraining, _G.FlySpeed = false, false, true, true, boostSpeed
                    local drain = TweenService:Create(energyFill, TweenInfo.new(10, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)})
                    drain:Play()
                    drain.Completed:Connect(function()
                        isDraining, _G.FlySpeed = false, normalSpeed
                        task.wait(0.5)
                        local fill = TweenService:Create(energyFill, TweenInfo.new(3), {Size = UDim2.new(1, 0, 1, 0)})
                        fill:Play()
                        fill.Completed:Connect(function() 
                            energyBg.Visible, boostBtn.Visible, canBoost = false, true, true 
                        end)
                    end)
                end)

                pcall(function() desc:SetEmotes({[emoteIdleName] = {emoteIdleId}, [emoteMoveName] = {emoteMoveId}}) end)
                
                local currentMode = ""
                local function playEmote(name)
                    if currentMode == name then return end
                    currentMode = name
                    local animator = hum:FindFirstChildOfClass("Animator")
                    if not animator then return end
                    for _, track in pairs(animator:GetPlayingAnimationTracks()) do track:Stop(0.5) end
                    pcall(function() 
                        hum:PlayEmote(name)
                        task.delay(0.05, function() 
                            for _, track in pairs(animator:GetPlayingAnimationTracks()) do 
                                if track.IsPlaying then 
                                    track.Priority = Enum.AnimationPriority.Action4
                                    track.Looped = true
                                    track:AdjustSpeed(1) 
                                end 
                            end 
                        end) 
                    end)
                end

                hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
                hum:ChangeState(Enum.HumanoidStateType.Physics)
                
                local bv = hrp:FindFirstChild("FlyBV") or Instance.new("BodyVelocity")
                bv.Name, bv.MaxForce, bv.Parent = "FlyBV", Vector3.new(math.huge, math.huge, math.huge), hrp
                
                local bg = hrp:FindFirstChild("FlyBG") or Instance.new("BodyGyro")
                bg.Name, bg.MaxTorque, bg.P, bg.Parent = "FlyBG", Vector3.new(math.huge, math.huge, math.huge), 5000, hrp

                task.spawn(function()
                    while _G.FlyEnabled and char.Parent do
                        if isDraining then for i = 1, 2 do createErodeParticle() end end 
                        local moveDir = hum.MoveDirection
                        if moveDir.Magnitude > 0 then
                            playEmote(emoteMoveName)
                            local look = camera.CFrame.LookVector
                            local vel = moveDir * _G.FlySpeed
                            if moveDir:Dot(Vector3.new(look.X, 0, look.Z).Unit) > 0.8 then vel = look * _G.FlySpeed end
                            bv.Velocity = vel
                            bg.CFrame = bg.CFrame:Lerp(CFrame.lookAt(hrp.Position, hrp.Position + vel), 0.15)
                        else
                            playEmote(emoteIdleName)
                            bv.Velocity = Vector3.zero
                            bg.CFrame = bg.CFrame:Lerp(CFrame.new(hrp.Position, hrp.Position + hrp.CFrame.LookVector), 0.15)
                        end
                        RunService.RenderStepped:Wait()
                    end
                    if bv then bv:Destroy() end
                    if bg then bg:Destroy() end
                    clearEffects()
                    hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end)
            else 
                _G.FlyEnabled = false
                clearEffects() 
            end
        end
    })
end

do
    local hidden = {}
    local hiding = false
    local hiderScreenGui = nil
    local hideBtn = nil

    local function hideUI()
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        end)

        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled and gui.Name ~= "CinematicFreecamUI" and gui.Name ~= "UIHiderButtonGui" then
                gui.Enabled = false
                table.insert(hidden, gui)
            end
        end
    end

    local function showUI()
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
        end)

        for _, gui in ipairs(hidden) do
            pcall(function() gui.Enabled = true end)
        end
        hidden = {}
    end

    playerGui.ChildAdded:Connect(function(gui)
        if hiding and gui:IsA("ScreenGui") and gui.Name ~= "CinematicFreecamUI" and gui.Name ~= "UIHiderButtonGui" then
            task.defer(function()
                if gui.Enabled then
                    gui.Enabled = false
                    table.insert(hidden, gui)
                end
            end)
        end
    end)

    local function createHiderUI()
        if hiderScreenGui then hiderScreenGui:Destroy() end
        
        hiderScreenGui = Instance.new("ScreenGui", playerGui)
        hiderScreenGui.Name = "UIHiderButtonGui"
        hiderScreenGui.ResetOnSpawn = false

        hideBtn = Instance.new("TextButton", hiderScreenGui)
        hideBtn.Name = "ToggleHideUIButton"
        hideBtn.Size = UDim2.new(0, 120, 0, 32)
        hideBtn.Position = UDim2.new(0, 15, 1, -47)
        hideBtn.Font, hideBtn.TextSize = Enum.Font.GothamBold, 12
        hideBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        hideBtn.BackgroundTransparency = 0.95
        
        if hiding then
            hideBtn.Text = "Ui On"
            hideBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        else
            hideBtn.Text = "Ui Off"
            hideBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        end

        Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 8)

        hideBtn.MouseButton1Click:Connect(function()
            hiding = not hiding
            if hiding then
                hideBtn.Text = "Ui On"
                hideBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                hideUI()
            else
                hideBtn.Text = "Ui Off"
                hideBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                showUI()
            end
        end)
    end

    local function removeHiderUI()
        if hiding then
            hiding = false
            showUI()
        end
        if hiderScreenGui then
            hiderScreenGui:Destroy()
            hiderScreenGui = nil
            hideBtn = nil
        end
    end

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.H and hiderScreenGui then
            hiding = not hiding
            if hiding then 
                hideBtn.Text = "Ui On"
                hideBtn.TextColor3 = Color3.fromRGB(0, 0, 0) 
                hideUI() 
            else 
                hideBtn.Text = "Ui Off"
                hideBtn.TextColor3 = Color3.fromRGB(0, 0, 0) 
                showUI() 
            end
        end
    end)

    local function ToggleFreecam(state)
        if state then
            createHiderUI()

            local MOVE_SPEED = 0.8
            local ROTATION_SPEED = 0.25
            local MOVEMENT_SMOOTHNESS = 0.1
            local targetRotation, currentRotation = Vector2.new(0, 0), Vector2.new(0, 0)
            local velocity = Vector3.new(0, 0, 0)
            camera.CameraType = Enum.CameraType.Scriptable
            
            local touchGui = playerGui:FindFirstChild("TouchGui")
            if touchGui then touchGui.Enabled = false end

            local screenGui = Instance.new("ScreenGui", playerGui)
            screenGui.Name, screenGui.ResetOnSpawn = "CinematicFreecamUI", false
            screenGui.DisplayOrder = 999

            local analogBgBox = Instance.new("Frame", screenGui)
            analogBgBox.Size = UDim2.new(0, 120, 0, 120)
            analogBgBox.Position = UDim2.new(0, 15, 1, -180)
            analogBgBox.BackgroundTransparency = 1 
            analogBgBox.Active = true

            local analogBase = Instance.new("Frame", analogBgBox)
            analogBase.Size = UDim2.new(0, 96, 0, 96)
            analogBase.Position = UDim2.new(0.5, -48, 0.5, -48)
            analogBase.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            analogBase.BackgroundTransparency = 0.5
            Instance.new("UICorner", analogBase).CornerRadius = UDim.new(1, 0)
            
            local analogBaseStroke = Instance.new("UIStroke", analogBase)
            analogBaseStroke.Thickness, analogBaseStroke.Transparency = 2, 0.3
            analogBaseStroke.Color = Color3.fromRGB(255, 255, 255)

            local analogStick = Instance.new("Frame", analogBase)
            analogStick.Size = UDim2.new(0, 36, 0, 36)
            analogStick.Position = UDim2.new(0.5, -18, 0.5, -18)
            analogStick.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            analogStick.BackgroundTransparency = 0.2
            Instance.new("UICorner", analogStick).CornerRadius = UDim.new(1, 0)

            local watermarkZ = Instance.new("TextLabel", analogStick)
            watermarkZ.Size = UDim2.new(1, 0, 1, 0)
            watermarkZ.BackgroundTransparency = 1
            watermarkZ.Text = "Z"
            watermarkZ.Font, watermarkZ.TextSize = Enum.Font.GothamBold, 14
            watermarkZ.TextColor3 = Color3.fromRGB(100, 100, 100)

            local analogVector = Vector2.new(0, 0)
            local isDraggingAnalog = false
            local analogTouchObj = nil

            analogBgBox.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDraggingAnalog = true
                    analogTouchObj = input
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input == analogTouchObj then
                    isDraggingAnalog = false
                    analogTouchObj = nil
                    analogVector = Vector2.new(0, 0)
                    analogStick.Position = UDim2.new(0.5, -18, 0.5, -18)
                end
            end)

            local isSwipingScreen = false
            local lastMousePos = Vector2.new(0, 0)
            local swipeTouchObj = nil

            UserInputService.InputBegan:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch) then
                    local pos = input.Position
                    if not (pos.X < 140 and pos.Y > camera.ViewportSize.Y - 190) then
                        isSwipingScreen = true
                        lastMousePos = Vector2.new(pos.X, pos.Y)
                        swipeTouchObj = input
                    end
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input == swipeTouchObj then
                    isSwipingScreen = false
                    swipeTouchObj = nil
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if isDraggingAnalog and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    if input == analogTouchObj or input.UserInputType == Enum.UserInputType.MouseMovement then
                        local absPos = analogBase.AbsolutePosition
                        local absSize = analogBase.AbsoluteSize
                        local center = absPos + (absSize / 2)
                        local mousePos = input.Position
                        
                        local delta = Vector2.new(mousePos.X, mousePos.Y) - center
                        local radius = absSize.X / 2 - 18
                        
                        if delta.Magnitude > radius then
                            delta = delta.Unit * radius
                        end
                        
                        analogStick.Position = UDim2.new(0.5, delta.X - 18, 0.5, delta.Y - 18)
                        analogVector = delta / radius
                    end
                end

                if isSwipingScreen and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    if input == swipeTouchObj or input.UserInputType == Enum.UserInputType.MouseMovement then
                        local currentPos = input.Position
                        local deltaMove = Vector2.new(currentPos.X, currentPos.Y) - lastMousePos
                        lastMousePos = Vector2.new(currentPos.X, currentPos.Y)

                        targetRotation = targetRotation + Vector2.new(-deltaMove.Y * ROTATION_SPEED, -deltaMove.X * ROTATION_SPEED)
                        targetRotation = Vector2.new(math.clamp(targetRotation.X, -85, 85), targetRotation.Y)
                    end
                end
            end)

            local renderConnection
            renderConnection = RunService.RenderStepped:Connect(function(dt)
                currentRotation = currentRotation:Lerp(targetRotation, 0.2)
                
                local moveX = analogVector.X
                local moveZ = analogVector.Y
                local moveY = 0

                local direction = Vector3.new(moveX, moveY, moveZ)
                local cameraCFrame = CFrame.Angles(0, math.rad(currentRotation.Y), 0) * CFrame.Angles(math.rad(currentRotation.X), 0, 0)
                velocity = velocity:Lerp(cameraCFrame:VectorToWorldSpace(direction) * MOVE_SPEED, MOVEMENT_SMOOTHNESS)
                camera.CFrame = CFrame.new(camera.CFrame.Position + velocity) * cameraCFrame
            end)

            miscTab._freecam = {renderConnection, screenGui}
        else
            removeHiderUI()

            local touchGui = playerGui:FindFirstChild("TouchGui")
            if touchGui then touchGui.Enabled = true end

            if miscTab._freecam then
                if miscTab._freecam[1] then miscTab._freecam[1]:Disconnect() end
                if miscTab._freecam[2] then miscTab._freecam[2]:Destroy() end
                miscTab._freecam = nil
            end
            camera.CameraType = Enum.CameraType.Custom
        end
    end

    playersMiscTab:AddToggle({
        Name = "Freecam",
        Default = false,
        Flag = genFlag(),
        Callback = function(Value) ToggleFreecam(Value) end
    })
end

do
    playersMiscTab:AddToggle({
        Name = "No-Clip",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            _G.NoClip = bool
            if bool then
                local noclipLoop
                noclipLoop = RunService.Stepped:Connect(function()
                    if _G.NoClip then
                        if player.Character then
                            for _, part in pairs(player.Character:GetDescendants()) do
                                if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                            end
                        end
                    else
                        noclipLoop:Disconnect()
                    end
                end)
                window:Notify({ Title = "No-Clip", Content = "Enabled" })
            end
        end
    })
end

local visualMiscTab = miscTabbox:AddTab("Visual", "lucide:eye")

do
    visualMiscTab:AddDivider({ Text = "Zoom Distance" })
    local zoomAmount, zoomActive = 10000, false

    visualMiscTab:AddTextInput({
        Name = "Zoom Distance",
        Placeholder = "Enter distance",
        Default = "10000",
        Callback = function(t)
            zoomAmount = tonumber(t) or 128
            if zoomActive then player.CameraMaxZoomDistance = zoomAmount end
        end
    })

    visualMiscTab:AddToggle({
        Name = "Enable Costume Zoom",
        Default = false,
        Flag = genFlag(),
        Callback = function(v)
            zoomActive = v
            if v then
                player.CameraMaxZoomDistance = zoomAmount
                camera.FieldOfView = 90
            else
                player.CameraMaxZoomDistance = 128
                camera.FieldOfView = 70
            end
        end
    })
end

do
    visualMiscTab:AddDivider({ Text = "Visual" })
    local parts, partSize, totalDistance, startPosition = {}, 2048, 50000, Vector3.new(-2, -9.5, -2)
    local numberOfParts = math.ceil(totalDistance / partSize)

    local function createParts()
        for x = 0, numberOfParts - 1 do
            for z = 0, numberOfParts - 1 do
                local function make(name, offset)
                    local p = Instance.new("Part")
                    p.Size, p.Position, p.Anchored = Vector3.new(partSize, 1, partSize), startPosition + offset, true
                    p.Transparency, p.CanCollide, p.Name, p.Parent = 1, true, name, workspace
                    table.insert(parts, p)
                end
                make("P_Side", Vector3.new(x * partSize, 0, z * partSize))
                make("P_LR", Vector3.new(-x * partSize, 0, z * partSize))
                make("P_UL", Vector3.new(-x * partSize, 0, -z * partSize))
                make("P_UR", Vector3.new(x * partSize, 0, -z * partSize))
            end
        end
    end

    local function makePartsWalkthrough()
        for _, part in ipairs(parts) do
            if part and part.Parent then part.CanCollide = false end
        end
    end

    visualMiscTab:AddToggle({
        Name = "Walk on Water",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            if bool then createParts() else makePartsWalkthrough() end
        end
    })
end

do
    visualMiscTab:AddToggle({
        Name = "Hide Frame",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            for _, obj in pairs(ReplicatedStorage:GetChildren()) do
                if obj.Name:match("Frame$") then
                    obj.Visible = not bool
                end
            end
        end
    })
end

do
    visualMiscTab:AddToggle({
        Name = "Hide All Players",
        Default = false,
        Flag = genFlag(),
        Callback = function(Value)
            _G.PlayerHideConn = _G.PlayerHideConn or nil
            if Value then
                _G.PlayerHideConn = RunService.RenderStepped:Connect(function()
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= player and p.Character then
                            for _, obj in ipairs(p.Character:GetDescendants()) do
                                if obj:IsA("BasePart") or obj:IsA("Decal") then
                                    obj.LocalTransparencyModifier = 1
                                elseif obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
                                    obj.Enabled = false
                                end
                            end
                        end
                    end
                end)
            else
                if _G.PlayerHideConn then _G.PlayerHideConn:Disconnect(); _G.PlayerHideConn = nil end
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character then
                        for _, obj in ipairs(p.Character:GetDescendants()) do
                            if obj:IsA("BasePart") or obj:IsA("Decal") then
                                obj.LocalTransparencyModifier = 0
                            elseif obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
                                obj.Enabled = true
                            end
                        end
                    end
                end
            end
        end
    })
end

do
    visualMiscTab:AddToggle({
        Name = "Hide Inventory Pets",
        Default = false,
        Flag = genFlag(),
        Callback = function(isOn)
            local petsFolder = player:WaitForChild("petsFolder")
            local storage = ReplicatedStorage:FindFirstChild("HiddenPets_Storage") or Instance.new("Folder", ReplicatedStorage)
            storage.Name = "HiddenPets_Storage"
            if isOn then
                for _, pet in ipairs(petsFolder:GetChildren()) do pet.Parent = storage end
            else
                for _, pet in ipairs(storage:GetChildren()) do pet.Parent = petsFolder end
            end
        end
    })
end

local eventMiscTab = miscTabbox:AddTab("Event", "lucide:calendar")
eventMiscTab:AddDivider({ Text = "Event Muscle" })

do
    eventMiscTab:AddToggle({
        Name = "Auto Farm Brawl",
        Default = false,
        Flag = genFlag(),
        Callback = function(Value)
            _G.AutoFarmBrawl = Value
            if not Value then
                _G.AutoJoinBrawl, _G.FastPunch, _G.CombatAktif = false, false, false
                return
            end

            local safeZones = {
                {Position = Vector3.new(4429.12, 16.82, -8669.67), Radius = 1200},
                {Position = Vector3.new(1005.82, 17.22, -7204.38), Radius = 1200},
                {Position = Vector3.new(-1866.51, 17.22, -6310.42), Radius = 1200}
            }

            local function isInSafeZone(pos)
                for _, zone in ipairs(safeZones) do
                    if (pos - zone.Position).Magnitude <= zone.Radius then return true end
                end
                return false
            end

            local brawlEvent = ReplicatedStorage:WaitForChild("rEvents"):WaitForChild("brawlEvent")
            local currentRadius, auraConnection = 2000, nil
            _G.CombatAktif = false

            local function activateDomainKiller(state)
                if auraConnection then auraConnection:Disconnect() end
                if state then
                    auraConnection = RunService.Heartbeat:Connect(function()
                        local char = player.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        if root then
                            for _, p in ipairs(Players:GetPlayers()) do
                                if p ~= player and p.Character then
                                    local eRoot = p.Character:FindFirstChild("HumanoidRootPart")
                                    local eHum = p.Character:FindFirstChild("Humanoid")
                                    if eRoot and eHum and eHum.Health > 0 and (eRoot.Position - root.Position).Magnitude <= currentRadius then
                                        local rHand, lHand = char:FindFirstChild("RightHand"), char:FindFirstChild("LeftHand")
                                        if rHand then firetouchinterest(rHand, eRoot, 1); firetouchinterest(rHand, eRoot, 0) end
                                        if lHand then firetouchinterest(lHand, eRoot, 1); firetouchinterest(lHand, eRoot, 0) end
                                    end
                                end
                            end
                        end
                    end)
                end
            end

            local function startFastPunchBrawl()
                if _G.FastPunchActive then return end
                _G.FastPunchActive = true
                task.spawn(function()
                    while _G.FastPunch and _G.AutoFarmBrawl do
                        local char = player.Character
                        local tool = char and char:FindFirstChild("Punch") or player.Backpack:FindFirstChild("Punch")
                        if tool then
                            if tool:FindFirstChild("attackTime") then tool.attackTime.Value = 0 end
                            if not char:FindFirstChild("Punch") and char:FindFirstChild("Humanoid") then
                                char.Humanoid:EquipTool(tool)
                            end
                        end
                        task.wait(0.1)
                    end
                end)
                task.spawn(function()
                    while _G.FastPunch and _G.AutoFarmBrawl do
                        local muscleEvent = player:FindFirstChild("muscleEvent")
                        if muscleEvent then
                            muscleEvent:FireServer("punch", "rightHand")
                            muscleEvent:FireServer("punch", "leftHand")
                        end
                        local tool = player.Character and player.Character:FindFirstChild("Punch")
                        if tool then tool:Activate() end
                        task.wait(0.05)
                    end
                    _G.FastPunchActive = false
                end)
            end

            task.spawn(function()
                while _G.AutoFarmBrawl do
                    local char = player.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then
                        if isInSafeZone(root.Position) then
                            if not _G.CombatAktif then
                                _G.CombatAktif, _G.FastPunch = true, true
                                activateDomainKiller(true)
                                startFastPunchBrawl()
                            end
                        else
                            if _G.CombatAktif then
                                _G.CombatAktif, _G.FastPunch = false, false
                                activateDomainKiller(false)
                            end
                            brawlEvent:FireServer("joinBrawl")
                        end
                    end
                    task.wait(7)
                end
            end)
        end
    })
end

do
    eventMiscTab:AddToggle({
        Name = "Auto Eat Egg | 30mins",
        Default = false,
        Flag = genFlag(),
        Callback = function(state)
            getgenv().AutoEatProtein = state
            local function activateProteinEgg()
                local character = player.Character
                if not character then return end
                local tool = character:FindFirstChild("Protein Egg") or player.Backpack:FindFirstChild("Protein Egg")
                if tool and player and player:FindFirstChild("muscleEvent") then
                    player.muscleEvent:FireServer("proteinEgg", tool)
                end
            end
            if state then
                task.spawn(function()
                    while getgenv().AutoEatProtein do
                        activateProteinEgg()
                        task.wait(1800)
                    end
                end)
                window:Notify({ Title = "Success", Content = "Auto Eat Egg Enabled" })
            end
        end
    })
end

do
    eventMiscTab:AddToggle({
        Name = "Eat All Snacks",
        Default = false,
        Flag = genFlag(),
        Callback = function(state)
            _G.AutoEatAll = state
            if state then
                local mE = player:WaitForChild("muscleEvent")
                local itemList = {"Tropical Shake", "Energy Shake", "Protein Bar", "TOUGH Bar", "Protein Shake", "ULTRA Shake", "Energy Bar"}
                local function formatEventName(itemName)
                    local parts = {}
                    for word in itemName:gmatch("%S+") do table.insert(parts, word:lower()) end
                    for i = 2, #parts do parts[i] = parts[i]:sub(1,1):upper() .. parts[i]:sub(2) end
                    return table.concat(parts)
                end
                task.spawn(function()
                    while _G.AutoEatAll do
                        for _, itemName in ipairs(itemList) do
                            if not _G.AutoEatAll then break end
                            local tool = player.Character and player.Character:FindFirstChild(itemName) or player.Backpack:FindFirstChild(itemName)
                            if tool then mE:FireServer(formatEventName(itemName), tool) end
                        end
                        task.wait(0.1)
                    end
                end)
            end
        end
    })
end

do
    eventMiscTab:AddToggle({
        Name = "Auto Spin Wheel",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            _G.AutoSpinWheel = bool
            if bool then
                task.spawn(function()
                    while _G.AutoSpinWheel do
                        game:GetService("ReplicatedStorage").rEvents.openFortuneWheelRemote:InvokeServer(
                            "openFortuneWheel",
                            game:GetService("ReplicatedStorage").shared.catalogs.fortuneWheelChances["Fortune Wheel"]
                        )
                        task.wait(1)
                    end
                end)
            end
        end
    })
end

do
    eventMiscTab:AddToggle({
        Name = "Auto Claim Gifts",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            _G.AutoClaimGifts = bool
            if bool then
                task.spawn(function()
                    while _G.AutoClaimGifts do
                        for i = 1, 8 do
                            ReplicatedStorage.rEvents.freeGiftClaimRemote:InvokeServer("claimGift", i)
                        end
                        task.wait(1)
                    end
                end)
            end
        end
    })
end

do
    eventMiscTab:AddButton({
        Name = "Reedem Code",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local codeRemote = ReplicatedStorage:WaitForChild("rEvents"):WaitForChild("codeRemote")

            local promoCodes = {
                "mightygems2500",
                "ultimate250",
                "spacegems50",
                "megalift50",
                "speedy50",
                "epicreward500",
                "MillionWarriors",
                "frostgems10",
                "Musclestorm50",
                "Skyagility50",
                "galaxycrystal50",
                "supermuscle100",
                "superpunch100",
                "launch250",
                "bossstrike",
                "bossguard"
            }

            for _, code in ipairs(promoCodes) do
                codeRemote:InvokeServer(code)
                task.wait(0.5)
            end
        end
    })
end


local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

do
    local serverTab = window:AddTab({
        Name = "Server",
        Icon = "lucide:server",
        Type = "Single",
    })

    local ServerTabbox = serverTab:AddTabbox({ Name = "Server", Position = "center" })

    local innerServerTab = ServerTabbox:AddTab("Server", "lucide:server")
    innerServerTab:AddDivider({ Text = "Server" })

    local currentJobID = ""
    innerServerTab:AddTextInput({
        Name = "Enter Server JobID",
        Placeholder = "Enter ID here...",
        Flag = genFlag(),
        Callback = function(text) currentJobID = text end
    })

    innerServerTab:AddButton({
        Name = "Join Server ID",
        Callback = function()
            if currentJobID ~= "" then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, currentJobID, player)
            else
                window:Notify({ Title = "Error", Content = "Please enter a valid JobID" })
            end
        end
    })

    innerServerTab:AddButton({
        Name = "Get Server's JobID",
        Callback = function()
            setclipboard(game.JobId)
            window:Notify({ Title = "Success", Content = "JobID copied to clipboard" })
        end
    })

    innerServerTab:AddToggle({
        Name = "Join Low Player",
        Default = false,
        Flag = genFlag(),
        Callback = function(bool)
            if bool then
                local module = loadstring(game:HttpGet("https://raw.githubusercontent.com/LeoKholYt/roblox/main/lk_serverhop.lua"))()
                module:Teleport(game.PlaceId, "Lowest")
            end
        end
    })

    innerServerTab:AddButton({
        Name = "Rejoin Server",
        Callback = function()
            TeleportService:Teleport(game.PlaceId, player)
        end
    })

    innerServerTab:AddButton({
        Name = "Delete Portals",
        Callback = function()
            for _, portal in pairs(game:GetDescendants()) do
                if portal.Name == "RobloxForwardPortals" then portal:Destroy() end
            end
            if _G.AdRemovalConnection then _G.AdRemovalConnection:Disconnect() end
            _G.AdRemovalConnection = game.DescendantAdded:Connect(function(descendant)
                if descendant.Name == "RobloxForwardPortals" then descendant:Destroy() end
            end)
            window:Notify({ Title = "Ads Delete", Content = "Portal Ads Deleted" })
        end
    })

    innerServerTab:AddButton({
        Name = "FPS Boost",
        Callback = function()
            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                    v.Enabled = false
                end
            end
            
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 0
            settings().Rendering.QualityLevel = 1
            
            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("Decal") or v:IsA("Texture") then
                    v.Transparency = 1
                elseif v:IsA("BasePart") and not v:IsA("MeshPart") then
                    v.Material = Enum.Material.SmoothPlastic
                    if not (v.Parent and (v.Parent:FindFirstChild("Humanoid") or v.Parent.Parent:FindFirstChild("Humanoid"))) then
                        v.Reflectance = 0
                    end
                end
            end
            
            for _, v in pairs(Lighting:GetChildren()) do
                if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
                    v.Enabled = false
                end
            end
            window:Notify({ Title = "Boost", Content = "FPS Boosted" })
        end
    })
end

window:Notify({ Title = "Vuzo Zilux", Content = "Script VIP | The Most Complete Features Currently", Duration = 7 })
