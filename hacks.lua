-- Settings
local ESP_ENABLED = true
local TRACERS_ENABLED = true
local BOXES_ENABLED = true
local HEALTH_BARS_ENABLED = true
local TEAM_CHECK = false

-- Constants
local CAMERA = workspace.CurrentCamera
local PLAYERS = game:GetService("Players")
local LOCAL_PLAYER = PLAYERS.LocalPlayer
local RUN_SERVICE = game:GetService("RunService")

-- Create ESP Functionality
local function createESP(player)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then return end

    -- Create Drawing Elements
    local tracer = Drawing.new("Line")
    local box = Drawing.new("Square")
    local healthBar = Drawing.new("Line")

    tracer.Visible = false
    box.Visible = false
    healthBar.Visible = false

    local function updateESP()
        if not ESP_ENABLED or not character or not rootPart or not humanoid or humanoid.Health <= 0 then
            tracer.Visible = false
            box.Visible = false
            healthBar.Visible = false
            return
        end

        local rootPosition, onScreen = CAMERA:WorldToViewportPoint(rootPart.Position)

        if onScreen then
            -- Tracer
            if TRACERS_ENABLED then
                tracer.From = Vector2.new(CAMERA.ViewportSize.X / 2, CAMERA.ViewportSize.Y)
                tracer.To = Vector2.new(rootPosition.X, rootPosition.Y)
                tracer.Color = TEAM_CHECK and player.TeamColor.Color or Color3.new(1, 0, 0)
                tracer.Thickness = 1
                tracer.Visible = true
            else
                tracer.Visible = false
            end

            -- Box
            if BOXES_ENABLED then
                local head = character:FindFirstChild("Head")
                local headPosition, headOnScreen = CAMERA:WorldToViewportPoint(head.Position)
                local torsoPosition, torsoOnScreen = CAMERA:WorldToViewportPoint(rootPart.Position)

                if headOnScreen and torsoOnScreen then
                    local height = math.abs(headPosition.Y - torsoPosition.Y)
                    local width = height / 2

                    box.Size = Vector2.new(width, height)
                    box.Position = Vector2.new(rootPosition.X - width / 2, rootPosition.Y - height / 2)
                    box.Color = TEAM_CHECK and player.TeamColor.Color or Color3.new(1, 0, 0)
                    box.Thickness = 1
                    box.Visible = true
                else
                    box.Visible = false
                end
            else
                box.Visible = false
            end

            -- Health Bar
            if HEALTH_BARS_ENABLED then
                local healthPercentage = humanoid.Health / humanoid.MaxHealth
                local barHeight = math.abs(box.Size.Y) * healthPercentage

                healthBar.From = Vector2.new(box.Position.X - 5, box.Position.Y + box.Size.Y)
                healthBar.To = Vector2.new(box.Position.X - 5, box.Position.Y + box.Size.Y - barHeight)
                healthBar.Color = Color3.new(0, 1, 0)
                healthBar.Thickness = 2
                healthBar.Visible = true
            else
                healthBar.Visible = false
            end
        else
            tracer.Visible = false
            box.Visible = false
            healthBar.Visible = false
        end
    end

    -- Connection to Render
    local connection
    connection = RUN_SERVICE.RenderStepped:Connect(function()
        if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            tracer:Remove()
            box:Remove()
            healthBar:Remove()
            connection:Disconnect()
            return
        end
        updateESP()
    end)
end

-- Monitor Players
for _, player in pairs(PLAYERS:GetPlayers()) do
    if player ~= LOCAL_PLAYER then
        createESP(player)
    end
end

PLAYERS.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(1) -- Allow time for character to load
        createESP(player)
    end)
end)
