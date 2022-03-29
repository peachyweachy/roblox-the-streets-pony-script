# identification-dev
Development of Identification.cc

# Loader.lua
```lua
local AuthToken = [[]]
local ScriptName = "The Streets" -- Script Name here; ex : The Streets


local request = request or syn and syn.request


local FilePath = string.gsub(ScriptName, "%s", "%%20")
local RepositoryPath = "https://" .. AuthToken .. "@raw.githubusercontent.com/RegularID/identification-dev/main/" .. FilePath .. "/"

function Import(Name)
    local Name = string.gsub(Name, "%s", "%%20") -- Replacing Spaces with %20's
    local Url = RepositoryPath .. Name .. ".lua"
    local Response = request({Url = Url})
    return loadstring(Response.Body)()
end

getgenv().Import = Import
Import("Source")
```

![image](https://user-images.githubusercontent.com/69537751/160294247-419c071c-dcfd-4f13-a557-3616b0ba8205.png)
