local Modules = script.Parent.Modules

for _, module in Modules:GetDescendants() do
    if module:IsA("ModuleScript") then
        require(module)
    end
end