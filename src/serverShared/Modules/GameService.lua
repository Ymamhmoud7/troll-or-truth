local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local GameService = {}
GameService.__index = GameService

local DataService = require(script.Parent.DataService)

local proximityBindable = Instance.new("BindableEvent")
local signVoteBindable = Instance.new("BindableEvent")

function GameService.new()
	local self = setmetatable({
		Timer = 0,
		Round = 0,

		Team1 = {},
		Team2 = {},

		Boosts = {},
		Slots = {},
		Traps = {},

		Votes = {
			["Team1"] = {},
			["Team2"] = {},
		},
	}, GameService)

	proximityBindable.Event:Connect(function(player, v)
		self.Slots[v.Name] = player
	end)

	signVoteBindable.Event:Connect(function(player, vote)
		self:SignVote(player, vote)
	end)

	self:Start()

	return self
end

function GameService:SetTimer(Time: number)
	self.Timer = Time
	ReplicatedStorage.GameSettings.Time.Value = Time
end

function GameService:SetState(State: string)
	ReplicatedStorage.GameSettings.State.Value = State
end

function GameService:WaitFor2Players()
	local bind = Instance.new("BindableEvent")

	repeat
		task.wait()
	until #Players:GetPlayers() >= 2
	bind:Fire()
	return bind
end

function GameService:Countdown(Time: number)
	for i = Time, 1, -1 do
		self:SetTimer(i)
		task.wait(0.9)
	end
end

function GameService:Set2Teams()
	for i, plr in Players:GetPlayers() do
		plr:AddTag("Playing")
		if i % 2 == 0 then
			table.insert(self.Team1, plr)
		else
			table.insert(self.Team2, plr)
		end
	end
end

