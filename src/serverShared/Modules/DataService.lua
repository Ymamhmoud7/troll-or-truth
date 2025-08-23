local Players = game:GetService("Players")
local ReplciatedStorage = game:GetService("ReplicatedStorage")

local FormatNumber = require(ReplciatedStorage.Libraries["FormatNumber 31.1"].Simple)
local ProfileService = require(ReplciatedStorage.Libraries.ProfileService)
local DataConfig = require(ReplciatedStorage.Configs.Data)

local DataStore = ProfileService.GetProfileStore(
    DataConfig._settings.DataName,
    DataConfig.Template
)

local DataService = {}
DataService.Profiles = {}

function DataService:UpdateLeaderstats(player: Player)
    local leaderstats = player:WaitForChild("leaderstats")

    local Data = DataService.Profiles[player].Data

    for i, v in DataConfig.leaderstats do
        if v.Type == 'string' then
            local Value = leaderstats:FindFirstChild(i)
            Value.Value = FormatNumber.FormatCompact(Data[v.DataName])
        end
    end
end

local function load(player: Player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = 'leaderstats'
    leaderstats.Parent = player

    local Data = DataService.Profiles[player].Data

    for i, v in DataConfig.leaderstats do
        if v.Type == 'string' then
            local Value = Instance.new("StringValue")
            Value.Parent = leaderstats
            Value.Name = i
            Value.Value = FormatNumber.FormatCompact(Data[v.DataName])
        end
    end
end

local function playerAdded(player: Player)
    local profile = DataStore:LoadProfileAsync(player.UserId.."_key")
    if profile ~= nil then
        profile:AddUserId(player.UserId)
        profile:Reconcile()
        profile:ListenToRelease(function()
            DataService.Profiles[player] = nil
            player:Kick("Data Load Error")
        end)

        if player:IsDescendantOf(Players) then
            DataService.Profiles[player] = profile
            load(player)
            -- Load
        else
            profile:Release()
        end
    else
        player:Kick()
    end
end

for _, plr in Players:GetPlayers() do
    task.spawn(playerAdded, plr)
end

Players.PlayerAdded:Connect(function(player)
    playerAdded(player)
end)

Players.PlayerRemoving:Connect(function(player)
    if DataService.Profiles[player] then
        DataService.Profiles[player]:Release()
    end
end)

return DataService