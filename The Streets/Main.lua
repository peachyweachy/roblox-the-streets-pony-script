-- Fake Roblex : 6029419 && Roblex : 6029417 && Platinum Rolex : 6094781
-- Original cash timer 10$ every 1 minute or 14440 cash every day

-- Variables

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Time = os.clock()

-- Original values maybe different for some remakes but I'm too lazy to add support for that
local ORIGINAL_GRAVITY = workspace.Gravity

local ORIGINAL_SPEED = 0 -- if this gets read first before write then umm :rainbow_dash_idk_3:
local ORIGINAL_HIPHEIGHT = 2
local ORIGINAL_JUMPPOWER = game:GetService("StarterPlayer").CharacterJumpPower

local script_name = "ponyhook"
local script_version

local Stats = game:GetService("Stats")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInput = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local Marketplace = game:GetService("MarketplaceService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ScriptContext = game:GetService("ScriptContext")
local ContextAction = game:GetService("ContextActionService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local request = request or syn and syn.request or http and http.request
local get_custom_asset = getcustomasset or syn and getsynasset
local queue_on_teleport = queue_on_teleport or syn and syn.queue_on_teleport
local get_script_version = function()
    local Response = request({Url = "https://api.github.com/repos/peachyweachy/roblox-the-streets-pony-script/commits"})
    if Response.StatusCode == 200 then
        return HttpService:JSONDecode(Response.Body)[1].sha
    end

    return script_version
end

script_version = get_script_version()
if not import then return messagebox("Error 0x5; Something went wrong with initializing the script (couldn't load modules)", script_name .. ".cc", 0) end

local ESP
local Menu
local Utils
local Enums
local Raycast
local Network
local Configs
local Commands
local ToolData
local DoorData
local Lighting
local UserTable
local TimerClass
local PlayerManager

-- Importing the modules and yielding until they are loaded

task.spawn(function() ESP = import("Libraries/ESP") end)
task.spawn(function() Menu = import("Libraries/Menu") end)
task.spawn(function() Enums = import("Enums") end)
task.spawn(function() Utils = import("Utils") end)
task.spawn(function() Raycast = import("Libraries/Raycast") end)
task.spawn(function() Network = import("Network") end)
task.spawn(function() Configs = import("Configs") end)
task.spawn(function() Commands = import("Libraries/Commands") end)
task.spawn(function() ToolData = import("Tool Data") end)
task.spawn(function() DoorData = import("Door Data") end)
task.spawn(function() Lighting = import("Lighting") end)
task.spawn(function() UserTable = import("Users") end)
task.spawn(function() TimerClass = import("Libraries/TimerClass") end)
task.spawn(function() PlayerManager = import("PlayerManager") end)

while not ESP or not Menu or not Enums or not Utils or not Network or not Configs or not Raycast or not Commands or not ToolData or not DoorData or not Lighting or not UserTable or not TimerClass or not PlayerManager do task.wait() end -- waiting for the modules to load...

if (Utils.IsOriginal and game.PlaceVersion ~= 1521) or (Utils.IsPrison and game.PlaceVersion ~= 225) then
    return messagebox("Error 0x2; Script is not up to date with place version", script_name .. ".cc", 0)
end

if _G.PonyHook then
    return messagebox("Error 0x3; Script is already running", script_name .. ".cc", 0)
end

local Player = PlayerManager.LocalPlayer
local Mouse = Player:GetMouse()
local Character = Player.Character or Player.CharacterAdded:Wait()
local Head, Root, Torso, Humanoid = Character:FindFirstChild("Head"), Character:FindFirstChild("HumanoidRootPart"), Character:FindFirstChild("Torso"), Character:FindFirstChild("Humanoid")
local Backpack = Player:WaitForChild("Backpack")
local Tool = Character:FindFirstChildOfClass("Tool")
local PlayerGui, ChatFrame = Player:WaitForChild("PlayerGui"), nil
local HUD = PlayerGui and PlayerGui:WaitForChild("HUD")
local Camera = workspace.CurrentCamera

local TagSystem = Utils.IsOriginal and require(ReplicatedStorage:WaitForChild("TagSystem")) -- "creator" || "creatorslow" || "gunslow" || "action" || "Action" || "KO" || "Dragged" || "Dragging" || "reloading" || "equipedgun" || yes with 1 p he's retarded
local PostMessage = require(Player:WaitForChild("PlayerScripts", 1/0):WaitForChild("ChatScript", 1/0):WaitForChild("ChatMain", 1/0)).MessagePosted

MessageEvent = Instance.new("BindableEvent")

_G.PonyHook = true


-- Initialize Localization

local Config = Configs.Config

local Events = {FirstPerson = {}, Reset = nil}

local Items = {}
local Seats = {}
local Doors = {}
local Drawn = {}
local Windows = {}
local Animations = {}
local AudioLogs = isfile(script_name .. "/Games/The Streets/Audios.dat") and string.split(readfile(script_name .. "/Games/The Streets/Audios.dat"), "\n") or {}
local BulletLogs = {}
local DamageLogs = {} -- debounce
local Placeholder = {}
local AnimationIds = {"376653421", "458506542", "8587081257", "1484589375", "10153231863", "10153228164"}
local LastVelocityTable = {}
local HatChangerColorSequenceColorPickers = {}

local BuyPart
local Target
local TargetLock
local SelectedTarget
local HitSound
local Crosshair

local FloatPart = Instance.new("Part")
local FlyVelocity = Instance.new("BodyVelocity")
local FlyAngularVelocity = Instance.new("BodyAngularVelocity")
local BrickTrajectory = ESP.Trajectory()
local FakeLagVisualizer = ESP.Skeleton()

local AimbotIndicator
local FieldOfViewCircle = Drawing.new("Circle")

local CommandsList = ""

local Ping = 0
local SendPing = 0
local ReceivePing = 0
local LastAudio = 0
local FireTick = 0
local BulletTick = 0
local ToolEquippedTick = 0

local Buying = false
local Healing = false
local Dragged = false
local Running = false
local Dragging = false
local Spamming = false
local Crouching = false
local BarsFading = false
local Teleporting = false
local AttackDebounce = false
local RefreshingCharacter = false

local DeathPosition = CFrame.new()

do
    Events.Reset = Instance.new("BindableEvent")

    Menu.Watermark = Menu.Watermark()
    Menu.Indicators = Menu.Indicators()
    Menu.Keybinds = Menu.Keybinds()
    Menu.BoomboxFrame = Instance.new("Frame")
    Menu.Commands = Instance.new("Frame")
    Menu.CommandBar = Instance.new("TextBox")
    Menu.CommandLabels = {}

    local SubFolder = script_name .. "/Games/The Streets/"


    UserTable.Whitelisted = isfile(SubFolder .. "Whitelist.dat") and string.split(readfile(SubFolder .. "Whitelist.dat"), "\n") or {}
    UserTable.Owners = isfile(SubFolder .. "Owners.dat") and string.split(readfile(SubFolder .. "Owners.dat"), "\n") or {}

    if not isfolder(script_name) then makefolder(script_name) end
    if not isfolder(script_name .. "/Games") then makefolder(script_name .. "/Games") end
    if not isfolder(script_name .. "/Games/The Streets") then makefolder(script_name .. "/Games/The Streets") end
    if not isfolder(SubFolder .. "bin") then makefolder(SubFolder .. "bin") end
    if not isfolder(SubFolder .. "Luas") then makefolder(SubFolder .. "Luas") end
    if not isfolder(SubFolder .. "Configs") then makefolder(SubFolder .. "Configs") end
    if not isfolder(SubFolder .. "bin/sounds") then makefolder(SubFolder .. "bin/sounds") end
    if not isfolder(SubFolder .. "bin/skyboxes") then makefolder(SubFolder .. "bin/skyboxes") end
    if not isfolder(SubFolder .. "bin/crosshairs") then makefolder(SubFolder .. "bin/crosshairs") end
    if not isfolder(SubFolder .. "bin/replays") then makefolder(SubFolder .. "bin/replays") end
    if not isfolder(SubFolder .. "bin/models") then makefolder(SubFolder .. "bin/models") end

    -- We read the values before this
    writefile(SubFolder .. "Whitelist.dat", table.concat(UserTable.Whitelisted, "\n"))
    writefile(SubFolder .. "Owners.dat", table.concat(UserTable.Owners, "\n"))

    if not isfile(SubFolder .. "Spam.dat") then writefile(SubFolder .. "Spam.dat", "") end
    if not isfile(SubFolder .. "bin/sounds/hitsound.mp3") then writefile(SubFolder .. "bin/sounds/hitsound.mp3", "") end
    if not isfile(SubFolder .. "bin/crosshairs/crosshair.png") then writefile(SubFolder .. "bin/crosshairs/crosshair.png", "") end
    if not isfile(SubFolder .. "bin/crosshairs/reload_crosshair.png") then writefile(SubFolder .. "bin/crosshairs/reload_crosshair.png", "") end

    HitSound = get_custom_asset(SubFolder .. "bin/sounds/hitsound.mp3")
    Crosshair = get_custom_asset(SubFolder .. "bin/crosshairs/crosshair.png")
end

-- Functions


function LoadConfig(Name: string)
    Config = Configs:Load(Name)
    RefreshMenu()

    ContextAction:BindAction("aimbotToggle", AimbotToggle, false, Config.Aimbot.Key)
    ContextAction:BindAction("AutoFireToggle", AutoFireToggle, false, Config.AutoFire.Key)
    ContextAction:BindAction("cameraLockToggle", CameraLockToggle, false, Config.CameraLock.Key)
    ContextAction:BindAction("flyToggle", FlyToggle, false, Config.Flight.Key)
    ContextAction:BindAction("blinkToggle", BlinkToggle, false, Config.Blink.Key)
    ContextAction:BindAction("floatToggle", FloatToggle, false, Config.Float.Key)
    ContextAction:BindAction("noclipToggle", NoclipToggle, false, Config.Noclip.Key)
    ContextAction:BindAction("antiAimToggle", AntiAimToggle, false, Config.AntiAim.Key)
    ContextAction:BindAction("commandBarToggle", CommandBarToggle, false, Config.Prefix)
    ContextAction:BindAction("menuToggle", MenuToggle, false, Config.Menu.Key)
	ContextAction:BindAction("buyAmmoKey", BuyAmmoToggle, false, Config.BuyAmmo.Key)


    pcall(function()
        ChatFrame = PlayerGui.Chat.Frame.ChatChannelParentFrame

        ChatFrame.Position = UDim2.new(0, 0, 1, Config.Interface.Chat.Position)
        ChatFrame.Visible = Config.Interface.Chat.Enabled
    end)

   UpdateESPState()

    if Config.ESP.Chams.Local.Enabled then
        SetPlayerChams(Player, Config.ESP.Chams.Local.Color, Config.ESP.Chams.Local.Material, Config.ESP.Chams.Local.Reflectance, Config.ESP.Chams.Local.Transparency, true)
    else
        SetPlayerChams(Player)
    end

    do
        local SeatsDisabled = Config.NoSeats.Enabled
        for _, Seat in next, Seats do
            Seat.Disabled = SeatsDisabled
        end
    end


    if Config.Enviorment.Ambient.Enabled then
        Lighting.Ambient = Config.Enviorment.Ambient.Colors.Ambient
        Lighting.OutdoorAmbient = Config.Enviorment.Ambient.Colors.OutdoorAmbient
    else
        Lighting.Ambient = Lighting.DefaultAmbient
        Lighting.OutdoorAmbient = Lighting.DefaultOutdoorAmbient
    end


    Mouse.Icon = Crosshair
    EnableInfiniteStamina()
    UpdateAntiAim()
    Lighting:UpdateSkybox(Config.Enviorment.Skybox.Value)
end


function AddHatChangerColorSequenceColorPicker(Color: string?)
    local Index = #HatChangerColorSequenceColorPickers + 1
    local ColorPicker = Menu:GetItem(Menu.ColorPicker("Visuals", "Hats", "Color #" .. Index, Color and Color3.fromHex(Color), nil, function(Color)
        Config.HatChanger.Sequence.Colors[Index] = Color:ToHex()
    end))
    Config.HatChanger.Sequence.Colors[Index] = Color or "000000"
    table.insert(HatChangerColorSequenceColorPickers, ColorPicker)
end


function RemoveHatChangerColorSequenceColorPicker()
    local Index = #HatChangerColorSequenceColorPickers
    if Index < 1 then return end

    local ColorPicker = table.remove(HatChangerColorSequenceColorPickers, Index)
    ColorPicker:SetVisible(false) -- no current method to destroy? LOL

    if #Config.HatChanger.Sequence.Colors == Index then
        table.remove(Config.HatChanger.Sequence.Colors, Index)
    end
end


function RefreshHatChangerColorSequence()
    for _ = 1, #HatChangerColorSequenceColorPickers do
        RemoveHatChangerColorSequenceColorPicker()
    end
    for i, Color in next, Config.HatChanger.Sequence.Colors do
        AddHatChangerColorSequenceColorPicker(Color)
    end
end


function RefreshMenu()
    RefreshHatChangerColorSequence()
    -- There ARE LIKE 200 MENU ITEMS TO UPDATE???

    Menu:FindItem("Combat", "Aimbot", "CheckBox", "Enabled"):SetValue(Config.Aimbot.Enabled)
    Menu:FindItem("Combat", "Aimbot", "Hotkey", "Aimbot key"):SetValue(Config.Aimbot.Key)
    Menu:FindItem("Combat", "Aimbot", "CheckBox", "Auto fire"):SetValue(Config.AutoFire.Enabled)
    Menu:FindItem("Combat", "Aimbot", "Slider", "Auto fire range"):SetValue(Config.AutoFire.Range)
    Menu:FindItem("Combat", "Aimbot", "CheckBox", "Auto fire velocity check"):SetValue(Config.AutoFire.VelocityCheck.Enabled)
    Menu:FindItem("Combat", "Aimbot", "Slider", "Auto fire max velocity"):SetValue(Config.AutoFire.VelocityCheck.MaxVelocity)
    Menu:FindItem("Combat", "Aimbot", "CheckBox", "Camera lock"):SetValue(Config.CameraLock.Enabled)
    Menu:FindItem("Combat", "Aimbot", "Hotkey", "Camera lock key"):SetValue(Config.CameraLock.Key)
    Menu:FindItem("Combat", "Aimbot", "ComboBox", "Camera lock mode"):SetValue(Config.CameraLock.Mode)
    Menu:FindItem("Combat", "Aimbot", "ComboBox", "Target hitbox"):SetValue(Config.Aimbot.HitBox)
    Menu:FindItem("Combat", "Aimbot", "ComboBox", "Target selection"):SetValue(Config.Aimbot.TargetSelection)

    Menu:FindItem("Combat", "Prediction", "ComboBox", "Prediction method"):SetValue(Config.Aimbot.Prediction.Method)
    Menu:FindItem("Combat", "Prediction", "Slider", "Velocity prediction amount"):SetValue(Config.Aimbot.Prediction.VelocityPredictionAmount)
    Menu:FindItem("Combat", "Prediction", "Slider", "Velocity multiplier"):SetValue(Config.Aimbot.Prediction.VelocityMultiplier)

    Menu:FindItem("Combat", "Other", "CheckBox", "Always ground hit"):SetValue(Config.AlwaysGroundHit.Enabled)
    Menu:FindItem("Combat", "Other", "CheckBox", "Stomp spam"):SetValue(Config.StompSpam.Enabled)
    Menu:FindItem("Combat", "Other", "CheckBox", "Auto stomp"):SetValue(Config.AutoStomp.Enabled)
    Menu:FindItem("Combat", "Other", "Slider", "Auto stomp range"):SetValue(Config.AutoStomp.Range)
    Menu:FindItem("Combat", "Other", "ComboBox", "Auto stomp target"):SetValue(Config.AutoStomp.Target)

    Menu:FindItem("Visuals", "ESP", "CheckBox", "Enabled"):SetValue(Config.ESP.Enabled)
    Menu:FindItem("Visuals", "ESP", "CheckBox", "Target lock"):SetValue(Config.ESP.ForceTarget)
    Menu:FindItem("Visuals", "ESP", "CheckBox", "Target override"):SetValue(Config.ESP.TargetOverride.Enabled)
    Menu:FindItem("Visuals", "ESP", "ColorPicker", "Target color"):SetValue(Config.ESP.TargetOverride.Color, 1 - Config.ESP.TargetOverride.Transparency)
    Menu:FindItem("Visuals", "ESP", "CheckBox", "Whitelist override"):SetValue(Config.ESP.WhitelistOverride.Enabled)
    Menu:FindItem("Visuals", "ESP", "ColorPicker", "Whitelist color"):SetValue(Config.ESP.WhitelistOverride.Color, 1 - Config.ESP.WhitelistOverride.Transparency)
    Menu:FindItem("Visuals", "ESP", "CheckBox", "Box"):SetValue(Config.ESP.Box.Enabled)
    Menu:FindItem("Visuals", "ESP", "ColorPicker", "Box color"):SetValue(Config.ESP.Box.Color, 1 - Config.ESP.Box.Transparency)
    Menu:FindItem("Visuals", "ESP", "CheckBox", "Skeleton"):SetValue(Config.ESP.Skeleton.Enabled)
    Menu:FindItem("Visuals", "ESP", "ColorPicker", "Skeleton color"):SetValue(Config.ESP.Skeleton.Color, 1 - Config.ESP.Skeleton.Transparency)
    Menu:FindItem("Visuals", "ESP", "CheckBox", "Chams"):SetValue(Config.ESP.Chams.Enabled)
    Menu:FindItem("Visuals", "ESP", "ColorPicker", "Chams color"):SetValue(Config.ESP.Chams.Color, Config.ESP.Chams.Transparency)
    Menu:FindItem("Visuals", "ESP", "ColorPicker", "Chams walls color"):SetValue(Config.ESP.Chams.WallsColor, 1 - Config.ESP.Chams.WallsTransparency)
    Menu:FindItem("Visuals", "ESP", "ColorPicker", "Chams outline color"):SetValue(Config.ESP.Chams.OutlineColor, Config.ESP.Chams.OutlineTransparency)
    Menu:FindItem("Visuals", "ESP", "CheckBox", "Chams auto outline color"):SetValue(Config.ESP.Chams.AutoOutlineColor)
    Menu:FindItem("Visuals", "ESP", "CheckBox", "Knocked out chams"):SetValue(Config.ESP.Chams.KnockedOut.Enabled)
    Menu:FindItem("Visuals", "ESP", "ColorPicker", "Knocked out chams color"):SetValue(Config.ESP.Chams.KnockedOut.Color, Config.ESP.Chams.KnockedOut.Transparency)
    Menu:FindItem("Visuals", "ESP", "CheckBox", "Snapline"):SetValue(Config.ESP.Snaplines.Enabled)
    Menu:FindItem("Visuals", "ESP", "ColorPicker", "Snapline color"):SetValue(Config.ESP.Snaplines.Color, 1 - Config.ESP.Snaplines.Transparency)
    Menu:FindItem("Visuals", "ESP", "CheckBox", "Snapline offscreen"):SetValue(Config.ESP.Snaplines.OffScreen)
    Menu:FindItem("Visuals", "ESP", "CheckBox", "Health bar"):SetValue(Config.ESP.Bars.Health.Enabled)
    Menu:FindItem("Visuals", "ESP", "CheckBox", "Health bar auto color"):SetValue(Config.ESP.Bars.Health.AutoColor)
    Menu:FindItem("Visuals", "ESP", "ColorPicker", "Health bar color"):SetValue(Config.ESP.Bars.Health.Color, 1 - Config.ESP.Bars.Health.Transparency)
    Menu:FindItem("Visuals", "ESP", "CheckBox", "Knocked out bar"):SetValue(Config.ESP.Bars.KnockedOut.Enabled)
    Menu:FindItem("Visuals", "ESP", "ColorPicker", "Knocked out bar color"):SetValue(Config.ESP.Bars.KnockedOut.Color, 1 - Config.ESP.Bars.KnockedOut.Transparency)
    Menu:FindItem("Visuals", "ESP", "CheckBox", "Ammo bar"):SetValue(Config.ESP.Bars.Ammo.Enabled)
    Menu:FindItem("Visuals", "ESP", "ColorPicker", "Ammo bar color"):SetValue(Config.ESP.Bars.Ammo.Color, 1 - Config.ESP.Bars.Ammo.Transparency)
    Menu:FindItem("Visuals", "ESP", "MultiSelect", "Flags"):SetValue({
        Name = Config.ESP.Flags.Name.Enabled,
        Weapon = Config.ESP.Flags.Weapon.Text.Enabled,
        Ammo = Config.ESP.Flags.Ammo.Enabled,
        Vest = Config.ESP.Flags.Vest.Enabled,
        Health = Config.ESP.Flags.Health.Enabled,
        Stamina = Config.ESP.Flags.Stamina.Enabled,
        ["Knocked out"] = Config.ESP.Flags.KnockedOut.Enabled,
        Distance = Config.ESP.Flags.Distance.Enabled,
        Velocity = Config.ESP.Flags.Velocity.Enabled
    })
    Menu:FindItem("Visuals", "ESP", "ComboBox", "Font"):SetValue(Config.ESP.Font.Font)
    Menu:FindItem("Visuals", "ESP", "ColorPicker", "Font color"):SetValue(Config.ESP.Font.Color, 1 - Config.ESP.Font.Transparency)
    Menu:FindItem("Visuals", "ESP", "Slider", "Font size"):SetValue(Config.ESP.Font.Size)

    Menu:FindItem("Visuals", "Local esp", "CheckBox", "Chams"):SetValue(Config.ESP.Chams.Local.Enabled)
    Menu:FindItem("Visuals", "Local esp", "ColorPicker", "Chams color"):SetValue(Config.ESP.Chams.Local.Color, Config.ESP.Chams.Local.Transparency)
    Menu:FindItem("Visuals", "Local esp", "Slider", "Chams reflectance"):SetValue(Config.ESP.Chams.Local.Reflectance)
    Menu:FindItem("Visuals", "Local esp", "ComboBox", "Chams material"):SetValue(Config.ESP.Chams.Local.Material)
    Menu:FindItem("Visuals", "Local esp", "CheckBox", "Visualize fake lag"):SetValue(Config.FakeLag.Visualize)
    Menu:FindItem("Visuals", "Local esp", "ColorPicker", "Visualize color"):SetValue(Config.FakeLag.Color, 1 - Config.FakeLag.Transparency)

    Menu:FindItem("Visuals", "Item esp", "CheckBox", "Enabled"):SetValue(Config.ESP.Item.Enabled)
    Menu:FindItem("Visuals", "Item esp", "CheckBox", "Name"):SetValue(Config.ESP.Item.Flags.Name.Enabled)
    Menu:FindItem("Visuals", "Item esp", "CheckBox", "Distance"):SetValue(Config.ESP.Item.Flags.Distance.Enabled)
    Menu:FindItem("Visuals", "Item esp", "CheckBox", "Snapline"):SetValue(Config.ESP.Item.Snaplines.Enabled)
    Menu:FindItem("Visuals", "Item esp", "ColorPicker", "Snapline color"):SetValue(Config.ESP.Item.Snaplines.Color, 1 - Config.ESP.Item.Snaplines.Transparency)
    Menu:FindItem("Visuals", "Item esp", "CheckBox", "Icons"):SetValue(Config.ESP.Item.Flags.Icon.Enabled)
    Menu:FindItem("Visuals", "Item esp", "ComboBox", "Font"):SetValue(Config.ESP.Item.Font.Font)
    Menu:FindItem("Visuals", "Item esp", "ColorPicker", "Font color"):SetValue(Config.ESP.Item.Font.Color, 1 - Config.ESP.Item.Font.Transparency)
    Menu:FindItem("Visuals", "Item esp", "Slider", "Font size"):SetValue(Config.ESP.Item.Font.Size)

    Menu:FindItem("Visuals", "Hit markers", "CheckBox", "Hit markers"):SetValue(Config.HitMarkers.Enabled)
    Menu:FindItem("Visuals", "Hit markers", "ComboBox", "Hit markers type"):SetValue(Config.HitMarkers.Type)
    Menu:FindItem("Visuals", "Hit markers", "ColorPicker", "Hit markers color"):SetValue(Config.HitMarkers.Color, 1 - Config.HitMarkers.Transparency)
    Menu:FindItem("Visuals", "Hit markers", "Slider", "Hit markers size"):SetValue(Config.HitMarkers.Size)
    Menu:FindItem("Visuals", "Hit markers", "CheckBox", "Hit sound"):SetValue(Config.HitSound.Enabled)

    Menu:FindItem("Visuals", "World", "CheckBox", "Ambient changer"):SetValue(Config.Enviorment.Ambient.Enabled)
    Menu:FindItem("Visuals", "World", "ColorPicker", "Ambient"):SetValue(Config.Enviorment.Ambient.Colors.Ambient, 0)
    Menu:FindItem("Visuals", "World", "ColorPicker", "Outdoor ambient"):SetValue(Config.Enviorment.Ambient.Colors.OutdoorAmbient, 0)
    Menu:FindItem("Visuals", "World", "CheckBox", "World time changer"):SetValue(Config.Enviorment.Time.Enabled)
    Menu:FindItem("Visuals", "World", "Slider", "World time"):SetValue(Config.Enviorment.Time.Value)
    Menu:FindItem("Visuals", "World", "CheckBox", "Saturation changer"):SetValue(Config.Enviorment.Saturation.Enabled)
    Menu:FindItem("Visuals", "World", "Slider", "Saturation"):SetValue(Config.Enviorment.Saturation.Value)
    Menu:FindItem("Visuals", "World", "CheckBox", "Bullet impacts"):SetValue(Config.BulletImpact.Enabled)
    Menu:FindItem("Visuals", "World", "ColorPicker", "Bullet impacts color"):SetValue(Config.BulletImpact.Color, 1 - Config.BulletImpact.Transparency)
    Menu:FindItem("Visuals", "World", "CheckBox", "Bullet tracers"):SetValue(Config.BulletTracers.Enabled)
    Menu:FindItem("Visuals", "World", "ColorPicker", "Bullet tracers color"):SetValue(Config.BulletTracers.Color)
    Menu:FindItem("Visuals", "World", "Slider", "Bullet tracers lifetime"):SetValue(Config.BulletTracers.Lifetime)
    Menu:FindItem("Visuals", "World", "CheckBox", "Disable bullet trails"):SetValue(Config.BulletTracers.DisableTrails)
    Menu:FindItem("Visuals", "World", "ComboBox", "Skybox"):SetValue(Config.Enviorment.Skybox.Value)

    Menu:FindItem("Visuals", "Other", "CheckBox", "Max zoom changer"):SetValue(Config.Zoom.Enabled)
    Menu:FindItem("Visuals", "Other", "Slider", "Max zoom"):SetValue(Config.Zoom.Value)
    Menu:FindItem("Visuals", "Other", "CheckBox", "Field of view changer"):SetValue(Config.FieldOfView.Enabled)
    Menu:FindItem("Visuals", "Other", "Slider", "Field of view"):SetValue(Config.FieldOfView.Value)
    Menu:FindItem("Visuals", "Other", "CheckBox", "First person"):SetValue(Config.FirstPerson.Enabled)

    Menu:FindItem("Visuals", "Interface", "CheckBox", "Aimbot vector indicator"):SetValue(Config.Aimbot.Visualize)
    Menu:FindItem("Visuals", "Interface", "CheckBox", "Field of view circle"):SetValue(Config.Interface.FieldOfViewCircle.Enabled)
    Menu:FindItem("Visuals", "Interface", "CheckBox", "Field of view circle filled"):SetValue(Config.Interface.FieldOfViewCircle.Filled)
    Menu:FindItem("Visuals", "Interface", "Slider", "Field of view circle sides"):SetValue(Config.Interface.FieldOfViewCircle.NumSides)
    Menu:FindItem("Visuals", "Interface", "ColorPicker", "Field of view circle color"):SetValue(Config.Interface.FieldOfViewCircle.Color, 1 - Config.Interface.FieldOfViewCircle.Transparency)
    Menu:FindItem("Visuals", "Interface", "CheckBox", "Watermark"):SetValue(Config.Interface.Watermark.Enabled)
    Menu:FindItem("Visuals", "Interface", "CheckBox", "Chat"):SetValue(Config.Interface.Chat.Enabled)
    Menu:FindItem("Visuals", "Interface", "Slider", "Chat position"):SetValue(Config.Interface.Chat.Position)
    Menu:FindItem("Visuals", "Interface", "CheckBox", "Indicators"):SetValue(Config.Interface.Indicators.Enabled)
    Menu:FindItem("Visuals", "Interface", "CheckBox", "Keybinds"):SetValue(Config.Interface.Keybinds.Enabled)
    Menu:FindItem("Visuals", "Interface", "CheckBox", "Show ammo"):SetValue(Config.Interface.ShowAmmo.Enabled)
    Menu:FindItem("Visuals", "Interface", "CheckBox", "Remove ui elements"):SetValue(Config.Interface.RemoveUIElements.Enabled)
    Menu:FindItem("Visuals", "Interface", "CheckBox", "Bar fade"):SetValue(Config.Interface.BarFade.Enabled)

    Menu:FindItem("Visuals", "Weapons", "CheckBox", "Gun chams"):SetValue(Config.GunChams.Enabled)
    Menu:FindItem("Visuals", "Weapons", "ColorPicker", "Chams color"):SetValue(Config.GunChams.Color, Config.GunChams.Transparency)
    Menu:FindItem("Visuals", "Weapons", "Slider", "Chams reflectance"):SetValue(Config.GunChams.Reflectance)
    Menu:FindItem("Visuals", "Weapons", "ComboBox", "Chams material"):SetValue(Config.GunChams.Material)

    Menu:FindItem("Visuals", "Hats", "CheckBox", "Hat color changer"):SetValue(Config.HatChanger.Enabled)
    Menu:FindItem("Visuals", "Hats", "ColorPicker", "Hat color"):SetValue(Config.HatChanger.Color)
    Menu:FindItem("Visuals", "Hats", "CheckBox", "Hat color sequence"):SetValue(Config.HatChanger.Sequence.Enabled)
    Menu:FindItem("Visuals", "Hats", "Slider", "Hat color sequence delay"):SetValue(Config.HatChanger.Sequence.Delay)

    Menu:FindItem("Player", "Movement", "Slider", "Walk speed"):SetValue(Config.WalkSpeed.Value)
    Menu:FindItem("Player", "Movement", "Slider", "Jump power"):SetValue(Config.JumpPower.Value)
    Menu:FindItem("Player", "Movement", "Slider", "Run speed"):SetValue(Config.RunSpeed.Value)
    Menu:FindItem("Player", "Movement", "Slider", "Crouch speed"):SetValue(Config.CrouchSpeed.Value)
    Menu:FindItem("Player", "Movement", "CheckBox", "Blink"):SetValue(Config.Blink.Enabled)
    Menu:FindItem("Player", "Movement", "Hotkey", "Blink key"):SetValue(Config.Blink.Key)
    Menu:FindItem("Player", "Movement", "Slider", "Blink speed"):SetValue(Config.Blink.Speed)
    Menu:FindItem("Player", "Movement", "CheckBox", "Flight"):SetValue(Config.Flight.Enabled)
    Menu:FindItem("Player", "Movement", "Hotkey", "Flight key"):SetValue(Config.Flight.Key)
    Menu:FindItem("Player", "Movement", "Slider", "Flight speed"):SetValue(Config.Flight.Speed)
    Menu:FindItem("Player", "Movement", "CheckBox", "Float"):SetValue(Config.Float.Enabled)
    Menu:FindItem("Player", "Movement", "Hotkey", "Float key"):SetValue(Config.Float.Key)
    Menu:FindItem("Player", "Movement", "CheckBox", "Infinite jump"):SetValue(Config.InfiniteJump.Enabled)
    Menu:FindItem("Player", "Movement", "CheckBox", "Noclip"):SetValue(Config.Noclip.Enabled)
    Menu:FindItem("Player", "Movement", "Hotkey", "Noclip key"):SetValue(Config.Noclip.Key)
    Menu:FindItem("Player", "Movement", "CheckBox", "Disable tool collision"):SetValue(Config.DisableToolCollision.Enabled)

    Menu:FindItem("Player", "Other", "CheckBox", "No knock out"):SetValue(Config.NoKnockOut.Enabled)
    Menu:FindItem("Player", "Other", "CheckBox", "No slow"):SetValue(Config.NoSlow.Enabled)
    Menu:FindItem("Player", "Other", "CheckBox", "Anti ground hit"):SetValue(Config.AntiGroundHit.Enabled)
    Menu:FindItem("Player", "Other", "CheckBox", "Anti fling"):SetValue(Config.AntiFling.Enabled)
    Menu:FindItem("Player", "Other", "CheckBox", "Death teleport"):SetValue(Config.DeathTeleport.Enabled)
    Menu:FindItem("Player", "Other", "CheckBox", "Flipped"):SetValue(Config.Flipped.Enabled)

    Menu:FindItem("Player", "Anti-aim", "CheckBox", "Enabled"):SetValue(Config.AntiAim.Enabled)
    Menu:FindItem("Player", "Anti-aim", "Hotkey", "Anti aim key"):SetValue(Config.AntiAim.Key)
    Menu:FindItem("Player", "Anti-aim", "ComboBox", "Anti aim type"):SetValue(Config.AntiAim.Type)
	Menu:FindItem("Player", "Anti-aim", "Slider", "X Minimum"):SetValue(Config.AntiAim.Motionless.X.Minimum)
	Menu:FindItem("Player", "Anti-aim", "Slider", "X Maximum"):SetValue(Config.AntiAim.Motionless.X.Maximum)
	Menu:FindItem("Player", "Anti-aim", "Slider", "Y Minimum"):SetValue(Config.AntiAim.Motionless.Y.Minimum)
	Menu:FindItem("Player", "Anti-aim", "Slider", "Y Maximum"):SetValue(Config.AntiAim.Motionless.Y.Maximum)
	Menu:FindItem("Player", "Anti-aim", "Slider", "Z Minimum"):SetValue(Config.AntiAim.Motionless.Z.Minimum)
	Menu:FindItem("Player", "Anti-aim", "Slider", "Z Maximum"):SetValue(Config.AntiAim.Motionless.Z.Maximum)

    Menu:FindItem("Misc", "Main", "CheckBox", "Auto cash"):SetValue(Config.AutoCash.Enabled)
    Menu:FindItem("Misc", "Main", "CheckBox", "Auto farm"):SetValue(Config.AutoFarm.Enabled)
    Menu:FindItem("Misc", "Main", "MultiSelect", "Auto farm table"):SetValue(Config.AutoFarm.Table)
    Menu:FindItem("Misc", "Main", "CheckBox", "Auto play"):SetValue(Config.AutoPlay.Enabled)
    Menu:FindItem("Misc", "Main", "CheckBox", "Auto reconnect"):SetValue(Config.AutoReconnect.Enabled)
    Menu:FindItem("Misc", "Main", "CheckBox", "Anti chat log"):SetValue(Config.AntiChatLog.Enabled)
    Menu:FindItem("Misc", "Main", "CheckBox", "Auto sort"):SetValue(Config.AutoSort.Enabled)
    Menu:FindItem("Misc", "Main", "MultiSelect", "Auto sort order"):SetValue(Config.AutoSort.Order)
    Menu:FindItem("Misc", "Main", "CheckBox", "Auto heal"):SetValue(Config.AutoHeal.Enabled)
    Menu:FindItem("Misc", "Main", "CheckBox", "Click open"):SetValue(Config.ClickOpen.Enabled)
    --Menu:FindItem("Misc", "Main", "CheckBox", "Chat spam"):SetValue(Spamming)
    Menu:FindItem("Misc", "Main", "CheckBox", "Event logs"):SetValue(Config.EventLogs.Enabled)
    Menu:FindItem("Misc", "Main", "MultiSelect", "Event log flags"):SetValue(Config.EventLogs.Flags)
    Menu:FindItem("Misc", "Main", "CheckBox", "Close doors"):SetValue(Config.CloseDoors.Enabled)
    Menu:FindItem("Misc", "Main", "CheckBox", "Open doors"):SetValue(Config.OpenDoors.Enabled)
    Menu:FindItem("Misc", "Main", "CheckBox", "Knock doors"):SetValue(Config.KnockDoors.Enabled)
    Menu:FindItem("Misc", "Main", "CheckBox", "No doors"):SetValue(Config.NoDoors.Enabled)
    Menu:FindItem("Misc", "Main", "CheckBox", "No seats"):SetValue(Config.NoSeats.Enabled)
    Menu:FindItem("Misc", "Main", "CheckBox", "Door aura"):SetValue(Config.DoorAura.Enabled)
    Menu:FindItem("Misc", "Main", "CheckBox", "Door menu"):SetValue(Config.DoorMenu.Enabled)
    --Menu:FindItem("Misc", "Main", "CheckBox", "Hide sprays"):SetValue(Config.HideSprays.Enabled)
    Menu:FindItem("Misc", "Main", "CheckBox", "Better spray quality"):SetValue(Config.BetterSprayQuality.Enabled)
    Menu:FindItem("Misc", "Main", "CheckBox", "Circular sprays"):SetValue(Config.CircularSprays.Enabled)

    Menu:FindItem("Misc", "Animations", "CheckBox", "Run"):SetValue(Config.Animations.Run.Enabled)
    Menu:FindItem("Misc", "Animations", "ComboBox", "Run animation"):SetValue(Config.Animations.Run.Style)
    Menu:FindItem("Misc", "Animations", "CheckBox", "Glock"):SetValue(Config.Animations.Glock.Enabled)
    Menu:FindItem("Misc", "Animations", "ComboBox", "Glock animation"):SetValue(Config.Animations.Glock.Style)
    Menu:FindItem("Misc", "Animations", "CheckBox", "Uzi"):SetValue(Config.Animations.Uzi.Enabled)
    Menu:FindItem("Misc", "Animations", "ComboBox", "Uzi animation"):SetValue(Config.Animations.Uzi.Style)
    Menu:FindItem("Misc", "Animations", "CheckBox", "Shotty"):SetValue(Config.Animations.Shotty.Enabled)
    Menu:FindItem("Misc", "Animations", "ComboBox", "Shotty animation"):SetValue(Config.Animations.Shotty.Style)
    Menu:FindItem("Misc", "Animations", "CheckBox", "Sawed off"):SetValue(Config.Animations["Sawed Off"].Enabled)
    Menu:FindItem("Misc", "Animations", "ComboBox", "Sawed off animation"):SetValue(Config.Animations["Sawed Off"].Style)

    Menu:FindItem("Misc", "Exploits", "CheckBox", "Infinite stamina"):SetValue(Config.InfiniteStamina.Enabled)
    Menu:FindItem("Misc", "Exploits", "CheckBox", "Infinite force field"):SetValue(Config.InfiniteForceField.Enabled)
    Menu:FindItem("Misc", "Exploits", "CheckBox", "Teleport bypass"):SetValue(Config.TeleportBypass.Enabled)
    Menu:FindItem("Misc", "Exploits", "CheckBox", "God"):SetValue(Config.God.Enabled)
    Menu:FindItem("Misc", "Exploits", "CheckBox", "Click spam"):SetValue(Config.ClickSpam.Enabled)
    Menu:FindItem("Misc", "Exploits", "CheckBox", "Lag on dragged"):SetValue(Config.LagOnDragged.Enabled)
    Menu:FindItem("Misc", "Exploits", "CheckBox", "Fake lag"):SetValue(Config.FakeLag.Enabled)
    Menu:FindItem("Misc", "Exploits", "Slider", "Fake lag limit"):SetValue(Config.FakeLag.Limit)

    --Menu:FindItem("Misc", "Players", "ListBox", "Target"):SetValue(SelectedTarget, Players:GetPlayers())
    Menu:FindItem("Misc", "Players", "CheckBox", "Target lock"):SetValue(TargetLock)
    Menu:FindItem("Misc", "Players", "Slider", "Priority"):SetValue(0)
    Menu:FindItem("Misc", "Players", "CheckBox", "Attach"):SetValue(Config.Attach.Enabled)
    Menu:FindItem("Misc", "Players", "Slider", "Attach rate"):SetValue(Config.Attach.Rate)
    Menu:FindItem("Misc", "Players", "CheckBox", "View"):SetValue(Config.View.Enabled)
    Menu:FindItem("Misc", "Players", "CheckBox", "Follow"):SetValue(Config.Follow.Enabled)
    --Menu:FindItem("Misc", "Players", "CheckBox", "Whitelisted"):SetValue(false)
    --Menu:FindItem("Misc", "Players", "CheckBox", "Owner"):SetValue(false)

    Menu:FindItem("Misc", "Clan tag", "CheckBox", "Enabled"):SetValue(Config.ClanTag.Enabled)
    Menu:FindItem("Misc", "Clan tag", "CheckBox", "Enabled"):SetValue(Config.ClanTag.Enabled)
    Menu:FindItem("Misc", "Clan tag", "CheckBox", "Visualize"):SetValue(Config.ClanTag.Visualize)
    Menu:FindItem("Misc", "Clan tag", "TextBox", "Tag"):SetValue(Config.ClanTag.Tag)
    Menu:FindItem("Misc", "Clan tag", "TextBox", "Prefix"):SetValue(Config.ClanTag.Prefix)
    Menu:FindItem("Misc", "Clan tag", "TextBox", "Suffix"):SetValue(Config.ClanTag.Suffix)
    Menu:FindItem("Misc", "Clan tag", "Slider", "Tag speed"):SetValue(Config.ClanTag.Speed)
    Menu:FindItem("Misc", "Clan tag", "ComboBox", "Tag type"):SetValue(Config.ClanTag.Type)
    Menu:FindItem("Misc", "Clan tag", "TextBox", "Spotify token"):SetValue(Config.ClanTag.SpotifyToken)

    Menu:FindItem("Settings", "Menu", "ColorPicker", "Menu accent"):SetValue(Config.Menu.Accent)
    Menu:FindItem("Settings", "Menu", "Hotkey", "Prefix"):SetValue(Config.Prefix)
    Menu:FindItem("Settings", "Menu", "Hotkey", "Menu key"):SetValue(Config.Menu.Key)

    Menu.Keybinds.List.Aimbot:Update(Config.Aimbot.Enabled and "on" or "off")
    Menu.Keybinds.List["Camera Lock"]:Update(Config.CameraLock.Enabled and "on" or "off")
    Menu.Keybinds.List.Flight:Update(Config.Flight.Enabled and "on" or "off")
    Menu.Keybinds.List.Blink:Update(Config.Blink.Enabled and "on" or "off")
    Menu.Keybinds.List.Float:Update(Config.Float.Enabled and "on" or "off")
    Menu.Keybinds.List.Noclip:Update(Config.Noclip.Enabled and "on" or "off")
    Menu.Keybinds.List["Anti Aim"]:Update(Config.AntiAim.Enabled and "on" or "off")

    Menu.Keybinds.List.Aimbot:SetVisible(Config.Aimbot.Enabled)
    Menu.Keybinds.List["Camera Lock"]:SetVisible(Config.CameraLock.Enabled)
    Menu.Keybinds.List.Flight:SetVisible(Config.Flight.Enabled)
    Menu.Keybinds.List.Blink:SetVisible(Config.Blink.Enabled)
    Menu.Keybinds.List.Float:SetVisible(Config.Float.Enabled)
    Menu.Keybinds.List.Noclip:SetVisible(Config.Noclip.Enabled)
    Menu.Keybinds.List["Anti Aim"]:SetVisible(Config.AntiAim.Enabled)

    Menu.Watermark:SetVisible(Config.Interface.Watermark.Enabled)
    Menu.Indicators:SetVisible(Config.Interface.Indicators.Enabled)
    Menu.Keybinds:SetVisible(Config.Interface.Keybinds.Enabled)
end


function GetSelectedTarget(): Player
    return Players:FindFirstChild(SelectedTarget or "")
end


function GetTarget(): Player
    if not Root then return end

    local Selected
    local Radius = math.huge

    local Whitelisted = {Player.UserId, unpack(PlayerManager:GetPlayersWithUserIds(UserTable.Whitelisted))}
    for _, _Player in next, PlayerManager:GetPlayers(Whitelisted) do
        if _Player == Player then continue end

        if _Player.Character then
            local _Root = Root -- _Root is equal to local player root
            local Root = Utils.GetRoot(_Player) -- Target root
            if Root then
                local Distance = 0

                if Config.Aimbot.TargetSelection == "Near mouse" then
                    Distance = (Mouse.Hit.Position - Root.Position).Magnitude
                    if Distance > (Config.Aimbot.Radius) then continue end
                elseif Config.Aimbot.TargetSelection == "Near player" then
                    if _Player:GetAttribute("KnockedOut") or not _Player:GetAttribute("IsAlive") then continue end
                    Distance = Player:DistanceFromCharacter(Root.Position)
                end

                if Distance < Radius then
                    Radius = Distance
                    Selected = _Player
                end
            end
        end
    end

    return Selected
end


function GetStompTarget(): Model
    if Character and Root then
        local Ray = Raycast.streets(Root.Position, Root.Position - Vector3.new(0, 2, 0), 3, {Character})

        if Ray and Ray.Parent then
            local Humanoid = Ray.Parent:FindFirstChild("Humanoid")
            if Humanoid and Humanoid.Parent:FindFirstChild("KO") and Humanoid.Health > 0 then
                return Humanoid.Parent
            end
        end
    end
end


function GetLimbs(Player: Player): table
    local Character = Player and Player.Character
    local Humanoid = Character and Character:FindFirstChild("Humanoid")

    if Character and Humanoid then
        local LimbCount = 0
        local Limbs = {}
        local Blacklist = {"RightHand", "LeftHand", "RightFoot"}

        for _, v in next, Character:GetChildren() do
            if table.find(Blacklist, v.Name) then continue end
            local Limb = Humanoid:GetLimb(v)

            if Limb ~= Enum.Limb.Unknown then
                LimbCount += 1
                Limbs[Limb.Name] = v
            end
        end

        return Limbs, LimbCount >= 6 and true or false
    end

    return {}, false
end


function GetAnimation(Name: string): Animation
    if typeof(Name) == "string" then
        if tonumber(Name) == nil then
            return Animations[Name].Track
        else
            for k, v in next, Animations do
                if v.Animation.AnimationId == "rbxassetid://" .. Name then
                    return v.Track
                end
            end
        end
    end
end


function GetClanModel(): Model
    if Character then
        for _, v in next, Character:GetChildren() do
            if v:IsA("Model") and v:FindFirstChild("f") then
                return v
            end
        end
    end
end


function GetAimbotCFrame(Randomize: boolean): CFrame
    local Character = Target and Target.Character
    local Humanoid = Character and Character.FindFirstChildOfClass(Character, "Humanoid")

    local HitPart = Character and (Character.FindFirstChild(Character, Config.Aimbot.HitBox) or Character.FindFirstChildWhichIsA(Character, "BasePart"))
    if not HitPart then return Mouse.Hit end

    if Config.Aimbot.Prediction.Method == "Default" then
        local VectorVelocity = Target.GetAttribute(Target, "Velocity") or Vector3.new() -- Don't want to error the script
        VectorVelocity *= Vector3.new(1, 0, 1) -- Making the y axis 0 due to over prediction
        VectorVelocity *= Config.Aimbot.VelocityMultiplier

        local Random = Vector3.new()
        if Randomize then
            Random = Vector3.new(math.random(-5, 5) / 10, math.random(-5, 5) / 10, math.random(-5, 5) / 10)
        end

        return HitPart.CFrame + Random + (VectorVelocity * Ping / 1000)
    elseif Config.Aimbot.Prediction.Method == "MoveDirection" then
        return HitPart.CFrame + Humanoid.MoveDirection * (Ping / 1000)
    elseif Config.Aimbot.Prediction.Method == "Velocity" then
        return HitPart.CFrame + (HitPart.Velocity / Config.Aimbot.Prediction.VelocityPredictionAmount)
    end

    return CFrame.new()
end


function GetTools(Player: Player, Type: string): table
    Player = Player or PlayerManager.LocalPlayer
    local Character = Player.Character
    local Backpack = Player:FindFirstChild("Backpack")

    if not Character or not Backpack then return {} end

    local Tools = {}
    local BackpackTools = {}
    local CharacterTools = {}

    for _, v in next, Character:GetChildren() do
        if v:IsA("Tool") then
            table.insert(CharacterTools, v)
        end
    end

    for _, v in next, Backpack:GetChildren() do
        if v:IsA("Tool") then
            table.insert(BackpackTools, v)
        end
    end

    if Type == "Backpack" then return BackpackTools end
    if Type == "Character" then return CharacterTools end

    table.move(BackpackTools, 1, #BackpackTools, #Tools + 1, Tools)
    table.move(CharacterTools, 1, #CharacterTools, #Tools + 1, Tools)

    return Tools
end


function GetToolInfo(Object: Tool, Property: string): any -- Maybe use attributes to log ammo;
    if typeof(Object) == "Instance" then
        local Tool_Name = Object.Name
        if Property then
            if Property == "Ammo" then
                local Ammo = Object:FindFirstChild("Ammo")
                local Clips = Object:FindFirstChild("Clips")
                local AmmoPerClip = Tool_Name == "Glock" and 8 or Tool_Name == "Uzi" and 14 or Tool_Name == "Shotty" and 4 or
                                    Tool_Name == "Sawed Off" and not Utils.IsOriginal and 4 or 2

                if Ammo and Clips then return Ammo.Value, Clips.Value, AmmoPerClip end
                if Object:GetAttribute("Gun") then return 0, 0, AmmoPerClip end

                return
            elseif Property == "IsGun" then
                local Guns = {"Glock", "Uzi", "Shotty", "Sawed Off"}
                return table.find(Guns, Tool_Name) and true or false
            end
        end

        return ToolData[Tool_Name]
    end
end


function GetModelParts(Model: Model, Ignore: table): table
    local Parts = {}

    for _, v in next, Model:GetDescendants() do
        if v:IsA("BasePart") then
            if Ignore then
                if table.find(Ignore, v) then continue end
            end
            table.insert(Parts, v)
        end
    end

    return Parts
end


function GetCash(): number
    local Cash
    local CashLabel = HUD and HUD:FindFirstChild("Cash")

    if CashLabel then
        Cash = string.gsub(CashLabel.Text, "%D", "")
        Cash = tonumber(Cash)
    end

    return Cash or 0
end


function GetFramerate(): number
    return math.round(1000 / Stats.FrameRateManager.RenderAverage:GetValue())
end


do
    local Buyers = {}

    function GetBuyPads(): table
        return Buyers
    end

    local ValidNames = {
        ["Buy Ammo"] = "Ammo",
        ["Sawed Off"] = "Sawed-Off"
    }

    local function AddPadToList(Object: Instance)
        if Object.Name == "Bought!" then
            local Event
            Event = Object:GetPropertyChangedSignal("Name"):Connect(function()
                AddPadToList(Object)
            end)

            task.delay(20, function()
                Event:Disconnect()
            end) -- if the buy pad is broken
        elseif string.match(Object.Name, "%a+%s?%a+ | %$%d+") then
            local Head = Object:FindFirstChild("Head")
            local ShopData = Head and Head:FindFirstChild("ShopData")

            local Name = string.match(Object.Name, "%a+%s?%a+")
            if ValidNames[Name] then
                Name = ValidNames[Name]
            end

            if ShopData then
                table.insert(Buyers, {
                    Name = string.lower(Name),
                    Part = Head,
                    Price = ShopData.Price.Value
                })
            end
        end
    end

    for _, v in next, workspace:GetChildren() do
        AddPadToList(v)
    end
end


function GetBrickTrajectoryPoints(Brick: Tool): table
    local Handle = Brick:FindFirstChild("Handle")
    if not Handle then return end

    local Points = {}
    local MaxPoints = 100

    local Origin = Handle.Position
    local End = Mouse.Hit.Position

    if Target and Config.Aimbot.Enabled then
        local AimbotCFrame = GetAimbotCFrame() + Vector3.new(0, 3, 0)

        if AimbotCFrame then
            End = AimbotCFrame.Position
        end
    end

    local Direction = (End - Origin).Unit
    local Distance = (End - Origin).Magnitude

    local Speed = Brick.Speed.Value
    local Gravity = Brick.Gravity.Value
    local Time = Distance / Speed

    local TimeStep = 0.1
    local TimeSteps = math.clamp(math.ceil(Time / TimeStep), 1, MaxPoints)

    -- nice math.clamp
    local Clamped = {}
    local function ClampAxis(Position, Position2)
        if not Clamped.x then
            if Position.x > Position2.x then
                Clamped.x = true
                Position = Vector3.new(End.x, Position.y, Position.z)
            end
        end

        if not Clamped.y then
            if Position.y > Position2.y then
                Clamped.y = true
                Position = Vector3.new(Position.x, End.y, Position.z)
            end
        end

        if not Clamped.z then
            if Position.z > Position2.z then
                Clamped.z = true
                Position = Vector3.new(Position.x, Position.y, End.z)
            end
        end
    end

    for i = 1, TimeSteps do
        local Time = TimeStep * i
        local Position = Origin + Direction * Speed * Time + Vector3.new(0, -Gravity * Time * Time / 2, 0)

        local LookVector = Handle.CFrame.LookVector * 1 -- why was I raycasting before do I have some kind of mental illness?

        ClampAxis(Position, Position + LookVector)
        table.insert(Points, Position)

        if Clamped.x and Clamped.y and Clamped.z then
            break
        end
    end

    return Points
end


function GetHitPoints(Target: Player): table
    local Points = {}
    local tCharacter = Target.Character

    if Tool and Tool:GetAttribute("Gun") then
        if tCharacter then
            local Parts = {}
            for _, v in next, tCharacter:GetDescendants() do
                if v:IsA("BasePart") then
                    table.insert(Parts, v)
                end
            end

            for _, Part in next, Parts do
                -- not sure if I should blacklist Tool or not but whatever
                local IsBehind, Hit = Utils.IsBehindAWall(Tool.Barrel, Part, {Tool})

                if IsBehind == false then
                    if Hit and Hit.Instance:IsDescendantOf(tCharacter) then
                        table.insert(Points, Hit.Position)
                    end
                end
            end
        end
    end

    return Points
end


function GetAssetInfo(AssetId: number): table
    AssetId = tonumber(AssetId)
    if not AssetId then return end

    local Info = {}
    local Success, Result = pcall(function()
        Info = Marketplace:GetProductInfo(AssetId)
    end)

    if not Success then
        warn(string.format("[Main::GetAssetInfo(%d)]: %s", AssetId, Result))
        task.wait(3)
        return GetAssetInfo(AssetId)
    end

    return Info
end


function IsDoorOpen(Door: Model): boolean
    local Vector = Door.WoodPart.Position

    for _, OpenVector in next, DoorData.Doors.Open do
        if math.abs((Vector - OpenVector).Magnitude) < 1.15 then
            return true
        end
    end

    for _, ClosedVector in next, DoorData.Doors.Closed do
        if math.abs((Vector - ClosedVector).Magnitude) < 1.15 then
            return false
        end
    end
end


function IsWindowOpen(Window: Model): boolean
    local Vector = Window.Move.Click.Position

    for _, OpenVector in next, DoorData.Windows.Open do
        if math.abs((Vector - OpenVector).Magnitude) < 2 then
            return true
        end
    end

    for _, ClosedVector in next, DoorData.Windows.Closed do
        if math.abs((Vector - ClosedVector).Magnitude) < 2 then
            return false
        end
    end
end


function IsInCar(): boolean
    local Jeep = workspace:FindFirstChild("Jeep")
    if Jeep then
        Jeep.Name = "_Jeep"
    else
        return false
    end

    local Jeep2 = workspace:FindFirstChild("Jeep")
    Jeep.Name = "Jeep"

    for _, Jeep in next, {Jeep, Jeep2} do
        local Seat = Jeep:FindFirstChild("DriveSeat")
        local IsSeated = IsOnSeat(Player, Seat) -- Don't use IsSeated that doesn't have Car Seats Cached

        if IsSeated then return Jeep end
    end

    return false
end


function IsOnSeat(Player: Player, Seat: Seat): boolean
    Player = Player or PlayerManager.LocalPlayer

    if Seat then
        local Occupant = Seat.Occupant
        if Occupant and tostring(Occupant.Parent) == Player.Name then return true end
    end

    return false
end


function IsSeated(Player: Player, Seat: Seat): boolean
    Player = Player or PlayerManager.LocalPlayer
    for _, Seat in next, Seats do
        local Seated = IsOnSeat(Seat)
        if Seated then return Seated end
    end

    return false
end


function TeleportToPlace(Place_Id: number, Job_Id: string)
    if Job_Id then
        TeleportService:TeleportToPlaceInstance(Place_Id, Job_Id)

        if Job_Id == game.JobId then
            if (#Players:GetPlayers() == 1) or (#Players:GetPlayers() == Players.MaxPlayers) then
                Player:Kick("Rejoining server..")
            end
        end
    else
        TeleportService:Teleport(Place_Id)
    end
end


function Teleport(Destination): Tween
    Teleporting = false

    local Event
    local Distance = Player:DistanceFromCharacter(Destination.Position)
    local Destination = CFrame.new(Destination.Position, Root.Orientation)

    if Distance < 50 or (Config.God.Enabled or Config.TeleportBypass.Enabled) then
        Root.CFrame = Destination
        Teleporting = false
        return true
    end

    Teleporting = true

    local Info = TweenInfo.new(Distance / 300, Enum.EasingStyle.Linear)
    local Tween = TweenService:Create(Root, Info, {CFrame = Destination})
    Root.CFrame = CFrame.new(Root.Position, Destination.Position)

    task.spawn(function()
        while Teleporting do task.wait() end
        Tween:Cancel()
    end)

    Tween.Completed:Connect(function()
        Teleporting = false
    end)

    Tween:Play()

    return Tween
end


function Chat(Message: string)
    Message = tostring(Message)
    Network:Send(Enums.NETWORK.CHAT, Message)
    --Players:Chat(Message)
    --ReplicatedStorage.Xbox:FireServer() ReplicatedStorage.Talk:FireServer(Message)
end


function SetAnimation(Name: string, Id: string)
    local Animation = Instance.new("Animation")
    Animation.AnimationId = "rbxassetid://" .. Id
    Animations[Name] = {
        Animation = Animation,
        Track = Humanoid:LoadAnimation(Animation)
    }
end


do
    local Event = Instance.new("BindableEvent")
    RunService:BindToRenderStep("fireEvent", 1, function() Event:Fire() end)

    local CFrameSending = false
    local VelocitySending = false

    local CFrameToSend
    local VelocityToSend, AngularVelocityToSend

    -- much easier with raknet but you know ._.

    function SetCharacterServerCFrame(CF: CFrame)
        if Root and typeof(CF) == "CFrame" then
            if CFrameSending then return end

            CFrameToSend = CF
            CFrameSending = true

            task.spawn(function()
                RunService.Heartbeat:Wait()
                local LastCFrame = Root.CFrame
                Root.CFrame = CFrameToSend

                Player:SetAttribute("ServerVector", CFrameToSend.Position)
                CFrameSending = false

                Event.Event:Wait()
                Root.CFrame = LastCFrame
            end)
        end
    end

    function SetCharacterServerVelocity(Velocity: Vector3, AngularVelocity: Vector3)
        if Root and typeof(Velocity) == "Vector3" and typeof(AngularVelocity) == "Vector3" then
            if VelocitySending then return end

            VelocityToSend, AngularVelocityToSend = Velocity, AngularVelocity
            VelocitySending = true

            task.spawn(function()
                RunService.Heartbeat:Wait()
                local LastVelocity = Root.AssemblyLinearVelocity
                local LastAngularVelocity = Root.AssemblyAngularVelocity

                Root.AssemblyLinearVelocity = Velocity
                Root.AssemblyAngularVelocity = AngularVelocity

                Player:SetAttribute("ServerVelocity", Velocity)
                Player:SetAttribute("ServerAngularVelocity", AngularVelocity)
                VelocitySending = false

                Event.Event:Wait()
                Root.AssemblyLinearVelocity = LastVelocity
                Root.AssemblyAngularVelocity = LastAngularVelocity
            end)
        end
    end
end


function SetModelDefaults(Model: Model, Ignore: table)
    if not Model:GetAttribute("DefaultsSet") then
        for _, Part in next, GetModelParts(Model, Ignore) do
            if Part:GetAttribute("DefaultTransparency") == 1 then continue end

            Part:SetAttribute("DefaultColor", Part.Color)
            Part:SetAttribute("DefaultMaterial", Part.Material.Name)
            Part:SetAttribute("DefaultReflectance", Part.Reflectance)
            Part:SetAttribute("DefaultTransparency", Part.Transparency)

            if Part:IsA("UnionOperation") then
                Part:SetAttribute("DefaultUsePartColor", Part.UsePartColor)
            end
        end

        Model:SetAttribute("DefaultsSet", true)
    end
end


function SetModelProperties(Model: Model, Color: Color3, Material: EnumItem, Reflectance: number, Transparency: number, UsePartColor: boolean)
    if Material == "Force field" then
	    Material = "ForceField"
    end

    for _, Part in next, GetModelParts(Model) do
        if Part:GetAttribute("DefaultTransparency") == 1 then continue end

        if Part:GetAttribute("DefaultColor") then
            Part.Color = typeof(Color) == "Color3" and Color or Part:GetAttribute("DefaultColor")
        end

        if Part:GetAttribute("DefaultMaterial") then
            Part.Material = typeof(Material) == "string" and Material or Part:GetAttribute("DefaultMaterial")
        end

        if Part:GetAttribute("DefaultReflectance") then
            Part.Reflectance = typeof(Reflectance) == "number" and Reflectance or Part:GetAttribute("DefaultReflectance")
        end

        if Part:GetAttribute("DefaultTransparency") then
            Part.Transparency = typeof(Transparency) == "number" and Transparency or Part:GetAttribute("DefaultTransparency")
        end

        if Part:IsA("UnionOperation") and Part:GetAttribute("DefaultUsePartColor") ~= nil then
            Part.UsePartColor = typeof(UsePartColor) == "boolean" and UsePartColor or Part:GetAttribute("DefaultUsePartColor") -- ?
        end
    end
end


function SetPlayerChams(Player: Player, ...) -- not actual chams just changing the properties of players parts
    local Character = Player.Character

    if Character then
        SetModelProperties(Character, ...)
    end
end


function SetToolChams(Tool: Tool)
    if not Tool then return end
    SetModelDefaults(Tool)

    if Config.GunChams.Enabled then
        SetModelProperties(Tool, Config.GunChams.Color, Config.GunChams.Material, Config.GunChams.Reflectance, Config.GunChams.Transparency, true)
    else
        SetModelProperties(Tool)
    end
end


function SetHat(Name: string)
    local Hat = Character and Character:FindFirstChild(Name)
    local Handle = Hat and Hat:FindFirstChild("Handle")

    if Handle then
        Network:Send(Enums.NETWORK.SET_HAT, Hat.Name) -- Server does WhiteDecal.Parent = Character:FindFirstChild(A.typ.Value).Handle [a is the second argument], every player has a whitedecal instance
    else
        Network:Send(Enums.NETWORK.REMOVE_HAT)
    end
end


--https://developer.roblox.com/en-us/articles/BrickColor-Codes
function SetHatColor(Color: Color3)
    Color = typeof(Color) == "Color3" and Color or Color3.new()
    Network:Send(Enums.NETWORK.SET_HAT_COLOR, Color)
end


function SetClanTag(Tag: string)
    Tag = typeof(Tag) == "string" and Tag or ""
    Tag = string.rep("\n", 100 - #Tag) .. Tag
    Network:Send(Enums.NETWORK.SET_GROUP, 1, Tag)

    --[[
    Stank.OnServerEvent:Connect(function(Player, Method, ...)
        if Method == "pick" then
            local GroupFrame = ...
            local Role = Player:GetRoleInGroup(GroupFrame.Name)
            local GroupName = GroupFrame.TextLabel.Text

            local X = GroupName .. "\n" .. Role .. "\n" .. Player.Name -- something like this
            db:set(Player, "clan", X) -- not sure if it saves the string or the group_id and group_role

            -- gets created everytime when player spawns
            ClanModel.Name = X

            -- when the player spawns
            ClanModel = Instance.new("Model")
            ClanModel.Name = db:get(Player, "clan") -- will error though if it's malformed
            ClanModel.Parent = Player.Character
        end
    end)
    ]]
end


function AddKnockedOutTimer(Player: Player)
    if Player:GetAttribute("KnockOutTimerActive") then return end

    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChild("Humanoid")

    if Player:GetAttribute("IsAlive") and Character and Humanoid then
        local Timer = TimerClass.new()
        local DownTime = 15 -- it's 30 when ko is less than hp but only on prison; and I can't check players ko value on prison so deal with it; well actually I can check my ko value but still DEAL with it

        Player:SetAttribute("KnockOutTimerActive", true)
        Timer:Start(function()
            if (DownTime > Timer.Time) and (Player and Player:GetAttribute("IsAlive")) then
                Player:SetAttribute("KnockOut", DownTime - Timer.Time)
            else
                Timer:Destroy()
                Player:SetAttribute("KnockOut", 0)
                Player:SetAttribute("KnockOutTimerActive", nil)
            end
        end)
    end
end


function AddFirstPersonEventListeners()
    for _, v in next, Events.FirstPerson do
        v:Disconnect()
    end

    table.clear(Events.FirstPerson)

    if Character and Config.FirstPerson.Enabled then
        for _, Object in next, Character:GetChildren() do
            if Object:IsA("BasePart") and string.find(Object.Name, "Arm") then
                Object.LocalTransparencyModifier = 0

                table.insert(Events.FirstPerson, Object:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
                    Object.LocalTransparencyModifier = 0
                end))
            end
        end
    end
end


function AddItem(Spawn: Instance)
    -- This Code is kinda ASS but whatever
    local function Set(Spawn, Name)
        Spawn:SetAttribute("Item", Name)
        Items[Spawn] = Spawn

        AddItemESP(Spawn)

        local Event, Touched
        Touched = Spawn.Touched:Connect(function(Part)
            if Event then return end

            local _Player = Player -- OUR LOCAL PLAYER
            local Player = Players:GetPlayerFromCharacter(Part.Parent)

            if Player then
                Event = Spawn.AncestryChanged:Connect(function(_, Parent)
                    if Parent then return end
                    Touched:Disconnect()
                    Event:Disconnect()

                    local Distance = Utils.math_round(_Player:DistanceFromCharacter(Part.Position), 2) -- DISTANCE FROM LOCAL PLAYER
                    local Color = Config.EventLogs.Colors["Picked up"]:ToHex()
                    local Message = string.format("%s picked up a %s from %s", Utils.GetRichTextColor(Player.Name, Color), Utils.GetRichTextColor(Name, Color),

                    Utils.GetRichTextColor(Distance, Color) .. " studs away")
                    LogEvent("Picked up", Message, tick())
                end)

                task.delay(10, function()
                    Event:Disconnect()
                    Event = nil
                end)
            end
        end)

        return Spawn, Name
    end

    for _, v in next, Spawn:GetDescendants() do
        for k2, v2 in next, ToolData do
            local Name = v.Name
            local ClassName = v.ClassName

            if ClassName == "Sound" then
                if string.find(tostring(v.SoundId), tostring(v2.EspId)) then return Set(Spawn, k2) end
            elseif ClassName == "SpecialMesh" then
                if string.find(tostring(v.MeshId), tostring(v2.EspId)) then return Set(Spawn, k2) end
            elseif ClassName == "MeshPart" then
                if string.find(tostring(v.MeshId), tostring(v2.EspId)) or string.find(tostring(v.TextureID), tostring(v2.EspId)) then
                    return Set(Spawn, k2)
                end
            end
        end
    end
end


function UpdateESPState()
    for _, Player in next, PlayerManager:GetPlayers({Player}) do
        if Config.ESP.Enabled then
            AddPlayerESP(Player)
        else
            RemovePlayerESP(Player)
        end
    end

    for _, Item in next, Items do
        if Config.ESP.Item.Enabled then
            AddItemESP(Item)
        else
            RemoveItemESP(Item)
        end
    end
end


function AddPlayerESP(Player: Player)
    RemovePlayerESP(Player)

    if typeof(Player) == "Instance" and Player:IsA("Player") and Player ~= PlayerManager.LocalPlayer then
    else
        return
    end

    local Character = Player.Character

    if not Character then return end

    local Humanoid = Character:FindFirstChild("Humanoid")
    local Head = Character:FindFirstChild("Head")
    local Torso = Character:FindFirstChild("Torso")
    local Root = Humanoid.RootPart

    if not Humanoid or not Head or not Torso then return end

    Drawn[Player] = {
        Character = Character,
        Root = Root,
        Type = "Player"
    }

    if Config.ESP.Chams.Enabled then
        Drawn[Player].Chams = ESP.Chams(Character) -- becareful with this, it can be detected
    end

    if Config.ESP.Flags.Name.Enabled then
        Drawn[Player].Name = ESP.Text(Head)
    end

    if Config.ESP.Flags.Weapon.Enabled then
        Drawn[Player].Weapon = ESP.Text(Head)
    end

    if Config.ESP.Flags.Ammo.Enabled then
        Drawn[Player].Ammo = ESP.Text(Head)
    end

    if Config.ESP.Flags.Vest.Enabled then
        Drawn[Player].Vest = ESP.Text(Head)
    end

    if Config.ESP.Flags.Health.Enabled then
        Drawn[Player].Health = ESP.Text(Head)
    end

    if Config.ESP.Flags.Stamina.Enabled then
        Drawn[Player].Stamina = ESP.Text(Head)
    end

    if Config.ESP.Flags.KnockedOut.Enabled then
        Drawn[Player].KnockedOut = ESP.Text(Head)
    end

    if Config.ESP.Flags.Velocity.Enabled then
        Drawn[Player].Velocity = ESP.Text(Head)
    end

    if Config.ESP.Flags.Distance.Enabled then
        Drawn[Player].Distance = ESP.Text(Head)
    end

    if Config.ESP.Box.Enabled then
        Drawn[Player].Box = ESP.Box(Torso)
    end

    if Config.ESP.Skeleton.Enabled then
        Drawn[Player].Skeleton = ESP.Skeleton()
    end

    if Config.ESP.Bars.Health.Enabled then
        Drawn[Player].HealthBar = ESP.Bar(Torso)
    end

    if Config.ESP.Bars.Ammo.Enabled then
        Drawn[Player].AmmoBar = ESP.Bar(Torso)
    end

    if Config.ESP.Bars.KnockedOut.Enabled then
        Drawn[Player].KnockedOutBar = ESP.Bar(Torso)
    end

    if Config.ESP.Flags.Weapon.Icon.Enabled then
        Drawn[Player].WeaponIcon = ESP.Image(Torso)
    end

    if Config.ESP.Snaplines.Enabled then
        Drawn[Player].Snapline = ESP.Snapline(Config.Aimbot.HitBox == "Head" and Head or Torso)
    end

    if Config.ESP.Arrows.Enabled then
        -- Drawn[Player].Arrow = ESP.Arrow(Torso)
    end


    Head.Destroying:Once(function(_, Parent)
        if Parent then return end
        RemovePlayerESP(Player)
    end)

    Torso.Destroying:Once(function(_, Parent)
        if Parent then return end
        RemovePlayerESP(Player)
    end)

    return Drawn[Player]
end


function AddItemESP(Item: Instance)
    RemoveItemESP(Item)

    Drawn[Item] = {}
    Drawn[Item].Type = "Item"
    if Config.ESP.Item.Flags.Name.Enabled then
        Drawn[Item].Name = ESP.Text(Item)
    end
    if Config.ESP.Item.Flags.Distance.Enabled then
        Drawn[Item].Distance = ESP.Text(Item)
    end
    if Config.ESP.Item.Flags.Icon.Enabled then
        --Drawn[Item].Icon = ESP.Image(Item)
    end
    if Config.ESP.Item.Snaplines.Enabled then
        Drawn[Item].Snapline = ESP.Snapline(Item)
    end

    return Drawn[Item]
end


function RemovePlayerESP(Player: Player)
    if not Drawn[Player] then return end

    for k, v in next, Drawn[Player] do
        if typeof(v) == "table" then
            v:Remove()
        end
    end

    Drawn[Player] = nil
end


function RemoveItemESP(Item: Instance)
    if not Drawn[Item] then return end

    for _, v in next, Drawn[Item] do
        if typeof(v) == "table" then
            v:Remove()
        end
    end

    Drawn[Item] = nil
end


function UpdateESP()
    debug.profilebegin("[Source.lua]::UpdateESP()")
    local ESP = Config.ESP
    local ESP_Enabled = ESP.Enabled
    local ESP_Flags = ESP.Flags
    local ESP_Font = ESP.Font
    local ESP_Bars = ESP.Bars

    local ESP_Name = ESP_Flags.Name
    local ESP_Weapon = ESP_Flags.Weapon.Text
    local ESP_Weapon_Icon = ESP_Flags.Weapon.Icon
    local ESP_Ammo = ESP_Flags.Ammo
    local ESP_Vest = ESP_Flags.Vest
    local ESP_Health = ESP_Flags.Health
    local ESP_Stamina = ESP_Flags.Stamina
    local ESP_KnockedOut = ESP_Flags.KnockedOut
    local ESP_Distance = ESP_Flags.Distance
    local ESP_Velocity = ESP_Flags.Velocity

    local ESP_AmmoBar = ESP_Bars.Ammo
    local ESP_HealthBar = ESP_Bars.Health
    local ESP_KnockedOutBar = ESP_Bars.KnockedOut

    local ESP_Chams = ESP.Chams
    local ESP_Box = ESP.Box
    local ESP_Skeleton = ESP.Skeleton
    local ESP_Snaplines = ESP.Snaplines
    local ESP_Arrows = ESP.Arrows

    local Item_ESP = ESP.Item
    local Item_ESP_Enabled = Item_ESP.Enabled
    local Item_ESP_Flags = Item_ESP.Flags
    local Item_ESP_Font = Item_ESP.Font

    local Item_ESP_Name = Item_ESP_Flags.Name
    local Item_ESP_Distance = Item_ESP_Flags.Distance
    local Item_ESP_Icon = Item_ESP_Flags.Icon
    local Item_ESP_Snaplines = Item_ESP.Snaplines

    for Object, v in next, Drawn do
        local Type = v.Type

        if Type == "Player" then
            local Player = Object
            local Character = v.Character
            if not Character then
                RemovePlayerESP(Player)
                continue
            end

            local Target = Player == Target and true or false
            local Admin = UserTable.Admin[Player.UserId]
            local Whitelisted = table.find(UserTable.Whitelisted, Player.UserId)
            local Distance = Player:GetAttribute("Distance")

            local function IS_VISIBLE()
                local TARGET_CHECK = true

                if ESP.ForceTarget then
                    TARGET_CHECK = Target
                end

                return ESP_Enabled and TARGET_CHECK
            end

            local FONT = ESP_Font.Font
            local FONT_SIZE = ESP_Font.Size
            local FONT_COLOR = (Admin and Admin.Color) or (Whitelisted and ESP.WhitelistOverride.Enabled and ESP.WhitelistOverride.Color) or (Target and ESP.TargetOverride.Enabled and ESP.TargetOverride.Color) or (ESP_Font.Color)
            local FONT_TRANSPARENCY = ESP_Font.Transparency
            local FONT_PUSH_AMOUNT = -6

            local function GET_FONT_PUSH()
                FONT_PUSH_AMOUNT -= 4
                return math.clamp(Distance / 100, 0.5, 10) * FONT_PUSH_AMOUNT
            end

            local TOP_BAR_PUSH = 6.125
            local LEFT_BAR_PUSH = 5.125
            local RIGHT_BAR_PUSH = 5.125
            local BOTTOM_BAR_PUSH = 6.125

            local function SET_BAR_POINTS(Bar, Position)
                if Position == "Top" then
                    Bar.Axis = "x"
                    Bar:SetPoints(TOP_BAR_PUSH, -TOP_BAR_PUSH, 6, 5)
                    TOP_BAR_PUSH -= 0.125
                elseif Position == "Left" then
                    Bar.Axis = "y"
                    Bar:SetPoints(6, 7, LEFT_BAR_PUSH, -LEFT_BAR_PUSH)
                    LEFT_BAR_PUSH += 0.125
                elseif Position == "Right" then
                    Bar.Axis = "y"
                    Bar:SetPoints(6, -7, RIGHT_BAR_PUSH, -RIGHT_BAR_PUSH)
                    RIGHT_BAR_PUSH += 0.125
                elseif Position == "Bottom" then
                    Bar.Axis = "x"
                    Bar:SetPoints(BOTTOM_BAR_PUSH, -BOTTOM_BAR_PUSH, 6, 5)
                    BOTTOM_BAR_PUSH += 0.125
                end
            end

            if v.Chams then
                v.Chams:SetVisible(IS_VISIBLE() and ESP_Chams.Enabled)
                if v.Chams.self.Enabled then
                    v.Chams:SetRenderMode("Walls")

                    if (Distance < 1000 and Utils.IsBehindAWall(v.Root, Root, {Root.Parent})) then
                        v.Chams:SetColor(ESP_Chams.WallsColor, ESP_Chams.WallsTransparency)
                    else
                        v.Chams:SetColor(ESP_Chams.Color, ESP_Chams.Transparency)
                    end

                    if ESP_Chams.AutoOutlineColor then
                        local Health = Player:GetAttribute("Health")
                        v.Chams:SetOutlineColor(Color3.fromHSV((Health / 100) * 0.3, 1, 1), ESP_Chams.OutlineTransparency)
                    else
                        v.Chams:SetOutlineColor(ESP_Chams.OutlineColor, ESP_Chams.OutlineTransparency)
                    end
                end
            end

            if v.Name then
                v.Name.Visible = IS_VISIBLE() and ESP_Name.Enabled
                if v.Name.Visible then
                    v.Name.Offset = ESP_Name.Offset
                    local Name = Admin and Admin.Tag or ESP_Name.Type == "User" and Player.Name or Player.DisplayName
                    v.Name:SetText(Name, FONT, FONT_SIZE, FONT_COLOR, FONT_TRANSPARENCY, true)
                end
            end

            do
                local Character = Player.Character
                local Tool = Player.Tool.Value

                if v.Weapon then
                    v.Weapon.Visible = IS_VISIBLE() and ESP_Weapon.Enabled and Tool and true or false
                    if v.Weapon.Visible then
                        v.Weapon.Offset = Vector2.new(0, GET_FONT_PUSH())
                        v.Weapon:SetText(string.format("Tool: [%s]", tostring(Tool)), FONT, FONT_SIZE, FONT_COLOR, FONT_TRANSPARENCY, true)
                    end
                end

                if v.WeaponIcon then
                    v.WeaponIcon.Visible = IS_VISIBLE() and ESP_Weapon_Icon.Enabled and Tool and true or false
                    if v.WeaponIcon.Visible then
                        v.WeaponIcon.Offset = ESP_Weapon_Icon.Offset

                    end
                end

                do
                    local Ammo, Clips, AmmoPerClip
                    if v.Ammo then
                        v.Ammo.Visible = IS_VISIBLE() and ESP_Ammo.Enabled and Tool and Tool:GetAttribute("Gun") and true or false
                        if v.Ammo.Visible then
                            Ammo, Clips, AmmoPerClip = GetToolInfo(Tool, "Ammo")
                            v.Ammo.Offset = Vector2.new(0, GET_FONT_PUSH())
                            v.Ammo:SetText(string.format("Ammo: [%s, %s]", Ammo, Clips), FONT, FONT_SIZE, FONT_COLOR, FONT_TRANSPARENCY, true)
                        end
                    end

                    if v.AmmoBar then
                        v.AmmoBar.Visible = IS_VISIBLE() and ESP_AmmoBar.Enabled and Tool and Tool:GetAttribute("Gun") and true or false
                        if v.AmmoBar.Visible then
                            if not Ammo then Ammo, Clips, AmmoPerClip = GetToolInfo(Tool, "Ammo") end
                            SET_BAR_POINTS(v.AmmoBar, ESP_AmmoBar.Position)
                            v.AmmoBar:SetValue((Ammo / AmmoPerClip) * 100)
                            v.AmmoBar:SetColor(ESP_AmmoBar.Color, ESP_AmmoBar.Transparency)
                        end
                    end
                end
            end

            if v.Vest then
                v.Vest.Visible = IS_VISIBLE() and ESP_Vest.Enabled
                if v.Vest.Visible then
                    v.Vest.Offset = Vector2.new(0, GET_FONT_PUSH())
                    v.Vest:SetText(string.format("Vest: [%s]", tostring(Player:GetAttribute("Vest"))), FONT, FONT_SIZE, FONT_COLOR, FONT_TRANSPARENCY, true)
                end
            end

            do
                local Health = Player:GetAttribute("Health")

                if v.Health then
                    v.Health.Visible = IS_VISIBLE() and ESP_Health.Enabled
                    if v.Health.Visible then
                        v.Health.Offset = Vector2.new(0, GET_FONT_PUSH())
                        v.Health:SetText(string.format("Health: [%s]", tostring(Health)), FONT, FONT_SIZE, FONT_COLOR, FONT_TRANSPARENCY, true)
                    end
                end

                if v.HealthBar then
                    v.HealthBar.Visible = IS_VISIBLE() and ESP_HealthBar.Enabled
                    if v.HealthBar.Visible then
                        SET_BAR_POINTS(v.HealthBar, ESP_HealthBar.Position)
                        v.HealthBar:SetValue(Health)

                        if ESP_HealthBar.AutoColor then
                            v.HealthBar:SetColor(Color3.fromHSV((Health / 100) * 0.3, 1, 1))
                        else
                            v.HealthBar:SetColor(ESP_HealthBar.Color, ESP_HealthBar.Transparency)
                        end
                    end
                end
            end

            do
                local Timer = Player:GetAttribute("KnockOut")

                if v.KnockedOut then
                    v.KnockedOut.Visible = IS_VISIBLE() and ESP_KnockedOut.Enabled
                    if v.KnockedOut.Visible then
                        v.KnockedOut.Offset = Vector2.new(0, GET_FONT_PUSH())
                        v.KnockedOut:SetText(string.format("Knock out: [%s]", tostring(Timer)), FONT, FONT_SIZE, FONT_COLOR, FONT_TRANSPARENCY, true)
                    end
                end

                if v.KnockedOutBar then
                    v.KnockedOutBar.Visible = IS_VISIBLE() and Timer > 0 and ESP_KnockedOutBar.Enabled
                    if v.KnockedOutBar.Visible then
                        SET_BAR_POINTS(v.KnockedOutBar, ESP_KnockedOutBar.Position)
                        v.KnockedOutBar:SetValue((Timer / 15) * 100)
                        v.KnockedOutBar:SetColor(ESP_KnockedOutBar.Color, ESP_KnockedOutBar.Transparency)
                    end
                end
            end

            if v.Stamina then
                v.Stamina.Visible = IS_VISIBLE() and ESP_Stamina.Enabled
                if v.Stamina.Visible then
                    v.Stamina.Offset = Vector2.new(0, GET_FONT_PUSH())
                    v.Stamina:SetText(string.format("Stamina: [%s]", Player:GetAttribute("Stamina")), FONT, FONT_SIZE, FONT_COLOR, FONT_TRANSPARENCY, true)
                end
            end

            if v.Distance then
                v.Distance.Visible = IS_VISIBLE() and ESP_Distance.Enabled
                if v.Distance.Visible then
                    v.Distance.Offset = Vector2.new(0, GET_FONT_PUSH())
                    v.Distance:SetText(string.format("Distance: [%s]", tostring(Distance)), FONT, FONT_SIZE, FONT_COLOR, FONT_TRANSPARENCY, true)
                end
            end

            if v.Velocity then
                v.Velocity.Visible = IS_VISIBLE() and ESP_Velocity.Enabled
                if v.Velocity.Visible then
                    v.Velocity.Offset = Vector2.new(0, GET_FONT_PUSH())
                    local Velocity = Player:GetAttribute("Velocity") or Vector3.new()
                    Velocity = tostring(Utils.math_round(Velocity.Magnitude, 2))
                    v.Velocity:SetText(string.format("Velocity: [%s u/s]", Velocity), FONT, FONT_SIZE, FONT_COLOR, FONT_TRANSPARENCY, true)
                end
            end

            if v.Box then v.Box.Visible = IS_VISIBLE() and ESP_Box.Enabled end

            if v.Snapline then
                v.Snapline.Visible = IS_VISIBLE() and ESP_Snaplines.Enabled
                v.Snapline.OffScreen = ESP_Snaplines.OffScreen
            end

            if v.Arrow then
                v.Arrow.Visible = IS_VISIBLE() and ESP_Arrows.Enabled
                v.Arrow.Offset = ESP_Arrows.Offset
            end

            if v.Skeleton then
                v.Skeleton.Visible = false
                if IS_VISIBLE() and ESP_Skeleton.Enabled then
                    local Limbs, Success = GetLimbs(Player)
                    v.Skeleton.Visible = Success and Player:GetAttribute("IsAlive") and true or false

                    if v.Skeleton.Visible then
                        pcall(function()
                            v.Skeleton:UpdatePoints({
                                Limbs.Head.Position,
                                Limbs.Head.Neck.WorldPosition,
                                Limbs.Torso.Pelvis.WorldPosition,

                                Limbs.LeftArm.LeftShoulder.WorldPosition,
                                Limbs.LeftArm.Position,
                                Limbs.LeftArm.LeftHand.WorldPosition,
                                Limbs.RightArm.RightShoulder.WorldPosition,
                                Limbs.RightArm.Position,
                                Limbs.RightArm.RightHand.WorldPosition,

                                Limbs.LeftLeg.LeftHip.WorldPosition,
                                Limbs.LeftLeg.Position,
                                Limbs.LeftLeg.LeftFoot.WorldPosition,
                                Limbs.RightLeg.RightHip.WorldPosition,
                                Limbs.RightLeg.Position,
                                Limbs.RightLeg.RightFoot.WorldPosition,
                            })
                        end)
                    end
                end
            end

            if Admin then
                if v.Skeleton then v.Skeleton:SetColor(Admin.Color, ESP_Skeleton.Transparency) end
                if v.Snapline then v.Snapline:SetColor(Admin.Color, ESP_Snaplines.Transparency) end
                if v.Box then v.Box:SetColor(Admin.Color, ESP_Box.Transparency) end
                if v.Arrow then v.Arrow:SetColor(Admin.Color, ESP_Arrows.Transparency) end
            elseif Whitelisted and ESP.WhitelistOverride.Enabled then
                if v.Skeleton then v.Skeleton:SetColor(ESP.WhitelistOverride.Color, ESP_Skeleton.Transparency) end
                if v.Snapline then v.Snapline:SetColor(ESP.WhitelistOverride.Color, ESP_Snaplines.Transparency) end
                if v.Box then v.Box:SetColor(ESP.WhitelistOverride.Color, ESP_Box.Transparency) end
                if v.Arrow then v.Arrow:SetColor(ESP.WhitelistOverride.Color, ESP_Arrows.Transparency) end
            elseif Target and ESP.TargetOverride.Enabled then
                if v.Skeleton then v.Skeleton:SetColor(ESP.TargetOverride.Color, ESP_Skeleton.Transparency) end
                if v.Snapline then v.Snapline:SetColor(ESP.TargetOverride.Color, ESP_Snaplines.Transparency) end
                if v.Box then v.Box:SetColor(ESP.TargetOverride.Color, ESP_Box.Transparency) end
                if v.Arrow then v.Arrow:SetColor(ESP.TargetOverride.Color, ESP_Arrows.Transparency) end
            else
                if v.Skeleton then v.Skeleton:SetColor(ESP_Skeleton.Color, ESP_Skeleton.Transparency) end
                if v.Snapline then v.Snapline:SetColor(ESP_Snaplines.Color, ESP_Snaplines.Transparency) end
                if v.Box then v.Box:SetColor(ESP_Box.Color, ESP_Box.Transparency) end
                if v.Arrow then v.Arrow:SetColor(ESP_Arrows.Color, ESP_Arrows.Transparency) end
            end
        elseif Type == "Item" then
            if Object.Parent ~= workspace then -- wait why Am I just not using a ancestry changed event ? :|
                RemoveItemESP(Object)
                continue
            end

            local Distance = Player:DistanceFromCharacter(Object.Position)

            local FONT_PUSH_AMOUNT = 0

            local function GET_FONT_PUSH()
                FONT_PUSH_AMOUNT -= 5
                return math.clamp(Distance / 200, 0, 10) * FONT_PUSH_AMOUNT
            end

            if v.Name then
                v.Name.Visible = Item_ESP_Enabled and Item_ESP_Name.Enabled
                if v.Name.Visible then
                    local Item_Name = Object:GetAttribute("Item")
                    v.Name.Offset = Vector2.new(0, GET_FONT_PUSH())
                    v.Name:SetText(Item_Name, Item_ESP_Font.Font, Item_ESP_Font.Size, Item_ESP_Font.Color, Item_ESP_Font.Transparency, true)
                end
            end

            if v.Distance then
                v.Distance.Visible = Item_ESP_Enabled and Item_ESP_Distance.Enabled
                if v.Distance.Visible then
                    local Distance = string.format("Distance: [%s]", tostring(math.round(Distance)))
                    v.Distance.Offset = Vector2.new(0, GET_FONT_PUSH())
                    v.Distance:SetText(Distance, Item_ESP_Font.Font, Item_ESP_Font.Size, Item_ESP_Font.Color, Item_ESP_Font.Transparency, true)
                end
            end

            if v.Icon then
                v.Icon.Visible = Item_ESP_Enabled and Item_ESP_Icon.Enabled
                if v.Icon.Visible then
                    local Icon = ""
                    v.Icon:SetSize(50, 50)
                    v.Icon:SetImage(Icon)
                    v.Icon:SetColor(Item_ESP_Icon.Color)
                end
            end

            if v.Snapline then
                v.Snapline.Visible = Item_ESP_Enabled and Item_ESP_Snaplines.Enabled
                if v.Snapline.Visible then
                    v.Snapline:SetColor(Item_ESP_Snaplines.Color, Item_ESP_Snaplines.Transparency)
                end
            end
        end
    end

    debug.profileend()
end


function UpdateInterface(Fade: boolean)
    if typeof(HUD) ~= "Instance" then return end

    local Bars = {HUD:FindFirstChild("HP"), HUD:FindFirstChild("KO"), HUD:FindFirstChild("Stam")}
    local Buttons = {HUD:FindFirstChild("ImageButton"), HUD:FindFirstChild("Mute")} -- ImageButton-LowGFX

    if Utils.IsOriginal then
        table.insert(Buttons, HUD:FindFirstChild("Shop"))
        table.insert(Buttons, HUD:FindFirstChild("Groups"))
    end

    if Config.Interface.BarFade.Enabled then
        if BarsFading then
            return
        end

        if Fade then
            BarsFading = true

            local Info = TweenInfo.new(0.5)
            local Properties = {Transparency = 1}

            for _, Bar in next, Bars do
                local Tween = TweenService:Create(Bar, Info, Properties)
                local Tween2 = TweenService:Create(Bar.Bar, Info, Properties)

                Tween:Play()
                Tween2:Play()

                Tween.Completed:Connect(function()
                    BarsFading = false
                end)
            end
        else
            for _, Bar in next, Bars do
                Bar.Transparency = 0
                Bar.Bar.Transparency = 0
            end
        end
    else
        BarsFading = false

        for _, Bar in next, Bars do
            Bar.Transparency = 0
            Bar.Bar.Transparency = 0
        end
    end

    for _, Button in next, Buttons do
        Button.Visible = not Config.Interface.RemoveUIElements.Enabled
    end
end


function UpdateAntiAim()
    Animations.AntiAim.Track:Stop()
    Menu.Indicators.List["Fake Velocity"]:SetVisible(false)

    if Config.AntiAim.Enabled then
        if Config.AntiAim.Type == "Velocity" then
            Menu.Indicators.List["Fake Velocity"]:SetVisible(true)
		elseif Config.AntiAim.Type == "Motionless" then
			Menu.Indicators.List["Fake Velocity"]:SetVisible(true)
        elseif Config.AntiAim.Type == "Desync" then
            local DesyncKeyPoints = {1, 2, 6}
        end
    end
end


function UpdatePlayerFlyState()
    if Config.Flight.Enabled then
        local LookVector = Camera.CFrame.LookVector
        local Car = IsInCar()

        FlyVelocity.Parent = Root
        FlyAngularVelocity.Parent = Root
        -- Root.AssemblyLinearVelocity = Vector3.new()

        if Car then
            local Root = Car.Chassis
            Car.PrimaryPart = Root

            Root.CanCollide = false
            Car:PivotTo(CFrame.new(Root.Position, Root.Position + LookVector))

            if not UserInput:GetFocusedTextBox() then
                if UserInput:IsKeyDown(Enum.KeyCode.W) then
                    Car:PivotTo(Root.CFrame + LookVector * Config.Flight.Speed)
                end
                if UserInput:IsKeyDown(Enum.KeyCode.A) then
                    Car:PivotTo(Root.CFrame * CFrame.new(-Config.Flight.Speed, 0, 0))
                end
                if UserInput:IsKeyDown(Enum.KeyCode.S) then
                    Car:PivotTo(Root.CFrame - LookVector * Config.Flight.Speed)
                end
                if UserInput:IsKeyDown(Enum.KeyCode.D) then
                    Car:PivotTo(Root.CFrame * CFrame.new(Config.Flight.Speed, 0, 0))
                end
            end
        else
            Humanoid:ChangeState(Enum.HumanoidStateType.Running)
            Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)

            Root.CFrame = Config.Flight.Rotation and CFrame.new(Root.Position, Root.Position + LookVector) or CFrame.new(Root.Position, Root.Position + LookVector * Vector3.new(1, 0, 1))

            local Velocity = Player:GetAttribute("Velocity")
            firesignal(Humanoid.Running, Velocity.Magnitude / 10)

            if not UserInput:GetFocusedTextBox() then
                if UserInput:IsKeyDown(Enum.KeyCode.W) then
                    Root.CFrame += LookVector * Config.Flight.Speed
                end

                if UserInput:IsKeyDown(Enum.KeyCode.S) then
                    Root.CFrame -= LookVector * Config.Flight.Speed
                end

                if UserInput:IsKeyDown(Enum.KeyCode.A) then
                    if Config.Flight.Rotation or Config.Flipped.Enabled then
                        Root.CFrame += (Humanoid.MoveDirection * Config.Flight.Speed)
                    else
                        Root.CFrame *= CFrame.new(-Config.Flight.Speed, 0, 0)
                    end
                end

                if UserInput:IsKeyDown(Enum.KeyCode.D) then
                    if Config.Flight.Rotation or Config.Flipped.Enabled then
                        Root.CFrame += (Humanoid.MoveDirection * Config.Flight.Speed)
                    else
                        Root.CFrame *= CFrame.new(Config.Flight.Speed, 0, 0)
                    end
                end
            end

        end
    else
        -- Unfly
        FlyVelocity.Parent = nil
        FlyAngularVelocity.Parent = nil
    end
end


function UpdateFieldOfViewCircle()
    FieldOfViewCircle.Visible = Config.Interface.FieldOfViewCircle.Enabled

    if FieldOfViewCircle.Visible then
        FieldOfViewCircle.Position = UserInput:GetMouseLocation()
        FieldOfViewCircle.Thickness = Config.Interface.FieldOfViewCircle.Thickness
        FieldOfViewCircle.Transparency = Config.Interface.FieldOfViewCircle.Transparency
        FieldOfViewCircle.NumSides = Config.Interface.FieldOfViewCircle.NumSides
        FieldOfViewCircle.Radius = Config.Aimbot.Radius
        FieldOfViewCircle.Color = Config.Interface.FieldOfViewCircle.Color
        FieldOfViewCircle.Filled = Config.Interface.FieldOfViewCircle.Filled
    end
end


function UpdateAimbotIndicator()
    if (Config.Aimbot.Visualize and Config.Aimbot.Enabled) then
        AimbotIndicator:SetVisible(true)
        AimbotIndicator:SetPosition(UserInput:GetMouseLocation())
        AimbotIndicator:SetColor(Color3.fromRGB(100, 40, 175), 0)

        local Vector, OnScreen = Camera:WorldToViewportPoint(GetAimbotCFrame().Position)
        if OnScreen then
            AimbotIndicator:SetPosition(Vector2.new(Vector.x, Vector.y))
        end
    else
        AimbotIndicator:SetVisible(false)
    end
end


function BindKey(Name: string, Mode: string, Key, Command, Arguments)
    if Mode == "Add" then
        Config.Keybinds.Commands[Name] = {
            Key,
            Command,
            Arguments
        }
    elseif Mode == "Remove" then
        Config.Keybinds.Commands[Name] = nil
    end
end


function LogEvent(Flag: string, Message: string, Time: number)
    if Config.EventLogs.Enabled and Config.EventLogs.Flags[Flag] then
        Menu.Notify(Message, 8)
    end
end


function BuyItem(Name: string)
    Name = string.lower(Name)

    local b_Pad
    local Closest = math.huge
    for _, Pad in next, GetBuyPads() do
        if string.find(Pad.Name, string.gsub(Name, "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")) then
            local Distance = (Root.Position - Pad.Part.Position).Magnitude
            if Distance < Closest then
                b_Pad = Pad
                Closest = Distance
            end
        end
    end

    if not b_Pad then
        local Color = Config.EventLogs.Colors.Error:ToHex()
        return Menu.Notify(Utils.GetRichTextColor("Item '" .. Name .. "' was not found", Color))
    end

    if b_Pad.Price > GetCash() then
        local Color = Config.EventLogs.Colors.Error:ToHex()
        return Menu.Notify(Utils.GetRichTextColor("Not enough cash...", Color))
    end

    Buying = true
    BuyPart = b_Pad.Part

    task.delay(5, function()
        Buying = false
        BuyPart = nil
    end)

    task.spawn(function()
        b_Pad.Part.Changed:Wait()
        Buying = false
        BuyPart = nil
    end)
end


function GetItem(Name: string)
    local Found, Part, Price
    for _, Item in next, Items do
        if string.lower(Item:GetAttribute("Item")) == Name then
            Found = true
            Teleport(Item.CFrame)
            break
        end
    end

    if Utils.IsOriginal and not Found then BuyItem(Name) end
end


function CreateBulletImpact(Position: Vector3, Color: Color3, Material: EnumItem): Part
    local Impact = Instance.new("Part")
    Impact.Anchored = true
    Impact.CanCollide = false
    Impact.Name = "BulletImpact"
    Impact.Color = Color or Color3.new(1, 1, 1)
    Impact.Material = Material or "ForceField"
    Impact.Position = Position
    Impact.Size = Vector3.new(0.2, 0.2, 0.2)
    Impact.Parent = Camera
    Debris:AddItem(Impact, 5)

    return Impact
end


function DrawLine(Color: Color3, Transparency: number, From: Vector2, To: Vector2): Line
    local Line = Drawing.new("Line")
    Line.Color = Color or Color3.new(1, 1, 1)
    Line.Transparency = Transparency or 1
    Line.From = From or Vector2.new()
    Line.To = To or Vector2.new()
    Line.Visible = false
    Line.ZIndex = 1

    return Line
end


function DrawCross(Size: number, Offset: number): Cross
    local Cross = {}
    local Lines = {DrawLine(), DrawLine(), DrawLine(), DrawLine()}

    Cross.Alive = true
    Cross.Angle = false
    Cross.Size = typeof(Size) == "number" and Size or 20
    Cross.Offset = typeof(Offset) == "number" and Offset or 4

    function Cross:SetSize(Size: number)
        assert(typeof(Size) == "number", "Size must be a number")
        Cross.Size = Size
    end

    function Cross:SetOffset(Offset: number)
        assert(typeof(Offset) == "number", "Offset must be a number")
        Cross.Offset = Offset
    end

    function Cross:SetPosition(Position: Vector2)
        if not Cross.Alive then return error("CROSS IS DEAD") end

        -- until I figure out a better way to do this and yes I need it to work by the angle to make it spin
        if Cross.Angle then
            Lines[1].From = Position + Vector2.new(0, -Cross.Offset)
            Lines[1].To = Position + Vector2.new(0, -Cross.Size)
            Lines[2].From = Position + Vector2.new(0, Cross.Offset)
            Lines[2].To = Position + Vector2.new(0, Cross.Size)

            Lines[3].From = Position + Vector2.new(-Cross.Offset, 0)
            Lines[3].To = Position + Vector2.new(-Cross.Size, 0)
            Lines[4].From = Position + Vector2.new(Cross.Offset, 0)
            Lines[4].To = Position + Vector2.new(Cross.Size, 0)
        else
            Lines[1].From = Position + Vector2.new(-Cross.Size, -Cross.Size)
            Lines[1].To = Position + Vector2.new(-Cross.Offset, -Cross.Offset)
            Lines[2].From = Position + Vector2.new(-Cross.Size, Cross.Size)
            Lines[2].To = Position + Vector2.new(-Cross.Offset, Cross.Offset)

            Lines[3].From = Position + Vector2.new(Cross.Size, -Cross.Size)
            Lines[3].To = Position + Vector2.new(Cross.Offset, -Cross.Offset)
            Lines[4].From = Position + Vector2.new(Cross.Size, Cross.Size)
            Lines[4].To = Position + Vector2.new(Cross.Offset, Cross.Offset)
        end
    end

    function Cross:Rotate(Angle: number)
        if not Cross.Alive then return error("CROSS IS DEAD") end
        Cross.Angle = not Cross.Angle
    end

    function Cross:SetColor(Color: Color3, Transparency: number)
        if not Cross.Alive then return error("CROSS IS DEAD") end

        Cross.Color = typeof(Color) == "Color3" and Color or Cross.Color
        Cross.Transparency = typeof(Transparency) == "number" and 1 - Transparency or Cross.Transparency

        for _, Line in next, Lines do
            Line.Color = Cross.Color
            Line.Transparency = Cross.Transparency
        end
    end

    function Cross:SetVisible(Visible: boolean)
        if not Cross.Alive then return error("CROSS IS DEAD") end

        for _, Line in next, Lines do
            Line.Visible = Visible and true or false
        end
    end

    function Cross:FadeIn(Callback: any)
        if not Cross.Alive then return error("CROSS IS DEAD") end

        task.spawn(function()
            for i = 1, 100 do
                if Cross.Alive then
                    Cross:SetColor(nil, 1 - i / 100)
                    RunService.RenderStepped:Wait()
                end
            end

            if typeof(Callback) == "function" then
                Callback()
            end
        end)
    end

    function Cross:FadeOut(Callback: any)
        if not Cross.Alive then return error("CROSS IS DEAD") end

        task.spawn(function()
            for i = 1, 100 do
                if Cross.Alive then
                    Cross:SetColor(nil, (i / 100))
                    RunService.RenderStepped:Wait()
                end
            end

            if typeof(Callback) == "function" then
                Callback()
            end
        end)
    end

    function Cross:Remove()
        if not Cross.Alive then return error("CROSS IS DEAD") end
        Cross.Alive = false

        for _, Line in next, Lines do
            Line:Remove()
        end
    end

    function Cross:Destroy() return Cross:Remove() end
    function Cross:IsAlive() return Cross.Alive end

    Cross:SetColor(Color3.new(1, 1, 1), 0)

    return Cross
end


-- Thanks to f6oor
function DrawStrawHat(Player: Player): table
    local Head = Player and Player.Character and Player.Character:FindFirstChild("Head")
    if not Head then return end

    local Hat = Instance.new("ConeHandleAdornment")
    local Outline = Instance.new("CylinderHandleAdornment")

    Hat.Name = "Hat"
    Hat.Transparency = 0.8
    Hat.Color3 = Color3.new(1, 1, 1)
    Hat.Height = 0.8
    Hat.Radius = 1.5
    Hat.CFrame = CFrame.new(Vector3.new(), Vector3.new(0, 1, 0))
    Hat.SizeRelativeOffset = Vector3.new(0, 1.2, 0)
    Hat.AlwaysOnTop = true
    Hat.Adornee = Head
    Hat.Parent = Head

    Outline.Name = "Outline"
    Outline.Color3 = Color3.new()
    Outline.Height = 0.001
    Outline.Radius = 1.5
    Outline.InnerRadius = 1.504
    Outline.CFrame = CFrame.new(Vector3.new(), Vector3.new(0, 1, 0))
    Outline.SizeRelativeOffset = Vector3.new(0, 1.2 ,0)
    Outline.AlwaysOnTop = true
    Outline.Adornee = Head
    Outline.Parent = Hat

    return {}
end


function PlaySound(SoundId: string, Volume: number)
    assert(SoundId, "Missing SoundId")

    local Sound = Instance.new("Sound")
    Sound.SoundId = SoundId
    Sound.Volume = Volume or 1
    Sound.PlayOnRemove = true
    Sound.Parent = SoundService

    Sound:Destroy()
end


function SortBackpack()
    if not Humanoid then return end

    local Tools = {}
    Humanoid:UnequipTools()

    for _, Tool in next, GetTools() do
        table.insert(Tools, Tool)
        Tool.Parent = nil
    end

    for k, v in next, Config.AutoSort.Order do
        if not v then continue end

        for _, Tool in next, Tools do
            if Tool.Name == k then
                Tool.Parent = Backpack
            end
        end
    end

    -- if it's already in backpack it won't change the order
    for _, Tool in next, Tools do
        Tool.Parent = Backpack
    end
end


function TeleportBypass()
    if Config.TeleportBypass.Enabled then
        if Utils.IsOriginal then
            Network:Send(Enums.NETWORK.SET_GROUP, "", 1)
        else
            local RootPart = Utils.GetRoot(Player)
            if tostring(RootPart) == "HumanoidRootPart" then
                Torso.Anchored = true
		        Player:SetAttribute("RootPoint", RootPart.Position)
                RootPart:Destroy()
                Torso.Anchored = false
                Root = Torso
            end
        end
    else
        if not Character:FindFirstChildOfClass("Model") then
            if Utils.IsOriginal then Network:Send(Enums.NETWORK.LEAVE_GROUP) end
        end
    end
end


function PlayAnimationServer(Animation: Instance)
   Network:Send(Enums.NETWORK.STOMP, Animation)
end


function EnableInfiniteStamina(Value: number)
    if Utils.IsOriginal or not Config.InfiniteStamina.Enabled then return end

    task.spawn(function()
        local Remote = Backpack:WaitForChild("ServerTraits"):WaitForChild("Touch1")
        local Sound = workspace.OneHoop.Score.Sound -- Don't ask okay
        -- Can't do damage since the server tries to clone the "Info" folder, can't send functions through a remote
        Remote:FireServer({
            Handle = {Swing = Sound},
            Info = {
                Stam = {Value = -(Value or math.huge)},
                Range = {Value = 0}
            }
        }, 0, false, 0)
    end)
end


function PlaySoundExploit(Sound: Instance)
    if Utils.IsOriginal or not Sound then return end

    task.spawn(function()
        Backpack:WaitForChild("ServerTraits"):WaitForChild("Touch1"):FireServer({
            Handle = {
                Hit = Sound, -- The Cloned "Parent" will be set after it tries to set the "Pitch" property, only sound has a pitch property
                Swing = Sound
            },
            Info = {
                Stam = {Value = 0},
                Range = {Value = 9e9}, --Can't use math.huge also every time you hit a player it will play it, ((PlayerCount - Local) + Swing) so always will play as many players there are
                Cooldown = {Value = 0}
            }
        }, 0, false, 0)
    end)
end


function RefreshCharacter()
    if RefreshingCharacter then return end
    RefreshingCharacter = true

    Character:WaitForChild("Humanoid")

    local Script = PlayerGui:FindFirstChild("LocalScript")
    local ScreenGui = PlayerGui:FindFirstChild("ScreenGui")
    local EquippedTool = Tool

    SortBackpack()
    if EquippedTool then EquippedTool.Parent = Character end

    if HUD then HUD.Parent = CoreGui end
    if ScreenGui then ScreenGui.Parent = CoreGui end
    if Script then Script.Parent = CoreGui end

    Player.Character = nil
    Player.Character = Character

    task.delay(0, function()
        HUD.Parent = PlayerGui
        Script.Parent = PlayerGui
        ScreenGui.Parent = PlayerGui
    end)

    task.wait(Players.RespawnTime - 0.1)
    ResetCharacter()

    RefreshingCharacter = false
end


function ResetCharacter()
    if Utils.IsOriginal then
        --Character.Head:Destroy()
        Torso:Destroy() -- Server Kill + No lag while dragged
    else
        Humanoid:ChangeState(Enum.HumanoidStateType.Running)
        Humanoid.Health = 0
    end
end


function Attack(CF: CFrame, Release: boolean)
    if not Tool then return end
    if AttackDebounce then return end

    CF = Target and Config.Aimbot.Enabled and GetAimbotCFrame(true) or CF

    -- if AttackCooldown then return end
    -- AttackCooldown = true
    -- task.delay(0.1, function() AttackCooldown = false end)

    if Utils.IsOriginal then
        -- Tool.CD is disabled for reg
        if TagSystem.has(Character, "reloading") then return end


        AttackDebounce = true
        Network:Send(Enums.NETWORK.ATTACK, 1, CF, UserInput:IsKeyDown(Enum.KeyCode.LeftShift), Root.AssemblyLinearVelocity.Magnitude)
        --if Release then
            Network:Send(Enums.NETWORK.ATTACK, 2, CF, UserInput:IsKeyDown(Enum.KeyCode.LeftShift), Root.AssemblyLinearVelocity.Magnitude)
        --else
        --end
        task.delay(0.1, function()
            AttackDebounce = false
        end)
    else
        if Tool:GetAttribute("Gun") then
            if not Tool.CD then return end -- Cooldown
            local AnimationId = string.gsub(Tool.Fires.AnimationId, "%D", "")
            GetAnimation(AnimationId):Play(0.1, 1, 2)
            Network:Send(Enums.NETWORK.ATTACK, Tool, CF)
        elseif Tool:FindFirstChild("Finish") then
            Network:Send(Enums.NETWORK.ATTACK, Tool, UserInput:IsKeyDown(Enum.KeyCode.LeftShift))
        end
    end
end


function Stomp(Amount: number)
    Amount = typeof(Amount) == "number" and Amount or 1

    if Utils.IsOriginal then
        if Tool and Tool:FindFirstChild("Finish") then
            for _ = 1, Amount do
                Network:Send(Enums.NETWORK.STOMP)
            end
        end
    else
        if not Tool or Tool and not Tool:FindFirstChild("Finish") then
            Tool = Backpack:FindFirstChild("Punch")
        end

        for _ = 1, Amount do
            Network:Send(Enums.NETWORK.STOMP, Tool)
        end
    end
end


function Drag()
    if Character and not Dragging then
        Network:Send(Enums.NETWORK.DRAG)
    end
end


-- Server Side Presumption
--[[
    local LocalRoot
    local Dragging = false

    Drag.OnServerEvent:Connect(function(Player, IsDrag)
        Dragging = false

        if not IsDrag then return end
        Dragging = true
        for _, v in next, Players:GetPlayers() do
            if v == Player then continue end
            local Character = v.Character
            -- no humanoid indexes
            if Character and Character:FindFirstChild("KO") then
                task.spawn(function()
                    while true do
                        if not Dragging then continue end
                        if not Character:FindFirstChild("KO") then break end -- if there is no KO value then break the loop
                        pcall(function()
                            local Root = Character.HumanoidRootPart -- Yes he does it like this
                            Root.CFrame = LocalRoot.CFrame + LocalRoot.CFrame.lookVector * 0.5
                            task.wait() -- wait is here because the server yields when the code errors
                        end)
                        --task.wait() -- retarded snake should've added the wait here
                    end
                end)
            end
        end
    end)
]]


function CanPlayerAttackVictim(Player: Player, Victim: Player, Range: number): boolean
    if Player:GetAttribute("IsAlive") and Victim:GetAttribute("IsAlive") then
        local Root = Utils.GetRoot(Player)
        local vRoot = Utils.GetRoot(Victim)

        if Root and vRoot then
            if (vRoot - (Root.Position + (Root.CFrame.LookVector * Range / 2))).Magnitude < Range then
                local Hit = Raycast.streets(Root.Position, vRoot.Position, 5, Character)

                if Hit == nil or Hit.Anchored == false then
                    return true
                end
            end
        end
    end

    return false
end


function GripTool(Tool: Tool, Grip_CFrame: CFrame): Weld
    local Arm = Character:FindFirstChild("Right Arm")
    local Handle = Tool:FindFirstChild("Handle")
    if not Arm or not Handle then return end

    return Weld("RightGrip", Arm, Handle, Grip_CFrame)
end


function CreateJoint(Name: string, Part: BasePart, CF: CFrame): Attachment
    local Attachment = Instance.new("Attachment")
    Attachment.Name = Name
    Attachment.CFrame = CF
    Attachment.Parent = Part

    return Attachment
end


function Weld(Name: string, Part: BasePart, Part2: BasePart, CF: CFrame, CF2: CFrame): Weld
    local Grip = Instance.new("Weld")
    Grip.Name = Name
    Grip.Part0 = Part
    Grip.Part1 = Part2
    Grip.Parent = Part
    Grip.C0 = CF or CFrame.new()
    Grip.C1 = CF2 or CFrame.new()

    return Grip
end


function CreateJoints(Player: Player)
    local Limbs, Success = GetLimbs(Player)

    if Success then
        CreateJoint("Neck", Limbs.Head, CFrame.new(Vector3.new(0, -0.7, 0)))
        CreateJoint("Pelvis", Limbs.Torso, CFrame.new(Vector3.new(0, -0.7, 0)))

        CreateJoint("LeftShoulder", Limbs.LeftArm, CFrame.new(Vector3.new(0, 0.7, 0)))
        CreateJoint("LeftHand", Limbs.LeftArm, CFrame.new(Vector3.new(0, -0.9, 0)))
        CreateJoint("RightShoulder", Limbs.RightArm, CFrame.new(Vector3.new(0, 0.7, 0)))
        CreateJoint("RightHand", Limbs.RightArm, CFrame.new(Vector3.new(0, -0.9, 0)))

        CreateJoint("LeftHip", Limbs.LeftLeg, CFrame.new(Vector3.new(0, 0.7, 0)))
        CreateJoint("LeftFoot", Limbs.LeftLeg, CFrame.new(Vector3.new(0, -0.9, 0)))
        CreateJoint("RightHip", Limbs.RightLeg, CFrame.new(Vector3.new(0, 0.7, 0)))
        CreateJoint("RightFoot", Limbs.RightLeg, CFrame.new(Vector3.new(0, -0.9, 0)))
    end
end


function ResyncPlayer(Player: Player)
    -- offset HumRoot > Torso :: GetANimations
    local Humanoid = Player and Player.Character and Player.Character:FindFirstChild("Humanoid")
    if Humanoid then
        local Animator = Humanoid and Humanoid:FindFirstChild("Animator")
        if Animator then
            local Root = Utils.GetRoot(Player)
            if tostring(Root) == "HumanoidRootPart" then
                local Torso = Character:FindFirstChild("Torso")
                if Torso then
                    local Magnitude = (Root.Position - Torso.Position).Magnitude
                    if Magnitude > 0.1 then
                        local Tracks = Humanoid:GetPlayingAnimationTracks()

                        for _, Track in next, Tracks do
                            if Track.Animation.AnimationId == "rbxassetid://215384594" then
                                local TimePosition = Track.TimePosition

                            end
                        end
                    end
                end
            end
        end
    end
end


function ShowDoorMenu(Object: Instance) -- I hate this shitty code
    local Lock = Object:FindFirstChild("Lock").ClickDetector.RemoteEvent
    local Locker = Object:FindFirstChild("Locker")
    local Click = Object:FindFirstChild("Click").ClickDetector.RemoteEvent

    if not Lock or not Locker or not Click then return end

    local BillboardGui = Instance.new("BillboardGui")
    local TopBar = Instance.new("Frame")
    local Frame = Instance.new("Frame")
    local LockButton = Instance.new("TextButton")
    local Title = Instance.new("TextLabel")
    local LastLabel = Instance.new("TextLabel")

    local LoopEvent

    BillboardGui.Name = "DoorMenu"
    BillboardGui.Active = true
    BillboardGui.AlwaysOnTop = true
    BillboardGui.Adornee = Object.WoodPart
    BillboardGui.Size = UDim2.new(0, 200, 0, 50)
    BillboardGui.ExtentsOffset = Vector3.new(2, 0, 0)
    BillboardGui.Parent = Menu.Screen

    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, 0, 0, 15)
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Font = Enum.Font.Code
    Title.Text = "Door Menu"
    Title.TextSize = 14
    Title.TextStrokeTransparency = 0.5
    Title.Parent = BillboardGui
    Menu.Line(Title)

    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Frame.BackgroundTransparency = 0.2
    Frame.BorderSizePixel = 0
    Frame.Position = UDim2.new(0, 0, 0, 15)
    Frame.Size = UDim2.new(1, 0, 0, 30)
    Frame.Parent = BillboardGui

    LockButton.BackgroundTransparency = 1
    LockButton.Position = UDim2.new(0.1, 0, 0.0, 0)
    LockButton.Size = UDim2.new(0.8, 0, 0.5, 0)
    LockButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    LockButton.Text = "Lock"
    LockButton.Parent = Frame
    LockButton.MouseButton1Click:Connect(function()
        Lock:FireServer()
        LoopEvent:Disconnect()
        BillboardGui:Destroy()
    end)

    LastLabel.BackgroundTransparency = 1
    LastLabel.Position = UDim2.new(0.1, 0, 0.5, 0)
    LastLabel.Size = UDim2.new(0.8, 0, 0.5, 0)
    LastLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    LastLabel.Text = "Last: " .. (Object.Last.Value or "Nobody")
    LastLabel.Parent = Frame

    LoopEvent = RunService.Heartbeat:Connect(function()
        local Distance = Player:DistanceFromCharacter(Object.WoodPart.Position)

        if Distance > 8 or not Humanoid or Humanoid.Health <= 0 then
            BillboardGui:Destroy()
            LoopEvent:Disconnect()
        end

        LastLabel.Text = "Last: " .. (Object.Last.Value or "Nobody")
        LockButton.Text = Locker.Value and "Unlock" or "Lock"
    end)
end


function AutoFireCheck()
    if Config.Aimbot.Enabled and Config.AutoFire.Enabled then
        if Tool and Tool:GetAttribute("Gun") then
            if Target:GetAttribute("IsAlive") and Target:GetAttribute("Health") > 0 then
                if Target:GetAttribute("KnockOut") < (Ping / 1000) and not Target.Character:FindFirstChild("ForceField") then
                    local CanShoot = true

                    if Config.AutoFire.VelocityCheck.Enabled then
                        local Velocity = Target:GetAttribute("Velocity")

                        if Velocity.Magnitude > Config.AutoFire.VelocityCheck.MaxVelocity then
                            CanShoot = false
                        end
                    end

                    if CanShoot then
                        local Barrel = Tool:FindFirstChild("Barrel")
                        local Ammo, Clips = GetToolInfo(Tool, "Ammo")

                        if Barrel and (Ammo > 0 or Clips > 0) then
                            if (Target:DistanceFromCharacter(Barrel.Position) < Config.AutoFire.Range) then
                                local HitPoints = GetHitPoints(Target)

                                if #HitPoints > 0 then
                                    Attack(CFrame.new(HitPoints[1]))
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end


function AutoHealCheck()
    if not Healing and Config.AutoHeal.Enabled and Player:GetAttribute("Health") < 88 then
        local Foods, HealCount = {}, 0

        for _, Tool in next, GetTools() do
            if Tool.Name == "Burger" or Tool.Name == "Chicken" then
                table.insert(Foods, Tool)
            end
        end

        if #Foods > 0 then
            Healing = true
            Humanoid:UnequipTools()

            local FoodsToEat = {}
            for _, Food in next, Foods do
                local FoodHealth = GetToolInfo(Food).Health
                if Player:GetAttribute("Health") + HealCount + FoodHealth < 110 then
                    HealCount += FoodHealth
                    table.insert(FoodsToEat, Food)
                end
            end

            task.spawn(function()
                for _, Food in next, FoodsToEat do
                    Food.Parent = Character
                    Food:Activate()
                    Food.Parent = Backpack
                end

                task.wait(1.8)
                Healing = false
            end)
        end
    end
end


function AnimationCheck()
    for _, Track in next, Humanoid:GetPlayingAnimationTracks() do
        local AnimationId = string.gsub(Track.Animation.AnimationId, "%D", "")

        if (not Tool or not Tool:GetAttribute("Gun")) then
            if AnimationId == "889968874" or AnimationId == "229339207" or AnimationId == "503285264" or AnimationId == "889390949" then
                Track:Stop()
            end
        end

        Animations.Gun.Track:Stop()
        Animations.Gun2.Track:Stop()
        Animations.Gun3.Track:Stop()

        if Tool then
            if (Tool.Name == "Glock" and Config.Animations.Glock.Enabled and Config.Animations.Glock.Style ~= "Default") or (Tool.Name == "Uzi" and Config.Animations.Uzi.Enabled and Config.Animations.Uzi.Style ~= "Default") then
                if AnimationId == "503285264" then
                    Track:Stop()
                end
            elseif (Tool.Name == "Shotty" and Config.Animations.Shotty.Enabled and Config.Animations.Shotty.Style ~= "Default") or (Tool.Name == "Sawed Off" and Config.Animations["Sawed Off"].Enabled and Config.Animations["Sawed Off"].Style ~= "Default") then
                if AnimationId == "889390949" then
                    Track:Stop()
                end
            end

            if (Tool.Name == "Glock" or Tool.Name == "Uzi") then
                if Config.Animations[Tool.Name].Enabled then
                    local Style = Config.Animations[Tool.Name].Style

                    if Style == "Style-2" then
                        Animations.Gun.Track:Play()
                    elseif Style == "Style-3" then
                        Animations.Gun3.Track:Play()
                    end
                end
            elseif (Tool.Name == "Shotty" or Tool.Name == "Sawed Off") then
                if Config.Animations[Tool.Name].Enabled then
                    local Style = Config.Animations[Tool.Name].Style

                    if Style == "Style-2" then
                        Animations.Gun.Track:Play()
                    elseif Style == "Style-3" then
                        Animations.Gun2.Track:Play()
                        Animations.Gun2.Track:AdjustSpeed(0)
                        Animations.Gun2.Track.TimePosition = 0.2
                    end
                end
            end
        end
    end
end


function AutoStompCheck()
    if Config.AutoStomp.Enabled and not Config.God.Enabled and not Player:GetAttribute("KnockedOut") and not Dragging and Ping < 500 and tostring(Root) == "HumanoidRootPart" then
        for _, _Player in next, Players:GetPlayers() do
            if Config.AutoStomp.Target == "Target" then
                if not GetSelectedTarget() ~= _Player then continue end
            elseif Config.AutoStomp.Target == "Whitelist" then
                if not table.find(UserTable.Whitelisted, tostring(_Player.UserId)) then continue end
            elseif Config.AutoStomp.Target == "All" then
                if table.find(UserTable.Whitelisted, tostring(_Player.UserId)) then continue end
            end

            local _Root = Utils.GetRoot(_Player)
            if _Player ~= Player and _Root and tostring(_Root) == "HumanoidRootPart" and _Player:GetAttribute("KnockedOut") then
                if Player:DistanceFromCharacter(_Root.Position) < Config.AutoStomp.Distance and _Player:GetAttribute("Health") > 0 then
                    Teleport(_Root.CFrame)

                    if GetStompTarget() then
                        Stomp()
                    end
                end
            end
        end
    end
end


function Heartbeat(Step: number) -- after phys :: after heartbeat comes network stepped
    debug.profilebegin("[Source.lua]::Heartbeat()")
    Camera = workspace.CurrentCamera
    if UserInput:GetFocusedTextBox() ~= Menu.CommandBar then OnCommandBarFocusLost() end

    local SelectedTarget = GetSelectedTarget()
    Target = TargetLock and SelectedTarget or GetTarget()

    do
        local tCharacter = SelectedTarget and SelectedTarget.Character
        local tHumanoid = tCharacter and tCharacter:FindFirstChild("Humanoid")

        Camera.CameraSubject = Config.View.Enabled and (tHumanoid or Humanoid) or Humanoid
    end

    if Utils.IsOriginal then
        if TagSystem then
            Dragging = TagSystem.has(Character, "Dragging")
            Dragged = TagSystem.has(Character, "Dragged")

            if Dragged and Root and Config.LagOnDragged.Enabled then
                Root:Destroy()
                Root = Torso
            end
        end

        if Config.ClanTag.Visualize and not Config.TeleportBypass.Enabled then
            local ClanModel = GetClanModel()
            local ClanModelHead = ClanModel and ClanModel:FindFirstChild("Head")

            if ClanModelHead then
                ClanModelHead.Transparency = 0
            end
        end
    end

    --if Config.AutoAttack.Enabled then

    --end

    if Target and Target.Character then
        local _Root = Utils.GetRoot(Target)
        local _Torso = Utils.GetTorso(Target)

        if _Root and _Torso then
            AutoFireCheck()

            if TargetLock then
                if _Torso then
                    if Config.CameraLock.Enabled and Config.CameraLock.Mode == "Heartbeat" then
                        if _Torso and Humanoid and Player:GetAttribute("IsAlive") then
                            Camera.CFrame = CFrame.new(Camera.CFrame.Position, _Torso.CFrame.Position)
                        end
                    end

                    if Config.Follow.Enabled then
                        local Position = Target:GetAttribute("Position")
                        local TargetDistance = Target:GetAttribute("Distance")

                        Humanoid:MoveTo(Position)

                        if TargetDistance > 5 then
                            if Config.Flight.Enabled then
                                Root.CFrame = Root.CFrame:Lerp(_Root.CFrame, Config.Flight.Speed / TargetDistance)
                            end

                            if Config.Blink.Enabled then
                                Root.CFrame = Root.CFrame:Lerp(_Root.CFrame * CFrame.new(1, 0, 1), Config.Blink.Speed / TargetDistance)
                            end
                        end
                    end
                end
            end
        end
    end

    if Character and Root and Humanoid and not Player:GetAttribute("KnockedOut") then
		if Config.AntiAim.Enabled and Config.AntiAim.Type == "Motionless" then
			for _, Part in next, Character:GetChildren() do
				if Part:IsA("BasePart") then
					LastVelocityTable[Part] = Part.Velocity
					Part.Velocity = Config.AntiAim.Motionless.AutomaticallySetAxisValues and Vector3.new(math.random(-9e9, 9e9), math.random(-9e9, 9e9), math.random(-9e9, 9e9)) or Vector3.new(math.random(Config.AntiAim.Motionless.X.Minimum or 0, Config.AntiAim.Motionless.X.Maximum or 0), math.random(Config.AntiAim.Motionless.Y.Minimum or 0, Config.AntiAim.Motionless.Y.Maximum or 0), math.random(Config.AntiAim.Motionless.Z.Minimum or 0, Config.AntiAim.Motionless.Z.Maximum or 0))
				end
			end

			RunService.RenderStepped:Wait()

			for _, Part in next, Character:GetChildren() do
				if Part:IsA("BasePart") then
					Part.Velocity = LastVelocityTable[Part]
				end
			end

			table.clear(LastVelocityTable)
		end

        if Config.AutoFarm.Enabled then
            for _, Item in next, Items do
                if Config.AutoFarm.Table[Item:GetAttribute("Item")] then
                    Teleport(Item.CFrame)
                end
            end
        end

        AutoHealCheck()

        if Buying and not Dragging then
            Root.CFrame = BuyPart.CFrame * CFrame.Angles(0, math.rad(5), 0)
        end

        if not UserInput:GetFocusedTextBox() and UserInput:IsKeyDown(Enum.KeyCode.Space) then
            if Player:GetAttribute("Health") > 0 and Config.InfiniteJump.Enabled then
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end

        AnimationCheck()
    end

    Ping = Utils.math_round(Stats.PerformanceStats.Ping:GetValue(), 2)
    SendPing = Utils.math_round(Stats.PerformanceStats.NetworkSent:GetValue(), 2)
    ReceivePing = Utils.math_round(Stats.PerformanceStats.NetworkReceived:GetValue(), 2)

    debug.profileend()
end


function Stepped(_, Step: number) -- before phys
    debug.profilebegin("[Source.lua]::Stepped()")
    UpdateESP()

    if Character and Root and Humanoid then
        if Config.Float.Enabled then
            if not Player:GetAttribute("KnockedOut") then
                if Config.Flipped.Enabled then
                    FloatPart.Position = Root.Position - Vector3.new(0, 2.5, 0)
                else
                    FloatPart.Position = Root.Position - Vector3.new(0, 3.499, 0)
                end

                if UserInput:IsKeyDown(Enum.KeyCode.E) and not UserInput:GetFocusedTextBox() then
                    FloatPart.Position += Vector3.new(0, 0.4, 0)
                elseif UserInput:IsKeyDown(Enum.KeyCode.Q) and not UserInput:GetFocusedTextBox() then
                    FloatPart.Position -= Vector3.new(0, 0.4, 0)
                end
            end
        end

        if Player:GetAttribute("IsAlive") and Player:GetAttribute("Health") > 0 then
            UpdatePlayerFlyState()

            if Config.Noclip.Enabled then
                Head.CanCollide = false
                Torso.CanCollide = false
            end

            if Config.DisableToolCollision.Enabled then
                for Index, Object in next, Character:GetDescendants() do
                    if Object and Object:FindFirstAncestorWhichIsA("Tool") and (Object:IsA("BasePart") or Object:IsA("MeshPart")) then
                        Object.CanCollide = false
                    end
                end
            end

            if Config.Blink.Enabled then
                local MoveDirection = Humanoid.MoveDirection
                if not UserInput:GetFocusedTextBox() and (UserInput:IsKeyDown(Enum.KeyCode.W) or UserInput:IsKeyDown(Enum.KeyCode.S) or UserInput:IsKeyDown(Enum.KeyCode.A) or UserInput:IsKeyDown(Enum.KeyCode.D)) then
                    Root.CFrame += ((MoveDirection.Magnitude > 0 and MoveDirection or Root.CFrame.LookVector) * Config.Blink.Speed)
                end
            end

            if TargetLock and Config.CameraLock.Enabled and Config.CameraLock.Mode == "Stepped" then
                local _Torso = Utils.GetTorso(Target)
                if _Torso then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, _Torso.CFrame.Position)
                end
            end

            if Config.AntiFling.Enabled then
                if Root.AssemblyLinearVelocity.Magnitude > 200 or Root.AssemblyAngularVelocity.Magnitude > 200 then
                    Root.AssemblyLinearVelocity = Vector3.new()
                end

                for _, Player in next, PlayerManager:GetPlayers({Player}) do
                    local Root = Utils.GetRoot(Player)
                    local Character = Player.Character
                    local Head = Character and Character:FindFirstChild("Head")

                    if Root then
                        Root.AssemblyLinearVelocity = Vector3.new()
                        Root.AssemblyAngularVelocity = Vector3.new()
                        Root.CanCollide = false
                    end

                    if Head then Head.CanCollide = false end
                end
            end

            if Config.Flipped.Enabled then
                local LookVector = Root.CFrame.LookVector
                Root.CFrame = CFrame.new(Root.Position, Root.Position + Vector3.new(1, 0, 0)) * CFrame.Angles(-math.rad(180), 0, 0)
            end

            AutoStompCheck()
        end

        if Config.DoorAura.Enabled then
            for _, Door in next, Doors do
                if Player:DistanceFromCharacter(Door.WoodPart.Position) < 10 then
                    local IsOpen = IsDoorOpen(Door)

                    if not IsOpen then
                        local Locker = Door:FindFirstChild("Locker")

                        if Locker and Locker.Value then
                            Network:Send(Enums.NETWORK.INTERACTABLE_LOCK, Door)
                        end

                        Network:Send(Enums.NETWORK.INTERACTABLE_CLICK, Door)
                    end
                end
            end

            for _, Window in next, Windows do
                if Player:DistanceFromCharacter(Window.Move.Click.Position) < 10 then
                    local IsOpen = IsWindowOpen(Window)

                    if not IsOpen then
                        Network:Send(Enums.NETWORK.INTERACTABLE_CLICK, Window)
                    end
                end
            end
        end

        if Ping < 500 then
            if (Config.OpenDoors.Enabled or Config.CloseDoors.Enabled) then
                for _, Door in next, Doors do
                    if Door:FindFirstChild("Locker") and Door.Locker.Value then continue end
                    local IsOpen = IsDoorOpen(Door)
                    if IsOpen == nil then continue end

                    if IsOpen then
                        if not Config.CloseDoors.Enabled then continue end
                        Network:Send(Enums.NETWORK.INTERACTABLE_CLICK, Door)
                    else
                        if not Config.OpenDoors.Enabled then continue end
                        Network:Send(Enums.NETWORK.INTERACTABLE_CLICK, Door)
                    end
                end
            end

            if (Config.OpenDoors.Enabled or Config.CloseDoors.Enabled) then
                for _, Window in next, Windows do
                    local IsOpen = IsWindowOpen(Window)
                    if IsOpen == nil then continue end

                    if IsOpen then
                        if not Config.CloseDoors.Enabled then continue end
                        Network:Send(Enums.NETWORK.INTERACTABLE_CLICK, Window)
                    else
                        if not Config.OpenDoors.Enabled then continue end
                        Network:Send(Enums.NETWORK.INTERACTABLE_CLICK, Window)
                    end
                end
            end
        end
    end

    debug.profileend()
end


function RenderStepped(Step: number)
    debug.profilebegin("[Source.lua]::RenderStepped()")
    UpdateFieldOfViewCircle() -- Has check if visible anyway
    UpdateAimbotIndicator()

    if Config.Interface.Watermark.Enabled then
        Menu.Watermark:Update(script_name .. " | " .. GetFramerate() .. "fps | " .. math.round(Ping) .. "ms | " .. os.date("%X"))
    end

    local Timer = Player:GetAttribute("KnockOut") or 0
    if Timer > 0 then
        Menu.Indicators.List["Knocked Out"]:SetVisible(true)
        Menu.Indicators.List["Knocked Out"]:Update(Utils.math_round(Timer, 2), 0, 15)
    else
        Menu.Indicators.List["Knocked Out"]:SetVisible(false)
    end
    Menu.Indicators.List.Target:Update("[" .. tostring(Target) .. "]")

    do
        local SelectedTarget = GetSelectedTarget()
        if SelectedTarget then
            UpdatePlayerListInfo(SelectedTarget)
        end
    end
    Menu.Indicators.List["Bullet Tick"]:Update(BulletTick)

    do
        local StompTarget = GetStompTarget()
        Menu.Indicators.List["Stomp Target"]:Update(tostring(StompTarget))
    end

    Config.Interface.Keybinds.Position = Menu.Keybinds.AbsolutePosition
    Config.Interface.Watermark.Position = Menu.Watermark.AbsolutePosition
    Config.Interface.Indicators.Position = Menu.Indicators.AbsolutePosition

    do
        local StaminaTick = os.clock() - (Player:GetAttribute("StaminaTick") or os.clock())
        local HealthTick = os.clock() - (Player:GetAttribute("HealthTick") or os.clock())
        -- if stamina and health have been static for 1.2 seconds then lets fade the bars else lets unfade/keep them visible
        UpdateInterface((HealthTick > 1.2 and StaminaTick > 1.2) and true or false)
    end

    local AmmoLabel = HUD:FindFirstChild("Ammo")
    if AmmoLabel then
        if Tool and Tool:GetAttribute("Gun") then
            local Ammo, Clips = GetToolInfo(Tool, "Ammo")

            AmmoLabel.Text = Config.Interface.ShowAmmo.Enabled and (Clips .. " Clips\n" .. Ammo .. " Ammo") or AmmoLabel.Text
            AmmoLabel.Visible = true
        else
            AmmoLabel.Visible = false
        end
    end

    if BrickTrajectory then
        BrickTrajectory:Remove()
        BrickTrajectory = nil
    end

    if Config.BrickTrajectory.Enabled then
        if Tool and Tool.Name == "Brick" then
            local Points = GetBrickTrajectoryPoints(Tool)
            if typeof(Points) == "table" and #Points > 0 then
                BrickTrajectory = ESP.Trajectory(Points)
                BrickTrajectory:SetColor(Config.BrickTrajectory.Color, Config.BrickTrajectory.Transparency)
            end
        end
    end

    debug.profileend()
end


function OnInput(Input: InputObject, Process: boolean)
    local Object = Mouse.Target
    local Key = Input.KeyCode
    local Input = Input.UserInputType

    local function CheckInput(Comparison)
        if Key == Comparison or Input == Comparison then
            return true
        end

        return false
    end

    -- Command binds set by user
    if not Process then
        for _, Bind in next, Config.Keybinds.Commands do
            if CheckInput(Bind[1]) then
                local Arguments = ""

                for _, v2 in next, Bind[3] do
                    Arguments ..= " " .. v2
                end

                Commands.Check(Bind[2] .. Arguments)
            end
        end
    end

    if CheckInput(Enum.KeyCode.E) then
        if Process then return end

    	if not Utils.IsOriginal then
            task.delay(0.1, function()
            	if not UserInput:IsKeyDown(Key) then
                    if Character and not Dragging and Config.StompSpam.Enabled then
                        if GetStompTarget() then
                            Stomp(200)
                        end
                    end
                end
            end)
    	end
    end

    if CheckInput(Enum.UserInputType.MouseButton1) then
        if Process then return end

        if Config.ClickOpen.Enabled and Object and Object:IsA("BasePart") and Player:DistanceFromCharacter(Object.Position) < 7 then
            local Object_Name = tostring(Object)
            local Door = Object:FindFirstAncestor("Door")
            local Window = Object:FindFirstAncestor("Window", true)

            if (Door or Window) then
                if (Object_Name == "Part" or Object_Name == "Union" or Object_Name == "Click" or Object_Name == "Hinge" or Object_Name == "Glass" or tostring(Object.Parent) == "WoodPart") then
                    local Click = Door:FindFirstChild("Click", true)

                    if Click then
                        Click:FindFirstChildWhichIsA("RemoteEvent", true):FireServer()
                    end
                end
            end
        end
    end

    if CheckInput(Enum.UserInputType.MouseButton2) then
        if Process then return end

        if Object and Config.DoorMenu.Enabled then
            local Door = Object:FindFirstAncestor("Door")

            if Door then
                local Distance = Player:DistanceFromCharacter(Object.Position)
                if Distance < 8 and not Menu.Screen:FindFirstChild("DoorMenu") then
                    ShowDoorMenu(Door)
                end
            end
        end
    end
end


function OnInputEnded(Input: InputObject, Process: boolean)
    local Key = Input.KeyCode
    local Input = Input.UserInputType

    local function CheckInput(Comparison)
        if Key == Comparison or Input == Comparison then return true end
    end
end


function OnChatted(Message: string)
    Commands.Check(Message, string.char(Config.Prefix.Value))
end


function OnIdle()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end


function OnCommandBarFocusLost()
    local CommandBar = Menu.CommandBar

    Menu.Commands.Visible = false
    CommandBar:ReleaseFocus()
    CommandBar:TweenPosition(UDim2.new(0.5, -100, 1, 5), nil, nil, 0.2, true)

    local Success, Result = pcall(Commands.Check, CommandBar.Text)
    if not Success then
        warn(string.format("[Main::OnCommandBarFocusLost()]: %s", Result))
    end

    CommandBar.Text = ""
end


function OnCommandBarTextChanged(Text: string)
    local function FilterCommands(Text: string)
        Menu.Commands.List.CanvasSize = UDim2.new(0, 0, 1, -165)
        for _, Label in next, Menu.CommandLabels do
            local Visible = (string.match(string.lower(Label.Text), string.lower(Text))) and true
            Label.Visible = Visible
            Menu.Commands.List.CanvasSize += UDim2.fromOffset(0, Visible and 15 or -15)
        end
    end

    pcall(FilterCommands, Text)
end


function OnDeath()
    OnPlayerDeath(Player)
    Dragging = false
    DeathPosition = CFrame.new(Root.Position, Root.Position + Root.CFrame.LookVector * Vector3.new(1, 0, 1))
end


function OnStateChange(Old: EnumItem, New: EnumItem)
    if (not Player:GetAttribute("KnockedOut") and Config.AntiGroundHit.Enabled) then
        if New == Enum.HumanoidStateType.FallingDown then
            Humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end

    if New == Enum.HumanoidStateType.PlatformStanding then
        Humanoid.PlatformStand = false
    end
end


function OnCharacterAdded(Player: Player, _Character: Model)
    task.spawn(function()
        if Player == PlayerManager.LocalPlayer then
            Tool = nil
            ToolEquippedTick = 0

            Character = _Character
            HUD = PlayerGui:WaitForChild("HUD")
            Backpack = Player:WaitForChild("Backpack")
            Humanoid = Character:WaitForChild("Humanoid")
            Head = Character:WaitForChild("Head")
            Torso = Character:WaitForChild("Torso")
            Root = Humanoid.RootPart

            if Config.DeathTeleport.Enabled then
                if Config.TeleportBypass.Enabled then
                    Root.CFrame = DeathPosition
                else
                    task.delay(1, Teleport, DeathPosition)
                end
            end

            TeleportBypass()
            EnableInfiniteStamina()
            CreateJoints(Player)

            local function OnBackpackChildAdded(Object: Instance)
                if Object:IsA("Tool") then
                    local Name = Object.Name

                    if Object == Tool then
                        Tool = nil
                        ToolEquippedTick = 0
                    end

                    if GetToolInfo(Object, "IsGun") then
                        if not Object:GetAttribute("Gun") then
                            task.delay(0.1, function()
                                SetToolChams(Object)
                                if Name == "Glock" or Name == "Uzi" then
                                    local Handle = Object:FindFirstChild("Handle")
                                    local Barrel = Object:FindFirstChild("Barrel")

                                    if Handle then Handle.CanCollide = false end
                                    if Barrel then Barrel.CanCollide = false end
                                end
                            end)

                            Object:SetAttribute("Gun", true)
                        end
                    elseif Name == "BoomBox" then
                        Menu.BoomboxFrame.Visible = false
                    elseif string.find(Name, "Cash") then
                        if not Config.AutoCash.Enabled then return end
                        local LastTool = Tool

                        task.delay(0, function()
                            Humanoid:UnequipTools()
                            Object.Parent = Character

                            task.wait()
                            Object:Activate()
                            task.wait()

                            if LastTool then
                                LastTool.Parent = Character
                            end
                        end)
                    end
                end
            end


            local function OnCharacterDescendantAdded(Object: Instance)
                local Name = Object.Name

                if Name == "Bone" then
                    if Player:GetAttribute("KnockedOut") then return end

                    for _, Object in next, Character:GetDescendants() do
                        if Object:IsA("Trail") then
                            Object:Destroy()
                        end
                    end

                    OnPlayerKnockedOut(Player, true)
                elseif Name == "creator" and Object:IsA("ObjectValue") then
                    OnCreatorValueAdded(Object)
                elseif Name == "Bullet" and Object.Parent == Humanoid then -- if it's the bullet instance not the value
                    OnBulletAdded(Object)
                elseif Object:IsA("Tool") then
                    Tool = Object
                    ToolEquippedTick = os.clock()

                    if GetToolInfo(Object, "IsGun") then
                        SetToolChams(Tool)
                        Tool:SetAttribute("Gun", true)
                    elseif Name == "BoomBox" then
                        Menu.BoomboxFrame.Visible = true
                        Menu.BoomboxFrame.List.CanvasSize = UDim2.new()

                        for _, Object in next, Menu.BoomboxFrame.List:GetChildren() do
                            if Object:IsA("GuiButton") then
                                Object:Destroy()
                            end
                        end
                        task.spawn(function()
                            for _, Id in next, AudioLogs do Menu.AddAudioButton(Id) end
                        end)
                    end
                elseif Name == "Dragging" then
                    Dragging = true
                elseif Name == "Dragged" then
                    Dragged = true

                    if Root.Name == "HumanoidRootPart" and Config.LagOnDragged.Enabled then
                        Dragged = true Torso.Anchored = true Root:Destroy() Torso.Anchored = false Root = Torso -- Fuck you it's ugly with newlines
                    end
                end
            end


            local function OnCharacterDescendantRemoving(Object: Instance)
                local Name = Object.Name

                if Name == "Bone" then
                    Player:SetAttribute("KnockedOut", false)
                elseif Name == "Dragging" then
                    Dragging = false
                elseif Name == "Dragged" then
                    Dragged = false
                end
            end


            Humanoid.Died:Connect(OnDeath)
            Humanoid.StateChanged:Connect(OnStateChange)
            Character.DescendantAdded:Connect(OnCharacterDescendantAdded)
            Character.DescendantRemoving:Connect(OnCharacterDescendantRemoving)
            Backpack.ChildAdded:Connect(OnBackpackChildAdded)

            do
                local Ignore = {}
                for _, v in next, Character:GetChildren() do
                    if v:IsA("Tool") then
                        for _, v2 in next, v:GetDescendants() do
                            table.insert(Ignore, v2)
                        end
                    end
                end
                SetModelDefaults(Character, Ignore)

                if Config.ESP.Chams.Local.Enabled then
                    SetPlayerChams(Player, Config.ESP.Chams.Local.Color, Config.ESP.Chams.Local.Material, Config.ESP.Chams.Local.Reflectance, Config.ESP.Chams.Local.Transparency, true)
                end

                if Player.UserId == 1552377192 then
                    DrawStrawHat(Player)
                end
            end

            for _, Tool in next, GetTools() do
                OnBackpackChildAdded(Tool)
            end

            if Config.God.Enabled then
                if Utils.IsOriginal then
                    -- Only 1 method by Cyrus, I know of, that got "patched"
                else
                    -- Method by Reestart;
                    -- Thanks to nixon for giving it to me
                    local Animator = Humanoid:WaitForChild("Animator")
                    Animator:Clone().Parent = Humanoid
                    Animator:Destroy()
                end
                --Character:WaitForChild(Utils.IsOriginal and "Used" or "Right Leg"):Destroy()
            else

                --Character:WaitForChild(Utils.IsOriginal and "GetMouse" or "Gun", 10)
            end

            -- https://devforum.roblox.com/t/error-cannot-load-the-animationclipprovider-service/1639315/7
            -- think this was patched not sure tho :starlightawkward:
            if Character and Humanoid and Character.Parent and Humanoid.Parent == Character then
        --         for _, Track in next, Humanoid:GetPlayingAnimationTracks() do
        --             local AnimationId = string.gsub(Track.Animation.AnimationId, "%D", "")

        --             if AnimationId == "8587081257" or AnimationId == "376653421" or AnimationId == "458506542" or AnimationId == "1484589375" or AnimationId == "180426354" then Track:Stop() end -- Stopping the run animations
        --         end
                for _, Animation in next, Animations do
                    Animation.Track = Humanoid:LoadAnimation(Animation.Animation) -- This has to be done after god mode
                end
            end

            if Config.FirstPerson.Enabled then
                AddFirstPersonEventListeners()
            end

            --if Config.HideVest.Enabled and Player:GetAttribute("Vest") then Character:WaitForChild("BulletResist"):Destroy() end
            if Config.AutoPlay.Enabled then
                if LastAudio ~= 0 then
                    if Utils.UserOwnsAsset(Player, 1159109, "GamePass") then
                        local Boombox = Backpack:WaitForChild("BoomBox")
                        local Remote = Boombox:WaitForChild("RemoteEvent")

                        if Remote then
                            Boombox.Parent = Character
                            Network:Send(Enums.NETWORK.PLAY_BOOMBOX, Boombox, LastAudio)
                            pcall(function() Boombox.BoomBoxu.Entry.TextBox.Text = LastAudio end)
                            task.delay(1, function() Boombox.Parent = Backpack end)
                        end
                    end
                end
            end

            if Config.AutoSort.Enabled then
                SortBackpack()
            end

            if Utils.IsOriginal then
                task.spawn(function()
                    local GroupTitle = HUD:WaitForChild("Clan"):WaitForChild("Group"):WaitForChild("Title")
                    GroupTitle.AutoLocalize = false -- disable TextScraper lag; LocalizationService:StopTextScraper()
                end)
            end

            task.delay(1, StarterGui.SetCore, StarterGui, "ResetButtonCallback", Events.Reset)
            Menu:FindItem("Visuals", "Hats", "ComboBox", "Hat"):SetValue("None", {"None", unpack(Humanoid:GetAccessories())})
        else
            local Character = _Character
            local Backpack = Player:WaitForChild("Backpack")
            local Humanoid = Character:WaitForChild("Humanoid")
            local Torso = Character:WaitForChild("Torso")
            local Root = Character:FindFirstChild("HumanoidRootPart")


            local function OnCharacterDescendantAdded(Object: Instance)
                local Name = Object.Name

                if Name == "creator" and Object:IsA("ObjectValue") then
                    OnCreatorValueAdded(Object)
                elseif Name == "Bullet" and Object.Parent == Humanoid then -- if it's the bullet instance not the value
                    OnBulletAdded(Object)
                elseif Name == "Bone" then
                    if Player:GetAttribute("KnockedOut") then return end

                    for _, Object in next, Character:GetDescendants() do
                        if Object:IsA("Trail") then
                            Object:Destroy()
                        end
                    end

                    OnPlayerKnockedOut(Player, false)
                elseif Object:IsA("Tool") then
                    Player.Tool.Value = Object
                    if GetToolInfo(Object, "IsGun") then
                        Object:SetAttribute("Gun", true)
                    end
                end
            end


            local function OnCharacterDescendantRemoving(Object: Instance)
                local Name = Object.Name

                if Name == "Bone" then
                    if Player:GetAttribute("KnockedOut") == false then return end
                    Player:SetAttribute("KnockedOut", false)

                    SetPlayerChams(Player)
                elseif Object:IsA("Tool") then
                    Player.Tool.Value = nil
                end
            end

            task.delay(1, function() -- Yielding for everything to load in properly
                if not Players:FindFirstChild(Player.Name) then
                    return
                end

                if Character.Parent == nil or Humanoid.Health == 0 then
                    return
                end

                CreateJoints(Player)

                if Player.UserId == 1552377192 then
                    DrawStrawHat(Player)
                end

                if Config.ESP.Enabled then
                    AddPlayerESP(Player)
                end

                do
                    local Ignore = {}

                    for _, v in next, Character:GetChildren() do
                        if v:IsA("Tool") then
                            for _, v2 in next, v:GetDescendants() do
                                table.insert(Ignore, v2)
                            end
                        end
                    end

                    SetModelDefaults(Character, Ignore) -- wait for character to load I guess?
                end
            end)

            Character.DescendantAdded:Connect(OnCharacterDescendantAdded)
            Character.DescendantRemoving:Connect(OnCharacterDescendantRemoving)

            Humanoid.Died:Once(function()
                OnPlayerDeath(Player)
                RemovePlayerESP(Player)
                Player.Tool.Value = nil
            end)

            local Animator = Humanoid:FindFirstChild("Animator")
            if Animator then
                Animator.AnimationPlayed:Connect(function(Track)
                    if Track.Animation.AnimationId == "rbxassetid://215384594" then
                        ResyncPlayer(Player)
                    end
                end)
            end
        end
    end)
end


function OnPlayerAdded(Player: Player)
    if Player == PlayerManager.LocalPlayer then
	local LastHealth = 0
	local LastStamina = 0

        local function OnHealthChange(Health: number)
            if typeof(Health) ~= "number" then return end
            if LastHealth < Health then -- if current health is less than last time then we give player the health_tick attribute
                Player:SetAttribute("HealthTick", os.clock())
            end
	    LastHealth = Health
        end


        local function OnStaminaChanged(Stamina: number)
            if typeof(Stamina) ~= "number" then return end
            if LastStamina < Stamina then -- if current stamina is less than last time then we give player the stamina_tick attribute
                Player:SetAttribute("StaminaTick", os.clock())
            end
	    LastStamina = Stamina
        end

        OnHealthChange(Player:GetAttribute("Health"))
        OnStaminaChanged(Player:GetAttribute("Stamina"))

        Player:GetAttributeChangedSignal("Health"):Connect(function()
            OnHealthChange(Player:GetAttribute("Health"))
        end)

        Player:GetAttributeChangedSignal("Stamina"):Connect(function()
            OnStaminaChanged(Player:GetAttribute("Stamina"))
        end)

        return
    end

    Menu:FindItem("Misc", "Players", "ListBox", "Target"):SetValue(SelectedTarget, Players:GetPlayers())
    Instance.new("ObjectValue", Player).Name = "Tool"

    if Player.Character then
        local Tool = Player.Character:FindFirstChildOfClass("Tool")
        if Tool then
            Player.Tool.Value = Tool

            if GetToolInfo(Tool, "IsGun") then
                Tool:SetAttribute("Gun", true)
            end
        end
    end

    LogEvent("Joined", "\"" .. Player.Name .. "\" has joined the game", tick())
end


function OnPlayerRemoving(Player: Player)
    Menu:FindItem("Misc", "Players", "ListBox", "Target"):SetValue(SelectedTarget, Players:GetPlayers())
    LogEvent("Left", "\"" .. tostring(Player) .. "\" has left the game", tick())

    RemovePlayerESP(Player)
    if Player == Target then
        Target = nil
    end
end


function OnPlayerKnockedOut(Player: Player, Local: boolean)
    Player:SetAttribute("KnockedOut", true)
    AddKnockedOutTimer(Player)

    local Character = Player.Character

    if Local then
        if Config.NoKnockOut.Enabled then ResetCharacter() end
    else
        if Character then
            if Config.ESP.Chams.KnockedOut.Enabled then
                SetPlayerChams(Player, Config.ESP.Chams.KnockedOut.Color, Config.ESP.Chams.KnockedOut.Material, Config.ESP.Chams.KnockedOut.Reflectance, Config.ESP.Chams.KnockedOut.Transparency, true)
            else
                SetPlayerChams(Player)
            end
        end
    end
end


function OnPlayerDamaged(Victim: Player, Attacker: Player, Damage: number, Time: number)
    if typeof(Victim) ~= "Instance" or typeof(Attacker) ~= "Instance" then
        return
    end -- if not instance then ignore

    if not Victim:IsA("Player") or not Attacker:IsA("Player") then
        return
    end -- if it's the DUMMY or a GHOST? or a buypad?

    if (Victim ~= Player and Attacker ~= Player) and (Victim ~= Attacker) then
        return
    end -- if it's not connected to localplayer then ignore

    -- shotty and sawed off check
    for _, Log in next, DamageLogs do
        if (Log.Time - Time) < 0.05 then
            if Log.Victim == Victim and Log.Attacker == Attacker then
                Log.Damage += Damage
                return
            end
        end
    end

    table.insert(DamageLogs, {
        Victim = Victim,
        Attacker = Attacker,
        Damage = Damage,
        Time = Time
    })

    if Attacker == Player then
        if Config.HitSound.Enabled then
            PlaySound(HitSound, 0.8)
        end

        if Config.HitMarkers.Enabled and (Config.HitMarkers.Type == "Crosshair" or Config.HitMarkers.Type == "Crosshair + model") then
            local Cross = DrawCross(Config.HitMarkers.Size, 4)

            Cross:SetColor(Config.HitMarkers.Color, 1 - Config.HitMarkers.Transparency)
            Cross:SetVisible(true)

            if Config.HitMarkers.Fade then
                Cross:FadeOut(Cross.Destroy)
            else
                task.delay(1, Cross.Destroy, Cross)
            end

            task.spawn(function()
                while Cross:IsAlive() do
                    local Location = UserInput:GetMouseLocation()
                    Cross:SetPosition(Location)

                    RunService.RenderStepped:Wait()
                end
            end)
        end
    end

    task.spawn(function()
        local Log = DamageLogs[1]
        local Attacker = Log.Attacker
        local Victim = Log.Victim
        local HealthChangedEvent

        task.delay(0.2, function()
            HealthChangedEvent:Disconnect()
            table.remove(DamageLogs, 1)
        end)

        HealthChangedEvent = Victim:GetAttributeChangedSignal("Health"):Connect(function()
            local Health = math.clamp(Utils.math_round(Victim:GetAttribute("Health"), 2), 0, 100)
            local Damage = Log.Damage

            if Attacker == Player then
                local Color = Config.EventLogs.Colors.Hit:ToHex()

                LogEvent("Damage", string.format("Damaged %s for %s (%s health remaining)", Utils.GetRichTextColor(tostring(Victim), Color),
                    Utils.GetRichTextColor(Damage, Color), Utils.GetRichTextColor(Health, Color)
                ))
            elseif Victim == Player then
                local Color = Config.EventLogs.Colors.Miss:ToHex()

                LogEvent("Damage", string.format("%s damaged you for %s (%s health remaining)", Utils.GetRichTextColor(tostring(Attacker), Color),
                    Utils.GetRichTextColor(Damage, Color), Utils.GetRichTextColor(Health, Color)
                ))
            end

            table.remove(DamageLogs, 1)
        end)
    end)
end


function OnPlayerDeath(Victim: Player, Attacker: Player)
    Victim:SetAttribute("IsAlive", false)
    Victim:SetAttribute("KnockedOut", false)

    LogEvent("Death", Utils.GetRichTextColor(Victim.Name .. " died", Config.EventLogs.Colors.Death:ToHex()), tick())
end


function OnLightingChanged(Property: string)
    if Config.Enviorment.Time.Enabled and Property == "TimeOfDay" then
        Lighting.Time = Config.Enviorment.Time.Value
    end

    if Config.Enviorment.Ambient.Enabled then
        if Property == "Ambient" then
            Lighting.Ambient = Config.Enviorment.Ambient.Colors.Ambient
        end

        if Property == "OutdoorAmbient" then
            Lighting.OutdoorAmbient = Config.Enviorment.Ambient.Colors.OutdoorAmbient
        end
    end
end


function OnCreatorValueAdded(Object: Instance)
    task.spawn(function()
        local Victim = Players:GetPlayerFromCharacter(Object.Parent.Parent) -- Parented in humanoid
        local Attacker = Players:GetPlayerFromCharacter(Object.Value)
        local Info = Object:WaitForChild("Info", 10)
        local Damage = Info:FindFirstChild("Damage")

        if Damage then
            OnPlayerDamaged(Victim, Attacker, Damage.Value, tick())
        end
    end)
end


function OnBulletAdded(Bullet: Instance)
    if Bullet.Parent == nil then
    	Bullet.AncestryChanged:Wait()
    	return OnBulletAdded(Bullet)
    end

    task.delay(0, function()
        if Bullet.Parent then
            Bullet.Parent = Camera
        end -- Snake didn't account for LocalTransparency so if ur in first person we can now see them again
    end)

    task.delay(15, Bullet.Destroy, Bullet)

    if Bullet.Parent ~= Humanoid then return end
    BulletTick = Utils.math_round(os.clock() - FireTick, 5)

    local Origin = Bullet.Position

    task.spawn(function()
        Bullet:GetPropertyChangedSignal("Position"):Wait()

        local End = Bullet.Position
        local Direction = (End - Origin).Unit
        local Distance = 150

        -- table.insert(BulletLogs, {
        --     Origin = Origin,
        --     End = End,
        --     TargetOrigin = Target and Target:GetAttribute("Position"),
        --     Time = tick()
        -- })

        if Config.BulletImpact.Enabled then
            CreateBulletImpact(End, Config.BulletImpact.Color)
        end

        -- TagSystem doesn't log Client damaged Player, so we have to raycast our bullets
        local Result = Raycast.new(Origin, Direction * Distance, {Camera, Character}) -- shouldn't this be done before the position change?
        local InterSection = Result and Result.Position or Origin + Direction
        local Distance = (Origin - InterSection).Magnitude
        local Part = Result and Result.Instance

        if Part then
            local Humanoid = Part.Parent:FindFirstChild("Humanoid") or Part.Parent.Parent:FindFirstChild("Humanoid")
            if Humanoid then
                if Utils.IsOriginal then -- not useful in prison, also the function isn't very reliable; snake please add damage logs in tagsystem
                    OnPlayerDamaged(Players:GetPlayerFromCharacter(Humanoid.Parent), Player, 0, tick())
                end
            end
        end

        if Config.HitMarkers.Enabled and (Config.HitMarkers.Type == "Model" or Config.HitMarkers.Type == "Crosshair + model") then
            local Cross = DrawCross(Config.HitMarkers.Size, 4)
            Cross:SetColor(Config.HitMarkers.Color, 1 - Config.HitMarkers.Transparency)

            if Config.HitMarkers.Fade then
                Cross:FadeOut(function()
                    Cross:Destroy()
                end)
            else
                task.delay(1, function()
                    Cross:Destroy()
                end)
            end

            while Cross:IsAlive() do
                local Position, Visible = Camera:WorldToViewportPoint(End)
                local Distance = (Camera.CFrame.Position - End).Magnitude

                Cross:SetVisible(Visible)
                Cross:SetSize((Distance / 100) * 1 - Config.HitMarkers.Size)
                Cross:SetPosition(Vector2.new(Position.x, Position.y))

                RunService.RenderStepped:Wait()
            end
        end
    end)


    task.spawn(function()
        local Trail = Bullet:WaitForChild("Trail")
        Bullet:WaitForChild("Attachment").Name = "Attachment0"
        Bullet:WaitForChild("Attachment").Name = "Attachment1"

        Trail.Enabled = not Config.BulletTracers.DisableTrails

        if Config.BulletTracers.Enabled and Config.BulletTracers.DisableTrails then -- Disable trails for bullet tracers
            local Tracer = Trail:Clone()
            --6091341618 ; 7151778302; 7071778278; 446111271; 3517446796; 7135001284; 7151842823; 7151777149; 5864341017; 6045867277; 6091329339; 6091474388; 1246346065

            Tracer.Color = ColorSequence.new(Config.BulletTracers.Color, Config.BulletTracers.Color)
            Tracer.Attachment0.Position = Vector3.new(0, -0.3, 0)
            Tracer.Attachment1.Position = Vector3.new(0, 0.3, 0)
            Tracer.Transparency = NumberSequence.new(0)
            Tracer.Texture = "rbxassetid://446111271"
            Tracer.TextureLength = 2
            Tracer.Lifetime = Config.BulletTracers.Lifetime / 1000 -- Clamped to Bullet Life
            Tracer.Enabled = true
            Tracer.Parent = Bullet
        end
    end)
end


function OnWorkspaceChildAdded(Object: Instance)
    local Name = Object.Name

    if Name == "RandomSpawner" then
        task.delay(0, AddItem, Object)
    elseif Object:IsA("Decal") then
        if Config.HideSprays.Enabled then

        end
    end
end


function OnWorkspaceChildRemoved(Object: Instance)
    local Name = Object.Name

    if Name == "RandomSpawner" then
        Items[Object] = nil
    end
end


function OnGetMouseInvoke(): any -- Uuh but weguwarid why don't u just hook mouse.hit and mouse.target; FUCK U
    FireTick = os.clock()

    if Target and Target.Character and Config.Aimbot.Enabled then
        local AimbotCFrame = (Tool and Tool.Name == "Brick") and (GetAimbotCFrame() + Vector3.new(0, 3, 0)) or GetAimbotCFrame(true)
        return AimbotCFrame or Mouse.Hit, Target.Character
    end

    return Mouse.Hit, Mouse.Target
end


function OnTagReplicateEvent(State, Data)
    for _, v in next, Data do
        for _, v2 in next, v do
            local Name = v2.n

            if Name == "creator" then
                local Me = v2.m -- Incase player changes their name on client (Don't do that retard)
                local Tick = string.gsub(v2.t, tostring(Me) .. Name .. "0" , "") -- Thanks for adding this extra useless shit, retarded snake
                local Value = v2.v

                local Victim = Player
                local Attacker = Players:GetPlayerFromCharacter(Value)

                OnPlayerDamaged(Victim, Attacker, 0, Tick)
            end
        end
    end
end


function OnNewMessageEvent(Data: table)
    if Data.SpeakerUserId == Player.UserId then
        OnChatted(Data.Message)
    end
end


-- Key bind toggles


function AimbotToggle(Action_Name: string, State: EnumItem, Input: InputObject)
    if not State or State == Enum.UserInputState.Begin then
        Config.Aimbot.Enabled = not Config.Aimbot.Enabled

        Menu:FindItem("Combat", "Aimbot", "CheckBox", "Enabled"):SetValue(Config.Aimbot.Enabled)
        Menu.Keybinds.List.Aimbot:Update(Config.Aimbot.Enabled and "on" or "off")
        Menu.Keybinds.List.Aimbot:SetVisible(Config.Aimbot.Enabled)
    end
end


function AutoFireToggle(Action_Name: string, State: EnumItem, Input: InputObject)
    if not State or State == Enum.UserInputState.Begin then
        Config.AutoFire.Enabled = not Config.AutoFire.Enabled
        Menu:FindItem("Combat", "Aimbot", "CheckBox", "Auto fire"):SetValue(Config.AutoFire.Enabled)
    end
end


function CameraLockToggle(Action_Name: string, State: EnumItem, Input: InputObject)
    if not State or State == Enum.UserInputState.Begin then
        Config.CameraLock.Enabled = not Config.CameraLock.Enabled

        Menu:FindItem("Combat", "Aimbot", "CheckBox", "Camera lock"):SetValue(Config.CameraLock.Enabled)
        Menu.Keybinds.List["Camera Lock"]:Update(Config.CameraLock.Enabled and "on" or "off")
        Menu.Keybinds.List["Camera Lock"]:SetVisible(Config.CameraLock.Enabled)
    end
end


function FlyToggle(Action_Name: string, State: EnumItem, Input: InputObject)
    if not State or State == Enum.UserInputState.Begin then
        Config.Flight.Enabled = not Config.Flight.Enabled

        if Humanoid and not Config.Flight.Enabled then
            Humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end

        Menu:FindItem("Player", "Movement", "CheckBox", "Flight"):SetValue(Config.Flight.Enabled)
        Menu.Keybinds.List.Flight:Update(Config.Flight.Enabled and "on" or "off")
        Menu.Keybinds.List.Flight:SetVisible(Config.Flight.Enabled)
    end
end


function BlinkToggle(Action_Name: string, State: EnumItem, Input: InputObject)
    if not State or State == Enum.UserInputState.Begin then
        Config.Blink.Enabled = not Config.Blink.Enabled

        Menu:FindItem("Player", "Movement", "CheckBox", "Blink"):SetValue(Config.Blink.Enabled)
        Menu.Keybinds.List.Blink:Update(Config.Blink.Enabled and "on" or "off")
        Menu.Keybinds.List.Blink:SetVisible(Config.Blink.Enabled)
    end
end


function FloatToggle(Action_Name: string, State: EnumItem, Input: InputObject)
    if not State or State == Enum.UserInputState.Begin then
        Config.Float.Enabled = not Config.Float.Enabled
        FloatPart.CanCollide = Config.Float.Enabled

        Menu:FindItem("Player", "Movement", "CheckBox", "Float"):SetValue(Config.Float.Enabled)
        Menu.Keybinds.List.Float:Update(Config.Float.Enabled and "on" or "off")
        Menu.Keybinds.List.Float:SetVisible(Config.Float.Enabled)
    end
end


function NoclipToggle(Action_Name: string, State: EnumItem, Input: InputObject)
    if not State or State == Enum.UserInputState.Begin then
        Config.Noclip.Enabled = not Config.Noclip.Enabled

        Menu:FindItem("Player", "Movement", "CheckBox", "Noclip"):SetValue(Config.Noclip.Enabled)
        Menu.Keybinds.List.Noclip:Update(Config.Noclip.Enabled and "on" or "off")
        Menu.Keybinds.List.Noclip:SetVisible(Config.Noclip.Enabled)
    end
end


function AntiAimToggle(Action_Name: string, State: EnumItem, Input: InputObject)
    if not State or State == Enum.UserInputState.Begin then
        Config.AntiAim.Enabled = not Config.AntiAim.Enabled
        UpdateAntiAim()

        Menu:FindItem("Player", "Anti-aim", "CheckBox", "Enabled"):SetValue(Config.AntiAim.Enabled)
        Menu.Keybinds.List["Anti Aim"]:Update(Config.AntiAim.Enabled and "on" or "off")
        Menu.Keybinds.List["Anti Aim"]:SetVisible(Config.AntiAim.Enabled)
    end
end


function BuyAmmoToggle(Action_Name: string, State: EnumItem, Input: InputObject)
	if not State or State == Enum.UserInputState.Begin then
	    BuyItem("Ammo")
	end
end


function CommandBarToggle(Action_Name: string, State: EnumItem, Input: InputObject)
    if not State or State == Enum.UserInputState.Begin then
        local CommandBar = Menu.CommandBar

        Menu.Commands.Visible = true
        CommandBar:CaptureFocus()
        CommandBar:TweenPosition(UDim2.new(0.5, -100, 0.6, -10), nil, nil, 0.2, true)

        task.delay(0, function() CommandBar.Text = "" end)
    end
end


function MenuToggle(Action_Name: string, State: EnumItem, Input: InputObject)
    if not State or State == Enum.UserInputState.Begin then
        Menu:SetVisible(not Menu.IsVisible)
    end
end


function HookGame()
    if Utils.IsOriginal then
        for _, Connection in next, getconnections(ScriptContext.Error) do
            if getfenv(Connection.Function).script == PlayerGui.LocalScript then
                Connection:Disable()
            end
        end
    else
        local wait_hook;
        wait_hook = hookfunction(wait, function(constant)
            if not checkcaller() and Config.NoGunDelay.Enabled and (constant == 0.5 or constant == 0.25 or constant == 0.33) then
                constant = 0
            end

            return wait_hook(constant)
        end)
    end

    local Index, NewIndex, NameCall, OldFunctionHook

    local function OnIndex(self: Instance, Key: any)
        local Caller = checkcaller()
        local Name = tostring(self)

        if not Caller then
            if table.find({"Stamina", "Stann", "Stam"}, Name) and Key == "Value" then
                return (Config.NoSlow.Enabled or Config.God.Enabled) and 100 or math.clamp(Player:GetAttribute("Stamina") or 0, 0, 100) -- meh?
            end

            if not Utils.IsOriginal and (Config.NoSlow.Enabled or Config.God.Enabled) then
                if self == Root and Key == "Anchored" and (Tool and Tool:GetAttribute("Gun")) then
                    return false
                end
            end

            if self == ScriptContext and Key == "Error" then
                return {connect = function() end} -- HACKED
            end

            if Name == "Namer" and Config.God.Enabled then
                return "Torso"
            end

            if Name == "LocalScript" and Key == "Disabled" then
                return false
            end

            if self == Humanoid then
                if Key == "WalkSpeed" then
                    return ORIGINAL_SPEED
                end

                if Key == "HipHeight" then
                    return ORIGINAL_HIPHEIGHT
                end

                if Key == "JumpPower" then
                    return ORIGINAL_JUMPPOWER
                end
            end

            if self == workspace and Key == "Gravity" then
                return ORIGINAL_GRAVITY
            end
        end

        return Index(self, Key)
    end

    local function OnNewIndex(self: Instance, Key: any, Value: any)
        local Caller = checkcaller()

        if Caller then
            return NewIndex(self, Key, Value)
        end

        if self == Mouse and Key == "Icon" then return end
        if Utils.IsOriginal and Key == "OnClientInvoke" and self.Name == "GetMouse" and self.ClassName == "RemoteFunction" then
            Value = OnGetMouseInvoke
        end

        if self == Humanoid then
            if Key == "WalkSpeed" then
                local IsRunning = Value > 16
                local IsWalking = Value > 8 and Value < 18
                local IsCrouching = Value == 8
                local Hit = Value == 2
                local CantMove = Value == 0

                Running = IsRunning
                Crouching = IsCrouching
                ORIGINAL_SPEED = Value

                if (Config.NoSlow.Enabled or Config.God.Enabled) and (CantMove or Hit) then
                    return
                end

                Value = (IsRunning and Config.RunSpeed.Value) or (IsCrouching and Config.CrouchSpeed.Value) or (IsWalking and Config.WalkSpeed.Value)
            end

            if Key == "JumpPower" then
                Value = (Value > 0 and Config.JumpPower.Value) or (Value == 0 and (Config.NoSlow.Enabled or Config.God.Enabled) and Config.JumpPower.Value or 0)
            end

            if (Key == "Jump" and not Value) and (Config.NoSlow.Enabled or Config.God.Enabled) then
                return
            end

            if Key == "AutoRotate" then
                Value = true
            end

            if Key == "Health" then return end
        end

        if Key == "CFrame" and self == Root then
            return
        end

        return NewIndex(self, Key, Value)
    end

    local function OnNameCall(self: Instance, ...)
        local Arguments = {...}
        local Name = self.Name
        local Caller, Method = checkcaller(), (getnamecallmethod or get_namecall_method)()

        if self == Player and (Method == "Kick" or Method == "kick") then
            return
        end

        if (Method == "FireServer" or Method == "fireServer") and self.ClassName == "RemoteEvent" then
            if self.Parent == ReplicatedStorage then
                local Whitelist = {"TagReplicate"} -- "Xbox", "Talk", "Feedback", "VoteKick"
                if not table.find(Whitelist, Name) then return end
            end
            
            if Name == "SprayIt" then
                if Config.BetterSprayQuality.Enabled then
                    Arguments[2] ..= "&w=768&h=432"
                end
                if Config.CircularSprays.Enabled then
                    Arguments[2] ..= "&filters=circular"
                end
            end

            if Name == "Input" then
                local Key = Arguments[1]

                if Key == "ml" or Key == "moff1" then
                    if not Caller and Menu.IsVisible and Menu:IsMouseInBounds() then
                        return
                    end

                    if typeof(Arguments[2]) ~= "table" then
                        Arguments[2] = {}
                    end

                    Arguments[2].mousehit = Mouse.Hit or CFrame.new()
                    Arguments[2].velo = 16

                    if Target and Config.Aimbot.Enabled then
                        Arguments[2].mousehit = GetAimbotCFrame(true) or Mouse.Hit
                    end

                    if Config.AlwaysGroundHit.Enabled then
                        Arguments[2].shift = true
                    end

                    FireTick = os.clock()
                elseif Key == 'e' or Key == "drag" or Key == "dragoff" then
                    Arguments = {Key, {}}
                elseif Key == "checkin1" or Key == "checkin2" or Key == "checkin3" then
                elseif Key == "buy" then
                else
                    -- unless u want to get banned
                    return
                end
            end

            if (Utils.IsPrison and Name == "Fire") then
                if not Caller and Menu.IsVisible and Menu:IsMouseInBounds() then
                    return
                end

                Arguments[1] = Mouse.Hit or CFrame.new()
                if Target and Config.Aimbot.Enabled then
                    Arguments[1] = GetAimbotCFrame(true) or Mouse.Hit
                end

                FireTick = os.clock()
            end

            if Name == "Touch1" then
                if Config.AlwaysGroundHit.Enabled then
                    Arguments[3] = true
                end
            end

            if not Caller and Arguments[1] == "play" and Arguments[2] then
                LastAudio = Arguments[2]

                if not table.find(AudioLogs, LastAudio) then
                    table.insert(AudioLogs, LastAudio)
                    writefile(script_name .. "/Games/The Streets/Audios.dat", table.concat(AudioLogs, "\n"))
                end
            end
        end


        if table.find({"Destroy", "destroy", "Remove", "remove"}, Method) then
            if FlyVelocity.Parent == self then
                FlyVelocity.Parent = nil
            end

            if FlyAngularVelocity.Parent == self then
                FlyAngularVelocity.Parent = nil
            end
        end

        if not Caller then
            if self.ClassName == "AnimationTrack" then
                local AnimationId = string.gsub(self.Animation.AnimationId, "%D", "")

                if table.find({"Play", "play", "Stop", "stop"}, Method) and table.find(AnimationIds, AnimationId) then
                    if Config.Animations.Run.Enabled then
                        local Style = Config.Animations.Run.Style
                        self = Style == "Default" and Animations.Run.Track or Style == "Style-2" and Animations.Run2.Track or Animations.Run3.Track
                    end
                end
            end

            if Method == "PlayerOwnsAsset" and Arguments[2] == 457667510 then
                return Player.GetAttribute(Player, "AnimeGamePass")
            end

            if Method == "IsA" or Method == "isA" then
                if (self == FlyVelocity or self == FlyAngularVelocity) or string.find(self.ClassName, "Body") then
                    return
                end
            end

            if Method == "Destroy" then
                if self == Character then return end
                if Name == "Head" or Name == "Torso" then return end
                if string.find(self.ClassName, "Body") then return end
            end

            if self == Character and (Method == "BreakJoints" or Method == "ClearAllChildren") then
                return
            end

            if (Method == "WaitForChild" or Method == "FindFirstChild" or Method == "findFirstChild") then
                local Key = Arguments[1]

                if Config.NoSlow.Enabled and ((Key == "Action") or (Key == "Info" and self.ClassName ~= "Tool")) then
                    return
                end -- Checks for OnHit :: Play Anim

                if self == Character and Key == "HumanoidRootPart" then
                    Arguments[1] = "Torso"
                end
            end
        end

        return NameCall(self, unpack(Arguments))
    end

    local PostMessageHook = function(self, Message)
        if not checkcaller() and self == PostMessage and Config.AntiChatLog.Enabled then
            MessageEvent:Fire(Message)
            return
        end
        -- Credits to whoever made this function
        return OldFunctionHook(self, Message)
    end

    Index = hookmetamethod(game, "__index", OnIndex)
    NewIndex = hookmetamethod(game, "__newindex", OnNewIndex)
    NameCall = hookmetamethod(game, "__namecall", OnNameCall)

    OldFunctionHook = hookfunction(PostMessage.fire, PostMessageHook)

    return true
end


function InitializeCommands()
    -- Commands
    Commands.Add("walkspeed", {"ws"}, "[number] - sets your walkspeed to 'number'", function(Arguments)
        Config.WalkSpeed.Value = Arguments[1] or 16
        Menu:FindItem("Player", "Movement", "Slider", "Walk speed"):SetValue(Config.WalkSpeed.Value)
    end)

    Commands.Add("jumppower", {"jp"}, "[number] - sets your jumppower to 'number'", function(Arguments)
        Config.JumpPower.Value = Arguments[1] or 37.5
        Menu:FindItem("Player", "Movement", "Slider", "Jump power"):SetValue(Config.JumpPower.Value)
    end)

    Commands.Add("runspeed", {"rs"}, "[number] - sets your runspeed to 'number'", function(Arguments)
        Config.RunSpeed.Value = Arguments[1] or 24.5
        Menu:FindItem("Player", "Movement", "Slider", "Run speed"):SetValue(Config.RunSpeed.Value)
    end)

    Commands.Add("crouchspeed", {"cs"}, "[number] - sets your crouchspeed to 'number'", function(Arguments)
        Config.CrouchSpeed.Value = Arguments[1] or 8
        Menu:FindItem("Player", "Movement", "Slider", "Crouch speed"):SetValue(Config.CrouchSpeed.Value)
    end)

    Commands.Add("hipheight", {"hh"}, "[number] - sets your hipheight to 'number'", function(Arguments)
        Humanoid.HipHeight = Arguments[1] or 0
    end)

    Commands.Add("gravity", {}, "[number] - sets your gravity to 'number'", function(Arguments)
        workspace.Gravity = Arguments[1] or 196.2
    end)

    Commands.Add("blink", {"cfwalk"}, "- enables 'blink mode'", function()
        Config.Blink.Enabled = true
        Menu:FindItem("Player", "Movement", "CheckBox", "Blink"):SetValue(Config.Blink.Enabled)
    end)

    Commands.Add("unblink", {"uncfwalk"}, "- disables 'blink mode'", function()
        Config.Blink.Enabled = false
        Menu:FindItem("Player", "Movement", "CheckBox", "Blink"):SetValue(Config.Blink.Enabled)
    end)

    Commands.Add("fly", {"flight"}, "- enables 'flight'", function()
        FlyToggle()
    end)

    Commands.Add("unfly", {"noflight"}, "- disables 'flight'", function()
        Config.Flight.Enabled = false
        Menu:FindItem("Player", "Movement", "CheckBox", "Flight"):SetValue(Config.Flight.Enabled)
    end)

    Commands.Add("float", {"airwalk"}, "- enables 'float'", function()
        Config.Float.Enabled = not Config.Float.Enabled
        FloatPart.CanCollide = Config.Float.Enabled
        Menu:FindItem("Player", "Movement", "CheckBox", "Float"):SetValue(Config.Float.Enabled)
    end)

    Commands.Add("unfloat", {"unairwalk"}, "- disables 'float'", function()
        Config.Float.Enabled = false
        FloatPart.CanCollide = false
        Menu:FindItem("Player", "Movement", "CheckBox", "Float"):SetValue(Config.Float.Enabled)
    end)

    Commands.Add("noclip", {}, "- enables 'noclip'", function()
        Config.Noclip.Enabled = true
        Menu:FindItem("Player", "Movement", "CheckBox", "Noclip"):SetValue(Config.Noclip.Enabled)
    end)

    Commands.Add("clip", {}, "- disables 'noclip'", function()
        Config.Noclip.Enabled = false
        Menu:FindItem("Player", "Movement", "CheckBox", "Noclip"):SetValue(Config.Noclip.Enabled)
    end)

    Commands.Add("god", {}, "- enables 'god mode'", function()
        Config.God.Enabled = true
        Menu:FindItem("Misc", "Exploits", "CheckBox", "God"):SetValue(Config.God.Enabled)
    end)

    Commands.Add("ungod", {}, "- disables 'god mode'", function()
        Config.God.Enabled = false
        Menu:FindItem("Misc", "Exploits", "CheckBox", "God"):SetValue(Config.God.Enabled)
    end)

    Commands.Add("reset", {"re"}, "- resets your character", RefreshCharacter)

    Commands.Add("car", {"bringcar"}, "[streets only] - brings a car to you", function()
        local Jeep = workspace:FindFirstChild("Jeep")
        if Jeep then
            Jeep.Name = "_Jeep"
        else
            return Menu.Notify("Car not found!", 5)
        end
    
        local Jeep2 = workspace:FindFirstChild("Jeep")
        Jeep.Name = "Jeep"
    
        for _, Jeep in next, {Jeep, Jeep2} do
            local Seat = Jeep:FindFirstChild("DriveSeat")
            if Seat and not Seat.Occupant then
                if not IsSeated() then
                    return Seat:Sit(Humanoid)
                end
            end
        end

        Menu.Notify("Car(s) are occupied by someone else!", 5)
    end)

    Commands.Add("rejoin", {"rj"}, "- attempts to rejoin to the current server", function()
        TeleportToPlace(game.PlaceId, game.JobId)
    end)

    Commands.Add("swap", {}, "- teleports either to the streets or the prison", function()
        TeleportToPlace(Utils.IsOriginal and 4669040 or 455366377)
    end)

    Commands.Add("goto", {"to"}, "[player] - teleports to the 'player'", function(Arguments)
        local Target = Arguments[1] and PlayerManager:FindPlayersByName(Arguments[1])
        for _, Target in next, Target do
            local Torso = Utils.GetTorso(Target)
            if Torso then
                Teleport(Torso.CFrame)
                break
            end
        end
    end)

    Commands.Add("view", {'v'}, "[player] - views the 'player'", function(Arguments)
        local Target = Arguments[1] and PlayerManager:FindPlayersByName(Arguments[1])
        Target = Target and Target[1]
        if Target then
            Config.View.Enabled = true
            SelectedTarget = Target.Name
            Menu:FindItem("Misc", "Players", "ListBox", "Target"):SetValue(SelectedTarget, Players:GetPlayers())
            Menu:FindItem("Misc", "Players", "CheckBox", "View"):SetValue(Config.View.Enabled)
        end
    end)

    Commands.Add("unview", {"uv"}, "disables player view", function()
        Config.View.Enabled = false
        Menu:FindItem("Misc", "Players", "CheckBox", "View"):SetValue(Config.View.Enabled)
    end)

    Commands.Add("item", {"get"}, "[name] - if the item is found then it teleports you to the item", function(Arguments)
        local Name = string.lower(table.concat(Arguments, " "))
        GetItem(Name)
    end)

    Commands.Add("play", {}, "[id] - mass plays the selected 'id'", function(Arguments)
        local Audio = Arguments[1]
        local Boomboxes = {}
        for _, Tool in next, GetTools() do
            if Tool.Name == "BoomBox" then
                Tool.Parent = Character
                local Remote = Tool:FindFirstChildWhichIsA("RemoteEvent", true)
                if Remote then table.insert(Boomboxes, Tool) end
            end
        end

        task.delay(0, function()
            if Audio == "stop" then
                for _, Boombox in next, Boomboxes do Network:Send(Enums.NETWORK.STOP_BOOMBOX, Boombox) end
            else
                for _, Boombox in next, Boomboxes do Network:Send(Enums.NETWORK.PLAY_BOOMBOX, Boombox, Audio) end
            end
        end)
    end)

    Commands.Add("bypass", {}, "[prison only] - attempts to give you tool- and teleport-bypass", function()
        if not Utils.IsOriginal then
            queue_on_teleport([[
                if not game:IsLoaded() then game.Loaded:Wait() end -- Synapse is shit
                game:GetService("TeleportService"):TeleportToPlaceInstance(4669040, game.JobId)
            ]])
            TeleportToPlace(game.PlaceId, game.JobId)
        end
    end)

    --[[
        Commands.Add("breakpads", {"breakbuypads"}, "", function()
            if Utils.IsOriginal then
                Humanoid:Destroy() -- Kicks you, disabling for now
                Backpack:Destroy() -- If This Replicated It Would Also Break Them
                BuyItem("Glock")
            end
        end)
    ]]

    Commands.Add("key", {"bind"}, "- [regularid please do this one]", function(Arguments)
        local Name, Key, Command = table.remove(Arguments, 1), table.remove(Arguments, 1), table.remove(Arguments, 1)
        if Name and Key and Command then
            Name = string.lower(Name)
            Key = string.lower(Key)

            for _, v in next, Enum.KeyCode:GetEnumItems() do
                if Key == string.lower(v.Name) then Key = v break end
            end

            for _, v in next, Enum.UserInputType:GetEnumItems() do
                if Key == string.lower(v.Name) then Key = v break end
            end

            if Name and Key then
                BindKey(Name, "Remove")
                BindKey(Name, "Add", Key, Command, Arguments)
            end
        end
    end)

    Commands.Add("unkey", {"unbind"}, "[keybind name] - unbinds 'keybind name'", function(Arguments)
        local Name = Arguments[1]
        if Name then BindKey(string.lower(Name), "Remove") end
    end)

    Commands.Add("steal", {"st", "log"}, "([audio]/[decal]) [player] - steals the selected audio or decal from 'player'", function(Arguments)
        local asset_type = string.lower(tostring(Arguments[1]))
        local player_name = Arguments[2]

        local Target = PlayerManager:FindPlayersByName(player_name)[1]
        if not Target then
            local Color = Config.EventLogs.Colors.Error:ToHex()
            return Menu.Notify(Utils.GetRichTextColor("player_name for argument[2] expeceted", Color))
        end

        if asset_type == "audio" or asset_type == "sound" or asset_type == "radio" or asset_type == "boombox" then
            local Tools = GetTools(Target)
            if Tools then
                for _, Tool in next, Tools do
                    if Tool.Name == "BoomBox" then
                        local sound = Tool:FindFirstChildWhichIsA("Sound", true)
                        local sound_id = sound and sound.SoundId
                        if sound_id then
                            setclipboard(sound_id)
                            local Color = Config.EventLogs.Colors.Success:ToHex()
                            return Menu.Notify(Utils.GetRichTextColor("set audio_id rbxassetid://'" .. sound_id .. "' to your clipboard", Color))
                        end
                    end
                end

                local Color = Config.EventLogs.Colors.Error:ToHex()
                return Menu.Notify(Utils.GetRichTextColor("no audio from player '" .. Target.Name .. "' found", Color))
            end
        elseif asset_type == "decal" or asset_type == "spray" then
            local spray_part = workspace:FindFirstChild(Target.Name .. "Spray")
            if spray_part then
                local decal = spray_part:WaitForChild("Decal")
                local decal_id = string.match(decal.Texture, "%d+")
                if not Utils.IsOriginal then decal_id += 1 end
                setclipboard(decal_id)
                local Color = Config.EventLogs.Colors.Success:ToHex()
                return Menu.Notify(Utils.GetRichTextColor("set decal_id rbxassetid://'" .. decal_id .. "' to your clipboard", Color))
            else
                local Color = Config.EventLogs.Colors.Error:ToHex()
                return Menu.Notify(Utils.GetRichTextColor("no decal from player '" .. Target.Name .. "' found", Color))
            end
            -- sign check?
        else
            local Color = Config.EventLogs.Colors.Error:ToHex()
            return Menu.Notify(Utils.GetRichTextColor("asset-type for argument[1] expected", Color))
        end
    end)

    -- Command auto-printization thingy (note from xaxa - sorry if this looks bad elden)
    for Index, Command in next, Commands do
        if typeof(Command) == "table" then
            Menu.AddCommandLabel(string.format("%s%s%s %s", Command.Name, (#Command.Aliases > 0 and "/" or ""), ((#Command.Aliases > 0 and table.concat(Command.Aliases, "/")) or ""), Command.Description) .. "\n")
            CommandsList ..= string.format("%s%s%s %s", Command.Name, (#Command.Aliases > 0 and "/" or ""), ((#Command.Aliases > 0 and table.concat(Command.Aliases, "/")) or ""), Command.Description) .. "\n"
        end
    end
end


function InitializeMenu()
    Menu.Accent = Config.Menu.Accent

    function Menu.AddAudioButton(Id: number)
        local Asset = GetAssetInfo(Id)
        local Name = Asset and Asset.Name

        if typeof(Name) == "string" then
            local AudioButton = Instance.new("TextButton")
            AudioButton.BackgroundColor3 = Color3.new(1, 1, 1)
            AudioButton.Size = UDim2.new(1, 0, 0, 22)
            AudioButton.Text = Name
            AudioButton.TextColor3 = Color3.new()
            AudioButton.Font = Enum.Font.SourceSans
            AudioButton.TextSize = 22
            AudioButton.Parent = Menu.BoomboxFrame.List
            AudioButton.MouseButton1Click:Connect(function()
                pcall(function()
                    PlayerGui.BoomBoxu.Entry.TextBox.Text = Id
                    LastAudio = Id
                    for _, Object in next, Character:GetChildren() do
                        if Object.Name == "BoomBox" then Network:Send(Enums.NETWORK.PLAY_BOOMBOX, Object, Id) end
                    end
                end)
            end)

            Menu.BoomboxFrame.List.CanvasSize += UDim2.fromOffset(0, 22)
            return AudioButton
        end
    end


    function Menu.AddCommandLabel(Description: string)
        local Label = Instance.new("TextLabel")
        Label.Name = "Command"
        Label.BackgroundTransparency = 1
        Label.Text = Description
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextColor3 = Color3.new(1, 1, 1)
        Label.TextSize = 12
        Label.Font = Enum.Font.Roboto
        Label.Size = UDim2.new(1, 0, 0, 15)
        Label.Parent = Menu.Commands.List
        
        table.insert(Menu.CommandLabels, Label)
    end


    function Menu:IsMouseInBounds()
        local Location = UserInput.GetMouseLocation(UserInput) - Vector2.new(0, 36)

        local o = 5
        local x2, y2 = Location.X, Location.Y
        local x, y, sx, sy = self.Position.X, self.Position.Y, self.Size.X, self.Size.Y

        return ((x2 + o) > x and (x2 - 5) < (x + sx)) and ((y2 + o) > y and (y2 - o) < (y + sy))
    end


    Menu.Screen.Name = script_name
    Menu:SetTitle(script_name .. Utils.GetRichTextColor(".cc", Config.Menu.Accent:ToHex()))

    Menu.Tab("Combat")
    Menu.Tab("Visuals")
    Menu.Tab("Player")
    Menu.Tab("Teleports")
    Menu.Tab("Misc")
    Menu.Tab("Settings")

    Menu.Container("Combat", "Aimbot", "Left")
    Menu.Container("Combat", "Prediction", "Left")
    Menu.Container("Combat", "Other", "Right")
    Menu.Container("Player", "Movement", "Left")
    Menu.Container("Player", "Other", "Right")
    Menu.Container("Player", "Anti-aim", "Right")
    Menu.Container("Visuals", "ESP", "Left")
    Menu.Container("Visuals", "Local esp", "Left")
    Menu.Container("Visuals", "Item esp", "Left")
    Menu.Container("Visuals", "Hit markers", "Left")
    Menu.Container("Visuals", "Other", "Right")
    Menu.Container("Visuals", "Interface", "Right")
    Menu.Container("Visuals", "World", "Right")
    Menu.Container("Visuals", "Weapons", "Right")
    Menu.Container("Visuals", "Hats", "Right"):SetVisible(Utils.IsOriginal)
	Menu.Container("Teleports", "Buyables", "Left")
	Menu.Container("Teleports", "Other", "Left")
    Menu.Container("Misc", "Main", "Left")
    Menu.Container("Misc", "Animations", "Left")
    Menu.Container("Misc", "Exploits", "Left")
    Menu.Container("Misc", "Players", "Right")
    Menu.Container("Misc", "Clan tag", "Right"):SetVisible(Utils.IsOriginal)
    Menu.Container("Settings", "Menu", "Left")
    Menu.Container("Settings", "Settings", "Left")
    Menu.Container("Settings", "Configs", "Right")

    Menu.CheckBox("Combat", "Aimbot", "Enabled", Config.Aimbot.Enabled, function(Bool)
        AimbotToggle()
    end)

    Menu.Hotkey("Combat", "Aimbot", "Aimbot key", Config.Aimbot.Key, function(KeyCode, State)
        Config.Aimbot.Key = KeyCode
        --[[
        Config.Keybinds.Client = {
            Key = KeyCode,
            State = State
        }]]
        ContextAction:BindAction("aimbotToggle", AimbotToggle, false, KeyCode)
    end)

    Menu.CheckBox("Combat", "Aimbot", "Auto fire", Config.AutoFire.Enabled, function(Bool)
        AutoFireToggle()
    end)
    Menu.Slider("Combat", "Aimbot", "Auto fire range", 5, 150, Config.AutoFire.Range, nil, 1, function(Value)
        Config.AutoFire.Range = Value
    end)
    Menu.CheckBox("Combat", "Aimbot", "Auto fire velocity check", Config.AutoFire.VelocityCheck.Enabled, function(Bool)
        Config.AutoFire.VelocityCheck.Enabled = Bool
    end)
    Menu.Slider("Combat", "Aimbot", "Auto fire max velocity", 0, 100, Config.AutoFire.VelocityCheck.MaxVelocity, nil, 1, function(Value)
	    Config.AutoFire.VelocityCheck.MaxVelocity = Value
    end)
    Menu.CheckBox("Combat", "Aimbot", "Camera lock", Config.CameraLock.Enabled, function(Bool)
        Config.CameraLock.Enabled = Bool
    end)
    Menu.Hotkey("Combat", "Aimbot", "Camera lock key", Config.CameraLock.Key, function(KeyCode)
        Config.CameraLock.Key = KeyCode
        ContextAction:BindAction("cameraLockToggle", CameraLockToggle, false, Config.CameraLock.Key)
    end)
    Menu.ComboBox("Combat", "Aimbot", "Camera lock mode", Config.CameraLock.Mode, {"RenderStepped", "Stepped", "Heartbeat"}, function(String)
        Config.CameraLock.Mode = String
    end)
    Menu.Slider("Combat", "Aimbot", "Radius", 20, 300, Config.Aimbot.Radius, nil, 1, function(Value)
        Config.Aimbot.Radius = Value
    end)
    Menu.ComboBox("Combat", "Aimbot", "Target hitbox", Config.Aimbot.HitBox, {"Head", "Torso", "Root"}, function(String)
        Config.Aimbot.HitBox = String
    end)
    Menu.ComboBox("Combat", "Aimbot", "Target selection", Config.Aimbot.TargetSelection, {"Near player", "Near mouse"}, function(String)
        Config.Aimbot.TargetSelection = String
    end)
    Menu.ComboBox("Combat", "Prediction", "Prediction method", Config.Aimbot.Prediction.Method, {"Velocity", "MoveDirection", "Default"}, function(String)
        Config.Aimbot.Prediction.Method = String

		Menu:FindItem("Combat", "Prediction", "Slider", "Velocity prediction amount"):SetVisible(String == "Velocity")
		Menu:FindItem("Combat", "Prediction", "Slider", "Velocity multiplier"):SetVisible(String == "Default")
    end)
    Menu:GetItem(Menu.Slider("Combat", "Prediction", "Velocity prediction amount", 0, 15, Config.Aimbot.Prediction.VelocityPredictionAmount, "", 1, function(Value)
        Config.Aimbot.Prediction.VelocityPredictionAmount = Value
    end)):SetVisible(Config.Aimbot.Prediction.Method == "Velocity")
	Menu:GetItem(Menu.Slider("Combat", "Prediction", "Velocity multiplier", 1, 3, Config.Aimbot.Prediction.VelocityMultiplier, "x", 1, function(Value)
        Config.Aimbot.Prediction.VelocityMultiplier = Value
    end)):SetVisible(Config.Aimbot.Prediction.Method == "Default")
	Menu.CheckBox("Combat", "Other", "Always ground hit", Config.AlwaysGroundHit.Enabled, function(Bool)
        Config.AlwaysGroundHit.Enabled = Bool
    end)
    Menu:GetItem(Menu.CheckBox("Combat", "Other", "Stomp spam", Config.StompSpam.Enabled, function(Bool)
        Config.StompSpam.Enabled = Bool
    end)):SetVisible(not Utils.IsOriginal)
    Menu.CheckBox("Combat", "Other", "Auto stomp", Config.AutoStomp.Enabled, function(Bool)
        Config.AutoStomp.Enabled = Bool
        --Menu.Indicators.List["Automatic Stomp"]:Update(Config.AutoStomp.Enabled)
    end)
    Menu.Slider("Combat", "Other", "Auto stomp range", 5, 50, Config.AutoStomp.Distance, nil, 1, function(Value)
        Config.AutoStomp.Distance = Value
    end)
    Menu.ComboBox("Combat", "Other", "Auto stomp target", Config.AutoStomp.Target, {"Target", "Whitelist", "All"}, function(String)
        Config.AutoStomp.Target = String
    end)
    Menu.Slider("Player", "Movement", "Walk speed", 0, 500, Config.WalkSpeed.Value, nil, 1, function(Value)
        Config.WalkSpeed.Value = Value
    end)
    Menu.Slider("Player", "Movement", "Jump power", 0, 500, Config.JumpPower.Value, nil, 1, function(Value)
        Config.JumpPower.Value = Value
    end)
    Menu.Slider("Player", "Movement", "Run speed", 0, 500, Config.RunSpeed.Value, nil, 1, function(Value)
        Config.RunSpeed.Value = Value
    end)
    Menu.Slider("Player", "Movement", "Crouch speed", 0, 500, Config.CrouchSpeed.Value, nil, 1, function(Value)
        Config.CrouchSpeed.Value = Value
    end)
    Menu.CheckBox("Player", "Movement", "Blink", Config.Blink.Enabled, function(Bool)
        BlinkToggle()
    end)
    Menu.Hotkey("Player", "Movement", "Blink key", Config.Blink.Key, function(KeyCode)
        Config.Blink.Key = KeyCode
        ContextAction:BindAction("blinkToggle", BlinkToggle, false, Config.Blink.Key)
    end)
    Menu.Slider("Player", "Movement", "Blink speed", 0.1, 20, Config.Blink.Speed, nil, 1, function(Value)
        Config.Blink.Speed = Value
    end)
    Menu.CheckBox("Player", "Movement", "Flight", Config.Flight.Enabled, function(Bool)
        FlyToggle()
    end)
    Menu.Hotkey("Player", "Movement", "Flight key", Config.Flight.Key, function(KeyCode)
        Config.Flight.Key = KeyCode
        ContextAction:BindAction("flyToggle", FlyToggle, false, KeyCode)
    end)
    Menu.Slider("Player", "Movement", "Flight speed", 0.1, 20, Config.Flight.Speed, nil, 1, function(Value)
        Config.Flight.Speed = Value
    end)
    Menu.CheckBox("Player", "Movement", "Float", Config.Float.Enabled, function(Bool)
        FloatToggle()
    end)
    Menu.Hotkey("Player", "Movement", "Float key", Config.Float.Key, function(KeyCode)
        Config.Float.Key = KeyCode
        ContextAction:BindAction("floatToggle", FloatToggle, false, KeyCode)
    end)
    Menu.CheckBox("Player", "Movement", "Infinite jump", Config.InfiniteJump.Enabled, function(Bool)
        Config.InfiniteJump.Enabled = Bool
    end)
    Menu.CheckBox("Player", "Movement", "Noclip", Config.Noclip.Enabled, function(Bool)
        NoclipToggle()
    end)
    Menu.Hotkey("Player", "Movement", "Noclip key", Config.Noclip.Key, function(KeyCode)
        Config.Noclip.Key = KeyCode
        ContextAction:BindAction("noclipToggle", NoclipToggle, false, KeyCode)
    end)
    Menu.CheckBox("Player", "Movement", "Disable tool collision", Config.DisableToolCollision.Enabled, function(Bool)
        Config.DisableToolCollision.Enabled = Bool
    end)
    Menu.CheckBox("Player", "Other", "No knock out", Config.NoKnockOut.Enabled, function(Bool)
        Config.NoKnockOut.Enabled = Bool
    end)
    Menu.CheckBox("Player", "Other", "No slow", Config.NoSlow.Enabled, function(Bool)
        Config.NoSlow.Enabled = Bool
    end)
    Menu.CheckBox("Player", "Other", "Anti ground hit", Config.AntiGroundHit.Enabled, function(Bool)
        Config.AntiGroundHit.Enabled = Bool
    end)
    Menu.CheckBox("Player", "Other", "Anti fling", Config.AntiFling.Enabled, function(Bool)
        Config.AntiFling.Enabled = Bool
    end)
    Menu.CheckBox("Player", "Other", "Death teleport", Config.DeathTeleport.Enabled, function(Bool)
        Config.DeathTeleport.Enabled = Bool
    end)
    Menu.CheckBox("Player", "Other", "Flipped", Config.Flipped.Enabled, function(Bool)
        Config.Flipped.Enabled = Bool
    end)
    Menu.CheckBox("Player", "Anti-aim", "Enabled", Config.AntiAim.Enabled, function(Bool)
        AntiAimToggle()
        UpdateAntiAim()
    end)
    Menu.Hotkey("Player", "Anti-aim", "Anti aim key", Config.AntiAim.Key, function(KeyCode)
        Config.AntiAim.Key = KeyCode
        ContextAction:BindAction("antiAimToggle", AntiAimToggle, false, Config.AntiAim.Key)
    end)
    Menu.ComboBox("Player", "Anti-aim", "Anti aim type", Config.AntiAim.Type, {"Velocity", "Motionless"}, function(String)
        Config.AntiAim.Type = String
        Menu.Keybinds.List["Anti Aim"]:Update("[" .. Config.AntiAim.Type .. "]")
        UpdateAntiAim()

		Menu:FindItem("Player", "Anti-aim", "CheckBox", "Automatically set axis values"):SetVisible(String == "Motionless")
		Menu:FindItem("Player", "Anti-aim", "Slider", "X Minimum"):SetVisible(String == "Motionless")
		Menu:FindItem("Player", "Anti-aim", "Slider", "X Maximum"):SetVisible(String == "Motionless")
		Menu:FindItem("Player", "Anti-aim", "Slider", "Y Minimum"):SetVisible(String == "Motionless")
		Menu:FindItem("Player", "Anti-aim", "Slider", "Y Maximum"):SetVisible(String == "Motionless")
		Menu:FindItem("Player", "Anti-aim", "Slider", "Z Minimum"):SetVisible(String == "Motionless")
		Menu:FindItem("Player", "Anti-aim", "Slider", "Z Maximum"):SetVisible(String == "Motionless")
    end)
	Menu:GetItem(Menu.CheckBox("Player", "Anti-aim", "Automatically set axis values", Config.AntiAim.Motionless.AutomaticallySetAxisValues, function(Bool)
		Config.AntiAim.Motionless.AutomaticallySetAxisValues = Bool

		Menu:FindItem("Player", "Anti-aim", "Slider", "X Minimum"):SetVisible(Bool == false)
		Menu:FindItem("Player", "Anti-aim", "Slider", "X Maximum"):SetVisible(Bool == false)
		Menu:FindItem("Player", "Anti-aim", "Slider", "Y Minimum"):SetVisible(Bool == false)
		Menu:FindItem("Player", "Anti-aim", "Slider", "Y Maximum"):SetVisible(Bool == false)
		Menu:FindItem("Player", "Anti-aim", "Slider", "Z Minimum"):SetVisible(Bool == false)
		Menu:FindItem("Player", "Anti-aim", "Slider", "Z Maximum"):SetVisible(Bool == false)
	end)):SetVisible(Config.AntiAim.Type == "Motionless" and Config.AntiAim.Motionless.AutomaticallySetAxisValues == false)
	Menu:GetItem(Menu.Slider("Player", "Anti-aim", "X Minimum", -2000, 0, 0, nil, 1, function(Value)
		Config.AntiAim.Motionless.X.Minimum = Value
	end)):SetVisible(Config.AntiAim.Type == "Motionless" and Config.AntiAim.Motionless.AutomaticallySetAxisValues == false)
	Menu:GetItem(Menu.Slider("Player", "Anti-aim", "X Maximum", 1, 2000, 0, nil, 1, function(Value)
		Config.AntiAim.Motionless.X.Maximum = Value
	end)):SetVisible(Config.AntiAim.Type == "Motionless" and Config.AntiAim.Motionless.AutomaticallySetAxisValues == false)
	Menu:GetItem(Menu.Slider("Player", "Anti-aim", "Y Minimum", -2000, 0, 0, nil, 1, function(Value)
		Config.AntiAim.Motionless.Y.Minimum = Value
	end)):SetVisible(Config.AntiAim.Type == "Motionless" and Config.AntiAim.Motionless.AutomaticallySetAxisValues == false)
	Menu:GetItem(Menu.Slider("Player", "Anti-aim", "Y Maximum", 1, 2000, 0, nil, 1, function(Value)
		Config.AntiAim.Motionless.Y.Maximum = Value
	end)):SetVisible(Config.AntiAim.Type == "Motionless" and Config.AntiAim.Motionless.AutomaticallySetAxisValues == false)
	Menu:GetItem(Menu.Slider("Player", "Anti-aim", "Z Minimum", -2000, 0, 0, nil, 1, function(Value)
		Config.AntiAim.Motionless.Z.Minimum = Value
	end)):SetVisible(Config.AntiAim.Type == "Motionless" and Config.AntiAim.Motionless.AutomaticallySetAxisValues == false)
	Menu:GetItem(Menu.Slider("Player", "Anti-aim", "Z Maximum", 1, 2000, 0, nil, 1, function(Value)
		Config.AntiAim.Motionless.Z.Maximum = Value
	end)):SetVisible(Config.AntiAim.Type == "Motionless" and Config.AntiAim.Motionless.AutomaticallySetAxisValues == false)
    Menu.CheckBox("Visuals", "ESP", "Enabled", Config.ESP.Enabled, function(Bool)
        Config.ESP.Enabled = Bool
        UpdateESPState()
    end)
    Menu.CheckBox("Visuals", "ESP", "Target lock", Config.ESP.ForceTarget, function(Bool)
        Config.ESP.ForceTarget = Bool
        UpdateESPState()
    end)
    Menu.CheckBox("Visuals", "ESP", "Target override", Config.ESP.TargetOverride.Enabled, function(Bool)
        Config.ESP.TargetOverride.Enabled = Bool
    end)
    Menu.ColorPicker("Visuals", "ESP", "Target color", Config.ESP.TargetOverride.Color, Config.ESP.TargetOverride.Transparency, function(Color, Transparency)
        Config.ESP.TargetOverride.Color = Color
        Config.ESP.TargetOverride.Transparency = Transparency
    end)
    Menu.CheckBox("Visuals", "ESP", "Whitelist override", Config.ESP.WhitelistOverride.Enabled, function(Bool)
        Config.ESP.WhitelistOverride.Enabled = Bool
    end)
    Menu.ColorPicker("Visuals", "ESP", "Whitelist color", Config.ESP.WhitelistOverride.Color, Config.ESP.WhitelistOverride.Transparency, function(Color, Transparency)
        Config.ESP.WhitelistOverride.Color = Color
        Config.ESP.WhitelistOverride.Transparency = Transparency
    end)
    Menu.CheckBox("Visuals", "ESP", "Box", Config.ESP.Box.Enabled, function(Bool)
        Config.ESP.Box.Enabled = Bool
        UpdateESPState()
    end)
    Menu.ColorPicker("Visuals", "ESP", "Box color", Config.ESP.Box.Color, 1 - Config.ESP.Box.Transparency, function(Color, Transparency)
        Config.ESP.Box.Color = Color
        Config.ESP.Box.Transparency = 1 - Transparency
    end)
    Menu.CheckBox("Visuals", "ESP", "Skeleton", Config.ESP.Skeleton.Enabled, function(Bool)
        Config.ESP.Skeleton.Enabled = Bool
        UpdateESPState()
    end)
    Menu.ColorPicker("Visuals", "ESP", "Skeleton color", Config.ESP.Skeleton.Color, 1 - Config.ESP.Skeleton.Transparency, function(Color, Transparency)
        Config.ESP.Skeleton.Color = Color
        Config.ESP.Skeleton.Transparency = 1 - Transparency
    end)
    Menu.CheckBox("Visuals", "ESP", "Chams", Config.ESP.Chams.Enabled, function(Bool)
        Config.ESP.Chams.Enabled = Bool
        UpdateESPState()
    end)
    Menu.CheckBox("Visuals", "ESP", "Chams auto outline color", Config.ESP.Chams.AutoOutlineColor, function(Bool)
        Config.ESP.Chams.AutoOutlineColor = Bool
    end)
    Menu.ColorPicker("Visuals", "ESP", "Chams color", Config.ESP.Chams.Color, Config.ESP.Chams.Transparency, function(Color, Transparency)
        Config.ESP.Chams.Color = Color
        Config.ESP.Chams.Transparency = Transparency
    end)
    Menu.ColorPicker("Visuals", "ESP", "Chams walls color", Config.ESP.Chams.WallsColor, Config.ESP.Chams.WallsTransparency, function(Color, Transparency)
        Config.ESP.Chams.WallsColor = Color
        Config.ESP.Chams.WallsTransparency = Transparency
    end)
    Menu.ColorPicker("Visuals", "ESP", "Chams outline color", Config.ESP.Chams.OutlineColor, Config.ESP.Chams.OutlineTransparency, function(Color, Transparency)
        Config.ESP.Chams.OutlineColor = Color
        Config.ESP.Chams.OutlineTransparency = Transparency
    end)
    Menu.CheckBox("Visuals", "ESP", "Knocked out chams", Config.ESP.Chams.KnockedOut.Enabled, function(Bool)
        Config.ESP.Chams.KnockedOut.Enabled = Bool
        UpdateESPState()
    end)
    Menu.ColorPicker("Visuals", "ESP", "Knocked out chams color", Config.ESP.Chams.KnockedOut.Color, Config.ESP.Chams.KnockedOut.Transparency, function(Color, Transparency)
        Config.ESP.Chams.KnockedOut.Color = Color
        Config.ESP.Chams.KnockedOut.Transparency = Transparency
    end)
    Menu.CheckBox("Visuals", "ESP", "Snapline", Config.ESP.Snaplines.Enabled, function(Bool)
        Config.ESP.Snaplines.Enabled = Bool
        UpdateESPState()
    end)
    Menu.ColorPicker("Visuals", "ESP", "Snapline color", Config.ESP.Snaplines.Color, 1 - Config.ESP.Snaplines.Transparency, function(Color, Transparency)
        Config.ESP.Snaplines.Color = Color
        Config.ESP.Snaplines.Transparency = 1 - Transparency
    end)
    Menu.CheckBox("Visuals", "ESP", "Snapline offscreen", Config.ESP.Snaplines.OffScreen, function(Bool)
        Config.ESP.Snaplines.OffScreen = Bool
    end)
    Menu.CheckBox("Visuals", "ESP", "OOF arrows", Config.ESP.Arrows.Enabled, function(Bool)
        Config.ESP.Arrows.Enabled = Bool
        UpdateESPState()
    end)
    Menu.ColorPicker("Visuals", "ESP", "OOF arrows color", Config.ESP.Arrows.Color, 1 - Config.ESP.Arrows.Transparency, function(Color, Transparency)
        Config.ESP.Arrows.Color = Color
        Config.ESP.Arrows.Transparency = 1 - Transparency
    end)
    Menu.Slider("Visuals", "ESP", "OOF arrows offset", 5, 200, Config.ESP.Arrows.Offset, "px", 1, function(Int)
        Config.ESP.Arrows.Offset = Int
    end)
    Menu.CheckBox("Visuals", "ESP", "Health bar", Config.ESP.Bars.Health.Enabled, function(Bool)
        Config.ESP.Bars.Health.Enabled = Bool
        UpdateESPState()
    end)
    Menu.CheckBox("Visuals", "ESP", "Health bar auto color", Config.ESP.Bars.Health.AutoColor, function(Bool)
        Config.ESP.Bars.Health.AutoColor = Bool
    end)
    Menu.ColorPicker("Visuals", "ESP", "Health bar color", Config.ESP.Bars.Health.Color, 1 - Config.ESP.Bars.Health.Transparency, function(Color, Transparency)
        Config.ESP.Bars.Health.Color = Color
        Config.ESP.Bars.Health.Transparency = 1 - Transparency
    end)
    Menu.CheckBox("Visuals", "ESP", "Knocked out bar", Config.ESP.Bars.KnockedOut.Enabled, function(Bool)
        Config.ESP.Bars.KnockedOut.Enabled = Bool
        UpdateESPState()
    end)
    Menu.ColorPicker("Visuals", "ESP", "Knocked out bar color", Config.ESP.Bars.KnockedOut.Color, 1 - Config.ESP.Bars.KnockedOut.Transparency, function(Color, Transparency)
        Config.ESP.Bars.KnockedOut.Color = Color
        Config.ESP.Bars.KnockedOut.Transparency = 1 - Transparency
    end)
    Menu.CheckBox("Visuals", "ESP", "Ammo bar", Config.ESP.Bars.Ammo.Enabled, function(Bool)
        Config.ESP.Bars.Ammo.Enabled = Bool
        UpdateESPState()
    end)
    Menu.ColorPicker("Visuals", "ESP", "Ammo bar color", Config.ESP.Bars.Ammo.Color, 1 - Config.ESP.Bars.Ammo.Transparency, function(Color, Transparency)
        Config.ESP.Bars.Ammo.Color = Color
        Config.ESP.Bars.Ammo.Transparency = 1 - Transparency
    end)
    Menu.MultiSelect("Visuals", "ESP", "Flags", {
        Name = Config.ESP.Flags.Name.Enabled,
        Weapon = Config.ESP.Flags.Weapon.Text.Enabled,
        Ammo = Config.ESP.Flags.Ammo.Enabled,
        Vest = Config.ESP.Flags.Vest.Enabled,
        Health = Config.ESP.Flags.Health.Enabled,
        Stamina = Config.ESP.Flags.Stamina.Enabled,
        ["Knocked out"] = Config.ESP.Flags.KnockedOut.Enabled,
        Distance = Config.ESP.Flags.Distance.Enabled,
        Velocity = Config.ESP.Flags.Velocity.Enabled
    }, function(Value)
        Config.ESP.Flags.Name.Enabled = Value["Name"]
        Config.ESP.Flags.Weapon.Text.Enabled = Value["Weapon"]
        Config.ESP.Flags.Ammo.Enabled = Value["Ammo"]
        Config.ESP.Flags.Vest.Enabled = Value["Vest"]
        Config.ESP.Flags.Health.Enabled = Value["Health"]
        Config.ESP.Flags.Stamina.Enabled = Value["Stamina"]
        Config.ESP.Flags.KnockedOut.Enabled = Value["Knocked out"]
        Config.ESP.Flags.Distance.Enabled = Value["Distance"]
        Config.ESP.Flags.Velocity.Enabled = Value["Velocity"]

        UpdateESPState()
    end)
    Menu.ComboBox("Visuals", "ESP", "Font", Config.ESP.Font.Font, {"UI", "System", "Plex", "Monospace"}, function(String)
        Config.ESP.Font.Font = String
    end)
    Menu.ColorPicker("Visuals", "ESP", "Font color", Config.ESP.Font.Color, 1 - Config.ESP.Font.Transparency, function(Color, Transparency)
        Config.ESP.Font.Color = Color
        Config.ESP.Font.Transparency = 1 - Transparency
    end)
    Menu.Slider("Visuals", "ESP", "Font size", 10, 32, Config.ESP.Font.Size, "px", 0, function(Value)
        Config.ESP.Font.Size = Value
    end)

    Menu.CheckBox("Visuals", "Local esp", "Chams", Config.ESP.Chams.Local.Enabled, function(Bool)
        Config.ESP.Chams.Local.Enabled = Bool
        if Bool then
            SetPlayerChams(Player, Config.ESP.Chams.Local.Color, Config.ESP.Chams.Local.Material, Config.ESP.Chams.Local.Reflectance, Config.ESP.Chams.Local.Transparency, true)
        else
            SetPlayerChams(Player)
        end
    end)
    Menu.ColorPicker("Visuals", "Local esp", "Chams color", Config.ESP.Chams.Local.Color, Config.ESP.Chams.Local.Transparency, function(Color, Transparency)
        Config.ESP.Chams.Local.Color = Color
        Config.ESP.Chams.Local.Transparency = Transparency
        if Config.ESP.Chams.Local.Enabled then
            SetPlayerChams(Player, Color, Config.ESP.Chams.Local.Material, Config.ESP.Chams.Local.Reflectance, Transparency, true)
        else
            SetPlayerChams(Player)
        end
    end)
    Menu.Slider("Visuals", "Local esp", "Chams reflectance", 0, 1, Config.ESP.Chams.Local.Reflectance, "", 2, function(Value)
        Config.ESP.Chams.Local.Reflectance = Value
        if Config.ESP.Chams.Local.Enabled then
            SetPlayerChams(Player, Config.ESP.Chams.Local.Color, Config.ESP.Chams.Local.Material, Value, Config.ESP.Chams.Local.Transparency, true)
        else
            SetPlayerChams(Player)
        end
    end)
    Menu.ComboBox("Visuals", "Local esp", "Chams material", Config.ESP.Chams.Local.Material, {"Force field", "Glass", "Plastic"}, function(String)
        Config.ESP.Chams.Local.Material = String
        if Config.ESP.Chams.Local.Enabled then
            SetPlayerChams(Player, Config.ESP.Chams.Local.Color, String, Config.ESP.Chams.Local.Reflectance, Config.ESP.Chams.Local.Transparency, true)
        else
            SetPlayerChams(Player)
        end
    end)
    Menu.CheckBox("Visuals", "Local esp", "Visualize fake lag", Config.FakeLag.Visualize, function(Bool)
        Config.FakeLag.Visualize = Bool
    end)
    Menu.ColorPicker("Visuals", "Local esp", "Visualize color", Config.FakeLag.Color, 1 - Config.FakeLag.Transparency, function(Color, Transparency)
        Config.FakeLag.Color = Color
        Config.FakeLag.Transparency = 1 - Transparency
    end)

    Menu.CheckBox("Visuals", "Item esp", "Enabled", Config.ESP.Item.Enabled, function(Bool)
        Config.ESP.Item.Enabled = Bool
        UpdateESPState()
    end)
    Menu.CheckBox("Visuals", "Item esp", "Name", Config.ESP.Item.Flags.Name.Enabled, function(Bool)
        Config.ESP.Item.Flags.Name.Enabled = Bool
        UpdateESPState()
    end)
    Menu.CheckBox("Visuals", "Item esp", "Distance", Config.ESP.Item.Flags.Distance.Enabled, function(Bool)
        Config.ESP.Item.Flags.Distance.Enabled = Bool
        UpdateESPState()
    end)
    Menu.CheckBox("Visuals", "Item esp", "Snapline", Config.ESP.Item.Snaplines.Enabled, function(Bool)
        Config.ESP.Item.Snaplines.Enabled = Bool
        UpdateESPState()
    end)
    Menu.ColorPicker("Visuals", "Item esp", "Snapline color", Config.ESP.Item.Snaplines.Color, 1 - Config.ESP.Item.Snaplines.Transparency, function(Color, Transparency)
        Config.ESP.Item.Snaplines.Color = Color
        Config.ESP.Item.Snaplines.Transparency = 1 - Transparency
    end)
    Menu.CheckBox("Visuals", "Item esp", "Icons", Config.ESP.Item.Flags.Icon.Enabled, function(Bool)
        Config.ESP.Item.Flags.Icon.Enabled = Bool
        UpdateESPState()
    end)
    Menu.ComboBox("Visuals", "Item esp", "Font", Config.ESP.Item.Font.Font, {"UI", "System", "Plex", "Monospace"}, function(String)
        Config.ESP.Item.Font.Font = String
    end)
    Menu.ColorPicker("Visuals", "Item esp", "Font color", Config.ESP.Item.Font.Color, 1 - Config.ESP.Item.Font.Transparency, function(Color, Transparency)
        Config.ESP.Item.Font.Color = Color
        Config.ESP.Item.Font.Transparency = 1 - Transparency
    end)
    Menu.Slider("Visuals", "Item esp", "Font size", 10, 32, Config.ESP.Item.Font.Size, "px", 0, function(Value)
        Config.ESP.Item.Font.Size = Value
    end)
    Menu.CheckBox("Visuals", "Hit markers", "Hit markers", Config.HitMarkers.Enabled, function(Bool)
        Config.HitMarkers.Enabled = Bool
    end)
    Menu.ColorPicker("Visuals", "Hit markers", "Hit markers color", Config.HitMarkers.Color, 1 - Config.HitMarkers.Transparency, function(Color, Transparency)
        Config.HitMarkers.Color = Color
        Config.HitMarkers.Transparency = 1 - Transparency
    end)
    Menu.Slider("Visuals", "Hit markers", "Hit markers size", 5, 20, Config.HitMarkers.Size, nil, 0, function(Value)
        Config.HitMarkers.Size = Value
    end)
    Menu.ComboBox("Visuals", "Hit markers", "Hit markers type", Config.HitMarkers.Type, {"Crosshair", "Model", "Crosshair + model"}, function(String)
        Config.HitMarkers.Type = String
    end)
    Menu.CheckBox("Visuals", "Hit markers", "Hit sound", Config.HitSound.Enabled, function(Bool)
        Config.HitSound.Enabled = Bool
    end)

    Menu.CheckBox("Visuals", "World", "Ambient changer", Config.Enviorment.Ambient.Enabled, function(Bool)
        Config.Enviorment.Ambient.Enabled = Bool
        if Config.Enviorment.Ambient.Enabled then
            Lighting.Ambient = Config.Enviorment.Ambient.Colors.Ambient
            Lighting.OutdoorAmbient = Config.Enviorment.Ambient.Colors.OutdoorAmbient
        else
            Lighting.Ambient = Lighting.DefaultAmbient
            Lighting.OutdoorAmbient = Lighting.DefaultOutdoorAmbient
        end
    end)
    Menu.ColorPicker("Visuals", "World", "Ambient", Config.Enviorment.Ambient.Colors.Ambient, 0, function(Color)
        Config.Enviorment.Ambient.Colors.Ambient = Color
        if Config.Enviorment.Ambient.Enabled then
            Lighting.Ambient = Config.Enviorment.Ambient.Colors.Ambient
            Lighting.OutdoorAmbient = Config.Enviorment.Ambient.Colors.OutdoorAmbient
        end
    end)
    Menu.ColorPicker("Visuals", "World", "Outdoor ambient", Config.Enviorment.Ambient.Colors.OutdoorAmbient, 0, function(Color)
        Config.Enviorment.Ambient.Colors.OutdoorAmbient = Color
        if Config.Enviorment.Ambient.Enabled then
            Lighting.Ambient = Config.Enviorment.Ambient.Colors.Ambient
            Lighting.OutdoorAmbient = Config.Enviorment.Ambient.Colors.OutdoorAmbient
        end
    end)
    Menu.CheckBox("Visuals", "World", "World time changer", Config.Enviorment.Time.Enabled, function(Bool)
        Config.Enviorment.Time.Enabled = Bool
    end)
    Menu.Slider("Visuals", "World", "World time", 0, 24, Config.Enviorment.Time.Value, "h", 1, function(Value)
        Config.Enviorment.Time.Value = math.round(Value)
    end)
    Menu.CheckBox("Visuals", "World", "Saturation changer", Config.Enviorment.Saturation.Enabled, function(Bool)
        Config.Enviorment.Saturation.Enabled = Bool
        Lighting.ColorEffect.Saturation = Config.Enviorment.Saturation.Enabled and Config.Enviorment.Saturation.Value or 0
    end)
    Menu.Slider("Visuals", "World", "Saturation", -1, 0, Config.Enviorment.Saturation.Value, nil, 2, function(Value)
        Config.Enviorment.Saturation.Value = Value
        Lighting.ColorEffect.Saturation = Config.Enviorment.Saturation.Enabled and Config.Enviorment.Saturation.Value or 0
    end)
    Menu.CheckBox("Visuals", "World", "Brick trajectory", Config.BrickTrajectory.Enabled, function(Bool)
        Config.BrickTrajectory.Enabled = Bool
    end)
    Menu.ColorPicker("Visuals", "World", "Brick trajectory color", Config.BrickTrajectory.Color, Config.BrickTrajectory.Transparency, function(Color, Transparency)
        Config.BrickTrajectory.Color = Color
        Config.BrickTrajectory.Transparency = 1 - Transparency
    end)
    Menu.CheckBox("Visuals", "World", "Bullet impacts", Config.BulletImpact.Enabled, function(Bool)
        Config.BulletImpact.Enabled = Bool
    end)
    Menu.ColorPicker("Visuals", "World", "Bullet impacts color", Config.BulletImpact.Color, Config.BulletImpact.Transparency, function(Color, Transparency)
        Config.BulletImpact.Color = Color
        Config.BulletImpact.Transparency = 1 - Transparency
    end)
    Menu.CheckBox("Visuals", "World", "Bullet tracers", Config.BulletTracers.Enabled, function(Bool)
        Config.BulletTracers.Enabled = Bool
    end)
    Menu.ColorPicker("Visuals", "World", "Bullet tracers color", Config.BulletTracers.Color, 0, function(Color)
        Config.BulletTracers.Color = Color
    end)
    Menu.Slider("Visuals", "World", "Bullet tracers lifetime", 0, 6000, Config.BulletTracers.Lifetime, "ms", 1, function(Value)
        Config.BulletTracers.Lifetime = Value
    end)
    Menu.CheckBox("Visuals", "World", "Disable bullet trails", Config.BulletTracers.DisableTrails, function(Bool)
        Config.BulletTracers.DisableTrails = Bool
    end)
    Menu.ComboBox("Visuals", "World", "Skybox", Config.Enviorment.Skybox.Value, Utils.GetFolders(script_name .. "/Games/The Streets/bin/skyboxes/").Names, function(String)
        Config.Enviorment.Skybox.Value = String
        Lighting:UpdateSkybox(Config.Enviorment.Skybox.Value)
    end)

    Menu.CheckBox("Visuals", "Other", "Max zoom changer", Config.Zoom.Enabled, function(Bool)
        Config.Zoom.Enabled = Bool
        Player.CameraMaxZoomDistance = Config.Zoom.Enabled and Config.Zoom.Value or 20
    end)
    Menu.Slider("Visuals", "Other", "Max zoom", 0, 1000, Config.Zoom.Value, nil, 1, function(Value)
        Config.Zoom.Value = Value
        Player.CameraMaxZoomDistance = Config.Zoom.Enabled and Config.Zoom.Value or 20
    end)
    Menu.CheckBox("Visuals", "Other", "Field of view changer", Config.FieldOfView.Enabled, function(Bool)
        Config.FieldOfView.Enabled = Bool
        Camera.FieldOfView = Config.FieldOfView.Enabled and Config.FieldOfView.Value or 70
    end)
    Menu.Slider("Visuals", "Other", "Field of view", 0, 120, Config.FieldOfView.Value, "°", 1, function(Value)
        Config.FieldOfView.Value = Value
        Camera.FieldOfView = Config.FieldOfView.Enabled and Config.FieldOfView.Value or 70
    end)
    Menu.CheckBox("Visuals", "Other", "First person", Config.FirstPerson.Enabled, function(Bool)
        Config.FirstPerson.Enabled = Bool
        if Bool then
            AddFirstPersonEventListeners()
        else
            for _, v in next, Events.FirstPerson do v:Disconnect() end
            table.clear(Events.FirstPerson)
        end
    end)

    Menu.CheckBox("Visuals", "Interface", "Aimbot vector indicator", Config.Aimbot.Visualize, function(Bool)
        Config.Aimbot.Visualize = Bool
    end)
    Menu.CheckBox("Visuals", "Interface", "Field of view circle", Config.Interface.FieldOfViewCircle.Enabled, function(Bool)
        Config.Interface.FieldOfViewCircle.Enabled = Bool
    end)
    Menu.CheckBox("Visuals", "Interface", "Field of view circle filled", Config.Interface.FieldOfViewCircle.Filled, function(Bool)
        Config.Interface.FieldOfViewCircle.Filled = Bool
    end)
    Menu.Slider("Visuals", "Interface", "Field of view circle sides", 0, 50, Config.Interface.FieldOfViewCircle.NumSides, nil, 0, function(Value)
        Config.Interface.FieldOfViewCircle.NumSides = Value
    end)
    Menu.ColorPicker("Visuals", "Interface", "Field of view circle color", Config.Interface.FieldOfViewCircle.Color, 1 - Config.Interface.FieldOfViewCircle.Transparency, function(Color, Transparency)
        Config.Interface.FieldOfViewCircle.Color = Color
        Config.Interface.FieldOfViewCircle.Transparency = 1 - Transparency
    end)
    Menu.CheckBox("Visuals", "Interface", "Watermark", Config.Interface.Watermark.Enabled, function(Bool)
        Config.Interface.Watermark.Enabled = Bool
        Menu.Watermark:SetVisible(Bool)
    end)
    Menu.CheckBox("Visuals", "Interface", "Chat", Config.Interface.Chat.Enabled, function(Bool)
        Config.Interface.Chat.Enabled = Bool
        ChatFrame.Visible = Config.Interface.Chat.Enabled
    end)
    Menu:GetItem(Menu.Slider("Visuals", "Interface", "Chat position", 0, 500, Config.Interface.Chat.Position, "", 0, function(Value)
        Config.Interface.Chat.Position = Value
        ChatFrame.Position = UDim2.new(0, 0, 1, Config.Interface.Chat.Position)
    end)):SetVisible(false) -- "attempt to index number with SetVisible" thats if I dont do the Menu.GetItem thing ???
    Menu.CheckBox("Visuals", "Interface", "Indicators", Config.Interface.Indicators.Enabled, function(Bool)
        Config.Interface.Indicators.Enabled = Bool
        Menu.Indicators:SetVisible(Bool)
    end)
    Menu.CheckBox("Visuals", "Interface", "Keybinds", Config.Interface.Keybinds.Enabled, function(Bool)
        Config.Interface.Keybinds.Enabled = Bool
        Menu.Keybinds:SetVisible(Bool)
    end)
    Menu.CheckBox("Visuals", "Interface", "Show ammo", Config.Interface.ShowAmmo.Enabled, function(Bool)
        Config.Interface.ShowAmmo.Enabled = Bool
    end)
    Menu.CheckBox("Visuals", "Interface", "Remove ui elements", Config.Interface.RemoveUIElements.Enabled, function(Bool)
        Config.Interface.RemoveUIElements.Enabled = Bool
        UpdateInterface()
    end)
    Menu.CheckBox("Visuals", "Interface", "Bar fade", Config.Interface.BarFade.Enabled, function(Bool)
        Config.Interface.BarFade.Enabled = Bool
        UpdateInterface()
    end)

    Menu.CheckBox("Visuals", "Weapons", "Gun chams", Config.GunChams.Enabled, function(Bool)
        Config.GunChams.Enabled = Bool
        for _, Tool in next, GetTools() do
            if Tool:GetAttribute("Gun") then SetToolChams(Tool) end
        end
    end)
    Menu.ColorPicker("Visuals", "Weapons", "Chams color", Config.GunChams.Color, Config.GunChams.Transparency, function(Color, Transparency)
        Config.GunChams.Color = Color
        Config.GunChams.Transparency = Transparency
        for _, Tool in next, GetTools() do
            if Tool:GetAttribute("Gun") then SetToolChams(Tool) end
        end
    end)
    Menu.Slider("Visuals", "Weapons", "Chams reflectance", 0, 1, Config.GunChams.Reflectance, nil, 1, function(Value)
        Config.GunChams.Reflectance = Value
        for _, Tool in next, GetTools() do
            if Tool:GetAttribute("Gun") then SetToolChams(Tool) end
        end
    end)
    Menu.ComboBox("Visuals", "Weapons", "Chams material", Config.GunChams.Material, {"Force field", "Glass", "Neon", "Plastic"}, function(Material)
        Config.GunChams.Material = Material
        for _, Tool in next, GetTools() do
            if Tool:GetAttribute("Gun") then SetToolChams(Tool) end
        end
    end)

    Menu.CheckBox("Visuals", "Hats", "Hat color changer", Config.HatChanger.Enabled, function(Bool)
        Config.HatChanger.Enabled = Utils.IsOriginal and Bool
    end)
    Menu.ComboBox("Visuals", "Hats", "Hat", "None", {"None", {}}, function(Hat)
        SetHat(Hat)
    end)
    Menu.ColorPicker("Visuals", "Hats", "Hat color", Config.HatChanger.Color, 0, function(Color)
        Config.HatChanger.Color = Color
    end)
    Menu.CheckBox("Visuals", "Hats", "Hat color sequence", Config.HatChanger.Sequence.Enabled, function(Bool)
        Config.HatChanger.Sequence.Enabled = Utils.IsOriginal and Bool
    end)
    Menu.Slider("Visuals", "Hats", "Hat color sequence delay", 0.1, 3, Config.HatChanger.Sequence.Delay, 's', 1, function(Value)
        Config.HatChanger.Sequence.Delay = Value
    end)
    Menu.Button("Visuals", "Hats", "Add color to sequence", AddHatChangerColorSequenceColorPicker)
    Menu.Button("Visuals", "Hats", "Remove last color from sequence", RemoveHatChangerColorSequenceColorPicker)

	Menu.CheckBox("Teleports", "Buyables", "Teleport back to last position", Config.TeleportBack.Enabled, function(Bool)
		Config.TeleportBack.Enabled = Bool
	end)
	for Index, Buyable in next, {"Uzi", "Glock", "Sawed Off", "Ammo"} do
		Menu.Button("Teleports", "Buyables", "Buy " .. Buyable, function()
			local Found, BuyableCFrame = false, nil
			if not Character then return end
			local LastCFrame = Character:GetPivot()
			for _, Item in next, Items do
				if string.lower(Item:GetAttribute("Item")) == Buyable then
					Found, BuyableCFrame = true, Item.CFrame
					if Config.TeleportBypass.Enabled then
						Teleport(BuyableCFrame)
					else
						task.spawn(function()
							repeat
								task.wait()
								SetCharacterServerCFrame(BuyableCFrame)
							until Backpack:FindFirstChild(Buyable) or not Character or Humanoid.Health == 0
						end)
					end
					break
				end
			end

			if Utils.IsOriginal and not Found then
				if Config.TeleportBypass.Enabled then
					BuyItem(Buyable)
				else
					task.spawn(function()
						BuyItem(Buyable)
						repeat
							task.wait()
							SetCharacterServerCFrame(BuyableCFrame)
						until Backpack:FindFirstChild(Buyable) or not Character or Humanoid.Health == 0
					end)
				end
			end
			if Config.TeleportBack.Enabled then
				Teleport(LastCFrame)
			end
		end)
	end
	Menu.Hotkey("Teleports", "Buyables", "Buy ammo key", nil, function(KeyCode, State)
		Config.BuyAmmo.Key = KeyCode
		ContextAction:BindAction("buyAmmoKey", BuyAmmoToggle, false, KeyCode)
	end)

    Menu.CheckBox("Misc", "Main", "Auto cash", Config.AutoCash.Enabled, function(Bool)
        Config.AutoCash.Enabled = Bool
    end)
    Menu.CheckBox("Misc", "Main", "Auto farm", Config.AutoFarm.Enabled, function(Bool)
        Config.AutoFarm.Enabled = Bool
    end)
    Menu.MultiSelect("Misc", "Main", "Auto farm table", Config.AutoFarm.Table, function(Items)
        Config.AutoFarm.Table = Items
    end)
    Menu.CheckBox("Misc", "Main", "Auto play", Config.AutoPlay.Enabled, function(Bool)
        Config.AutoPlay.Enabled = Bool
    end)
    Menu.CheckBox("Misc", "Main", "Auto reconnect", Config.AutoReconnect.Enabled, function(Bool)
        Config.AutoReconnect.Enabled = Bool
    end)
    Menu.CheckBox("Misc", "Main", "Anti chat log", Config.AntiChatLog.Enabled, function(Bool)
        Config.AntiChatLog.Enabled = Bool
    end)
    Menu.CheckBox("Misc", "Main", "Auto sort", Config.AutoSort.Enabled, function(Bool)
        Config.AutoSort.Enabled = Bool
    end)
    Menu.MultiSelect("Misc", "Main", "Auto sort order", Config.AutoSort.Order, function(Order)
        Config.AutoSort.Order = Order
    end)
    Menu:GetItem(Menu.CheckBox("Misc", "Main", "Auto heal", Config.AutoHeal.Enabled, function(Bool)
        Config.AutoHeal.Enabled = Bool
    end)):SetVisible(Utils.IsOriginal)
    Menu.CheckBox("Misc", "Main", "Click open", Config.ClickOpen.Enabled, function(Bool)
        Config.ClickOpen.Enabled = Bool
    end)
    Menu.CheckBox("Misc", "Main", "Chat spam", Spamming, function(Bool)
        Spamming = Bool

        if not isfile(script_name .. "/Games/The Streets/Spam.dat") then
            writefile(script_name .. "/Games/The Streets/Spam.dat", "")
        end
    end)
    Menu.CheckBox("Misc", "Main", "Event logs", Config.EventLogs.Enabled, function(Bool)
        Config.EventLogs.Enabled = Bool
    end)
    Menu.MultiSelect("Misc", "Main", "Event log flags", Config.EventLogs.Flags, function(Flags)
        Config.EventLogs.Flags = Flags
    end)
    Menu.CheckBox("Misc", "Main", "Close doors", Config.CloseDoors.Enabled, function(Bool)
        Config.CloseDoors.Enabled = Bool
    end)
    Menu.CheckBox("Misc", "Main", "Open doors", Config.OpenDoors.Enabled, function(Bool)
        Config.OpenDoors.Enabled = Bool
    end)
    Menu.CheckBox("Misc", "Main", "Knock doors", Config.KnockDoors.Enabled, function(Bool)
        Config.KnockDoors.Enabled = Bool
    end)
    Menu.CheckBox("Misc", "Main", "No doors", Config.NoDoors.Enabled, function(Bool)
        Config.NoDoors.Enabled = Bool
        for _, Door in next, Doors do
            for _, Object in next, Door:GetDescendants() do
                if Object:IsA("BasePart") then
                    if Config.NoDoors.Enabled then
                        Object.Transparency = 1
                        Object.CanCollide = false
                    else
                        if not Object:GetAttribute("Ignore") then
                            Object.Transparency = 0
                        end
                        Object.CanCollide = true
                    end
                end
            end
        end
        for _, Window in next, Windows do
            for _, Object in next, Window:GetDescendants() do
                if Object:IsA("BasePart") then
                    if Config.NoDoors.Enabled then
                        Object.Transparency = 1
                        Object.CanCollide = false
                    else
                        if not Object:GetAttribute("Ignore") then
                            Object.Transparency = 0
                        end
                        Object.CanCollide = true
                    end
                end
            end
        end
    end)
    Menu.CheckBox("Misc", "Main", "No seats", Config.NoSeats.Enabled, function(Bool)
        Config.NoSeats.Enabled = Bool
        for _, Seat in next, Seats do
            Seat.Disabled = Bool
        end
    end)
    Menu.CheckBox("Misc", "Main", "Door aura", Config.DoorAura.Enabled, function(Bool)
        Config.DoorAura.Enabled = Bool
    end)
    Menu.CheckBox("Misc", "Main", "Door menu", Config.DoorMenu.Enabled, function(Bool)
        Config.DoorMenu.Enabled = Bool
    end)
	Menu.CheckBox("Misc", "Main", "Remove ice", false, function(Bool)
	    if Bool then
    	    local WinterDecorations = workspace:FindFirstChild("winter")
    		if WinterDecorations then
    			WinterDecorations.Parent = nil
    			Placeholder.WinterDecorations = WinterDecorations
    		end
    	else
    	    if Placeholder.WinterDecorations then
    	        Placeholder.WinterDecorations.Parent = workspace
    	        Placeholder.WinterDecorations = nil
	       end
    	end
	end)
	--Menu.CheckBox("Misc", "Main", "Hide sprays", Config.HideSprays.Enabled, function(Bool)
        --Config.HideSprays.Enabled = Bool
	--end)
	Menu.CheckBox("Misc", "Main", "Better spray quality", Config.BetterSprayQuality.Enabled, function(Bool)
	    Config.BetterSprayQuality.Enabled = Bool
	end)
    Menu.CheckBox("Misc", "Main", "Circular sprays", Config.CircularSprays.Enabled, function(Bool)
        Config.CircularSprays.Enabled = Bool
    end)
    Menu.CheckBox("Misc", "Animations", "Run", Config.Animations.Run.Enabled, function(Bool)
        Config.Animations.Run.Enabled = Bool
    end)
    Menu.ComboBox("Misc", "Animations", "Run animation", "Default", {"Default", "Style-2", "Style-3"}, function(String)
        Config.Animations.Run.Style = String
        Animations.Run.Track:Stop()
        Animations.Run2.Track:Stop()
        Animations.Run3.Track:Stop()
    end)
    Menu.CheckBox("Misc", "Animations", "Glock", Config.Animations.Glock.Enabled, function(Bool)
        Config.Animations.Glock.Enabled = Bool
    end)
    Menu.ComboBox("Misc", "Animations", "Glock animation", "Default", {"Default", "Style-2", "Style-3"}, function(String)
        Config.Animations.Glock.Style = String
    end)
    Menu.CheckBox("Misc", "Animations", "Uzi", Config.Animations.Uzi.Enabled, function(Bool)
        Config.Animations.Uzi.Enabled = Bool
    end)
    Menu.ComboBox("Misc", "Animations", "Uzi animation", "Default", {"Default", "Style-2", "Style-3"}, function(String)
        Config.Animations.Uzi.Style = String
    end)
    Menu.CheckBox("Misc", "Animations", "Shotty", Config.Animations.Shotty.Enabled, function(Bool)
        Config.Animations.Shotty.Enabled = Bool
    end)
    Menu.ComboBox("Misc", "Animations", "Shotty animation", "Default", {"Default", "Style-2", "Style-3"}, function(String)
        Config.Animations.Shotty.Style = String
    end)
    Menu.CheckBox("Misc", "Animations", "Sawed off", Config.Animations["Sawed Off"].Enabled, function(Bool)
        Config.Animations["Sawed Off"].Enabled = Bool
    end)
    Menu.ComboBox("Misc", "Animations", "Sawed off animation", "Default", {"Default", "Style-2", "Style-3"}, function(String)
        Config.Animations["Sawed Off"].Style = String
    end)

    Menu:GetItem(Menu.CheckBox("Misc", "Exploits", "Infinite stamina", Config.InfiniteStamina.Enabled, function(Bool)
        Config.InfiniteStamina.Enabled = Bool
        EnableInfiniteStamina()
    end)):SetVisible(not Utils.IsOriginal)
    Menu.CheckBox("Misc", "Exploits", "Infinite force field", Config.InfiniteForceField.Enabled, function(Bool)
        Config.InfiniteForceField.Enabled = Bool
    end)
    Menu.CheckBox("Misc", "Exploits", "Teleport bypass", Config.TeleportBypass.Enabled, function(Bool)
        Config.TeleportBypass.Enabled = Bool
        TeleportBypass()
    end, Utils.IsOriginal and "Must have clan tag changer disabled and must respawn after enabling")
    Menu:GetItem(Menu.CheckBox("Misc", "Exploits", "God", Config.God.Enabled, function(Bool)
        Config.God.Enabled = Bool
    end)):SetVisible(not Utils.IsOriginal)
    Menu:GetItem(Menu.CheckBox("Misc", "Exploits", "Click spam", Config.ClickSpam.Enabled, function(Bool)
        Config.ClickSpam.Enabled = not Utils.IsOriginal and Bool
    end)):SetVisible(not Utils.IsOriginal)
    Menu:GetItem(Menu.CheckBox("Misc", "Exploits", "No gun delay", Config.NoGunDelay.Enabled, function(Bool)
        Config.NoGunDelay.Enabled = Bool
    end)):SetVisible(not Utils.IsOriginal)
    Menu.CheckBox("Misc", "Exploits", "Lag on dragged", Config.LagOnDragged.Enabled, function(Bool)
        Config.LagOnDragged.Enabled = Bool
    end)
    Menu.CheckBox("Misc", "Exploits", "Fake lag", Config.FakeLag.Enabled, function(Bool)
        Config.FakeLag.Enabled = Bool
    end)
    Menu.Slider("Misc", "Exploits", "Fake lag limit", 3, 15, Config.FakeLag.Limit, "", 1, function(Value)
        Config.FakeLag.Limit = Value / 10
    end)
    -- Menu.Button("Misc", "Exploits", "Crash server", function()
    -- end)
    Menu.ListBox("Misc", "Players", "Target", false, Players:GetPlayers(), function(Player_Name)
        local Player = PlayerManager:FindPlayersByName(Player_Name)[1]
        if not Player then return end
        SelectedTarget = Player.Name

        local Whitelist = table.find(UserTable.Whitelisted, tostring(Player.UserId)) and true or false
        local Owner = table.find(UserTable.Owners, tostring(Player.UserId)) and true or false
        Menu:FindItem("Misc", "Players", "CheckBox", "Whitelisted"):SetValue(Whitelist)
        Menu:FindItem("Misc", "Players", "CheckBox", "Owner"):SetValue(Owner)
    end)

    Menu.CheckBox("Misc", "Players", "Target lock", TargetLock, function(Bool) TargetLock = Bool end)
    Menu.Button("Misc", "Players", "Copy target uid", function()
        local Target = PlayerManager:FindPlayersByName(SelectedTarget)[1]
        if Target then
            setclipboard(tostring(Target.UserId))
        end
    end)
    Menu.Slider("Misc", "Players", "Priority", 0, 3, 1, "", 0, function(Value)
        -- 0 don't attack target; > 0 attack target higher priority target
    end)
    Menu.CheckBox("Misc", "Players", "Attach", Config.Attach.Enabled, function(Bool)
        Config.Attach.Enabled = Bool
        if not Bool then
            for _, Tool in next, GetTools() do
                local ToolInfo = GetToolInfo(Tool)
                if ToolInfo then
                    Tool.Grip = ToolInfo.Grip
                end
            end
        end
    end)
    Menu.Slider("Misc", "Players", "Attach rate", 0, 3000, Config.Attach.RefreshRate, "ms", 1, function(Value)
        Config.Attach.RefreshRate = Value
    end)
    Menu.CheckBox("Misc", "Players", "View", Config.View.Enabled, function(Bool)
        Config.View.Enabled = Bool
    end)
    Menu.CheckBox("Misc", "Players", "Follow", Config.Follow.Enabled, function(Bool)
        Config.Follow.Enabled = Bool
    end)
    Menu.CheckBox("Misc", "Players", "Whitelisted", false, function(Bool)
        local UserId = tostring(GetSelectedTarget().UserId)
        local Index = table.find(UserTable.Whitelisted, UserId)
        if Index then
            table.remove(UserTable.Whitelisted, Index)
        else
            table.insert(UserTable.Whitelisted, UserId)
        end
        writefile(script_name .. "/Games/The Streets/Whitelist.dat", table.concat(UserTable.Whitelisted, "\n"))
    end)
    Menu.CheckBox("Misc", "Players", "Owner", false, function(Bool)
        local UserId = tostring(GetSelectedTarget().UserId)
        local Index = table.find(UserTable.Owners, UserId)
        if Index then
            table.remove(UserTable.Owners, Index)
        else
            table.insert(UserTable.Owners, UserId)
        end
        writefile(script_name .. "/Games/The Streets/Owners.dat", table.concat(UserTable.Owners, "\n"))
    end)
    do
        local Player_Info_Items = {}
        Player_Info_Items["Display name"] = Menu:GetItem(Menu.Label("Misc", "Players", "Display name: ?"))
        Player_Info_Items["Age"] = Menu:GetItem(Menu.Label("Misc", "Players", "Age: 0"))
        Player_Info_Items["Vest"] = Menu:GetItem(Menu.Label("Misc", "Players", "Vest: false"))
        Player_Info_Items["Origin"] = Menu:GetItem(Menu.Label("Misc", "Players", "Origin: (0; 0; 0)"))
        Player_Info_Items["Health"] = Menu:GetItem(Menu.Label("Misc", "Players", "Health: 0"))
        Player_Info_Items["Stamina"] = Menu:GetItem(Menu.Label("Misc", "Players", "Stamina: 0"))
        Player_Info_Items["Knocked out"] = Menu:GetItem(Menu.Label("Misc", "Players", "Knocked out: 0"))

        local function UpdateItemValue(Index, Value)
            Player_Info_Items[Index]:SetLabel(Value)
        end

        function UpdatePlayerListInfo(Player)
            if typeof(Player) == "Instance" and Player:IsA("Player") then
                UpdateItemValue("Display name", "Display name: " .. Player.DisplayName)
                UpdateItemValue("Age", "Age: " .. Player.AccountAge)
                do
                    local Vest = Player:GetAttribute("Vest")
                    UpdateItemValue("Vest", "Vest: " .. tostring(Vest))
                end
                do
                    local Position = Player:GetAttribute("Position")
                    if typeof(Position) == "Vector3" then
                        UpdateItemValue("Origin", string.format("Origin: (%d;, %d; ,%d)", Utils.math_round(Position.X, 2), Utils.math_round(Position.Y, 2), Utils.math_round(Position.Z, 2)))
                    end
                end

                local Health = Utils.math_round(Player:GetAttribute("Health") or 0, 2)
                local Stamina = Utils.math_round(Player:GetAttribute("Stamina") or 0, 2)
                local KnockOut = Utils.math_round(Player:GetAttribute("KnockOut") or 0, 2)

                UpdateItemValue("Health", "Health: " .. tostring(Health))
                UpdateItemValue("Stamina", "Stamina: " .. tostring(Stamina))
                UpdateItemValue("Knocked out", "Knocked out: " .. tostring(KnockOut))
            end
        end
    end

    Menu.CheckBox("Misc", "Clan tag", "Enabled", Config.ClanTag.Enabled, function(Bool)
        Config.ClanTag.Enabled = Bool
    end)
    Menu.CheckBox("Misc", "Clan tag", "Visualize", Config.ClanTag.Visualize, function(Bool)
        Config.ClanTag.Visualize = Bool
    end)
    Menu.TextBox("Misc", "Clan tag", "Tag", Config.ClanTag.Tag, function(Tag)
        Config.ClanTag.Tag = Tag
    end)
    Menu.TextBox("Misc", "Clan tag", "Prefix", Config.ClanTag.Prefix, function(Prefix)
        Config.ClanTag.Prefix = Prefix
    end)
    Menu.TextBox("Misc", "Clan tag", "Suffix", Config.ClanTag.Suffix, function(Suffix)
        Config.ClanTag.Suffix = Suffix
    end)
    Menu.Slider("Misc", "Clan tag", "Tag speed", 0, 5, Config.ClanTag.Speed, 's', 2, function(Speed)
        Config.ClanTag.Speed = Speed
    end)
    Menu.ComboBox("Misc", "Clan tag", "Tag type", Config.ClanTag.Type, {"Static", "Blink", "Normal", "Forward", "Reverse", "Cheat", "Custom", "Info", "Boombox", "Spotify"}, function(Type)
        Config.ClanTag.Type = Type
    end)
    Menu.TextBox("Misc", "Clan tag", "Spotify token", Config.ClanTag.SpotifyToken, function(Token)
        Config.ClanTag.SpotifyToken = Token
    end)

    Menu.Hotkey("Settings", "Menu", "Menu key", Config.Menu.Key, function(KeyCode)
        Config.Menu.Key = KeyCode
        ContextAction:BindAction("menuToggle", MenuToggle, false, KeyCode)
    end)
    Menu.Hotkey("Settings", "Menu", "Prefix", Config.Prefix, function(KeyCode)
        Config.Prefix = KeyCode
        Menu.CommandBar.PlaceholderText = "Command bar [" .. string.char(Config.Prefix.Value) .. "]"
        ContextAction:BindAction("commandBarToggle", CommandBarToggle, false, KeyCode)
    end)
    Menu.ColorPicker("Settings", "Menu", "Menu accent", Config.Menu.Accent, 0, function(Color)
        Menu.Accent = Color
        Config.Menu.Accent = Color
	    Menu:SetTitle(script_name .. Utils.GetRichTextColor(".cc", Color:ToHex()))
    end)

    Menu.Label("Settings", "Settings", "Build version: " .. script_version)
    Menu.Button("Settings", "Settings", "Refresh", function()
        local cfg_name = Menu:FindItem("Settings", "Configs", "ListBox", "Configs"):GetValue()
        Menu:FindItem("Visuals", "World", "ComboBox", "Skybox"):SetValue(Config.Enviorment.Skybox.Value, Utils.GetFolders(script_name .. "/Games/The Streets/bin/skyboxes/").Names)
        Menu:FindItem("Settings", "Configs", "ListBox", "Configs"):SetValue(cfg_name .. ".cfg", Utils.GetFiles(script_name .. "/Games/The Streets/Configs").Names)
        
        HitSound = get_custom_asset(script_name .. "/Games/The Streets/bin/sounds/hitsound.mp3") -- huh seems to automatically when file changes?
        Crosshair = get_custom_asset(script_name .. "/Games/The Streets/bin/crosshairs/crosshair.png")
        Mouse.Icon = Crosshair
    end)

    Menu.TextBox("Settings", "Configs", "Config name", "")
    Menu.ListBox("Settings", "Configs", "Configs", false, Utils.GetFiles(script_name .. "/Games/The Streets/Configs/").Names, function(cfg_name)
        Menu:FindItem("Settings", "Configs", "TextBox", "Config name"):SetValue(cfg_name)
    end)
    Menu.Button("Settings", "Configs", "Create", function()
        local cfg_name = Menu:FindItem("Settings", "Configs", "TextBox", "Config name"):GetValue()
        -- file already exists?
        Configs:Save(cfg_name)
        Menu:FindItem("Settings", "Configs", "ListBox", "Configs"):SetValue(cfg_name .. ".cfg", Utils.GetFiles(script_name .. "/Games/The Streets/Configs").Names)
    end)
    Menu.Button("Settings", "Configs", "Save", function()
        local cfg_name = Menu:FindItem("Settings", "Configs", "ListBox", "Configs"):GetValue()
        Menu.Prompt("Are you sure you want to overwrite save  of  '" .. cfg_name .. "' ?", function() -- 2 spaces since the font makes it look like no spaces
            cfg_name = string.gsub(cfg_name, ".cfg", "")
            Configs:Save(cfg_name)
            Menu:FindItem("Settings", "Configs", "ListBox", "Configs"):SetValue(cfg_name .. ".cfg", Utils.GetFiles(script_name .. "/Games/The Streets/Configs").Names)
        end)
    end)
    Menu.Button("Settings", "Configs", "Load", function()
        local cfg_name = Menu:FindItem("Settings", "Configs", "ListBox", "Configs"):GetValue()
        cfg_name = string.gsub(cfg_name, ".cfg", "")
        LoadConfig(cfg_name)
    end)
    Menu.Button("Settings", "Configs", "Delete", function()
        local cfg_name = Menu:FindItem("Settings", "Configs", "ListBox", "Configs"):GetValue()
        Menu.Prompt("Are you sure you want to delete '" .. cfg_name .. "' ?", function()
            delfile(script_name .. "/Games/The Streets/Configs/" .. cfg_name)
            Menu:FindItem("Settings", "Configs", "ListBox", "Configs"):SetValue("", Utils.GetFiles(script_name .. "/Games/The Streets/Configs").Names)
        end)
    end)


    local BoomboxText = Instance.new("TextLabel")
    local BoomboxList = Instance.new("ScrollingFrame")
    local BoomboxLayout = Instance.new("UIListLayout")

    Menu.BoomboxFrame.ClipsDescendants = true
    Menu.BoomboxFrame.Visible = false
    Menu.BoomboxFrame.Position = UDim2.new(0.375, 0, 0.65, 0)
    Menu.BoomboxFrame.Size = UDim2.new(0.25, 0, 0.25, 0)
    Menu.BoomboxFrame.Style = Enum.FrameStyle.RobloxRound
    Menu.BoomboxFrame.Parent = Menu.Screen

    BoomboxText.Name = "Text"
    BoomboxText.BackgroundTransparency = 1
    BoomboxText.Position = UDim2.new(0, 0, 0, -8)
    BoomboxText.Size = UDim2.new(1, 0, 0, 20)
    BoomboxText.Text = "Recently Played"
    BoomboxText.TextColor3 = Color3.new(1, 1, 1)
    BoomboxText.TextStrokeTransparency = 0
    BoomboxText.Font = Enum.Font.SourceSans
    BoomboxText.TextSize = 24
    BoomboxText.Parent = Menu.BoomboxFrame

    BoomboxList.Name = "List"
    BoomboxList.Active = true
    BoomboxList.BackgroundTransparency = 1
    BoomboxList.BorderSizePixel = 0
    BoomboxList.Position = UDim2.new(0, 0, 0, 20)
    BoomboxList.Size = UDim2.new(1, 0, 0, 150)
    BoomboxList.CanvasSize = UDim2.new()
    BoomboxList.ScrollBarThickness = 0
    BoomboxList.Parent = Menu.BoomboxFrame

    BoomboxLayout.SortOrder = Enum.SortOrder.LayoutOrder
    BoomboxLayout.Padding = UDim.new(0, 5)
    BoomboxLayout.Parent = BoomboxList


    local CommandsList = Instance.new("ScrollingFrame", Menu.Commands)
    local CommandsListLayout = Instance.new("UIListLayout", CommandsList)

    Menu.Commands.Name = "Commands"
    Menu.Commands.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Menu.Commands.BorderColor3 = Color3.new()
    Menu.Commands.Size = UDim2.fromOffset(400, 150)
    Menu.Commands.Position = UDim2.new(0.5, 0, 0, 100)
    Menu.Commands.AnchorPoint = Vector2.new(0.5, 0.5)
    Menu.Commands.Parent = Menu.Screen

    CommandsList.Name = "List"
    CommandsList.BackgroundTransparency = 1
    CommandsList.Size = UDim2.fromScale(1, 1)
    CommandsList.CanvasSize = UDim2.new(0, 0, 1, -165)
    CommandsList.ScrollBarThickness = 4
    CommandsList.ScrollBarImageColor3 = Color3.new(1, 1, 1)

    CommandsListLayout.Name = ''
    CommandsListLayout.Padding = UDim.new()
    CommandsListLayout.VerticalAlignment = Enum.VerticalAlignment.Top

    Menu.CommandBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Menu.CommandBar.BackgroundTransparency = 0.2
    Menu.CommandBar.BorderSizePixel = 0
    Menu.CommandBar.Position = UDim2.new(0.5, -100, 1, 0)
    Menu.CommandBar.Size = UDim2.new(0, 200, 0, 20)
    Menu.CommandBar.Font = Enum.Font.Code
    Menu.CommandBar.PlaceholderColor3 = Color3.new(1, 1, 1)
    Menu.CommandBar.PlaceholderText = "Command bar [" .. string.char(Config.Prefix.Value) .. "]"
    Menu.CommandBar.Text = ""
    Menu.CommandBar.TextColor3 = Color3.new(1, 1, 1)
    Menu.CommandBar.TextSize = 14
    Menu.CommandBar.TextStrokeTransparency = 0.5
    Menu.CommandBar.Parent = Menu.Screen
    Menu.Line(Menu.CommandBar)

    Menu.Indicators.Add("Target", "Text", "nil")
    Menu.Indicators.Add("Knocked Out", "Bar", 0, 0, 15)
    Menu.Indicators.Add("Bullet Tick", "Text", 0)
    Menu.Indicators.Add("Stomp Target", "Text", 0)
    Menu.Indicators.Add("Fake Lag", "Bar", 0, 0, 15) -- 15 is 1.5 seconds
    Menu.Indicators.Add("Fake Velocity", "Text", "on")

    --[[
        Health = false
        Stamina = false
        GunCooldown = false --(Tool.Info.Cooldown) Lol
        FakeLag = false
        AntiGroudHit = false
    ]]

    Menu.Keybinds.Add("Aimbot", Config.Aimbot.Enabled and "on" or "off")
    Menu.Keybinds.Add("Camera Lock", Config.CameraLock.Enabled and "on" or "off")
    Menu.Keybinds.Add("Flight", Config.Flight.Enabled and "on" or "off")
    Menu.Keybinds.Add("Blink", Config.Blink.Enabled and "on" or "off")
    Menu.Keybinds.Add("Float", Config.Float.Enabled and "on" or "off")
    Menu.Keybinds.Add("Noclip", Config.Noclip.Enabled and "on" or "off")
    Menu.Keybinds.Add("Anti Aim", Config.AntiAim.Enabled and "on" or "off")


    Menu.Keybinds.List.Aimbot:SetVisible(Config.Aimbot.Enabled)
    Menu.Keybinds.List["Camera Lock"]:SetVisible(Config.CameraLock.Enabled)
    Menu.Keybinds.List.Flight:SetVisible(Config.Flight.Enabled)
    Menu.Keybinds.List.Blink:SetVisible(Config.Blink.Enabled)
    Menu.Keybinds.List.Float:SetVisible(Config.Float.Enabled)
    Menu.Keybinds.List.Noclip:SetVisible(Config.Noclip.Enabled)
    Menu.Keybinds.List["Anti Aim"]:SetVisible(Config.AntiAim.Enabled)
    Menu.Watermark:SetVisible(Config.Interface.Watermark.Enabled)
    Menu.Indicators:SetVisible(Config.Interface.Indicators.Enabled)
    Menu.Keybinds:SetVisible(Config.Interface.Keybinds.Enabled)
    Menu:SetTab("Combat")
end


function InitializeWorkspace()
    for _, Pad in next, GetBuyPads() do
        local Part = Pad.Part
        local Price = Pad.Price

        local Player
        local Debounce
        Part:GetPropertyChangedSignal("BrickColor"):Connect(function()
            if tostring(Part.BrickColor) ~= "Bright red" then
                Debounce = false
                Player = nil
                return
            end

            if Debounce or not Player then return end
            Debounce = true

            local Color = Config.EventLogs.Colors.Buy:ToHex()
            local Message = string.format("%s bought a %s for %s", Utils.GetRichTextColor(Player.Name, Color), Utils.GetRichTextColor(Pad.Name, Color), Utils.GetRichTextColor("$" .. Price, Color))

            LogEvent("Buy", Message, tick())
        end)
        Part.Touched:Connect(function(Part)
            if tostring(Part.BrickColor) == "Bright red" then return end
            Player = Players:GetPlayerFromCharacter(Part.Parent)
            Debounce = false
        end)
    end

    for _, v in next, workspace:GetChildren() do OnWorkspaceChildAdded(v) end

    for _, Object in next, workspace:GetDescendants() do
        local Name = Object.Name
        local ClassName = Object.ClassName

        if (Name == "Door" or Name == "Window") and Object:FindFirstChild("RemoteEvent", true) then
            if Object:FindFirstChild("WoodPart") then
                table.insert(Doors, Object)
            elseif Object:FindFirstChild("Move") then
                table.insert(Windows, Object)
            end
            for _, Object in next, Object:GetDescendants() do
                if Object:IsA("BasePart") then
                    if Object.Transparency == 1 then Object:SetAttribute("Ignore", true) end
                end
            end
        end

        if ClassName == "Seat" then -- Don't care about saving car seats, they don't matter;
            Seats[Object] = Object
            if Config.NoSeats.Enabled then Object.Disabled = true end -- There are only 2 cars; I doubt u care about accidentally sitting on one
        end
    end

    workspace.FallenPartsDestroyHeight = 0/0
end


function InitializeConnections()
    RunService.Heartbeat:Connect(Heartbeat)
    RunService.Stepped:Connect(Stepped)
    RunService.RenderStepped:Connect(RenderStepped)
    UserInput.InputBegan:Connect(OnInput)
    UserInput.InputEnded:Connect(OnInputEnded)
    Player.Idled:Connect(OnIdle)
    Menu.CommandBar.FocusLost:Connect(OnCommandBarFocusLost)
    Menu.CommandBar:GetPropertyChangedSignal("Text"):Connect(function() OnCommandBarTextChanged(Menu.CommandBar.Text) end)
    workspace.ChildAdded:Connect(OnWorkspaceChildAdded)
    workspace.ChildRemoved:Connect(OnWorkspaceChildRemoved)
    Lighting.Changed:Connect(OnLightingChanged)

    Network:Add(Enums.NETWORK.CHAT, OnNewMessageEvent)
    if Utils.IsOriginal then
        Character:WaitForChild("GetMouse").OnClientInvoke = OnGetMouseInvoke
        Network:Add(Enums.NETWORK.TAG_REPLICATE, OnTagReplicateEvent)
    end
end


function Initialize()
    if not HookGame() then
        return messagebox("Error 0x4; Failed to hook games anticheat!", script_name .. ".cc", 0)
    end

    InitializeMenu()
    InitializeCommands()

    PlayerManager.PlayerAdded:Connect(OnPlayerAdded)
    PlayerManager.PlayerRemoved:Connect(OnPlayerRemoving)
    PlayerManager.CharacterAdded:Connect(OnCharacterAdded)

    Events.Reset.Event:Connect(ResetCharacter)

    ESP:Init()
    Menu:Init()
    PlayerManager:Init()

    InitializeWorkspace()

    Lighting:Init()
    Lighting:UpdateSkybox(Config.Enviorment.Skybox.Value)

    pcall(function()
        ChatFrame = PlayerGui.Chat.Frame.ChatChannelParentFrame
        ChatFrame.Position = UDim2.new(0, 0, 1, Config.Interface.Chat.Position)
        ChatFrame.Visible = Config.Interface.Chat.Enabled
    end)

    --[[
        427729412, -- JUMP
        376654657, -- DIVE
        429404922, -- SIT
        413255557, -- ARM HOLD
        413612350, -- 2 ARM HOLD
        401045066, -- DRINK
        400468322, -- ANTI HEAD HIT
        433903719 -- Levitate Lol || Ghost
        8587081257; 376653421; 1357408709 -- default run
    ]]


    AimbotIndicator = DrawCross(20, 4)
    AimbotIndicator:Rotate(90)

    FlyVelocity.Velocity = Vector3.new()
    FlyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

    FlyAngularVelocity.AngularVelocity = Vector3.new()
    FlyAngularVelocity.MaxTorque = Vector3.new(9e9, 9e9, 9e9)

    FloatPart.Name = script_name .. ".Float"
    FloatPart.Transparency = 1
    FloatPart.Anchored = true
    FloatPart.CanCollide = Float
    FloatPart.Size = Vector3.new(100, 1, 100)
    FloatPart.Parent = workspace


    local AnimationIds = {
        BackFlip = 363364837, Chill = 526821274, Dab = 526812070, Kick = 376851671, Lay = 526815097, Pushups = 526813828, Sit = 178130996, Sit2 = 0, Situps = 526814775, Slide = 1461265895, Roll = 376654657,
        Gun = 889968874, Gun2 = 229339207, Gun3 = 889390949, Run = 8587081257, Run2 = 10153231863, Run3 = 1484589375, Crouch = 8533780211, AntiAim = 215384594, AntiAim2 = 242203091,
        GlockIdle = 503285264, GlockFire = 503287783, GlockReload = 8533765435, ShottyIdle = 889390949, ShottyFire = 889391270, ShottyReload = 8533763280
    }

    Humanoid = Character:WaitForChild("Humanoid")
    for Name, Id in next, AnimationIds do
        SetAnimation(Name, Id)
    end

    Mouse.Icon = Crosshair

    -- Initialize Binds || I don't particularly like camel case but Roblox uses it so...
    ContextAction:BindAction("aimbotToggle", AimbotToggle, false, Config.Aimbot.Key)
    ContextAction:BindAction("AutoFireToggle", AutoFireToggle, false, Config.AutoFire.Key)
    ContextAction:BindAction("cameraLockToggle", CameraLockToggle, false, Config.CameraLock.Key)
    ContextAction:BindAction("flyToggle", FlyToggle, false, Config.Flight.Key)
    ContextAction:BindAction("blinkToggle", BlinkToggle, false, Config.Blink.Key)
    ContextAction:BindAction("floatToggle", FloatToggle, false, Config.Float.Key)
    ContextAction:BindAction("noclipToggle", NoclipToggle, false, Config.Noclip.Key)
    ContextAction:BindAction("antiAimToggle", AntiAimToggle, false, Config.AntiAim.Key)
    ContextAction:BindAction("commandBarToggle", CommandBarToggle, false, Config.Prefix)
    ContextAction:BindAction("menuToggle", MenuToggle, false, Config.Menu.Key)
    ContextAction:BindAction("buyAmmoKey", BuyAmmoToggle, false, Config.BuyAmmo.Key)

    RunService:BindToRenderStep("cameraLock", Enum.RenderPriority.Camera.Value - 1, function()
        if TargetLock and Config.CameraLock.Enabled and Config.CameraLock.Mode == "RenderStepped" then
            if Root and Humanoid and Player:GetAttribute("IsAlive") then
                local _Torso = Utils.GetTorso(Target) -- I changed the Root to Torso because it bugs out when they turn on tp bypass
                if _Torso then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, _Torso.CFrame.Position)
                end
            end
        end
    end)

    -- Initialize Threads
    if Utils.IsOriginal then
        coroutine.wrap(function()
            local CurrentStep = 1

            while true do
                RunService.Heartbeat:Wait()
                if not Config.HatChanger.Enabled then continue end
                --BrickColor.random().Color

                if Config.HatChanger.Sequence.Enabled and #Config.HatChanger.Sequence.Colors > 0 then
                    if CurrentStep > #Config.HatChanger.Sequence.Colors then CurrentStep = 1 end
                    SetHatColor(Color3.fromHex(Config.HatChanger.Sequence.Colors[CurrentStep]))
                    CurrentStep += 1
                else
                    SetHatColor(Config.HatChanger.Color)
                end
                task.wait(Config.HatChanger.Sequence.Delay)
            end
        end)()


        -- pasted function don't know from who
        local function HMS(Seconds)
            local Minutes = (Seconds - Seconds % 60) / 60
            Seconds = Seconds - Minutes * 60
            local Hours = (Minutes - Minutes % 60) / 60
            Minutes = Minutes - Hours * 60
            return string.format("%02i", Minutes).. ":" ..string.format("%02i", Seconds)
        end


        local LastId = 0
        local LastName
        local function GetAudioName(Id)
            if LastId == Id then return LastName end
            LastId = Id

            local Asset = GetAssetInfo(Id)
            if Asset then
                Name = Asset.Name
                LastName = Name
                return Name
            end
        end


        --https://developer.spotify.com/console/get-users-currently-playing-track
        local function GetPlayingSpotifySong()
            local Url = "https://api.spotify.com/v1/me/player/currently-playing"
            local Response = request({
                Url = Url,
                Headers = {Authorization = "Bearer " .. Config.ClanTag.SpotifyToken}
            })

            if Response.StatusCode == 200 then
                return HttpService:JSONDecode(Response.Body)
            end
        end


        local CurrentClanTag = ""
        local ClanTagForward = false
        local ClanTagBlinking = false
        local ClanTagIteration = 0

        coroutine.wrap(function()
            while true do
                RunService.Heartbeat:Wait()
                if not Config.ClanTag.Enabled then continue end

                local Tag = Config.ClanTag.Tag
                local Type = Config.ClanTag.Type

                if Type == "Custom" then continue end
                if Type == "Static" then
                    CurrentClanTag = Tag
                elseif Type == "Cheat" then
                    local Cheat = script_name .. ".cc"

                    -- this probably can be just a string, but im too lazy to think rn
                    local TagSequences = {}
                    for i = #Cheat, 0, -1 do
                        table.insert(TagSequences, string.sub(Cheat, 1, #Cheat - i) .. string.rep('_', i))
                    end

                    ClanTagIteration = math.clamp(ClanTagIteration + 1, 0, #TagSequences + 1)
                    CurrentClanTag = TagSequences[ClanTagIteration]
                    if ClanTagIteration == #TagSequences then ClanTagIteration = 0 end
                elseif Type == "Normal" then
                    if ClanTagForward then
                        CurrentClanTag = string.sub(Tag, 1, ClanTagIteration)
                    else
                        CurrentClanTag = string.sub(Tag, 1, #Tag - ClanTagIteration)
                    end
                    if ClanTagIteration == #Tag + 1 then
                        ClanTagForward = not ClanTagForward
                        if ClanTagForward then CurrentClanTag = "" end
                        ClanTagIteration = 1
                        task.wait(0.5)
                    end
                    ClanTagIteration = math.clamp(ClanTagIteration + 1, 0, #Tag + 1)
                elseif Type == "Forward" then
                    CurrentClanTag = string.sub(Tag, 1, ClanTagIteration)
                    ClanTagIteration = math.clamp(ClanTagIteration + 1, 1, #Tag + 1)
                    if ClanTagIteration == #Tag + 1 then
                        ClanTagIteration = 0
                        task.wait(0.5)
                    end
                elseif Type == "Reverse" then
                    CurrentClanTag = string.sub(Tag, 1, #Tag - ClanTagIteration)
                    ClanTagIteration = math.clamp(ClanTagIteration + 1, 1, #Tag + 1)
                    if ClanTagIteration == #Tag + 1 then
                        ClanTagIteration = 0
                        task.wait(0.5)
                    end
                elseif Type == "Blink" then
                    CurrentClanTag = ClanTagBlinking and "" or Tag
                    ClanTagBlinking = not ClanTagBlinking
                elseif Type == "Boombox" then
                    local Boombox = Character and (Character:FindFirstChild("BoxModel") or Character:FindFirstChild("BoomBox"))
                    if not Boombox then Type = "Static" end

                    local Sound = Boombox and Boombox:FindFirstChild("SoundX", true)
                    if Sound then
                        local Id = string.gsub(Sound.SoundId, "%D", "")
                        Id = tonumber(Id)
                        if Id then
                            local Name = GetAudioName(Id)
                            if Name then
                                local Time = HMS(Sound.TimePosition) .. "/" .. HMS(Sound.TimeLength)
                                CurrentClanTag = "Playing: " .. Name .. "\n" .. "[" .. Time .. "]"
                            end
                        end
                    end
                elseif Type == "Spotify" then
                    -- why would this crash you?
                    local Data = GetPlayingSpotifySong()
                    if Data and Data.item then
                        local Name = Data.item.name
                        local Artist = Data.item.artists[1].name
                        local Progress = math.round(Data.progress_ms) / 1000
                        local Duration = math.round(Data.item.duration_ms) / 1000
                        local Time = HMS(Progress) .. "/" .. HMS(Duration)
                        CurrentClanTag = "Listening to\n" .. Name .. "\nBy: " .. Artist .. "\n" .. "[" .. Time .. "]"
                    end
                elseif Type == "Info" then
                    local Executor = string.format("Executor: %s %s", identifyexecutor())
                    --local IsAFK = "IsAFK: "
                    local FPS = "FPS: " .. GetFramerate()
                    local Ping = "Ping: " .. Ping .. "ms"
                    local LocalTime = os.date("Time: %X %p")
                    CurrentClanTag = Executor .. "\n" .. FPS .. "\n" .. Ping .. "\n" .. LocalTime
                end

                -- Limitting the Tag it self for Prefix and Suffix just incase
                if CurrentClanTag then
                    CurrentClanTag = string.sub(CurrentClanTag, 1, 100 - (#Config.ClanTag.Prefix + #Config.ClanTag.Suffix))
                    CurrentClanTag = Config.ClanTag.Prefix .. CurrentClanTag
                    CurrentClanTag ..= Config.ClanTag.Suffix
                end

                SetClanTag(CurrentClanTag)
                task.wait(Config.ClanTag.Speed)
            end
        end)()
    else
        coroutine.wrap(function()
            -- Prison Only
            while true do
                RunService.Heartbeat:Wait()
                if not Config.ClickSpam.Enabled then continue end
                if Ping > 500 then continue end

                for _, Player in next, Players:GetPlayers() do
                    if not Player.Character then continue end

                    for _, Tool in next, GetTools(Player) do
                        local Click = Tool:FindFirstChild("Click")
                        if not Click then continue end

                        Click:FireServer()
                    end
                end
            end
        end)()
    end

    coroutine.wrap(function()
        -- Windows don't have a knocking system
        while true do
            task.wait(0.2)
            if not Config.KnockDoors.Enabled then continue end
            if Ping > 500 then continue end

            for _, Door in next, Doors do
                if IsDoorOpen(Door) then continue end
                Network:Send(Enums.NETWORK.INTERACTABLE_KNOCK, Door)
            end
        end
    end)()

    coroutine.wrap(function()
        while true do
            RunService.Heartbeat:Wait()
            if not Config.Attach.Enabled then continue end

            if Character then
                local RightArm = Character:FindFirstChild("Right Arm")
                local _Root = Utils.GetRoot(Target)

                if RightArm and Tool and _Root and Humanoid then
                    Tool.Grip = (RightArm.CFrame * CFrame.new(0, -1, 0, 1, 0, 0, 0, 0, 1, 0, -1, 0)):ToObjectSpace(_Root.CFrame):Inverse()
                    Humanoid:EquipTool(Tool)
                end

                task.wait((Config.Attach.RefreshRate or 0) / 1000)
            end
        end
    end)()

    coroutine.wrap(function()
        while true do
            task.wait(3.5)
            if not Spamming then continue end

            pcall(function()
                local Messages = string.split(readfile(script_name .. "/Games/The Streets/Spam.dat"), "\n")
                Chat(string.gsub(Messages[math.random(1, #Messages)], "%c", ""))
            end)
        end
    end)()

    coroutine.wrap(function()
        while true do
            task.wait(5)
            if not Config.InfiniteForceField.Enabled then continue end
            RefreshCharacter()
        end
    end)()

    coroutine.wrap(function()
        local Tick = 0
        local LastCFrame = Root and Root.CFrame
        local LastPoints

        while true do
            RunService.Stepped:Wait()
            if not Config.FakeLag.Enabled then
                Menu.Indicators.List["Fake Lag"]:SetVisible(false)
                FakeLagVisualizer.Visible = false
                Tick = 0
                continue
            end

            Menu.Indicators.List["Fake Lag"]:SetVisible(true)
            FakeLagVisualizer.Visible = Config.FakeLag.Visualize
            if LastPoints and FakeLagVisualizer.Visible then
                FakeLagVisualizer:UpdatePoints(LastPoints)
                FakeLagVisualizer:SetColor(Config.FakeLag.Color, Config.FakeLag.Transparency)
            end

            if not Teleporting and Root and typeof(LastCFrame) == "CFrame" then
                SetCharacterServerCFrame(LastCFrame)

                local Randomization = math.random(-10, 10) / 100
                local Limit = Config.FakeLag.Limit + Randomization
                local Current = Utils.math_round(os.clock() - Tick, 2)

                Menu.Indicators.List["Fake Lag"]:Update(math.clamp(Current, 0, Limit), 0, Limit)
                if Current >= Limit then -- if it's more than the limit then lets get our new last position
                    LastCFrame = Root.CFrame

                    local Limbs, Success = GetLimbs(Player)
                    if Success then
                        pcall(function()
                            LastPoints = {
                                Limbs.Head.Position,
                                Limbs.Head.Neck.WorldPosition,
                                Limbs.Torso.Pelvis.WorldPosition,

                                Limbs.LeftArm.LeftShoulder.WorldPosition,
                                Limbs.LeftArm.Position,
                                Limbs.LeftArm.LeftHand.WorldPosition,
                                Limbs.RightArm.RightShoulder.WorldPosition,
                                Limbs.RightArm.Position,
                                Limbs.RightArm.RightHand.WorldPosition,

                                Limbs.LeftLeg.LeftHip.WorldPosition,
                                Limbs.LeftLeg.Position,
                                Limbs.LeftLeg.LeftFoot.WorldPosition,
                                Limbs.RightLeg.RightHip.WorldPosition,
                                Limbs.RightLeg.Position,
                                Limbs.RightLeg.RightFoot.WorldPosition
                            }
                        end)
                    end

                    Tick = os.clock()
                end
            end
        end
    end)()

    coroutine.wrap(function()
        while true do
            RunService.Stepped:Wait()

            if Config.AntiAim.Enabled then
                if Config.AntiAim.Type == "Velocity" then
                    SetCharacterServerVelocity(Vector3.new(100, 100, 100) * math.random(-10, 10), Vector3.new(100, 100, 100) * math.random(-10, 10))
		        end
            end
        end
    end)()

    coroutine.wrap(function()
        while true do
            task.wait(60)
            if get_script_version() ~= script_version then
                local Message = "Your version of the script is outdated, rejoin to get the latest build"
                Menu.Notify(Message, 10000000)
                coroutine.yield()
            end
        end
    end)()

    coroutine.wrap(function()
        while true do
            task.wait()
            if Config.AutoReconnect.Enabled then
                if GuiService:GetErrorMessage() ~= '' then
                    TeleportToPlace(game.PlaceId, game.JobId)
                    queue_on_teleport([[
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/elde-n/roblox-the-streets-pony-script/main/loadstring.lua"))("The Streets")
                    ]])
                    coroutine.yield()
                end
            end
        end
    end)()

    InitializeConnections()
    RefreshMenu()
    Menu:SetVisible(true)
    Menu.Notify(string.format(script_name .. ".cc took %s seconds to load in", Utils.GetRichTextColor(Utils.math_round((os.clock() - Time), 2), Config.Menu.Accent:ToHex()), 10))
end


Initialize()
