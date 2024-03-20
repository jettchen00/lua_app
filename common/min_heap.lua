
-- 最小堆实现，用于求解海量数据的top N问题
_G.min_heap = _G.min_heap or {};

local max_height = 10  -- 最小堆的最大高度，支持解决top N问题（N最大为2^max_height -1）
local max_heap_size = 2 ^ max_height - 1
local max_group_cnt = 15
-- name为业务名称，size为top n问题中的n，group_cnt是用于支持求解多个分组的top n
function min_heap:new(name, group_cnt, size)
    if size > max_heap_size or group_cnt > max_group_cnt or group_cnt < 1 then
        return
    end
    local tab = {
        __index = min_heap,
        size = size,
        group_cnt = group_cnt,
        all_group_array = {},
        name = name,
    };
    return setmetatable(tab, tab)
end

function min_heap:clear()
    self.all_group_array = {}
end

-- 上浮操作
function min_heap:bubble_up(array, pos)
    local loop_cnt = 0
    while (pos > 1) do
        local parent_pos = math_floor(pos / 2)
        if parent_pos <= 0 then
            break
        end
        local current_obj = array[pos]
        local parent_obj = array[parent_pos]
        if not (current_obj and parent_obj) then
            break
        end
        if current_obj.weight >= parent_obj.weight then
            -- 已经上浮到正确位置了
            break
        end
        -- 交换下key与weight
        current_obj.weight, parent_obj.weight = parent_obj.weight, current_obj.weight
        current_obj.key, parent_obj.key = parent_obj.key, current_obj.key

        pos = parent_pos
        loop_cnt = loop_cnt + 1
        if loop_cnt >= max_height then
            -- 防止死循环，也限制下最小堆的高度
            break
        end
    end
end

-- 下沉操作
function min_heap:bubble_down(array, pos)
    local loop_cnt = 0
    local count = #array
    while (true) do
        local lelf_child_pos = pos * 2
        local right_child_pos = pos * 2 + 1
        if lelf_child_pos > count then
            -- 说明pos处的node没有子节点
            break
        end
        local current_obj = array[pos]
        -- 在左右子节点中寻找较小的子节点
        local left_child_obj = array[lelf_child_pos]
        local min_child_pos = lelf_child_pos
        local min_child_obj = left_child_obj
        
        local right_child_obj = array[right_child_pos]
        if right_child_obj and right_child_obj.weight < left_child_obj.weight then
            min_child_pos = right_child_pos
            min_child_obj = right_child_obj
        end
        if current_obj.weight <= min_child_obj.weight then
            -- 已经下沉到正确位置了
            break
        end
        -- 交换下key与weight
        current_obj.weight, min_child_obj.weight = min_child_obj.weight, current_obj.weight
        current_obj.key, min_child_obj.key = min_child_obj.key, current_obj.key
        pos = min_child_pos
        loop_cnt = loop_cnt + 1
        if loop_cnt >= max_height then
            -- 防止死循环，也限制下最小堆的高度
            break
        end
    end
end

-- key可以是数字也可以是字符串，weight需要是数字(根据weight排序)
function min_heap:push(group_id, key, weight)
    local group_cnt = self.group_cnt
    if group_id < 1 or group_id > group_cnt then
        return
    end
    local all_group_array = self.all_group_array
    all_group_array[group_id] = all_group_array[group_id] or {}
    local array = all_group_array[group_id]
    local count = #array
    if count < self.size then
        -- 还有剩余空间
        local new_pos = count + 1
        array[new_pos] = {
            key = key,
            weight = weight,
        }
        self:bubble_up(array, new_pos)
        return
    end
    local first_obj = array[1]
    if weight > first_obj.weight then
        -- 新元素比堆顶元素大，则用新元素替换掉堆顶元素
        first_obj.weight = weight
        first_obj.key = key
        self:bubble_down(array, 1)
    end
end

-- 弹出堆顶元素
function min_heap:pop(array)
    local count = #array
    if count <= 0 then
        return
    end
    local first_obj = array[1]
    local last_obj = array[count]
    local ret_key, ret_weight = first_obj.key, first_obj.weight
    -- 将堆顶元素替换为最后一个元素，然后移除掉最后一个元素
    first_obj.key, first_obj.weight = last_obj.key, last_obj.weight
    table_remove(array)
    -- 执行下沉操作
    self:bubble_down(array, 1)
    return ret_key, ret_weight
