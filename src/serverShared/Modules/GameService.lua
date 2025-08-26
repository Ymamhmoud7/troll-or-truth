local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameService = {}
GameService.__index = GameService

local proximityBindable = Instance.new("BindableEvent")

function GameService.new()
    local self = setmetatable({
        Timer = 0;
        Round = 0;
        
        Team1 = {};
        Team2 = {};
        
        Boosts = {};
        Slots = {};
        Traps = {};

        Votes = {
            ["Team1"] = {};
            ["Team2"] = {};
        };

    }, GameService)

    proximityBindable.Event:Connect(function(player, v)
        self.Slots[v.Name] = player
    end)

    self:Start()

    return self
end

function GameService:SetTimer(Time : number)
    self.Timer = Time
    ReplicatedStorage.GameSettings.Time.Value = Time
end

function GameService:SetState(State : string)
    ReplicatedStorage.GameSettings.State.Value = State
end

function GameService:WaitFor2Players()
    local bind = Instance.new('BindableEvent')

    repeat
        task.wait()
    until #Players:GetPlayers() >= 2
    bind:Fire()
    return bind
end

function GameService:Countdown(Time : number)
    for i = Time,1,-1 do
        self:SetTimer(i)
        task.wait(.9)
    end
end

function GameService:Set2Teams()
    for i, plr in Players:GetPlayers() do
        if i%2 == 0 then
            table.insert(self.Team1, plr)
        else
            table.insert(self.Team2, plr)
        end
    end

end

local function getRandomOfChildren(Parent: Instance)
    return Parent:GetChildren()[math.random(1,#Parent:GetChildren())]
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
            plr.Character:PivotTo(emptySlot.CFrame * Vector3.new(0,3,0))
            freeze(plr.Character.Humanoid)
        end
    end

    for _, plr in self.Team2 do
        if not plrIndexTable[plr] then
            local emptySlot = self:FindEmptySlot()
            plr.Character:PivotTo(emptySlot.CFrame * Vector3.new(0,3,0))
            freeze(plr.Character.Humanoid)
        end
    end
end

local function setProximities()
    for _, v in workspace.SpawnPoints do
        local proximity: ProximityPrompt = v.ProximityPrompt
        proximity.Triggered:Connect(function(playerWhoTriggered)
            if playerWhoTriggered and playerWhoTriggered.Character and playerWhoTriggered.Character.PrimaryPart and playerWhoTriggered:HasTag("Playing") then
                playerWhoTriggered.Character:PivotTo(v.CFrame * CFrame.new(0,3,0))
                freeze(playerWhoTriggered.Character.Humanoid)
                proximityBindable:Fire(playerWhoTriggered, v)
            end
        end)
    end
end

setProximities()

function GameService:EnableSlots()
    for _, v in workspace.SpawnPoints do
        v.ProximityPrompt.Enabled = true
    end
end

function GameService:DisableSlots()
    for _, v in workspace.SpawnPoints do
        v.ProximityPrompt.Enabled = false
    end
end

function GameService:Eliminate()
    
end

function GameService:Award()
    
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

function GameService:PromptVoting()
    for _, plr in self.Team1 do
        ReplicatedStorage.Remotes.Vote:FireClient(plr)
    end
    for _, plr in self.Team2 do
        ReplicatedStorage.Remotes.Vote:FireClient(plr)
    end
end

local function getEvenNumber()
    local random = Random.new(tick)
    local picked
    repeat
        picked = random:NextInteger(1,12)
    until picked%2 == 0
    return picked
end

local function getOddNumber()
    local random = Random.new(tick)
    local picked
    repeat
        picked = random:NextInteger(1,12)
    until picked%2 == 1
    return picked
end

function GameService:PickTraps()
    local odd = getOddNumber()
    local even = getEvenNumber()
    self.Traps = {
        odd, even
    }
    return odd, even
end

function GameService:GetFinalVote()
    local team1Votes = self.Votes.Team1
    local team2Votes = self.Votes.Team2

    local final1, final2 = '', ''

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
        final1 = 'Truth'
    else
        final1 = "Lie"
    end

    if truth2 >= lie2 then
        final2 = 'Truth'
    else
        final2 = "Lie"
    end

    return final1, final2
end


function GameService:Start()
    
    -- if #Players:GetPlayers() < 2 then
    --     self:SetState("Not Enough")
    --     local NotEnoughPlayers = self:WaitFor2Players()
    --     NotEnoughPlayers.Event:Wait()
    --     self:SetState("")
    -- end


    -- Intermission
    self:SetState("Intermission")
    self:Countdown(10) 
    print('hello world')

    -- Teleport Players
    self:SetState("Phase1")
    self:Set2Teams()
    self:TpPlayersToTheirSpots()

    self:EnableSlots()

    self:Countdown(10)
    self:PickTraps()
    self:TpUnclaimedplayers()
    self:SetState("Voting")
    self:PromptVoting()

    -- Revealing Answers
    -- Letting players change the spots
    -- Revealing True Answers
    
    -- Next Round Starts
end

return GameService.new()