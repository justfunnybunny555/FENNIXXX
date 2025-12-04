--[[
    ███████╗███████╗███╗   ███╗███╗   ██╗██╗██╗  ██╗██╗  ██╗██╗  ██╗
    ██╔════╝██╔════╝████╗ ████║████╗  ██║██║╚██╗██╔╝╚██╗██╔╝╚██╗██╔╝
    █████╗  █████╗  ██╔████╔██║██╔██╗ ██║██║ ╚███╔╝  ╚███╔╝  ╚███╔╝ 
    ██╔══╝  ██╔══╝  ██║╚██╔╝██║██║╚██╗██║██║ ██╔██╗  ██╔██╗  ██╔██╗ 
    ██║     ███████╗██║ ╚═╝ ██║██║ ╚████║██║██╔╝ ██╗██╔╝ ██╗██╔╝ ██╗
    ╚═╝     ╚══════╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝
              iOS CONTROL CENTER STYLE V4.1
    Made with by FENNIXXX Team
]]

-- ════════════════════════════════════════════════════════════════
-- CORE SERVICES
-- ════════════════════════════════════════════════════════════════

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    Workspace = game:GetService("Workspace"),
    CoreGui = game:GetService("CoreGui"),
    HttpService = game:GetService("HttpService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = workspace.CurrentCamera

--- KeyAuth Configuration
local KeyAuthApp = "FENNIXXX"
local KeyAuthOwnerID = "edcEgR58Gp"
local KeyAuthVersion = "1.0"
local KeyAuthURL = "https://keyauth.win/api/1.2/"

local isAuthorized = false
local sessionID = ""
local scriptEnabled = true

-- Функция получения HWID
local function getHWID()
    local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
    return hwid
end

-- Функция инициализации KeyAuth
local function initKeyAuth()
    local success, response = pcall(function()
        return request({
            Url = KeyAuthURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded"
            },
            Body = "type=init&ver=" .. KeyAuthVersion .. "&name=" .. KeyAuthApp .. "&ownerid=" .. KeyAuthOwnerID
        })
    end)
    
    if not success then
        warn("KeyAuth init request failed: " .. tostring(response))
        return false, "Connection failed"
    end
    
    if response.StatusCode == 200 then
        local decodeSuccess, data = pcall(function()
            return Services.HttpService:JSONDecode(response.Body)
        end)
        
        if decodeSuccess then
            if data.success then
                sessionID = data.sessionid
                return true, "Initialized"
            else
                warn("KeyAuth init failed: " .. (data.message or "Unknown error"))
                return false, data.message or "Init failed"
            end
        else
            warn("KeyAuth init decode failed: " .. response.Body)
            return false, "Invalid response"
        end
    else
        warn("KeyAuth init status code: " .. response.StatusCode)
        return false, "Server error: " .. response.StatusCode
    end
end

-- Функция проверки лицензии
local function verifyLicense(key)
    if not sessionID or sessionID == "" then
        local initSuccess, initMsg = initKeyAuth()
        if not initSuccess then
            return false, "Failed to initialize: " .. initMsg
        end
        wait(0.5)
    end
    
    local hwid = getHWID()
    
    local success, response = pcall(function()
        return request({
            Url = KeyAuthURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded"
            },
            Body = "type=license&key=" .. Services.HttpService:UrlEncode(key) ..
                    "&sessionid=" .. sessionID ..
                    "&name=" .. KeyAuthApp ..
                    "&ownerid=" .. KeyAuthOwnerID ..
                    "&hwid=" .. hwid
        })
    end)
    
    if not success then
        warn("KeyAuth license request failed: " .. tostring(response))
        return false, "Connection failed"
    end
    
    if response.StatusCode == 200 then
        local decodeSuccess, data = pcall(function()
            return Services.HttpService:JSONDecode(response.Body)
        end)
        
        if decodeSuccess then
            if data.success then
                local exp = "Lifetime"
                if data.info and data.info.subscriptions then
                    for _, sub in pairs(data.info.subscriptions) do
                        if sub.expiry and sub.expiry ~= "lifetime" then
                            exp = os.date("%m/%d/%Y %H:%M", tonumber(sub.expiry))
                        end
                    end
                end
                return true, "License verified! Expires: " .. exp
            else
                return false, data.message or "Invalid license key"
            end
        else
            warn("KeyAuth license decode failed: " .. response.Body)
            return false, "Invalid response from server"
        end
    else
        warn("KeyAuth license status code: " .. response.StatusCode .. " Body: " .. response.Body)
        return false, "Server error: " .. response.StatusCode
    end
end

