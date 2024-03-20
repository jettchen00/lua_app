import("common/search_queue.lua")


local save_reason_delay = 1
local save_reason_queue_full = 2

_G.delay_save_class = _G.delay_save_class or {}
function delay_save_class:new(name, queue_size, delay_time, save_speed, fast_save_speed)
    local tab = {
        __index = delay_save_class,
        name = name,
        queue_size = queue_size,
        db_save_queue = search_queue:new(queue_size),

        queue_full_cnt = 0,
        print_errlog_tm = 0,
        print_infolog_tm = 0,

        normal_delay_time = delay_time,  -- 延迟回写时间，单位秒
        save_count_per_tick = save_speed,  -- 每次调用update时，处理延迟回写的node数量
        fast_save_count_per_tick = fast_save_speed,  -- 每次调用update时，处理延迟回写的node数量（停机时）

        --begin_time_when_stop = 0,
        --end_time_when_stop = 0,
        --queue_size_when_stop = 0,
    }
    return setmetatable(tab, tab)
end

function delay_save_class:clear()
    local db_save_queue = self.db_save_queue
    db_save_queue:clear()
    self.queue_full_cnt = 0
    self.print_errlog_tm = 0
    self.print_infolog_tm = 0
    log_debug("delay save class::clear succ, name=%s", self.name)
end

function delay_save_class:set_save_db_func(save_func)
    self.save_db_func = save_func
    log_debug("delay save class::set save db func succ, name=%s", self.name)
end


function delay_save_class:push_save_key(save_key)
    local db_save_queue = self.db_save_queue
    local node = db_save_queue:get(save_key)
    if node then
        -- 已经在写队列中
        return
    end
    node = {
        enqueue_time = os.time(),
    }
    local ret = db_save_queue:set(save_key, node)
    if 0 ~= ret then
        self.queue_full_cnt = self.queue_full_cnt + 1
        if self.queue_full_cnt % 100 < 3 then
            log_err("delay save class::queue is full, name=%s, save_key=%s, full_cnt=%s", self.name, save_key, self.queue_full_cnt)
        end
        -- 延迟队列满的时候, 不写db了。因为此时再写db，那写db的频率其实就不可控了
    end
end

function delay_save_class:has_save_key(save_key)
    local db_save_queue = self.db_save_queue
    local node = db_save_queue:get(save_key)
    if node then
        return true
    end
    return false
end


function delay_save_class:delete_save_key(save_key)
    local db_save_queue = self.db_save_queue
    db_save_queue:del(save_key)
end

function delay_save_class:handle_delay_save_node(save_key, node)
    --log_debug("delay save class::begin, name=%s, save_key=%s", self.name, save_key)
    local save_db_func = self.save_db_func
    if save_db_func then
        save_db_func(save_key, save_reason_delay)
    else
        log_err("delay save class::save db func is nil, name=%s, save_key=%s", self.name, save_key)
    end
end


-- 分帧处理延迟写队列
function delay_save_class:update()
    local db_save_queue = self.db_save_queue
    local cur_queue_count = db_save_queue:count()
    local delay_save_time = self.normal_delay_time
    local save_cnt = self.save_count_per_tick  -- 本次tick处理的node数量
    local handle_count = 0
    local now_time = os.time()
    local finish = true
    repeat
        local save_key, node = db_save_queue:peek_head()
        if not (save_key and node) then
            break
        end
        
        local enqueue_time = node.enqueue_time
        local delay_time = now_time - enqueue_time
        if delay_time >= delay_save_time then
            handle_count = handle_count + 1
            db_save_queue:del(save_key)
            if delay_time > (self.normal_delay_time + 10) and (now_time - self.print_errlog_tm > 60) then
                -- 超过10s延时，说明处理不过来，打个错误日志，打印错误日志间隔为1分钟
                log_err("delay save class::handle too slow, name=%s, delay_time=%s(s)", self.name, delay_time)
                self.print_errlog_tm = now_time
            end
            -- 到时间处理了
            self:handle_delay_save_node(save_key, node)
        else
            -- 都没到时间
            break
        end
        if handle_count >= save_cnt then
            finish = false
            break
        end
    until (false)
    if not finish and (now_time - self.print_infolog_tm > 30) then
        log_info("delay save class::current info, name=%s, size=%s", self.name, db_save_queue:count())
        self.print_infolog_tm = now_time
    end
end

function delay_save_class:is_allow_stop()
    local db_save_queue = self.db_save_queue
    local is_empty = db_save_queue:empty()
    return is_empty
end