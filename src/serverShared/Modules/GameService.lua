local MarketplaceService = game:GetService("MarketplaceService")
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

	Players.PlayerRemoving:Connect(function(player)
		-- Remove from Team1 if present
		for i, plr in ipairs(self.Team1) do
			if plr == player then
				table.remove(self.Team1, i)
				break
			end
		end
		-- Remove from Team2 if present
		for i, plr in ipairs(self.Team2) do
			if plr == player then
				table.remove(self.Team2, i)
				break
			end
		end
	end)

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
		local player = Players:GetPlayerByUserId(userId)
		print(player, productId, isPurchased)
		if isPurchased then
			if productId == 3390064882 then
				self["AddTimes"] = true
			elseif productId == 3390065191 then
				self:HideVotes()
			elseif productId == 3390065347 then
				self:AddTrap(player)
			elseif productId == 3390065501 then
				self:GiveHint(player)
			end
		end
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
	repeat
		task.wait()
	until #Players:GetPlayers() >= 2
end

function GameService:Countdown(Time: number)
	local all = Time
	repeat
		all -= 1
		self:SetTimer(all)
		if self["AddTimes"] then
			print("a")
			self["AddTimes"] = nil
			all += 10
		end
		task.wait(0.9)
	until all <= 0
end

function GameService:Set2Teams()
	for i, plr: Player in Players:GetPlayers() do
		plr:AddTag("Playing")
		if i % 2 == 1 then
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

-- Blue Teamn --> Team 1
-- Red Team --> Team 2

function GameService:TpPlayersToTheirSpots()
	for _, plr in self.Team1 do
		tpPlayer(plr, getRandomOfChildren(workspace.BlueTeamSpawns).CFrame)
	end

	for _, plr in self.Team2 do
		tpPlayer(plr, getRandomOfChildren(workspace.RedTeamSpawns).CFrame)
	end
end

local function freeze(humanoid: Humanoid)
	if not humanoid then
		return
	end
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false
end

local function unfreeze(humanoid: Humanoid)
	if not humanoid then
		return
	end
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

function GameService:FindEmptySlot(teamNumber)
	for _, v in workspace.Slots.SpawnPoints:GetChildren() do
		local slotNum = tonumber(v.Name)
		if not slotNum then
			warn("Slot name is not a number:", v.Name)
			continue
		end

		if self.Slots[v.Name] then
			continue
		end

		if v:HasTag("Taken") then
			continue
		end

		if teamNumber == 1 and slotNum % 2 == 0 then
			continue
		elseif teamNumber == 2 and slotNum % 2 == 1 then
			continue
		end

		return v
	end
end

function GameService:TpUnclaimedplayers()
	local plrIndexTable = reverseDictionary(self.Slots)

	for _, plr in self.Team1 do
		if not plrIndexTable[plr] then
			local emptySlot = self:FindEmptySlot(2)
			emptySlot:AddTag("Taken")
			plr.Character:PivotTo(emptySlot.CFrame * CFrame.new(0, 3, 0))
			freeze(plr.Character.Humanoid)
		end
	end

	for _, plr in self.Team2 do
		if not plrIndexTable[plr] then
			local emptySlot = self:FindEmptySlot(1)
			emptySlot:AddTag("Taken")

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
				v:AddTag("Taken")
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
	for i, plr in self.Team1 do
		if plr == player then
			table.remove(self.Team1, i)
			break
		end
	end

	for i, plr in self.Team2 do
		if plr == player then
			table.remove(self.Team2, i)
			break
		end
	end
	unfreeze(player.Character.Humanoid)
	player:RemoveTag("Playing")
	player:RemoveTag("Taken")
	player.Character:PivotTo(workspace.Lobby.Spawns.SpawnLocation.CFrame * CFrame.new(0, 3, 0))
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
	unfreeze(player.Character.Humanoid)
	player.Character:PivotTo(workspace.Lobby.Spawns.SpawnLocation.CFrame * CFrame.new(0, 3, 0))

	DataService.Profiles[player].Data.Gems += 1000
	DataService.Profiles[player].Data.Wins += 1
	DataService:UpdateLeaderstats(player)
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

local function getUniqueNumber(used, parity)
	local random = Random.new(os.clock() * 1000)
	local picked

	repeat
		picked = random:NextInteger(1, 10)
	until (picked % 2 == parity) and not used[picked]

	used[picked] = true
	return picked
end