-- Создание GUI для ввода ключа
local function createAuthGUI()
    local authGui = Instance.new("ScreenGui")
    authGui.Name = "KeyAuthGUI"
    authGui.IgnoreGuiInset = true
    authGui.ResetOnSpawn = false
    authGui.Parent = Services.CoreGui
    
    -- Фон с blur эффектом (iOS стиль)
    local darkBackground = Instance.new("Frame")
    darkBackground.Size = UDim2.new(1, 0, 1, 0)
    darkBackground.Position = UDim2.new(0, 0, 0, 0)
    darkBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    darkBackground.BorderSizePixel = 0
    darkBackground.BackgroundTransparency = 0.3
    darkBackground.Parent = authGui
    
    -- Основной фрейм авторизации (iOS стиль - закругленный, прозрачный)
    local authFrame = Instance.new("Frame")
    authFrame.Size = UDim2.new(0, 380, 0, 460)
    authFrame.Position = UDim2.new(0.5, -190, 0.5, -230)
    authFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    authFrame.BorderSizePixel = 0
    authFrame.BackgroundTransparency = 0.1
    authFrame.Parent = authGui
    
    local authCorner = Instance.new("UICorner", authFrame)
    authCorner.CornerRadius = UDim.new(0, 28)
    
    local authStroke = Instance.new("UIStroke", authFrame)
    authStroke.Color = Color3.fromRGB(200, 200, 200)
    authStroke.Thickness = 1
    authStroke.Transparency = 0.7
    
    -- Логотип
    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.new(1, 0, 0, 70)
    logoText.Position = UDim2.new(0, 0, 0, 30)
    logoText.Text = "FENNIXXX"
    logoText.TextColor3 = Color3.fromRGB(60, 60, 67)
    logoText.TextSize = 34
    logoText.Font = Enum.Font.GothamBold
    logoText.BackgroundTransparency = 1
    logoText.Parent = authFrame
    
    -- Подзаголовок
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, 0, 0, 25)
    subtitleLabel.Position = UDim2.new(0, 0, 0, 100)
    subtitleLabel.Text = "License Verification"
    subtitleLabel.TextColor3 = Color3.fromRGB(142, 142, 147)
    subtitleLabel.TextSize = 14
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Parent = authFrame
    
    -- HWID Label
    local hwidLabel = Instance.new("TextLabel")
    hwidLabel.Size = UDim2.new(1, -100, 0, 18)
    hwidLabel.Position = UDim2.new(0, 25, 0, 150)
    hwidLabel.Text = "HWID: " .. getHWID()
    hwidLabel.TextColor3 = Color3.fromRGB(142, 142, 147)
    hwidLabel.TextSize = 10
    hwidLabel.Font = Enum.Font.Gotham
    hwidLabel.BackgroundTransparency = 1
    hwidLabel.TextXAlignment = Enum.TextXAlignment.Left
    hwidLabel.TextWrapped = true
    hwidLabel.TextScaled = false
    hwidLabel.Parent = authFrame
    
    -- Кнопка копирования HWID
    local copyHWIDBtn = Instance.new("TextButton")
    copyHWIDBtn.Size = UDim2.new(0, 65, 0, 26)
    copyHWIDBtn.Position = UDim2.new(1, -90, 0, 147)
    copyHWIDBtn.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
    copyHWIDBtn.Text = "Copy"
    copyHWIDBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyHWIDBtn.TextSize = 12
    copyHWIDBtn.Font = Enum.Font.GothamMedium
    copyHWIDBtn.BorderSizePixel = 0
    copyHWIDBtn.Parent = authFrame
    
    local copyCorner = Instance.new("UICorner", copyHWIDBtn)
    copyCorner.CornerRadius = UDim.new(0, 8)
    
    copyHWIDBtn.MouseButton1Click:Connect(function()
        setclipboard(getHWID())
        copyHWIDBtn.Text = "Copied!"
        copyHWIDBtn.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
        wait(1.5)
        copyHWIDBtn.Text = "Copy"
        copyHWIDBtn.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
    end)
    
    -- Поле ввода ключа (iOS стиль)
    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(0, 330, 0, 45)
    keyBox.Position = UDim2.new(0.5, -165, 0, 195)
    keyBox.BackgroundColor3 = Color3.fromRGB(242, 242, 247)
    keyBox.Text = ""
    keyBox.PlaceholderText = "Enter License Key"
    keyBox.PlaceholderColor3 = Color3.fromRGB(174, 174, 178)
    keyBox.TextColor3 = Color3.fromRGB(0, 0, 0)
    keyBox.TextSize = 15
    keyBox.Font = Enum.Font.Gotham
    keyBox.BorderSizePixel = 0
    keyBox.ClearTextOnFocus = false
    keyBox.TextWrapped = true
    keyBox.TextScaled = false
    keyBox.Parent = authFrame
    
    local keyBoxCorner = Instance.new("UICorner", keyBox)
    keyBoxCorner.CornerRadius = UDim.new(0, 12)
    
    local keyBoxPadding = Instance.new("UIPadding", keyBox)
    keyBoxPadding.PaddingLeft = UDim.new(0, 15)
    keyBoxPadding.PaddingRight = UDim.new(0, 15)
    
    keyBox.Focused:Connect(function()
        Services.TweenService:Create(keyBox, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    
    keyBox.FocusLost:Connect(function()
        Services.TweenService:Create(keyBox, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(242, 242, 247)
        }):Play()
    end)
    
    -- Кнопка верификации (iOS стиль)
    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(0, 330, 0, 45)
    submitBtn.Position = UDim2.new(0.5, -165, 0, 260)
    submitBtn.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
    submitBtn.Text = "Verify License"
    submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitBtn.TextSize = 16
    submitBtn.Font = Enum.Font.GothamBold
    submitBtn.BorderSizePixel = 0
    submitBtn.Parent = authFrame
    
    local submitBtnCorner = Instance.new("UICorner", submitBtn)
    submitBtnCorner.CornerRadius = UDim.new(0, 12)
    
    -- Статус лейбл
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -40, 0, 30)
    statusLabel.Position = UDim2.new(0, 20, 0, 320)
    statusLabel.Text = ""
    statusLabel.TextColor3 = Color3.fromRGB(255, 59, 48)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextWrapped = true
    statusLabel.Parent = authFrame
    
    -- Кнопка получения лицензии
    local getKeyBtn = Instance.new("TextButton")
    getKeyBtn.Size = UDim2.new(0, 180, 0, 38)
    getKeyBtn.Position = UDim2.new(0.5, -90, 0, 370)
    getKeyBtn.BackgroundColor3 = Color3.fromRGB(242, 242, 247)
    getKeyBtn.Text = "Get License"
    getKeyBtn.TextColor3 = Color3.fromRGB(0, 122, 255)
    getKeyBtn.TextSize = 14
    getKeyBtn.Font = Enum.Font.GothamMedium
    getKeyBtn.BorderSizePixel = 0
    getKeyBtn.Parent = authFrame
    
    local getKeyCorner = Instance.new("UICorner", getKeyBtn)
    getKeyCorner.CornerRadius = UDim.new(0, 12)
    
    getKeyBtn.MouseButton1Click:Connect(function()
        setclipboard("https://keyauth.win/panel/" .. KeyAuthApp .. "/licenses")
        getKeyBtn.Text = "Link Copied!"
        getKeyBtn.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
        getKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        wait(2)
        getKeyBtn.Text = "Get License"
        getKeyBtn.BackgroundColor3 = Color3.fromRGB(242, 242, 247)
        getKeyBtn.TextColor3 = Color3.fromRGB(0, 122, 255)
    end)
    
    -- Функция верификации
    local function verifyKey()
        local key = keyBox.Text
        if key == "" or #key < 10 then
            statusLabel.Text = "Please enter a valid license key"
            statusLabel.TextColor3 = Color3.fromRGB(255, 59, 48)
            
            local originalPos = authFrame.Position
            for i = 1, 3 do
                Services.TweenService:Create(authFrame, TweenInfo.new(0.05), {Position = originalPos + UDim2.new(0, 10, 0, 0)}):Play()
                wait(0.05)
                Services.TweenService:Create(authFrame, TweenInfo.new(0.05), {Position = originalPos - UDim2.new(0, 10, 0, 0)}):Play()
                wait(0.05)
            end
            authFrame.Position = originalPos
            return
        end
        
        submitBtn.Text = "Verifying..."
        submitBtn.BackgroundColor3 = Color3.fromRGB(142, 142, 147)
        statusLabel.TextColor3 = Color3.fromRGB(0, 122, 255)
        statusLabel.Text = "Verifying license..."
        
        local success, message = verifyLicense(key)
        
        if success then
            isAuthorized = true
            statusLabel.Text = message
            statusLabel.TextColor3 = Color3.fromRGB(52, 199, 89)
            
            submitBtn.Text = "Verified!"
            submitBtn.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
            
            wait(1.5)
            
            Services.TweenService:Create(authFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }):Play()
            
            Services.TweenService:Create(darkBackground, TweenInfo.new(0.4), {
                BackgroundTransparency = 1
            }):Play()
            
            wait(0.4)
            authGui:Destroy()
            initializeScript()
        else
            submitBtn.Text = "Verify License"
            submitBtn.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
            statusLabel.Text = message
            statusLabel.TextColor3 = Color3.fromRGB(255, 59, 48)
            
            local originalPos = authFrame.Position
            for i = 1, 3 do
                Services.TweenService:Create(authFrame, TweenInfo.new(0.05), {Position = originalPos + UDim2.new(0, 10, 0, 0)}):Play()
                wait(0.05)
                Services.TweenService:Create(authFrame, TweenInfo.new(0.05), {Position = originalPos - UDim2.new(0, 10, 0, 0)}):Play()
                wait(0.05)
            end
            authFrame.Position = originalPos
        end
    end
    
    submitBtn.MouseButton1Click:Connect(verifyKey)
    keyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            verifyKey()
        end
    end)
    
    -- Анимация появления
    authFrame.Size = UDim2.new(0, 0, 0, 0)
    authFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    Services.TweenService:Create(authFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 380, 0, 460),
        Position = UDim2.new(0.5, -190, 0.5, -230)
    }):Play()
end

-- WalkSpeed система
getgenv().walkSpeedSettings = {
    WalkSpeed = {
        Enabled = false,
        Speed = 300,
    },
    Activation = {
        WalkSpeedToggleKey = "Q",
    }
}

local isSpeedEnabled = false
local originalSpeeds = {}
local speedConnection = nil

local function saveOriginalSpeed()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local humanoid = LocalPlayer.Character.Humanoid
        if not originalSpeeds[humanoid] then
            originalSpeeds[humanoid] = humanoid.WalkSpeed
        end
    end
end

local function updateSpeed()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local humanoid = LocalPlayer.Character.Humanoid
        
        if isSpeedEnabled and getgenv().walkSpeedSettings.WalkSpeed.Enabled then
            humanoid.WalkSpeed = getgenv().walkSpeedSettings.WalkSpeed.Speed
        else
            if originalSpeeds[humanoid] then
                humanoid.WalkSpeed = originalSpeeds[humanoid]
            end
        end
    end
end

local function setupWalkSpeed()
    if speedConnection then
        speedConnection:Disconnect()
    end
    
    LocalPlayer.CharacterAdded:Connect(function(character)
        wait(0.5)
        character:WaitForChild("Humanoid")
        wait(0.1)
        saveOriginalSpeed()
        if isSpeedEnabled and getgenv().walkSpeedSettings.WalkSpeed.Enabled then
            updateSpeed()
        end
    end)
    
    if LocalPlayer.Character then
        saveOriginalSpeed()
    end
    
    speedConnection = Services.RunService.Heartbeat:Connect(function()
        if isSpeedEnabled and getgenv().walkSpeedSettings.WalkSpeed.Enabled then
            updateSpeed()
        end
    end)
end

function initializeScript()
    if not isAuthorized then
        return
    end

