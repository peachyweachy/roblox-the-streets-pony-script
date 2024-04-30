local ScriptName = "The Streets" -- Script Name here; ex : The Streets


local request = request or syn and syn.request


local FilePath = string.gsub(ScriptName, "%s", "%%20")
local RepositoryPath = "https://raw.githubusercontent.com/peachyweachy/roblox-the-streets-pony-script/main/" .. FilePath .. "/"


local Cached = {}
function import(Name: string, ...)
    Name = string.gsub(Name, "%s", "%%20")
    if Cached[Name] then return Cached[Name] end
    
    local Url = RepositoryPath .. Name .. ".lua"
    local Response = request({Url = Url})
    
    local Source, Result = loadstring(Response.Body, Name)
    if not Source then
        return warn(Result)
    end
    
    local Success, Result, Traceback = xpcall(Source, function(Error: string)
        warn(string.format("[%s]: %s", File, string.match(Error, "%d+.+")))
        return false, Error, debug.traceback()
    end, ...)
    if not Success then return end

    Cached[Name] = Result
    return Result
end

getgenv().import = import
import "Main"