end

function min_heap:pop_all(group_id)
    local group_cnt = self.group_cnt
    if group_id < 1 or group_id > group_cnt then
        return
    end
    local all_group_array = self.all_group_array
    local array = all_group_array[group_id]
    if not array then
        return
    end
    local pos = 0
    local result -- 从小到大排序
    while true do
        local key, weight = self:pop(array)
        if not (key and weight) then
            break
        end
        --log_debug("min heap pop one item::key=%s, weight=%s", key, weight)
        result = result or {}
        pos = pos + 1
        result[pos] = {
            key = key,
            weight = weight,
        }
    end
    return result
end

function min_heap:pop_count(group_id, count)
    local group_cnt = self.group_cnt
    if group_id < 1 or group_id > group_cnt then
        return
    end
    local all_group_array = self.all_group_array
    local array = all_group_array[group_id]
    if not array then
        return
    end
    local pos = 0
    local result -- 从小到大排序
    while true do
        local key, weight = self:pop(array)
        if not (key and weight) then
            break
        end
        --log_debug("min heap pop one item::key=%s, weight=%s", key, weight)
        result = result or {}
        pos = pos + 1
        result[pos] = {
            key = key,
            weight = weight,
        }
        if pos >= count then
            break
        end
    end
    return result
end

function min_heap:get_count(group_id)
    local group_cnt = self.group_cnt
    if group_id < 1 or group_id > group_cnt then
        return
    end
    local all_group_array = self.all_group_array
    local array = all_group_array[group_id]
    return array and #array or 0
end

--[[
--测试代码
function test_one()
    test_obj = min_heap:new("test_min_heap_one", 5, 5)
    test_obj:push(2, 5, 55)  -- 第4大
    test_obj:push(2, 6, 66)  -- 第2大
    test_obj:push(2, 1, 11)
    test_obj:push(2, 3, 33)
    test_obj:push(2, 8, 88)  -- 第1大
    test_obj:push(2, 10, 1)
    test_obj:push(2, 100, 3)
    test_obj:push(2, 22, 61)  -- 第3大
    test_obj:push(2, 22, 36)  -- 第5大
    test_obj:push(2, 22, 26)


    test_obj:push(5, 15, 180)  -- 第4大
    test_obj:push(5, "test", 222)  -- 第2大
    test_obj:push(5, 1, 11)
    test_obj:push(5, 3, 33)
    test_obj:push(5, 18, 233)  -- 第1大
    test_obj:push(5, 10, 1)
    test_obj:push(5, 100, 3)
    test_obj:push(5, "abc", 199)  -- 第3大
    test_obj:push(5, 166, 166)  -- 第5大
    test_obj:push(5, 22, 26)

    -- 预期输出：第5、4、3、2、1大的元素
    log_debug("min heap::current count=%s", test_obj:get_count(2))
    test_obj:pop_all(2)
    log_debug("min heap::current count=%s", test_obj:get_count(5))
    test_obj:pop_all(5)
end

function test_two()
    test_obj = min_heap:new("test_min_heap_two", 1, 9)
    test_obj:push(1, 5001, 20001)
    test_obj:push(1, 6, 62236)         -- 第7大
    test_obj:push(1, "abcd", 11)
    test_obj:push(1, "hello", 33333)   -- 第9大
    test_obj:push(1, 82, 80008)        -- 第5-6大
    test_obj:push(1, 10, 10000)
    test_obj:push(1, 130, 1232)
    test_obj:push(1, "min heap", 90000)  -- 第4大
    test_obj:push(1, 22, 23336)
    test_obj:push(1, 12345, 2333336)  -- 第1大
    test_obj:push(1, 888, 123)
    test_obj:push(1, "aaaa", 44444)   -- 第8大
    test_obj:push(1, 345, 23336)
    test_obj:push(1, "111", 80008)    -- 第5-6大
    test_obj:push(1, "666", 90008)    -- 第2-3大
    test_obj:push(1, 150, 90008)      -- 第2-3大
    test_obj:push(1, 151, 908)
    test_obj:push(1, 152, 908)
    test_obj:push(1, 153, 2008)
    log_debug("min heap::current count=%s", test_obj:get_count(1))

    -- 预期输出：第9、8、7、6、5、4、3、2、1大的元素
    test_obj:pop_all(1)
    log_debug("min heap::current count=%s", test_obj:get_count(1))
end
test_one()
--]]