local Config = {
    Enabled = true,
    HitPart = "Closest Point",
    FOVSize = 80,
    TeamCheck = false,
    KnockedCheck = false,
    WallCheck = false,
    VisibleCheck = false,
    MaxDistance = 500,
    Keybind = Enum.KeyCode.C,
    Resolver = false,
    ShowFOV = false,
    RapidFire = false,
    RapidFireDelay = 0.05,
    Multipoint = false,
    MultipointSize = 5,
    ShowTargeting = false,
    
    UpdateRate = 3,
    MaxPlayersToCheck = 15,
    UseSpatialOptimization = true,
    
    GUISize = {Width = 600, Height = 700},
    GUIToggleKey = Enum.KeyCode.Insert,
    
    WeaponProfiles = {
        ["Revolver"] = {
            Prediction = Vector3.new(0, 0, 0),
            MaxDistance = 400
        },
        ["Double-Barrel"] = {
            Prediction = Vector3.new(0, 0, 0),
            MaxDistance = 200
        },
        ["Shotgun"] = {
            Prediction = Vector3.new(0, 0, 0),
            MaxDistance = 200
        },
        ["TacticalShotgun"] = {
            Prediction = Vector3.new(0, 0, 0),
            MaxDistance = 225
        },
        ["SMG"] = {
            Prediction = Vector3.new(0, 0, 0),
            MaxDistance = 350
        },
        ["Rifle"] = {
            Prediction = Vector3.new(0, 0, 0),
            MaxDistance = 500
        },
        ["AR"] = {
            Prediction = Vector3.new(0, 0, 0),
            MaxDistance = 450
        },
        ["AK47"] = {
            Prediction = Vector3.new(0, 0, 0),
            MaxDistance = 500
        },
        ["Silencer"] = {
            Prediction = Vector3.new(0, 0, 0),
            MaxDistance = 400
        },
        ["Default"] = {
            Prediction = Vector3.new(0.165, 0.165, 0.165),
            MaxDistance = 400
        }
    },
    
    CurrentWeapon = nil,
    CurrentPrediction = Vector3.new(0.165, 0.165, 0.165),
    CurrentMaxDistance = 400,
    
    ESP = {
        Enabled = false,
        ShowBox = false,
        ShowName = false,
        ShowDistance = false,
        ShowHealth = false,
        ShowSkeleton = false,
        BoxColor = Color3.fromRGB(0, 122, 255),
        NameColor = Color3.fromRGB(255, 255, 255),
        DistanceColor = Color3.fromRGB(142, 142, 147),
        HealthBarColor = Color3.fromRGB(52, 199, 89),
        SkeletonColor = Color3.fromRGB(0, 122, 255),
        MaxDistance = 500,
        TeamCheck = false
    }
}

local SpreadMod = {
    BulletSpread = {
        Enabled = true,
        Amount = 70
    }
}

local allBodyParts = {
    "Head",
    "UpperTorso",
    "LowerTorso",
    "HumanoidRootPart",
    "LeftUpperArm",
    "LeftLowerArm",
    "LeftHand",
    "RightUpperArm",
    "RightLowerArm",
    "RightHand",
    "LeftUpperLeg",
    "LeftLowerLeg",
    "LeftFoot",
    "RightUpperLeg",
    "RightLowerLeg",
    "RightFoot"
}

local skeletonConnections = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(0, 122, 255)
FOVCircle.Transparency = 1
FOVCircle.NumSides = 24
FOVCircle.Filled = false

local TargetIndicator = Drawing.new("Circle")
TargetIndicator.Visible = false
TargetIndicator.Thickness = 3
TargetIndicator.Color = Color3.fromRGB(52, 199, 89)
TargetIndicator.Transparency = 1
TargetIndicator.NumSides = 16
TargetIndicator.Radius = 8
TargetIndicator.Filled = false

local MultipointCircle = Drawing.new("Circle")
MultipointCircle.Visible = false
MultipointCircle.Thickness = 1
MultipointCircle.Color = Color3.fromRGB(0, 122, 255)
MultipointCircle.Transparency = 0.5
MultipointCircle.NumSides = 12
MultipointCircle.Radius = 5
MultipointCircle.Filled = false

local cachedTarget = nil
local cachedTargetPoint = nil
local lastShotTime = 0
local rapidFireConnection = nil

local playerCache = {}
local lastCacheUpdate = 0
local CACHE_UPDATE_INTERVAL = 1

local mouseLocation = Vector2.new(0, 0)
local lastMouseUpdate = 0

local currentWeaponCache = nil
local lastWeaponCheck = 0
local WEAPON_CHECK_INTERVAL = 0.2

local ESPObjects = {}

local function createESP(player)
    if ESPObjects[player] then return end
    
    local esp = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
        HealthBarOutline = Drawing.new("Square"),
        SkeletonLines = {}
    }
    
    for i = 1, #skeletonConnections do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Thickness = 2
        line.Transparency = 1
        table.insert(esp.SkeletonLines, line)
    end
    
    esp.Box.Visible = false
    esp.Box.Thickness = 2
    esp.Box.Filled = false
    esp.Box.Transparency = 1
    
    esp.Name.Visible = false
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.Size = 14
    esp.Name.Font = 2
    
    esp.Distance.Visible = false
    esp.Distance.Center = true
    esp.Distance.Outline = true
    esp.Distance.Size = 13
    esp.Distance.Font = 2
    
    esp.HealthBar.Visible = false
    esp.HealthBar.Filled = true
    esp.HealthBar.Thickness = 1
    
    esp.HealthBarOutline.Visible = false
    esp.HealthBarOutline.Filled = false
    esp.HealthBarOutline.Thickness = 1
    esp.HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    
    ESPObjects[player] = esp
end

local function removeESP(player)
    if ESPObjects[player] then
        for _, drawing in pairs(ESPObjects[player]) do
            if type(drawing) == "table" then
                for _, line in pairs(drawing) do
                    line:Remove()
                end
            else
                drawing:Remove()
            end
        end
        ESPObjects[player] = nil
    end
end

