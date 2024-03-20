--支持以O(1)的时间复杂度，查找、删除队列中的任意元素
--需要快速插入
--需要快速删除
--需要按入队顺序遍历
_G.search_queue = _G.search_queue or {}


--size: lru cache总容量
function search_queue:new(size)
    local tab = {
        __index = search_queue,
        size = size,
        list = { count = 0 },
        map = {},
    }
    return setmetatable(tab, tab)
end

function search_queue:clear()
    self.list = { count = 0 }
    self.map = {}
end

function search_queue:push_back(node)
    local list = self.list

    node.right = nil
    list.count = list.count + 1

    if not list.tail then
        assert(list.head == nil)
        list.head = node
        list.tail = node
        node.left = nil
        return
    end

    node.left = list.tail
    list.tail.right = node
    list.tail = node
end

function search_queue:remove(node)
    local list = self.list
    if node == list.head then
        list.head = node.right
    end

    if node == list.tail then
        list.tail = node.left
    end

    if node.left then
        node.left.right = node.right
    end

    if node.right then
        node.right.left = node.left
    end

    node.left = nil
    node.right = nil
    list.count = list.count - 1
end

function search_queue:set(key, value)
    local map = self.map
    local node = map[key]
    if node then
        -- 队列按key去重
        return 1
    end
    local list = self.list
    if list.count >= self.size then
        -- 队列满了
        return 2
    end
    node = {
        key = key,
        value = value,
    }
    self:push_back(node)
    map[key] = node
    return 0
end

function search_queue:del(key)
    local map = self.map
    local node = map[key]
    if node then
        map[key] = nil
        self:remove(node)
    end
end

function search_queue:get(key)
    local node = self.map[key]
    if not node then
        return nil
    end
    return node.value
end

function search_queue:dump()
    local list = self.list
    local node = list.head
    local txt = ""
    while node do
        txt = string_format("%s{%s, %s}", txt, node.key, node.value)
        node = node.right
        if node then
            txt = txt..", "
        end
    end
    print(txt)
    print("")
end

function search_queue:peek_head()
    local head = self.list.head
    if head then
        return head.key, head.value
    end
    return
end

function search_queue:pop_head()
    local head = self.list.head
    if head then
        self:del(head.key)
        return head.key, head.value
    end
    return
end

function search_queue:count()
    return self.list.count
end

function search_queue:is_full()
    return self.list.count >= self.size
end

function search_queue:empty()
    return (self.list.count <= 0)
end

--test code---------
--[[
log_debug("new, size=5");
c=search_queue:new(5);

log_debug("push 5 item, A...E");
c:set(100, 'A');
c:set(200, 'B');
c:set(300, 'C');
c:set(400, 'D');
c:set(500, 'E');
c:set(500, 'EE');
c:dump();

log_debug("push {600, X}");
c:set(600, 'X');
c:dump();
key, value = c:peek_head()
log_debug("head node, key=%s,value=%s", key, value)
log_debug("get [300]=%s", c:get(300) );
c:dump();

log_debug("get [900]=%s", c:get(900) );
c:dump();

log_debug("get [200]=%s", c:get(200) );
c:dump();
log_debug("cur count=%s", c:count() );

log_debug("push {700, Y}");
c:set(700, 'Y');
c:dump();
key, value = c:peek_head()
log_debug("head node, key=%s,value=%s", key, value)
log_debug("del {500}");
c:del(500)
c:dump();

log_debug("del {100}");
c:del(100)
c:dump();

log_debug("del {300}");
c:del(300)
c:dump();
key, value = c:peek_head()
log_debug("head node, key=%s,value=%s", key, value)

log_debug("cur count=%s", c:count() );

log_debug("push {800, Z}");
c:set(800, 'Z');
c:dump();
--]]