function GameService:PickTraps(amnt: number)
	local oddTraps = {}
	local evenTraps = {}
	local used = {}

	for i = 1, amnt do
		local parity = (i % 2 == 1) and 1 or 0
		local trap = getUniqueNumber(used, parity)

		if parity == 1 then
			table.insert(oddTraps, trap)
		else
			table.insert(evenTraps, trap)
		end
	end

	self.Traps = { oddTraps, evenTraps }
	print(self.Traps)
	return oddTraps, evenTraps
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
		for _, plr in Players:GetPlayers() do
			plr:RemoveTag("Playing")
			plr:RemoveTag("Taken")
			plr.Character:PivotTo(workspace.Lobby.Spawns.SpawnLocation.CFrame * CFrame.new(0, 3, 0))
		end
		self.Team1 = {}
		self.Team2 = {}
		self.Votes = {
			["Team1"] = {},
			["Team2"] = {},
		}
		self.Traps = {}
		self.Slots = {}
		self:SetState("Not Enough Players")
		self:WaitFor2Players()
		self:SetState("")
		return true
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

function GameService:AddTime(time: number)
	self.Timer += time
end

function GameService:GiveHint(Player: Player)
	if self.Round ~= 3 then
		return
	end
	local isTeam1, isTeam2 = table.find(self.Team1, Player), table.find(self.Team2, Player)
	if isTeam1 then
		for _, v in self.Traps do
			if v % 2 == 0 then
				continue
			end
			ReplicatedStorage.Remotes.Hints:FireClient(Player, true, v)
			return
		end
	elseif isTeam2 then
		for _, v in self.Traps do
			if v % 2 == 1 then
				continue
			end
			ReplicatedStorage.Remotes.Hints:FireClient(Player, true, v)
			return
		end
	end
end

function GameService:RemoveHints()
	ReplicatedStorage.Remotes.Hints:FireAllClients(false)
end

function GameService:HideVotes()
	if self.Boosts["HideVotes_used"] then
		return
	end
	if self.Round == 2 or self.Round == 3 then
		return
	end
	self.Boosts["HideVotes_used"] = true
	self.Boosts["HideVotes"] = true
	ReplicatedStorage.GameSettings.HideVotesDisabled.Value = true
end

function GameService:AddTrap(Player: Player)
	if self.Round ~= 3 then
		return
	end
	if self["TrapsDisabled"] then
		return
	end
	if self["TrapUsed"] then
		return
	end
	local isTeam1 = table.find(self.Team1, Player)
	local isTeam2 = table.find(self.Team2, Player)

	if isTeam1 then
		local trap = getUniqueNumber(self.UsedTraps, 0)
		table.insert(self.Traps[2], trap)
		return trap
	elseif isTeam2 then
		local trap = getUniqueNumber(self.UsedTraps, 1)
		table.insert(self.Traps[1], trap)
		return trap
	end

	ReplicatedStorage.GameSettings.TrapsDisabled.Value = true
	self["TrapUsed"] = true
end