local function updateESP()
    if not Config.ESP.Enabled then
        for _, esp in pairs(ESPObjects) do
            for key, drawing in pairs(esp) do
                if key == "SkeletonLines" then
                    for _, line in pairs(drawing) do
                        line.Visible = false
                    end
                else
                    drawing.Visible = false
                end
            end
        end
        return
    end
    
    for player, esp in pairs(ESPObjects) do
        if player and player.Character and player ~= LocalPlayer then
            local character = player.Character
            local hrp = character:FindFirstChild("HumanoidRootPart")
            local head = character:FindFirstChild("Head")
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            
            if hrp and head and humanoid and humanoid.Health > 0 then
                local distance = (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                
                if distance <= Config.ESP.MaxDistance then
                    if Config.ESP.TeamCheck and LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
                        for key, drawing in pairs(esp) do
                            if key == "SkeletonLines" then
                                for _, line in pairs(drawing) do
                                    line.Visible = false
                                end
                            else
                                drawing.Visible = false
                            end
                        end
                    else
                        local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        
                        if onScreen then
                            local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                            local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                            
                            local height = math.abs(headPos.Y - legPos.Y)
                            local width = height / 2
                            
                            if Config.ESP.ShowBox then
                                esp.Box.Visible = true
                                esp.Box.Size = Vector2.new(width, height)
                                esp.Box.Position = Vector2.new(vector.X - width / 2, vector.Y - height / 2)
                                esp.Box.Color = Config.ESP.BoxColor
                            else
                                esp.Box.Visible = false
                            end
                            
                            if Config.ESP.ShowName then
                                esp.Name.Visible = true
                                esp.Name.Text = player.Name
                                esp.Name.Position = Vector2.new(vector.X, headPos.Y - 20)
                                esp.Name.Color = Config.ESP.NameColor
                            else
                                esp.Name.Visible = false
                            end
                            
                            if Config.ESP.ShowDistance then
                                esp.Distance.Visible = true
                                esp.Distance.Text = math.floor(distance) .. "m"
                                esp.Distance.Position = Vector2.new(vector.X, legPos.Y + 5)
                                esp.Distance.Color = Config.ESP.DistanceColor
                            else
                                esp.Distance.Visible = false
                            end
                            
                            if Config.ESP.ShowHealth then
                                local healthPercent = humanoid.Health / humanoid.MaxHealth
                                
                                esp.HealthBarOutline.Visible = true
                                esp.HealthBarOutline.Size = Vector2.new(4, height + 2)
                                esp.HealthBarOutline.Position = Vector2.new(vector.X - width / 2 - 8, vector.Y - height / 2 - 1)
                                
                                esp.HealthBar.Visible = true
                                esp.HealthBar.Size = Vector2.new(2, height * healthPercent)
                                esp.HealthBar.Position = Vector2.new(vector.X - width / 2 - 7, vector.Y + height / 2 - height * healthPercent)
                                esp.HealthBar.Color = Color3.fromRGB(
                                    math.clamp(255 * (1 - healthPercent), 0, 255),
                                    math.clamp(255 * healthPercent, 0, 255),
                                    0
                                )
                            else
                                esp.HealthBar.Visible = false
                                esp.HealthBarOutline.Visible = false
                            end
                            
                            if Config.ESP.ShowSkeleton then
                                for i, connection in ipairs(skeletonConnections) do
                                    local part1 = character:FindFirstChild(connection[1])
                                    local part2 = character:FindFirstChild(connection[2])
                                    
                                    if part1 and part2 and esp.SkeletonLines[i] then
                                        local pos1, vis1 = Camera:WorldToViewportPoint(part1.Position)
                                        local pos2, vis2 = Camera:WorldToViewportPoint(part2.Position)
                                        
                                        if vis1 and vis2 then
                                            esp.SkeletonLines[i].Visible = true
                                            esp.SkeletonLines[i].From = Vector2.new(pos1.X, pos1.Y)
                                            esp.SkeletonLines[i].To = Vector2.new(pos2.X, pos2.Y)
                                            esp.SkeletonLines[i].Color = Config.ESP.SkeletonColor
                                        else
                                            esp.SkeletonLines[i].Visible = false
                                        end
                                    elseif esp.SkeletonLines[i] then
                                        esp.SkeletonLines[i].Visible = false
                                    end
                                end
                            else
                                for _, line in pairs(esp.SkeletonLines) do
                                    line.Visible = false
                                end
                            end
                        else
                            for key, drawing in pairs(esp) do
                                if key == "SkeletonLines" then
                                    for _, line in pairs(drawing) do
                                        line.Visible = false
                                    end
                                else
                                    drawing.Visible = false
                                end
                            end
                        end
                    end
                else
                    for key, drawing in pairs(esp) do
                        if key == "SkeletonLines" then
                            for _, line in pairs(drawing) do
                                line.Visible = false
                            end
                        else
                            drawing.Visible = false
                        end
                    end
                end
            else
                for key, drawing in pairs(esp) do
                    if key == "SkeletonLines" then
                        for _, line in pairs(drawing) do
                            line.Visible = false
                        end
                    else
                        drawing.Visible = false
                    end
                end
            end
        else
            for key, drawing in pairs(esp) do
                if key == "SkeletonLines" then
                    for _, line in pairs(drawing) do
                        line.Visible = false
                    end
                else
                    drawing.Visible = false
                end
            end
        end
    end
end

Services.Players.PlayerAdded:Connect(function(player)
    createESP(player)
end)

Services.Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

for _, player in ipairs(Services.Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESP(player)
    end
end

local function getCurrentWeapon()
    local now = tick()
    if now - lastWeaponCheck < WEAPON_CHECK_INTERVAL and currentWeaponCache then
        return currentWeaponCache
    end
    
    lastWeaponCheck = now
    local character = LocalPlayer.Character
    if not character then
        currentWeaponCache = nil
        return nil
    end
    
    local tool = character:FindFirstChildOfClass("Tool")
    currentWeaponCache = tool and tool.Name or nil
    return currentWeaponCache
end

local function updateWeaponSettings()
    local weaponName = getCurrentWeapon()
    if not weaponName then
        Config.CurrentWeapon = nil
        return
    end
    
    if Config.CurrentWeapon == weaponName then return end
    
    local profile = Config.WeaponProfiles[weaponName] or Config.WeaponProfiles["Default"]
    
    Config.CurrentWeapon = weaponName
    Config.CurrentPrediction = profile.Prediction
    Config.CurrentMaxDistance = profile.MaxDistance
end

local teamCheckCache = {}
local function isOnSameTeam(player)
    if not Config.TeamCheck then return false end
    if not LocalPlayer.Team or not player.Team then return false end
    
    local cacheKey = player.UserId
    local now = tick()
    
    if teamCheckCache[cacheKey] and now - teamCheckCache[cacheKey].time < 2 then
        return teamCheckCache[cacheKey].result
    end
    
    local result = LocalPlayer.Team == player.Team
    teamCheckCache[cacheKey] = {result = result, time = now}
    return result
end

local knockedCache = {}
local function isKnocked(player)
    if not Config.KnockedCheck then return false end
    
    local cacheKey = player.UserId
    local now = tick()
    
    if knockedCache[cacheKey] and now - knockedCache[cacheKey].time < 0.5 then
        return knockedCache[cacheKey].result
    end
    
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        knockedCache[cacheKey] = {result = true, time = now}
        return true
    end
    
    local bodyEffects = character:FindFirstChild("BodyEffects")
    local result = false
    if bodyEffects then
        local knocked = bodyEffects:FindFirstChild("K.O")
        if knocked and knocked.Value == true then
            result = true
        end
    end
    
    knockedCache[cacheKey] = {result = result, time = now}
    return result
end

local wallCheckCache = {}
local function hasWallBetween(origin, targetPart)
    if not Config.WallCheck then return false end
    
    local cacheKey = tostring(targetPart)
    local now = tick()
    
    if wallCheckCache[cacheKey] and now - wallCheckCache[cacheKey].time < 0.2 then
        return wallCheckCache[cacheKey].result
    end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    
    local direction = (targetPart.Position - origin)
    local rayResult = workspace:Raycast(origin, direction, rayParams)
    
    local result = false
    if rayResult and rayResult.Instance then
        if not rayResult.Instance:IsDescendantOf(targetPart.Parent) then
            result = true
        end
    end
    
    wallCheckCache[cacheKey] = {result = result, time = now}
    return result
end

local function isVisible(part)
    if not Config.VisibleCheck then return true end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return false end
    
    return not hasWallBetween(Camera.CFrame.Position, part)
end

local function resolveVelocity(part)
    if not Config.Resolver then
        return part.Velocity
    end
    
    local velocity = part.Velocity
    local magnitude = velocity.Magnitude
    
    if magnitude < 5 then
        return Vector3.new(0, 0, 0)
    end
    
    if velocity.Y > 10 or velocity.Y < -10 then
        velocity = Vector3.new(velocity.X, velocity.Y * 0.7, velocity.Z)
    end
    
    if magnitude > 80 then
        velocity = velocity * 0.5
    end
    
    return velocity
end

local function getClosestPointOnPart(part, mousePos)
    if not Config.Multipoint then
        return part.Position
    end
    
    local size = part.Size
    local cf = part.CFrame
    local multipointSize = Config.MultipointSize / 10
    
    local points = {
        part.Position,
        (cf * CFrame.new(size.X * multipointSize, 0, 0)).Position,
        (cf * CFrame.new(-size.X * multipointSize, 0, 0)).Position,
        (cf * CFrame.new(0, size.Y * multipointSize, 0)).Position,
        (cf * CFrame.new(0, -size.Y * multipointSize, 0)).Position,
        (cf * CFrame.new(0, 0, size.Z * multipointSize)).Position,
        (cf * CFrame.new(0, 0, -size.Z * multipointSize)).Position,
        (cf * CFrame.new(size.X * multipointSize, size.Y * multipointSize, 0)).Position,
        (cf * CFrame.new(-size.X * multipointSize, size.Y * multipointSize, 0)).Position,
        (cf * CFrame.new(size.X * multipointSize, -size.Y * multipointSize, 0)).Position,
    }
    
    local closestPoint = part.Position
    local closestDist = math.huge
    
    for _, point in ipairs(points) do
        local screenPos, onScreen = Camera:WorldToViewportPoint(point)
        if onScreen then
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestPoint = point
            end
        end
    end
    
    return closestPoint
end

local function getClosestPart(character)
    if not character then return nil, nil end
    
    if Config.HitPart ~= "Closest Point" then
        local part = character:FindFirstChild(Config.HitPart)
        if part and part:IsA("BasePart") then
            local hitPoint = getClosestPointOnPart(part, mouseLocation)
            return part, hitPoint
        end
    end
    
    local bestPart, bestPoint, bestDist = nil, nil, math.huge
    
    for _, partName in ipairs(allBodyParts) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            local hitPoint = getClosestPointOnPart(part, mouseLocation)
            local screenPos, onScreen = Camera:WorldToViewportPoint(hitPoint)
            
            if onScreen then
                local partPos = Vector2.new(screenPos.X, screenPos.Y)
                local dist = (mouseLocation - partPos).Magnitude
                
                if dist < bestDist then
                    bestPart = part
                    bestPoint = hitPoint
                    bestDist = dist
                end
            end
        end
    end
    
    return bestPart, bestPoint
end

local function updatePlayerCache()
    local now = tick()
    if now - lastCacheUpdate < CACHE_UPDATE_INTERVAL then return end
    lastCacheUpdate = now
    
    playerCache = {}
    local myPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myPos then return end
    
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (myPos.Position - player.Character.HumanoidRootPart.Position).Magnitude
            
            if distance <= Config.CurrentMaxDistance * 1.3 then
                table.insert(playerCache, {
                    player = player,
                    distance = distance
                })
            end
        end
    end
    
    table.sort(playerCache, function(a, b) return a.distance < b.distance end)
end

local function updateTarget()
    updateWeaponSettings()
    updatePlayerCache()
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        cachedTarget = nil
        cachedTargetPoint = nil
        return
    end
    
    local fovRadius = Config.FOVSize
    local bestPart, bestPoint, bestDist = nil, nil, math.huge
    
    local playersToCheck = math.min(#playerCache, Config.MaxPlayersToCheck)
    
    for i = 1, playersToCheck do
        local data = playerCache[i]
        local player = data.player
        
        if Config.TeamCheck and isOnSameTeam(player) then continue end
        if Config.KnockedCheck and isKnocked(player) then continue end
        
        local part, hitPoint = getClosestPart(player.Character)
        
        if part and hitPoint then
            local screenPos, onScreen = Camera:WorldToViewportPoint(hitPoint)
            if not onScreen then continue end
            
            local partPos = Vector2.new(screenPos.X, screenPos.Y)
            local distFromMouse = (mouseLocation - partPos).Magnitude
            
            if distFromMouse <= fovRadius then
                if Config.WallCheck and hasWallBetween(Camera.CFrame.Position, part) then
                    continue
                end
                
                if distFromMouse < bestDist then
                    bestPart = part
                    bestPoint = hitPoint
                    bestDist = distFromMouse
                end
            end
        end
    end
    
    cachedTarget = bestPart
    cachedTargetPoint = bestPoint
end

local function applyPrediction(position, velocity, offset)
    return position + velocity * offset
end

local uiUpdateCounter = 0
local UI_UPDATE_RATE = 3

Services.RunService.RenderStepped:Connect(function()
    if not scriptEnabled then return end
    
    mouseLocation = Services.UserInputService:GetMouseLocation()
    
    uiUpdateCounter = uiUpdateCounter + 1
    
    if uiUpdateCounter % UI_UPDATE_RATE == 0 then
        FOVCircle.Position = mouseLocation
        FOVCircle.Radius = Config.FOVSize
        FOVCircle.Visible = Config.ShowFOV
        
        if Config.Multipoint then
            MultipointCircle.Position = mouseLocation
            MultipointCircle.Radius = Config.MultipointSize
            MultipointCircle.Visible = Config.ShowFOV
        else
            MultipointCircle.Visible = false
        end
        
        if Config.ShowTargeting and cachedTarget and cachedTargetPoint and Config.Enabled then
            local velocity = resolveVelocity(cachedTarget)
            local predictedPos = applyPrediction(cachedTargetPoint, velocity, Config.CurrentPrediction.X)
            local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
            
            if onScreen then
                TargetIndicator.Position = Vector2.new(screenPos.X, screenPos.Y)
                TargetIndicator.Visible = true
                TargetIndicator.Color = Color3.fromRGB(52, 199, 89)
                TargetIndicator.Radius = 8
            else
                TargetIndicator.Visible = false
            end
        else
            TargetIndicator.Visible = false
        end
    end
    
    updateESP()
end)

Services.UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.Keybind then
        Config.Enabled = not Config.Enabled
        print("Silent Aimbot is now", Config.Enabled and "Enabled" or "Disabled")
    end
    
    if input.KeyCode == Enum.KeyCode[getgenv().walkSpeedSettings.Activation.WalkSpeedToggleKey] then
        isSpeedEnabled = not isSpeedEnabled
        updateSpeed()
        print("WalkSpeed is now", isSpeedEnabled and "Enabled" or "Disabled")
    end
end)

local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)
mt.__index = newcclosure(function(obj, prop)
    if Config.Enabled and scriptEnabled and obj:IsA("Mouse") and (prop == "Hit" or prop == "Target") then
        if cachedTarget and cachedTargetPoint then
            local velocity = resolveVelocity(cachedTarget)
            local predictedPos = applyPrediction(cachedTargetPoint, velocity, Config.CurrentPrediction.X)
            
            return prop == "Hit" and CFrame.new(predictedPos) or cachedTarget
        end
    end
    return oldIndex(obj, prop)
end)
setreadonly(mt, true)

local frameCounter = 0
Services.RunService.RenderStepped:Connect(function()
    if not Config.Enabled or not scriptEnabled then return end
    frameCounter = frameCounter + 1
    if frameCounter % Config.UpdateRate == 0 then
        updateTarget()
    end
end)

local function setupRapidFire()
    if rapidFireConnection then
        rapidFireConnection:Disconnect()
        rapidFireConnection = nil
    end
    
    if not Config.RapidFire then return end
    
    rapidFireConnection = Services.UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local shooting = true
            
            local connection
            connection = Services.UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 then
                    shooting = false
                    connection:Disconnect()
                end
            end)
            
            while shooting and Config.RapidFire and Config.Enabled and scriptEnabled do
                local currentTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if currentTool then
                    currentTool:Activate()
                end
                wait(Config.RapidFireDelay)
            end
        end
    end)