local function getRandomOfChildren(Parent: Instance)
	return Parent:GetChildren()[math.random(1, #Parent:GetChildren())]
end

local function tpPlayer(player: Player, Target: CFrame)
	if player and player.Character and player.Character.PrimaryPart then
		player.Character:PivotTo(Target)
	end
end

function GameService:TpPlayersToTheirSpots()
	for _, plr in self.Team1 do
		tpPlayer(plr, getRandomOfChildren(workspace.BlueTeamSpawns).CFrame)
	end

	for _, plr in self.Team2 do
		tpPlayer(plr, getRandomOfChildren(workspace.RedTeamSpawns).CFrame)
	end
end

local function freeze(humanoid: Humanoid)
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false
end

local function unfreeze(humanoid: Humanoid)
	humanoid.WalkSpeed = 16
	humanoid.JumpPower = 50
	humanoid.AutoRotate = true
end

local function reverseDictionary(dictionary)
	local t = {}
	for i, v in dictionary do
		t[v] = i
	end
	return t
end

function GameService:FindEmptySlot()
	for _, v in workspace.Slots.SpawnPoints:GetChildren() do
		if v:HasTag("Taken") then
			continue
		end
		return v
	end
end

function GameService:TpUnclaimedplayers()
	local plrIndexTable = reverseDictionary(self.Slots)

	for _, plr in self.Team1 do
		if not plrIndexTable[plr] then
			local emptySlot = self:FindEmptySlot()
			plr.Character:PivotTo(emptySlot.CFrame * CFrame.new(0, 3, 0))
			freeze(plr.Character.Humanoid)
		end
	end

	for _, plr in self.Team2 do
		if not plrIndexTable[plr] then
			local emptySlot = self:FindEmptySlot()
			plr.Character:PivotTo(emptySlot.CFrame * CFrame.new(0, 3, 0))
			freeze(plr.Character.Humanoid)
		end
	end
end

local function setProximities()
	for _, v in workspace.Slots.SpawnPoints:GetChildren() do
		local proximity: ProximityPrompt = v.ProximityPrompt
		proximity.Triggered:Connect(function(playerWhoTriggered)
			if
				playerWhoTriggered
				and playerWhoTriggered.Character
				and playerWhoTriggered.Character.PrimaryPart
				and playerWhoTriggered:HasTag("Playing")
				and not playerWhoTriggered:HasTag("Taken")
			then
				proximity.Enabled = false
				playerWhoTriggered.Character:PivotTo(v.CFrame * CFrame.new(0, 3, 0))
				freeze(playerWhoTriggered.Character.Humanoid)
				proximityBindable:Fire(playerWhoTriggered, v)
				playerWhoTriggered:AddTag("Taken")
			end
		end)
	end
end

setProximities()

function GameService:EnableSlots()
	for _, v in workspace.Slots.SpawnPoints:GetChildren() do
		v.ProximityPrompt.Enabled = true
	end
end

function GameService:DisableSlots()
	for _, v in workspace.Slots.SpawnPoints:GetChildren() do
		v.ProximityPrompt.Enabled = false
	end
end

function GameService:Eliminate(player: Player)
	player:RemoveTag("Playing")
	player:RemoveTag("Taken")

	for i, plr in self.Team1 do
		if plr == player then
			table.remove(self.Team1, i)
			break
		end
	end

	player.Character.Humanoid:BreakJoints()
end

function GameService:Award(player: Player)
	player:RemoveTag("Playing")
	player:RemoveTag("Taken")

	for i, plr in self.Team1 do
		if plr == player then
			table.remove(self.Team1, i)
			break
		end
	end

	player.Character.Humanoid:BreakJoints()

	DataService.Profiles[player].Data.Gems += 10
	DataService.Profiles[player].Data.Wins += 1
end

function GameService:FreezePlayers()
	for _, plr in self.Team1 do
		freeze(plr.Character.Humanoid)
	end
	for _, plr in self.Team2 do
		freeze(plr.Character.Humanoid)
	end
end

function GameService:UnfreezePlayers()
	for _, plr in self.Team1 do
		unfreeze(plr.Character.Humanoid)
	end
	for _, plr in self.Team2 do
		unfreeze(plr.Character.Humanoid)
	end
end

function GameService:PromptVoting(enabled: boolean)
	for _, plr in self.Team1 do
		ReplicatedStorage.Remotes.Vote:FireClient(plr, enabled)
	end
	for _, plr in self.Team2 do
		ReplicatedStorage.Remotes.Vote:FireClient(plr, enabled)
	end
end

local function getEvenNumber()
	local random = Random.new(tick())
	local picked
	repeat
		picked = random:NextInteger(1, 10)
	until picked % 2 == 0
	return picked
end

local function getOddNumber()
	local random = Random.new(tick())
	local picked
	repeat
		picked = random:NextInteger(1, 10)
	until picked % 2 == 1
	return picked
end

function GameService:PickTraps()
	local odd = getOddNumber()
	local even = getEvenNumber()
	self.Traps = {
		odd,
		even,
	}
	return odd, even
end

function GameService:SendAMessageToTeam(Team, Message: string)
	for _, v in Team do
		ReplicatedStorage.Remotes.Message:FireClient(v, Message)
	end
end

function GameService:GetFinalVote()
	local team1Votes = self.Votes.Team1
	local team2Votes = self.Votes.Team2

	local final1, final2 = "", ""

	local truth1, truth2, lie1, lie2 = 0, 0, 0, 0

	for _, vote in team1Votes do
		if vote == true then
			truth1 += 1
		else
			lie1 += 1
		end
	end

	for _, vote in team2Votes do
		if vote == true then
			truth2 += 1
		else
			lie2 += 1
		end
	end

	if truth1 >= lie1 then
		final1 = "Truth"
	else
		final1 = "Lie"
	end

	if truth2 >= lie2 then
		final2 = "Truth"
	else
		final2 = "Lie"
	end

	return final1, final2
end

function GameService:ValidatePlayers()
	if RunService:IsStudio() then
		return
	end
	if #Players:GetPlayers() < 2 then
		self:SetState("Not Enough Players")
		local NotEnoughPlayers = self:WaitFor2Players()
		NotEnoughPlayers.Event:Wait()
		self:SetState("")
	end
end

function GameService:SignVote(player: Player, vote: string)
	if table.find(self.Team1, player) then
		if vote == "Truth" then
			table.insert(self.Votes.Team1, true)
		elseif vote == "Troll" then
			table.insert(self.Votes.Team1, false)
		end
	elseif table.find(self.Team2, player) then
		if vote == "Truth" then
			table.insert(self.Votes.Team2, true)
		elseif vote == "Troll" then
			table.insert(self.Votes.Team2, false)
		end
	end
end

ReplicatedStorage.Remotes.Vote.OnServerEvent:Connect(function(player: Player, vote: string)
	if not player:HasTag("Playing") then
		return
	end

	signVoteBindable:Fire(player, vote)
end)

local function mergeTables(t1, t2)
	local merged = {}
	for _, v in ipairs(t1) do
		table.insert(merged, v)
	end
	for _, v in ipairs(t2) do
		table.insert(merged, v)
	end
	return merged
end

function GameService:Start()
	-- Wait for enough players

	self:ValidatePlayers()

	-- Intermission
	self:SetState("Intermission")
	self:Countdown(10)
	self:ValidatePlayers()

	for _ = 1, 4 do
		-- Teleport Players
		self:SetState("Pick your spots!")
		self:Set2Teams()
		self:TpPlayersToTheirSpots()
		self:EnableSlots()
		self:Countdown(10)
		self:ValidatePlayers()

		-- Voting
		self:DisableSlots()
		local trap2, trap1 = self:PickTraps()
		print("Trap 1 is: " .. trap1)
		print("Trap 2 is: " .. trap2)
		self:TpUnclaimedplayers()
		self:SetState("Voting")
		self:PromptVoting(true)
		self:ValidatePlayers()

		-- Repicking Spots
		self.Slots = {}
		self:SendAMessageToTeam(self.Team1, trap2)
		self:SendAMessageToTeam(self.Team2, trap1)
		self:Countdown(15)
		local t1Vote, t2Vote = self:GetFinalVote()
		print("Team 1 voted: " .. t1Vote)
		print("Team 2 voted: " .. t2Vote)
		self:PromptVoting(false)
		self:EnableSlots()
		self:TpPlayersToTheirSpots()
		self:SetState("Pick your spots!")
		self:UnfreezePlayers()
		for _, v in Players:GetPlayers() do
			v:RemoveTag("Taken")
		end
		local trap1Instance, trap2Instance =
			workspace.Slots.SpawnPoints:FindFirstChild(tostring(trap1)).Glass,
			workspace.Slots.SpawnPoints:FindFirstChild(tostring(trap2)).Glass
		print(trap1Instance, trap2Instance)

		for _, v in workspace.Slots.SpawnPoints:GetChildren() do
			v.Glass.Color = Color3.fromRGB(163, 162, 165)
		end

		if t1Vote == "Truth" then
			if trap1Instance then
				trap1Instance.BrickColor = BrickColor.new("Bright red")
			end
		else
			for _, v in workspace.Slots.SpawnPoints:GetChildren() do
				if v == trap1Instance.Parent then
					continue
				end
				if tonumber(v.name) % 2 == 1 then
					continue
				end
				v.Glass.BrickColor = BrickColor.new("Really red")
				return
			end
		end

		if t2Vote == "Truth" then
			if trap2Instance then
				trap2Instance.BrickColor = BrickColor.new("Bright red")
			end
		else
			for _, v in workspace.Slots.SpawnPoints:GetChildren() do
				if v == trap2Instance.Parent then
					continue
				end
				if tonumber(v.name) % 2 == 0 then
					continue
				end
				v.Glass.BrickColor = BrickColor.new("Really red")
				return
			end
		end
		self:Countdown(10)
		-- Revealing Answers
		self:ValidatePlayers()
		self:DisableSlots()
		self:TpUnclaimedplayers()
		self:SetState("Revealing Answers")
		self:Countdown(5)
		self:ValidatePlayers()

		for _, v in workspace.Slots.SpawnPoints:GetChildren() do
			v.Glass.Color = Color3.fromRGB(163, 162, 165)
		end

		trap1Instance.BrickColor = BrickColor.new("Bright red")
		trap1Instance.Material = Enum.Material.Neon

		trap2Instance.BrickColor = BrickColor.new("Bright red")
		trap2Instance.Material = Enum.Material.Neon

		local loser1, loser2 = self.Slots[tostring(trap1)], self.Slots[tostring(trap2)]

		if loser1 then
			self:Eliminate(loser1)
		end

		if loser2 then
			self:Eliminate(loser2)
		end
	end

	local winners = mergeTables(self.Team1, self.Team2)

	for _, plr in winners do
		self:Award(plr)
	end
end

return GameService.new()
