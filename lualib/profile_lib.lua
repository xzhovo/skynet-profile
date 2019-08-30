local profile = require "skynet.profile"
local skynet = require "skynet"
local envSwith = skynet.getenv("profile")

local table_insert = table.insert

local profileLib = {}

local profileTime = {}

function profileLib.init(CMD, name, swith, realFun, extFun)
    if swith == nil then swith = envSwith end
    if extFun == nil then extFun = function() end end
    if realFun == nil then 
        realFun = function(session, _, cmd, ...)
            local f = CMD[cmd]
            if not f then
                skynet.error(name .. " can't dispatch cmd ".. (cmd or nil))
                skynet.ret(skynet.pack({ok=false}))
                return
            end

            if session > 0 then
                skynet.ret(skynet.pack(f(CMD, ...)))
            else
                f(CMD, ...)
            end

            extFun()
        end 
    end

    if swith then
        skynet.info_func(function(sortByAverage)
            local ret = {}
            for cmd, info in pairs(profileTime) do
                local time = string.format("%.10f", info.ti)
                local average = string.format("%.10f", time/info.n)
                table_insert(ret, {average=average, costTime=time, callTimes=info.n, fun=cmd})
            end
            if sortByAverage then
                table.sort(ret, function(a,b)
                    return a.average > b.average
                end)
            else
                table.sort(ret, function(a,b)
                    return a.costTime > b.costTime
                end)
            end
            return ret
        end)

        return function(session, _, cmd, ...)
            profile.start()

            realFun(session, _, cmd, ...)

            extFun()

            local time = profile.stop()
            local p = profileTime[cmd]
            if p == nil then
                p = { n = 0, ti = 0 }
                profileTime[cmd] = p
            end
            p.n = p.n + 1
            p.ti = p.ti + time

        end
    else
        return realFun
    end
end

return profileLib