end

setupRapidFire()

local oldRandom
oldRandom = hookfunction(math.random, function(...)
    local args = {...}
    if checkcaller() then return oldRandom(...) end
    if (#args == 0) or (args[1] == -0.05 and args[2] == 0.05) or (args[1] == -0.1) or (args[1] == -0.05) then
        if SpreadMod.BulletSpread.Enabled then
            return oldRandom(...) * (SpreadMod.BulletSpread.Amount / 100)
        end
    end
    return oldRandom(...)
end)

Services.Players.PlayerRemoving:Connect(function(player)
    teamCheckCache[player.UserId] = nil
    knockedCache[player.UserId] = nil
end)

setupWalkSpeed()

-- ════════════════════════════════════════════════════════════════
-- iOS CONTROL CENTER STYLE GUI
-- ════════════════════════════════════════════════════════════════

local gui = Instance.new("ScreenGui")
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Name = "FennixAimUI"
gui.Parent = Services.CoreGui

-- Главное окно (iOS Control Center стиль)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, Config.GUISize.Width, 0, Config.GUISize.Height)
mainFrame.Position = UDim2.new(0.5, -Config.GUISize.Width/2, 0.5, -Config.GUISize.Height/2)
mainFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.05
mainFrame.Active = true
mainFrame.ClipsDescendants = false
mainFrame.Parent = gui

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 28)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(210, 210, 215)
mainStroke.Thickness = 1
mainStroke.Transparency = 0.5

-- Заголовок (iOS стиль)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 70)
titleBar.BackgroundTransparency = 1
titleBar.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.Text = "FENNIXXX"
title.TextColor3 = Color3.fromRGB(0, 0, 0)
title.TextSize = 26
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Система изменения размера БЕЗ ВИДИМЫХ ЭЛЕМЕНТОВ
local resizing = false
local resizeDirection = nil
local resizeStart = nil
local startSize = nil
local startPos = nil

local function createInvisibleHandle(sizeProp, posProp, cursor)
    local handle = Instance.new("Frame")
    handle.Size = sizeProp
    handle.Position = posProp
    handle.BackgroundTransparency = 1
    handle.BorderSizePixel = 0
    handle.Parent = mainFrame
    handle.ZIndex = 10
    return handle
end

