local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Spring = require(ReplicatedStorage.Libraries.Spring)

local Player = Players.LocalPlayer
local PlayerUI = Player.PlayerGui

local function animateButton(button: GuiButton)
    if button:IsA("GuiButton") then
        
        local UIScale = button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
        UIScale.Parent = button
        UIScale.Scale = 1

        local ScaleSpring = Spring.new(1)
        ScaleSpring.Speed = 300

        local Spring_Connection = RunService.RenderStepped:Connect(function(deltaTime)
            UIScale.Scale = ScaleSpring:Update(deltaTime)            
        end)

        button.MouseEnter:Connect(function()
            ScaleSpring.Target = 1.1
        end)
    
        button.MouseLeave:Connect(function()
            ScaleSpring.Target = 1.0
        end)

        button.MouseButton1Down:Connect(function()
            ScaleSpring.Target = 1.2
        end)

        button.MouseButton1Up:Connect(function()
            ScaleSpring.Target = 1.1
        end)

        button.Destroying:Connect(function()
            Spring_Connection:Disconnect()
        end)
    end
end

for _, v in PlayerUI:GetDescendants() do
    animateButton(v)
end

PlayerUI.DescendantAdded:Connect(function(descendant)
    animateButton(descendant)
end)

return {}