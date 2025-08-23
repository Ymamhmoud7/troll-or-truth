local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Spring = require(ReplicatedStorage.Libraries.Spring)

local UIManager = {}
UIManager.__index = UIManager

function UIManager.new(Frame: Frame, openButton: GuiButton?, closeButton: GuiButton?)
    local UIScale = Frame:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
    UIScale.Parent = Frame
    UIScale.Scale = 0

    local ScaleSpring = Spring.new(0)
    ScaleSpring.Speed = 350

    local Spring_Connection = RunService.RenderStepped:Connect(function(deltaTime)
        UIScale.Scale = ScaleSpring:Update(deltaTime)            
    end)
    
    local self = setmetatable({
        OpenButton = openButton;
        CloseButton = closeButton;
        UIScale = UIScale;
        Spring_Connection = Spring_Connection;
        Frame = Frame;
        Spring = ScaleSpring;
        Visible = false;
    }, UIManager)

    if openButton then
        if openButton:IsA("GuiButton") then
            openButton.Activated:Connect(function()
                if self.Visible == false then
                    self:Open()
                else
                    self:Close()
                end
            end)
        end
    end

    if closeButton then
        if closeButton:IsA("GuiButton") then
            closeButton.Activated:Connect(function()
                self:Close()
            end)
        end
    end

    return self
end

function UIManager:Open()
    self.Spring.Speed = 350
    self.Spring.Damping = 0.8
    self.Spring.Target = 1
    self.Visible = true
end

function UIManager:Close()
    self.Spring.Speed = 3000
    self.Spring.Damping = 0.1
    self.Spring.Target = 0
    self.Visible = false
end

return UIManager