local rightHandle = createInvisibleHandle(UDim2.new(0, 10, 1, 0), UDim2.new(1, -5, 0, 0))
local leftHandle = createInvisibleHandle(UDim2.new(0, 10, 1, 0), UDim2.new(0, -5, 0, 0))
local bottomHandle = createInvisibleHandle(UDim2.new(1, 0, 0, 10), UDim2.new(0, 0, 1, -5))
local topHandle = createInvisibleHandle(UDim2.new(1, 0, 0, 10), UDim2.new(0, 0, 0, -5))
local cornerBR = createInvisibleHandle(UDim2.new(0, 20, 0, 20), UDim2.new(1, -10, 1, -10))
local cornerBL = createInvisibleHandle(UDim2.new(0, 20, 0, 20), UDim2.new(0, -10, 1, -10))
local cornerTR = createInvisibleHandle(UDim2.new(0, 20, 0, 20), UDim2.new(1, -10, 0, -10))
local cornerTL = createInvisibleHandle(UDim2.new(0, 20, 0, 20), UDim2.new(0, -10, 0, -10))

local function setupResize(handle, direction)
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeDirection = direction
            resizeStart = Services.UserInputService:GetMouseLocation()
            startSize = mainFrame.Size
            startPos = mainFrame.Position
        end
    end)
    
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and resizeDirection == direction then
            resizing = false
            resizeDirection = nil
        end
    end)
end

setupResize(rightHandle, "right")
setupResize(leftHandle, "left")
setupResize(bottomHandle, "bottom")
setupResize(topHandle, "top")
setupResize(cornerBR, "corner-br")
setupResize(cornerBL, "corner-bl")
setupResize(cornerTR, "corner-tr")
setupResize(cornerTL, "corner-tl")

Services.RunService.RenderStepped:Connect(function()
    if resizing and resizeDirection then
        local currentMouse = Services.UserInputService:GetMouseLocation()
        local delta = currentMouse - resizeStart
        
        if resizeDirection == "right" then
            local newWidth = math.clamp(startSize.X.Offset + delta.X, 400, 1000)
            mainFrame.Size = UDim2.new(0, newWidth, 0, startSize.Y.Offset)
            Config.GUISize.Width = newWidth
        elseif resizeDirection == "left" then
            local newWidth = math.clamp(startSize.X.Offset - delta.X, 400, 1000)
            mainFrame.Size = UDim2.new(0, newWidth, 0, startSize.Y.Offset)
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + (startSize.X.Offset - newWidth), startPos.Y.Scale, startPos.Y.Offset)
            Config.GUISize.Width = newWidth
        elseif resizeDirection == "bottom" then
            local newHeight = math.clamp(startSize.Y.Offset + delta.Y, 400, 1000)
            mainFrame.Size = UDim2.new(0, startSize.X.Offset, 0, newHeight)
            Config.GUISize.Height = newHeight
        elseif resizeDirection == "top" then
            local newHeight = math.clamp(startSize.Y.Offset - delta.Y, 400, 1000)
            mainFrame.Size = UDim2.new(0, startSize.X.Offset, 0, newHeight)
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset + (startSize.Y.Offset - newHeight))
            Config.GUISize.Height = newHeight
        elseif resizeDirection == "corner-br" then
            local newWidth = math.clamp(startSize.X.Offset + delta.X, 400, 1000)
            local newHeight = math.clamp(startSize.Y.Offset + delta.Y, 400, 1000)
            mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
            Config.GUISize.Width = newWidth
            Config.GUISize.Height = newHeight
        elseif resizeDirection == "corner-bl" then
            local newWidth = math.clamp(startSize.X.Offset - delta.X, 400, 1000)
            local newHeight = math.clamp(startSize.Y.Offset + delta.Y, 400, 1000)
            mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + (startSize.X.Offset - newWidth), startPos.Y.Scale, startPos.Y.Offset)
            Config.GUISize.Width = newWidth
            Config.GUISize.Height = newHeight
        elseif resizeDirection == "corner-tr" then
            local newWidth = math.clamp(startSize.X.Offset + delta.X, 400, 1000)
            local newHeight = math.clamp(startSize.Y.Offset - delta.Y, 400, 1000)
            mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset + (startSize.Y.Offset - newHeight))
            Config.GUISize.Width = newWidth
            Config.GUISize.Height = newHeight
        elseif resizeDirection == "corner-tl" then
            local newWidth = math.clamp(startSize.X.Offset - delta.X, 400, 1000)
            local newHeight = math.clamp(startSize.Y.Offset - delta.Y, 400, 1000)
            mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + (startSize.X.Offset - newWidth), startPos.Y.Scale, startPos.Y.Offset + (startSize.Y.Offset - newHeight))
            Config.GUISize.Width = newWidth
            Config.GUISize.Height = newHeight
        end
    end
end)

-- Перетаскивание
local dragging = false
local dragStart = nil
local startPosFrame = nil

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = Services.UserInputService:GetMouseLocation()
        startPosFrame = mainFrame.Position
    end
end)

Services.UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

Services.RunService.RenderStepped:Connect(function()
    if dragging and not resizing then
        local currentMouse = Services.UserInputService:GetMouseLocation()
        local delta = currentMouse - dragStart
        mainFrame.Position = UDim2.new(
            startPosFrame.X.Scale,
            startPosFrame.X.Offset + delta.X,
            startPosFrame.Y.Scale,
            startPosFrame.Y.Offset + delta.Y
        )
    end
end)

-- Контейнер с прокруткой
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -24, 1, -90)
scrollFrame.Position = UDim2.new(0, 12, 0, 78)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(142, 142, 147)
scrollFrame.Parent = mainFrame

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.Parent = scrollFrame
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Padding = UDim.new(0, 12)
scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 20)
end)

-- Функция создания круглой кнопки (iOS Control Center стиль) - ИСПРАВЛЕНО
local function createCircleButton(name, order, defaultValue, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 110, 0, 110)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 90, 0, 90)
    button.Position = UDim2.new(0.5, -45, 0, 0)
    button.BackgroundColor3 = defaultValue and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(255, 255, 255)
    button.Text = ""
    button.BorderSizePixel = 0
    button.BackgroundTransparency = 0.15
    button.Parent = container
    
    local btnCorner = Instance.new("UICorner", button)
    btnCorner.CornerRadius = UDim.new(1, 0)
    
    local btnStroke = Instance.new("UIStroke", button)
    btnStroke.Color = Color3.fromRGB(210, 210, 215)
    btnStroke.Thickness = 2
    btnStroke.Transparency = defaultValue and 1 or 0.5
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.Position = UDim2.new(0, 0, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = name:sub(1, 1):upper()
    iconLabel.TextColor3 = defaultValue and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 105)
    iconLabel.TextSize = 28
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextYAlignment = Enum.TextYAlignment.Center
    iconLabel.Parent = button
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 18)
    nameLabel.Position = UDim2.new(0, 0, 1, 2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.Parent = container
    
    local enabled = defaultValue
    
    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        
        Services.TweenService:Create(button, TweenInfo.new(0.25), {
            BackgroundColor3 = enabled and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(255, 255, 255)
        }):Play()
        
        Services.TweenService:Create(btnStroke, TweenInfo.new(0.25), {
            Transparency = enabled and 1 or 0.5
        }):Play()
        
        Services.TweenService:Create(iconLabel, TweenInfo.new(0.25), {
            TextColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 105)
        }):Play()
        
        callback(enabled)
    end)
    
    return container, button
end

-- Функция создания модульной секции (iOS стиль)
local function createModuleSection(title, order)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(0, scrollFrame.AbsoluteSize.X - 12, 0, 45)
    section.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    section.BorderSizePixel = 0
    section.BackgroundTransparency = 0.3
    section.LayoutOrder = order
    section.Parent = scrollFrame
    
    local sectionCorner = Instance.new("UICorner", section)
    sectionCorner.CornerRadius = UDim.new(0, 16)
    
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Size = UDim2.new(1, -20, 1, 0)
    sectionTitle.Position = UDim2.new(0, 16, 0, 0)
    sectionTitle.Text = title
    sectionTitle.TextColor3 = Color3.fromRGB(0, 0, 0)
    sectionTitle.TextSize = 18
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.TextYAlignment = Enum.TextYAlignment.Center
    sectionTitle.Parent = section
    
    return section
end

