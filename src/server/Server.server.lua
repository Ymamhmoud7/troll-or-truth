local ServerStorage = game:GetService("ServerStorage")

for _, v in ServerStorage.Modules:GetChildren() do
    if v:IsA("ModuleScript") then
        require(v)
    end
end