这是一个 Skynet profile 的便捷用例，查看服务中处理消息的函数实际 cpu 消耗情况，[Skynet profile wiki](https://github.com/cloudwu/skynet/wiki/Profile)  

Skynet 默认开启 profile ，但只会统计单个服务所有消息回调的 cpu 总耗时，函数的真实耗时需要手动开启(不包括挂起等待的时间)  

**API**  
这个 API 会返回一个 function 供 `skynet.dispatch` 或 `skynet.register_protocol` ，通常我们只关心 `"lua"` type  
`profileLib.init(CMD, name, swith, realFun, extFun)` `CMD` 服务回调函数 table， `name` 服务名，`swith` 该服务的 profile 开关， nil 时默认为 skynet config 中的 profile 配置，`realFun` 自定义整个函数，`extFun` 自定义追加函数  
**注意**  
返回的默认注册函数中调用方式为 `CMD[cmd](CMD, ...)` ，所以 `CMD` 函数样例为 `CMD:xxxFun(...)` 或 `CMD.xxxFun(self, ...)`  

示例：  
```lua
local profileLib = require "profile_lib"

--同配置开关，使用默认注册函数
skynet.dispatch("lua", profileLib.init(CMD, "player_mgr"))

--不开启 profile，使用默认注册函数
skynet.dispatch("lua", profileLib.init(CMD, "logger", false))

--同配置开关，自定义注册函数
skynet.dispatch("lua", profileLib.init(CMD, "watchdog", nil, function(session, _, cmd, subcmd, ...)
    if cmd == "socket" then
        local f = CMD.SockMgr[subcmd]
        f(CMD.SockMgr, ...)
    else
        local f = CMD[cmd]
        if not f then
            log.info("watchdog can't dispatch cmd ".. (cmd or nil))
            skynet.ret(skynet.pack({ok=false}))
            return
        end
        if session == 0 then
            f(CMD, subcmd, ...)
        else
            skynet.ret(skynet.pack(f(CMD, subcmd, ...)))
        end
    end
end))

--同配置开关，使用默认注册函数，定义追加函数
skynet.dispatch("lua", profileLib.init(CMD, "agent", nil, nil, function()
	collectgarbage("step")
end))
```