-- Функция создания слайдера (iOS стиль)
local function createModernSlider(name, order, min, max, defaultValue, callback, isDecimal)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(0, scrollFrame.AbsoluteSize.X - 12, 0, 75)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.BackgroundTransparency = 0.3
    sliderFrame.LayoutOrder = order
    sliderFrame.Parent = scrollFrame
    
    local sliderCorner = Instance.new("UICorner", sliderFrame)
    sliderCorner.CornerRadius = UDim.new(0, 16)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.55, 0, 0, 26)
    label.Position = UDim2.new(0, 16, 0, 12)
    label.Text = name
    label.TextColor3 = Color3.fromRGB(0, 0, 0)
    label.TextSize = 15
    label.Font = Enum.Font.GothamMedium
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = sliderFrame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.4, 0, 0, 26)
    valueLabel.Position = UDim2.new(0.6, 0, 0, 12)
    valueLabel.Text = isDecimal and string.format("%.2f", defaultValue) or tostring(defaultValue)
    valueLabel.TextColor3 = Color3.fromRGB(0, 122, 255)
    valueLabel.TextSize = 15
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextYAlignment = Enum.TextYAlignment.Center
    valueLabel.Parent = sliderFrame
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -32, 0, 8)
    sliderBg.Position = UDim2.new(0, 16, 0, 52)
    sliderBg.BackgroundColor3 = Color3.fromRGB(220, 220, 225)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = sliderFrame
    
    local sliderBgCorner = Instance.new("UICorner", sliderBg)
    sliderBgCorner.CornerRadius = UDim.new(1, 0)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((defaultValue - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    
    local sliderFillCorner = Instance.new("UICorner", sliderFill)
    sliderFillCorner.CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    Services.RunService.RenderStepped:Connect(function()
        if dragging then
            local mousePos = Services.UserInputService:GetMouseLocation()
            local relX = math.clamp((mousePos.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            
            Services.TweenService:Create(sliderFill, TweenInfo.new(0.1), {
                Size = UDim2.new(relX, 0, 1, 0)
            }):Play()
            
            local value = min + (max - min) * relX
            if not isDecimal then
                value = math.floor(value)
            end
            
            valueLabel.Text = isDecimal and string.format("%.2f", value) or tostring(value)
            callback(value)
        end
    end)
    
    return sliderFrame
end

-- Функция создания тоггла в стиле iOS (маленький переключатель)
local function createCompactToggle(name, order, defaultValue, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(0, scrollFrame.AbsoluteSize.X - 12, 0, 52)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleFrame.BorderSizePixel = 0
    toggleFrame.BackgroundTransparency = 0.3
    toggleFrame.LayoutOrder = order
    toggleFrame.Parent = scrollFrame
    
    local toggleCorner = Instance.new("UICorner", toggleFrame)
    toggleCorner.CornerRadius = UDim.new(0, 16)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.Position = UDim2.new(0, 16, 0, 0)
    label.Text = name
    label.TextColor3 = Color3.fromRGB(0, 0, 0)
    label.TextSize = 15
    label.Font = Enum.Font.Gotham
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = toggleFrame
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 51, 0, 31)
    toggle.Position = UDim2.new(1, -67, 0.5, -15.5)
    toggle.BackgroundColor3 = defaultValue and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(220, 220, 225)
    toggle.Text = ""
    toggle.BorderSizePixel = 0
    toggle.Parent = toggleFrame
    
    local toggleCorner2 = Instance.new("UICorner", toggle)
    toggleCorner2.CornerRadius = UDim.new(1, 0)
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 27, 0, 27)
    circle.Position = defaultValue and UDim2.new(0, 22, 0, 2) or UDim2.new(0, 2, 0, 2)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.BorderSizePixel = 0
    circle.Parent = toggle
    
    local circleCorner = Instance.new("UICorner", circle)
    circleCorner.CornerRadius = UDim.new(1, 0)
    
    local enabled = defaultValue
    
    toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        
        Services.TweenService:Create(toggle, TweenInfo.new(0.25), {
            BackgroundColor3 = enabled and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(220, 220, 225)
        }):Play()
        
        Services.TweenService:Create(circle, TweenInfo.new(0.25), {
            Position = enabled and UDim2.new(0, 22, 0, 2) or UDim2.new(0, 2, 0, 2)
        }):Play()
        
        callback(enabled)
    end)
    
    return toggleFrame
end

-- Функция создания dropdown (выбор части тела)
local function createDropdown(name, order, options, defaultValue, callback)
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(0, scrollFrame.AbsoluteSize.X - 12, 0, 52)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dropdownFrame.BorderSizePixel = 0
    dropdownFrame.BackgroundTransparency = 0.3
    dropdownFrame.LayoutOrder = order
    dropdownFrame.ClipsDescendants = false
    dropdownFrame.Parent = scrollFrame
    
    local dropdownCorner = Instance.new("UICorner", dropdownFrame)
    dropdownCorner.CornerRadius = UDim.new(0, 16)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.Position = UDim2.new(0, 16, 0, 0)
    label.Text = name
    label.TextColor3 = Color3.fromRGB(0, 0, 0)
    label.TextSize = 15
    label.Font = Enum.Font.Gotham
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = dropdownFrame
    
    local selectedBtn = Instance.new("TextButton")
    selectedBtn.Size = UDim2.new(0.55, -16, 0, 36)
    selectedBtn.Position = UDim2.new(0.45, 0, 0.5, -18)
    selectedBtn.BackgroundColor3 = Color3.fromRGB(242, 242, 247)
    selectedBtn.Text = defaultValue
    selectedBtn.TextColor3 = Color3.fromRGB(0, 122, 255)
    selectedBtn.TextSize = 14
    selectedBtn.Font = Enum.Font.GothamMedium
    selectedBtn.BorderSizePixel = 0
    selectedBtn.Parent = dropdownFrame
    
    local selectedCorner = Instance.new("UICorner", selectedBtn)
    selectedCorner.CornerRadius = UDim.new(0, 10)
    
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Size = UDim2.new(0.55, -16, 0, 0)
    optionsFrame.Position = UDim2.new(0.45, 0, 1, 4)
    optionsFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    optionsFrame.BorderSizePixel = 0
    optionsFrame.Visible = false
    optionsFrame.ClipsDescendants = true
    optionsFrame.ZIndex = 100
    optionsFrame.Parent = dropdownFrame
    
    local optionsCorner = Instance.new("UICorner", optionsFrame)
    optionsCorner.CornerRadius = UDim.new(0, 12)
    
    local optionsLayout = Instance.new("UIListLayout", optionsFrame)
    optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optionsLayout.Padding = UDim.new(0, 2)
    
    local isOpen = false
    
    selectedBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        
        if isOpen then
            optionsFrame.Visible = true
            Services.TweenService:Create(optionsFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0.55, -16, 0, #options * 38 + 4)
            }):Play()
        else
            Services.TweenService:Create(optionsFrame, TweenInfo.new(0.2), {
                Size = UDim2.new(0.55, -16, 0, 0)
            }):Play()
            wait(0.2)
            optionsFrame.Visible = false
        end
    end)
    
    for i, option in ipairs(options) do
        local optionBtn = Instance.new("TextButton")
        optionBtn.Size = UDim2.new(1, -4, 0, 36)
        optionBtn.Position = UDim2.new(0, 2, 0, 0)
        optionBtn.BackgroundColor3 = Color3.fromRGB(242, 242, 247)
        optionBtn.Text = option
        optionBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        optionBtn.TextSize = 13
        optionBtn.Font = Enum.Font.Gotham
        optionBtn.BorderSizePixel = 0
        optionBtn.LayoutOrder = i
        optionBtn.Parent = optionsFrame
        
        local optionCorner = Instance.new("UICorner", optionBtn)
        optionCorner.CornerRadius = UDim.new(0, 8)
        
        optionBtn.MouseButton1Click:Connect(function()
            selectedBtn.Text = option
            callback(option)
            
            isOpen = false
            Services.TweenService:Create(optionsFrame, TweenInfo.new(0.2), {
                Size = UDim2.new(0.55, -16, 0, 0)
            }):Play()
            wait(0.2)
            optionsFrame.Visible = false
        end)
    end
    
    return dropdownFrame
end

-- Кнопка полного выключения скрипта
local shutdownBtn = Instance.new("TextButton")
shutdownBtn.Size = UDim2.new(0, scrollFrame.AbsoluteSize.X - 12, 0, 55)
shutdownBtn.Position = UDim2.new(0, 0, 0, 0)
shutdownBtn.BackgroundColor3 = Color3.fromRGB(255, 59, 48)
shutdownBtn.Text = "Shutdown Script"
shutdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
shutdownBtn.TextSize = 17
shutdownBtn.Font = Enum.Font.GothamBold
shutdownBtn.BorderSizePixel = 0
shutdownBtn.BackgroundTransparency = 0.15
shutdownBtn.LayoutOrder = 999
shutdownBtn.Parent = scrollFrame