function GameService:Start()
	while true do
		-- Wait for enough players
		ReplicatedStorage.GameSettings.Round.Value = 0
		self:ValidatePlayers()

		-- Intermission
		self:SetState("Intermission")
		self:Countdown(10)
		self:ValidatePlayers()
		self:Set2Teams()

		for i = 1, 6 do
			if i <= 2 then
				ReplicatedStorage.GameSettings.TrapsDisabled.Value = true
				self["TrapsDisabled"] = true
			else
				ReplicatedStorage.GameSettings.TrapsDisabled.Value = false
				self["TrapsDisabled"] = nil
			end
			self.Round = i
			ReplicatedStorage.GameSettings.Round.Value = i
			-- Teleport Players
			self:SetState("Pick your spots!")
			self:TpPlayersToTheirSpots()
			self:EnableSlots()
			self:Countdown(10)
			if self:ValidatePlayers() == true then
				break
			end

			-- Voting
			self:DisableSlots()
			local trapamnt
			if i == 1 or i == 2 then
				trapamnt = 2
			elseif i == 3 or i == 4 then
				trapamnt = 3
			elseif i == 5 then
				trapamnt = 4
			elseif i == 6 then
				trapamnt = 5
			end
			local trap1, trap2 = self:PickTraps(trapamnt)
			self:TpUnclaimedplayers()
			self:SetState("Voting")
			self:PromptVoting(true)
			if self:ValidatePlayers() == true then
				break
			end
			-- Repicking Spots
			self.Slots = {}
			self:SendAMessageToTeam(self.Team1, trap1)
			self:SendAMessageToTeam(self.Team2, trap2)
			self:Countdown(15)
			local t1Vote, t2Vote = self:GetFinalVote()

			self:PromptVoting(false)
			self:EnableSlots()
			self:TpPlayersToTheirSpots()
			self:SetState("Pick your spots!")
			self:UnfreezePlayers()
			for _, v in Players:GetPlayers() do
				v:RemoveTag("Taken")
			end
			for _, v in workspace.Slots.SpawnPoints:GetChildren() do
				v:RemoveTag("Taken")
			end

			for _, v in workspace.Slots.SpawnPoints:GetChildren() do
				v.Glass.Color = Color3.fromRGB(163, 162, 165)
			end
			if not self.Boosts["HideVotes"] then
				for _, t1 in trap1 do
					local trap1Instance = workspace.Slots.SpawnPoints:FindFirstChild(tostring(t1)).Glass
					if t1Vote == "Truth" then
						if trap1Instance then
							trap1Instance.BrickColor = BrickColor.new("Bright red")
						else
							for _, v in workspace.Slots.SpawnPoints:GetChildren() do
								if v == trap1Instance.Parent then
									continue
								end
								if tonumber(v.name) % 2 == 0 then
									continue
								end
								v.Glass.BrickColor = BrickColor.new("Really red")
								break
							end
						end
					end
				end
				for _, t2 in trap2 do
					local trap2Instance = workspace.Slots.SpawnPoints:FindFirstChild(tostring(t2)).Glass
					if t2Vote == "Truth" then
						if trap2Instance then
							trap2Instance.BrickColor = BrickColor.new("Bright red")
						end
					else
						for _, v in workspace.Slots.SpawnPoints:GetChildren() do
							if v == trap2Instance.Parent then
								continue
							end
							if tonumber(v.name) % 2 == 1 then
								continue
							end

							v.Glass.BrickColor = BrickColor.new("Really red")
							break
						end
					end
				end
			end

			self.Boosts["HideVotes"] = nil

			self:Countdown(10)
			-- Revealing Answers
			if self:ValidatePlayers() == true then
				break
			end
			self:DisableSlots()
			self:TpUnclaimedplayers()
			self:SetState("Revealing Answers")
			self:Countdown(5)
			self:RemoveHints()
			if self:ValidatePlayers() == true then
				break
			end
			for _, v in workspace.Slots.SpawnPoints:GetChildren() do
				v.Glass.Color = Color3.fromRGB(163, 162, 165)
			end

			for _, t1 in trap1 do
				local trap1Instance = workspace.Slots.SpawnPoints:FindFirstChild(tostring(t1)).Glass
				if trap1Instance then
					trap1Instance.BrickColor = BrickColor.new("Bright red")
					trap1Instance.Material = Enum.Material.Neon
				end
			end

			for _, t2 in trap2 do
				local trap2Instance = workspace.Slots.SpawnPoints:FindFirstChild(tostring(t2)).Glass
				if trap2Instance then
					trap2Instance.BrickColor = BrickColor.new("Bright red")
					trap2Instance.Material = Enum.Material.Neon
				end
			end

			local loser1, loser2 = self.Slots[tostring(trap1)], self.Slots[tostring(trap2)]

			if loser1 then
				self:Eliminate(loser1)
			end

			if loser2 then
				self:Eliminate(loser2)
			end

			self:SetState("Eliminating Losers")
			self:Countdown(5)
			if self:ValidatePlayers() == true then
				break
			end
			for _, v in workspace.Slots.SpawnPoints:GetChildren() do
				v.Glass.Color = Color3.fromRGB(163, 162, 165)
				v.Glass.Material = Enum.Material.Glass
			end

			self:SendAMessageToTeam(self.Team1)
			self:SendAMessageToTeam(self.Team2)
			if #self.Team1 <= 0 then
				break
			end

			if #self.Team2 <= 0 then
				break
			end

			if i >= 4 then
				break
			end

			self:TpPlayersToTheirSpots()
			self:UnfreezePlayers()
			self:SetState("Round Over, Starting the next in moments!")
			self:Countdown(5)
			if self:ValidatePlayers() == true then
				break
			end
			self.Votes = {
				["Team1"] = {},
				["Team2"] = {},
			}
			self.Traps = {}
			self.Slots = {}
			self.Boosts = {}
			self["TrapsDisabled"] = nil
			self["TrapUsed"] = nil
			for _, v in Players:GetPlayers() do
				v:RemoveTag("Taken")
			end
			for _, v in workspace.Slots.SpawnPoints:GetChildren() do
				v:RemoveTag("Taken")
			end
		end

		local winners = mergeTables(self.Team1, self.Team2)

		for _, plr in winners do
			print(plr, "Winner!")
			self:Award(plr)
		end
	end
end

return GameService.new()
