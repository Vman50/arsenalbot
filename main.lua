-- Arsenal Aimbot
-- Compatible: Synapse X, KRNL, Fluxus, Delta

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local Camera          = workspace.CurrentCamera
local LocalPlayer     = Players.LocalPlayer

-- ╔══════════════════════════╗
--   CONFIG
-- ╚══════════════════════════╝
local Config = {
    Enabled    = true,
    AimKey     = Enum.UserInputType.MouseButton2, -- hold RMB to aim
    TargetPart = "Head",       -- "Head" | "HumanoidRootPart"
    Smoothing  = 0.25,         -- 0 = instant snap, 1 = never arrives
    TeamCheck  = true,         -- skip teammates
    FOV        = 160,          -- screen-space radius in px
    DrawFOV    = true,         -- render FOV circle via Drawing API
}

-- ╔══════════════════════════╗
--   FOV CIRCLE
-- ╚══════════════════════════╝
local fovCircle
if Config.DrawFOV and Drawing then
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible   = true
    fovCircle.Radius    = Config.FOV
    fovCircle.Color     = Color3.fromRGB(255, 255, 255)
    fovCircle.Thickness = 1
    fovCircle.Filled    = false
    fovCircle.Transparency = 0.6

    RunService.RenderStepped:Connect(function()
        fovCircle.Position = Camera.ViewportSize / 2
    end)
end

-- ╔══════════════════════════╗
--   TARGET ACQUISITION
-- ╚══════════════════════════╝
local function getTarget()
    local best, bestDist = nil, Config.FOV
    local center = Camera.ViewportSize / 2

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end

        -- team filter
        if Config.TeamCheck then
            local ok, sameTeam = pcall(function()
                return plr.Team and plr.Team == LocalPlayer.Team
            end)
            if ok and sameTeam then continue end
        end

        local char = plr.Character
        if not char then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local part = char:FindFirstChild(Config.TargetPart)
            or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen or screenPos.Z < 0 then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < bestDist then
            bestDist = dist
            best     = part
        end
    end

    return best
end

-- ╔══════════════════════════╗
--   AIM LOOP
-- ╚══════════════════════════╝
RunService.RenderStepped:Connect(function()
    if not Config.Enabled then return end
    if not UserInputService:IsMouseButtonPressed(Config.AimKey) then return end

    local target = getTarget()
    if not target then return end

    local goalCF  = CFrame.new(Camera.CFrame.Position, target.Position)
    Camera.CFrame = Camera.CFrame:Lerp(goalCF, Config.Smoothing)
end)

-- ╔══════════════════════════╗
--   TOGGLE  (F key)
-- ╚══════════════════════════╝
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F then
        Config.Enabled = not Config.Enabled
        print("[Aimbot] " .. (Config.Enabled and "ON" or "OFF"))
    end
end)