local shutdownCorner = Instance.new("UICorner", shutdownBtn)
shutdownCorner.CornerRadius = UDim.new(0, 16)

shutdownBtn.MouseButton1Click:Connect(function()
    shutdownBtn.Text = "Shutting down..."
    shutdownBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 30)
    
    scriptEnabled = false
    Config.Enabled = false
    Config.ESP.Enabled = false
    isSpeedEnabled = false
    
    -- Очистка всех визуальных элементов
    FOVCircle.Visible = false
    TargetIndicator.Visible = false
    MultipointCircle.Visible = false
    
    -- Очистка ESP
    for player, esp in pairs(ESPObjects) do
        removeESP(player)
    end
    
    wait(0.5)
    
    -- Анимация закрытия GUI
    Services.TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    
    wait(0.4)
    gui:Destroy()
    
    print("FENNIXXX Script has been shut down completely.")
end)

-- ═══════════════════════════════════════════════════════════════
-- СОЗДАНИЕ UI ЭЛЕМЕНТОВ
-- ═══════════════════════════════════════════════════════════════

-- COMBAT SECTION
createModuleSection("Combat", 1)

local gridContainer1 = Instance.new("Frame")
gridContainer1.Size = UDim2.new(0, scrollFrame.AbsoluteSize.X - 12, 0, 240)
gridContainer1.BackgroundTransparency = 1
gridContainer1.LayoutOrder = 2
gridContainer1.Parent = scrollFrame

local gridLayout1 = Instance.new("UIGridLayout")
gridLayout1.CellSize = UDim2.new(0, 110, 0, 110)
gridLayout1.CellPadding = UDim2.new(0, 10, 0, 10)
gridLayout1.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout1.Parent = gridContainer1

createCircleButton("Silent Aim", 1, true, function(value)
    Config.Enabled = value
end).Parent = gridContainer1

createCircleButton("Team Check", 2, false, function(value)
    Config.TeamCheck = value
end).Parent = gridContainer1

createCircleButton("Knocked", 3, false, function(value)
    Config.KnockedCheck = value
end).Parent = gridContainer1

createCircleButton("Wall Check", 4, false, function(value)
    Config.WallCheck = value
end).Parent = gridContainer1

createCircleButton("Visible", 5, false, function(value)
    Config.VisibleCheck = value
end).Parent = gridContainer1

createCircleButton("Resolver", 6, false, function(value)
    Config.Resolver = value
end).Parent = gridContainer1

createCircleButton("Rapid Fire", 7, false, function(value)
    Config.RapidFire = value
    setupRapidFire()
end).Parent = gridContainer1

createCircleButton("Multipoint", 8, false, function(value)
    Config.Multipoint = value
end).Parent = gridContainer1

createModernSlider("FOV Size", 3, 10, 500, 80, function(value)
    Config.FOVSize = value
end, false)

createModernSlider("Max Distance", 4, 50, 1000, 500, function(value)
    Config.MaxDistance = value
end, false)

-- Dropdown для выбора части тела
createDropdown("Target Part", 5, {
    "Closest Point",
    "Head",
    "UpperTorso",
    "LowerTorso",
    "HumanoidRootPart"
}, "Closest Point", function(value)
    Config.HitPart = value
end)

-- VISUALS SECTION
createModuleSection("Visuals", 6)

createCompactToggle("Enable ESP", 7, false, function(value)
    Config.ESP.Enabled = value
end)

createCompactToggle("Show Box", 8, false, function(value)
    Config.ESP.ShowBox = value
end)

createCompactToggle("Show Name", 9, false, function(value)
    Config.ESP.ShowName = value
end)

createCompactToggle("Show Distance", 10, false, function(value)
    Config.ESP.ShowDistance = value
end)

createCompactToggle("Show Health", 11, false, function(value)
    Config.ESP.ShowHealth = value
end)

createCompactToggle("Show Skeleton", 12, false, function(value)
    Config.ESP.ShowSkeleton = value
end)

createCompactToggle("Show FOV Circle", 13, false, function(value)
    Config.ShowFOV = value
end)

createCompactToggle("Show Targeting", 14, false, function(value)
    Config.ShowTargeting = value
end)

-- MOVEMENT SECTION
createModuleSection("Movement", 15)

createCompactToggle("Enable WalkSpeed", 16, false, function(value)
    getgenv().walkSpeedSettings.WalkSpeed.Enabled = value
    if isSpeedEnabled then
        updateSpeed()
    end
end)

createModernSlider("Speed Value", 17, 16, 500, 300, function(value)
    getgenv().walkSpeedSettings.WalkSpeed.Speed = value
    if isSpeedEnabled then
        updateSpeed()
    end
end, false)

-- Dropdown для выбора клавиши WalkSpeed
createDropdown("Toggle Key", 18, {
    "Q", "E", "R", "T", "Y", "U", "F", "G", "H", "Z", "X", "C", "V", "B"
}, "Q", function(value)
    getgenv().walkSpeedSettings.Activation.WalkSpeedToggleKey = value
end)

-- SPREAD SECTION
createModuleSection("Bullet Spread", 19)

createCompactToggle("Reduce Spread", 20, true, function(value)
    SpreadMod.BulletSpread.Enabled = value
end)

createModernSlider("Spread Amount", 21, 0, 100, 70, function(value)
    SpreadMod.BulletSpread.Amount = value
end, false)

-- GUI Toggle
Services.UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.GUIToggleKey then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- Уведомление о загрузке (iOS стиль)
local notificationGui = Instance.new("ScreenGui")
notificationGui.IgnoreGuiInset = true
notificationGui.ResetOnSpawn = false
notificationGui.Parent = Services.CoreGui

local notification = Instance.new("Frame")
notification.Size = UDim2.new(0, 360, 0, 100)
notification.Position = UDim2.new(0.5, -180, 0, -110)
notification.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
notification.BorderSizePixel = 0
notification.BackgroundTransparency = 0.1
notification.Parent = notificationGui

local notifCorner = Instance.new("UICorner", notification)
notifCorner.CornerRadius = UDim.new(0, 20)

local notifStroke = Instance.new("UIStroke", notification)
notifStroke.Color = Color3.fromRGB(210, 210, 215)
notifStroke.Thickness = 1
notifStroke.Transparency = 0.5

local notifTitle = Instance.new("TextLabel")
notifTitle.Size = UDim2.new(1, 0, 0, 42)
notifTitle.Position = UDim2.new(0, 0, 0, 14)
notifTitle.Text = "FENNIXXX"
notifTitle.TextColor3 = Color3.fromRGB(0, 0, 0)
notifTitle.TextSize = 20
notifTitle.Font = Enum.Font.GothamBold
notifTitle.BackgroundTransparency = 1
notifTitle.Parent = notification

local notifText = Instance.new("TextLabel")
notifText.Size = UDim2.new(1, 0, 0, 30)
notifText.Position = UDim2.new(0, 0, 0, 56)
notifText.Size = UDim2.new(1, 0, 0, 30)
notifText.Position = UDim2.new(0, 0, 0, 56)
notifText.Text = "Script Loaded Successfully"
notifText.TextColor3 = Color3.fromRGB(142, 142, 147)
notifText.TextSize = 13
notifText.Font = Enum.Font.Gotham
notifText.BackgroundTransparency = 1
notifText.Parent = notification

Services.TweenService:Create(notification, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, -180, 0, 20)
}):Play()

wait(3)

Services.TweenService:Create(notification, TweenInfo.new(0.4), {
    Position = UDim2.new(0.5, -180, 0, -110)
}):Play()

wait(0.4)
notificationGui:Destroy()

print([[
    ╔═══════════════════════════════════════════════════════╗
    ║         FENNIXXX V4.1 - LOADED SUCCESSFULLY          ║
    ╠═══════════════════════════════════════════════════════╣
    ║  Silent Aim: C (Toggle)                              ║
    ║  WalkSpeed: Q (Toggle)                               ║
    ║  GUI Toggle: INSERT                                   ║
    ╚═══════════════════════════════════════════════════════╝
]])
end

-- ════════════════════════════════════════════════════════════════
-- ЗАПУСК АВТОРИЗАЦИИ
-- ════════════════════════════════════════════════════════════════

createAuthGUI()
