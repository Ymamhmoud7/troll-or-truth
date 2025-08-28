local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local MarketPlaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameSettings = ReplicatedStorage.GameSettings
local TimeValue = GameSettings:WaitForChild("Time") :: NumberValue
local StateValue = GameSettings:WaitForChild("State") :: StringValue
local RoundValue = GameSettings:WaitForChild("Round") :: NumberValue

local Configs = ReplicatedStorage.Configs
local Libraries = ReplicatedStorage.Libraries

local Market = require(Configs.Market)
local Spring = require(Libraries.Spring)

local Player = Players.LocalPlayer
local leaderstats = Player:WaitForChild("leaderstats")
local PlayerUI = Player.PlayerGui
local HUD = PlayerUI:WaitForChild("HUD")

local Phase = HUD.Phase
local CurrentRound = HUD.CurrentRound

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

local PhaseSprrinSize = {
	X = Spring.new(Phase.Size.X.Scale),
	Y = Spring.new(Phase.Size.Y.Scale),
}

local PhaseSpringPosition = {
	X = Spring.new(Phase.Position.X.Scale),
	Y = Spring.new(Phase.Position.Y.Scale),
}

local CurrentRoundSpringPosition = {
	X = Spring.new(CurrentRound.Position.X.Scale),
	Y = Spring.new(CurrentRound.Position.Y.Scale),
}

local CurrentRoundSpringSize = {
	X = Spring.new(CurrentRound.Size.X.Scale),
	Y = Spring.new(CurrentRound.Size.Y.Scale),
}

PhaseSpringPosition.X.Speed = 300
PhaseSpringPosition.Y.Speed = 300
CurrentRoundSpringPosition.X.Speed = 300
CurrentRoundSpringPosition.Y.Speed = 300
CurrentRoundSpringSize.X.Speed = 300
CurrentRoundSpringSize.Y.Speed = 300
PhaseSprrinSize.X.Speed = 300
PhaseSprrinSize.Y.Speed = 300

function switchMode(mode: number)
	if mode == 1 then --> Both are visible
		PhaseSprrinSize.X.Target = 0.24
		PhaseSprrinSize.Y.Target = 0.172

		PhaseSpringPosition.X.Target = 0.424
		PhaseSpringPosition.Y.Target = 0.009

		CurrentRoundSpringPosition.X.Target = 0.219
		CurrentRoundSpringPosition.Y.Target = 0.009

		CurrentRoundSpringSize.X.Target = 0.193
		CurrentRoundSpringSize.Y.Target = 0.148
	elseif mode == 2 then --> Only Phase is visible
		PhaseSprrinSize.X.Target = 0.358
		PhaseSprrinSize.Y.Target = 0.172

		PhaseSpringPosition.X.Target = 0.321
		PhaseSpringPosition.Y.Target = 0.015

		CurrentRoundSpringPosition.X.Target = CurrentRound.Position.X.Scale
		CurrentRoundSpringPosition.Y.Target = CurrentRound.Position.Y.Scale

		CurrentRoundSpringSize.X.Target = 0
		CurrentRoundSpringSize.Y.Target = 0
	elseif mode == 3 then --> Only CurrentRound is visible
		PhaseSprrinSize.X.Target = 0
		PhaseSprrinSize.Y.Target = 0

		PhaseSpringPosition.X.Target = Phase.Position.X.Scale
		PhaseSpringPosition.Y.Target = Phase.Position.Y.Scale

		CurrentRoundSpringPosition.X.Target = 0.403
		CurrentRoundSpringPosition.Y.Target = 0.02

		CurrentRoundSpringSize.X.Target = 0.193
		CurrentRoundSpringSize.Y.Target = 0.148
	else
		warn(`Invalid mode: {mode}`)
	end
end

RunService.RenderStepped:Connect(function(deltaTime)
	Phase.Size = UDim2.fromScale(PhaseSprrinSize.X:Update(deltaTime), PhaseSprrinSize.Y:Update(deltaTime))
	Phase.Position = UDim2.fromScale(PhaseSpringPosition.X:Update(deltaTime), PhaseSpringPosition.Y:Update(deltaTime))
	CurrentRound.Position =
		UDim2.fromScale(CurrentRoundSpringPosition.X:Update(deltaTime), CurrentRoundSpringPosition.Y:Update(deltaTime))
	CurrentRound.Size =
		UDim2.fromScale(CurrentRoundSpringSize.X:Update(deltaTime), CurrentRoundSpringSize.Y:Update(deltaTime))

	Phase.TextLabel.Text = if StateValue.Value == "Not Enough Players"
		then `{StateValue.Value}`
		else `{StateValue.Value} ({TimeValue.Value})`
	CurrentRound.TextLabel.Text = `Round {RoundValue.Value}/4`
	if StateValue.Value == "Intermission" or StateValue.Value == "Not Enough Players" then
		switchMode(2)
	else
		switchMode(1)
	end
end)

local HUDSharedTable = {}

HUDSharedTable["SwitchMode"] = switchMode

return HUDSharedTable
