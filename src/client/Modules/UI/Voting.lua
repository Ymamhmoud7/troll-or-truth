local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes

local Player = Players.LocalPlayer
local PlayerUI = Player:WaitForChild("PlayerGui")

local UIManager = require(script.Parent.Parent.UIManager)

local Voting = PlayerUI:WaitForChild("Voting")
local Panel = UIManager.new(Voting.ImageLabel)

Panel.Children.Troll.Activated:Connect(function()
	Remotes.Vote:FireServer("Troll")
	Panel:Close()
end)

Panel.Children.Truth.Activated:Connect(function()
	Remotes.Vote:FireServer("Truth")
	Panel:Close()
end)

Remotes.Message.OnClientEvent:Connect(function(trap: string)
	for _, v in workspace.Slots.SpawnPoints:GetChildren() do
		if v:FindFirstChild("BillboardGui") then
			v.BillboardGui.Enabled = false
		end
	end
	if trap then
		for _, x in trap do
			local trapInst = workspace.Slots.SpawnPoints:FindFirstChild(x)
			if trapInst then
				trapInst.BillboardGui.Enabled = true
				trapInst.BillboardGui.TextLabel.Text = "⬇️"
			end
		end
	end
end)

Remotes.Hints.OnClientEvent:Connect(function(enabled: boolean, trap: number?)
	print(enabled, trap)
	if enabled == true then
		local trapInst = workspace.Slots.SpawnPoints:FindFirstChild(trap)
		local highlight = Instance.new("Highlight")
		highlight.Parent = trapInst
		highlight.FillTransparency = 1
	else
		for _, v: Highlight in workspace.Slots.SpawnPoints:GetDescendants() do
			if v:IsA("Highlight") then
				v:Destroy()
			end
		end
	end
end)

Remotes.Vote.OnClientEvent:Connect(function(x: boolean)
	if x == true then
		Panel:Open()
	else
		Panel:Close()
	end
end)

return {}
