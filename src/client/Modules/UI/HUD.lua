local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Configs = ReplicatedStorage.Configs

local Market = require(Configs.Market)

local Player = Players.LocalPlayer
local leaderstats = Player:WaitForChild("leaderstats")
local PlayerUI = Player.PlayerGui
local HUD = PlayerUI:WaitForChild("HUD")

local Left = HUD.left

Left.Invite.Activated:Connect(function()
    SocialService:PromptGameInvite(Player)
end)

for _, v in PlayerUI:GetDescendants() do
    if v:IsA("GuiButton") then
        local isGamepass = v:HasTag("Gamepass")
        local isProduct = v:HasTag("Product")

        if isGamepass then
            MarketPlaceService:PromptGamePassPurchase(Player, Market.Gamepasses[v.Name])
        elseif isProduct then
            MarketPlaceService:PromptProductPurchase(Player, Market.Products[v.Name])
        end
    end
end

local Gems = leaderstats:WaitForChild("Gems") :: StringValue
Gems.Changed:Connect(function(value)
    HUD.diamonds.TextLabel.Text = value
end)
HUD.diamonds.TextLabel.Text = Gems.Value

return {}