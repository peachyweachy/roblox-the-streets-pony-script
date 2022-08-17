local TimerClass = {}

local Utils = import "Utils"

local RunService = game:GetService("RunService")

local Timers = {}

function TimerClass.new(): Timer
    local Timer = {}

    Timer.Tick = 0
    Timer.Time = 0

    function Timer:Start(Callback: any)
        self.Tick = os.clock()
        self.Callback = Callback
    end

    function Timer:Destroy()
        self.Time = 0 -- do we really need to
        Timers[self] = nil
    end

    Timers[Timer] = Timer
    return Timer
end


local function StepTimers()
    for _, Timer in pairs(Timers) do
        Timer.Time = Utils.math_round(os.clock() - Timer.Tick, 2)
        if typeof(Timer.Callback) == "function" then
            Timer:Callback()
        end
    end
end


RunService.Heartbeat:Connect(StepTimers)


return TimerClass