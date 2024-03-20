--[[
    自定义的table，可以通过ctable:get_size函数高效地获取table中的元素数量
    注意next调用一定会返回非nil值，这个结果与lua的原始table有差异，因此业务如果需要判断table中是否有值则应该调用ctable:get_size

    这个table给一个不存在的key赋值为nil，不会发生任何事情，不像lua 5.3会插入新元素
]]

_G.ctable = _G.ctable or {}

function ctable:new(capacity)
    local new_table = {
        map = {},
        capacity = tonumber(capacity) or 0,
        size = 0,
        get_size = function(tb)
            return tb.size
        end,
        
        __pairs = function(tb)
            --log_debug("enter __pairs begin")
            return pairs(tb.map)
        end,
        
        __ipairs = function(tb)
            --log_debug("enter __ipairs begin")
            return ipairs(tb.map)
        end,

        __index = function(tb, key)
            --log_debug("enter __index begin, key=%s", key)
            if nil == key then
                return nil
            end
            local map = tb.map
            return map[key]
        end,

        __newindex = function(tb, key, value)
            --log_debug("enter __newindex begin, key=%s, value=%s", key, value)
            if nil == key then
                return
            end
            local map = tb.map
            -- if value is nil, then remove the key
            if nil == value then
                if nil == map[key] then
                    -- key is not exist
                    return
                end
                map[key] = nil
                tb.size = tb.size - 1
                if tb.size < 0 then
                    log_alert("ctable:size err, key=%s, size=%s", key, tb.size)
                    tb.size = 0
                end
                return
            end
    
            -- if key already exist, then modify value
            if nil ~= map[key] then
                map[key] = value
                return
            end
        
            -- capacity is already full
            if tb.capacity > 0 and tb.size >= tb.capacity then
                log_alert("ctable:capacity is full, key=%s, value=%s, size=%s, capacity=%s", key, value, tb.size, tb.capacity)
                return
            end
            map[key] = value
            tb.size = tb.size + 1
        end
    }

    return setmetatable(new_table, new_table)
end

--[[
local mytable = ctable:new(100)
print(next(mytable))
for i = 1, 7 do
    mytable[i] = i * 10
end
mytable.map = 1
for k, v in ipairs(mytable) do
    log_debug("AAA k=%s, v=%s", k, v)
end

log_debug("cur size=%s", mytable:get_size())
mytable[1] = nil
log_debug("cur size=%s, value=%s", mytable:get_size(), mytable[1])


mytable[155] = "1a1a1a"
log_debug("cur size=%s, value=%s", mytable:get_size(), mytable[155])

mytable[155] = "bbbbb"
log_debug("cur size=%s, value=%s", mytable:get_size(), mytable[155])

mytable.uid = 12345
log_debug("cur size=%s, uid=%s", mytable:get_size(), mytable.uid)
for k, v in pairs(mytable) do
    log_debug("k=%s, v=%s", k, v)
end

function my_test()
    
    local test_tb = {
        [5626943852] = {1},
        [5539957528] = {1, 2, 3, 4, 7},
        [51271540917] = {1, 2, 3, 4, 5}
    }
    

    local test_tb = ctable:new(0)
    test_tb[5626943852] = {1}
    test_tb[5539957528] = {1, 2, 3, 4, 7}
    test_tb[51271540917] = {1, 2, 3, 4, 5}

    local count = 0
    local sender_count = 0
    for sender, sender_info in pairs(test_tb) do
        sender_count = sender_count + 1
        for k, v in pairs(sender_info) do
            test_tb[k] = nil
            count = count + 1
        end
        log_err("sender_count=%s", sender_count)
        if sender_count == 100 then
            log_err("dead loop exist")
            return
        end
    end
end

my_test()
]]