get_stat = function(host_info, file_name)
    local tcp = socket:tcp()
    local connection, err = tcp:connect(host_info["host"], host_info["port"])
    if (err ~= nil) then
        print("Connection error: " .. dump(err))
        return
    end
    local conn = np.attach(tcp, "root", "")
    local p = conn:newfid()
    np:walk(conn.rootfid, p, host_info["path"] .. "/" .. file_name)
    conn:open(p, 0)
    local st = conn:stat(p)
    conn:clunk(p)
    conn:clunk(conn.rootfid)
    tcp:close()
    return st
end


create_new_file = function(host_info, file_name, file_content)
    local tcp = socket:tcp()
    local connection, err = tcp:connect(host_info["host"], host_info["port"])
    if (err ~= nil) then
        print("Connection error: " .. dump(err))
        return
    end
    local conn = np.attach(tcp, "root", "")
    local f, g = conn:newfid(), conn:newfid()
    conn:walk(conn.rootfid, f, host_info["path"])
    conn:clone(f, g)
    conn:create(g, file_name, 511, 1)
    if file_content ~= nil or file_content ~= "" then
        local buf = data.new(file_content)
        local n = conn:write(g, 0, buf)
        if n ~= #buf then
            error("test: expected to write " .. #buf .. " bytes but wrote " .. n)
        end
    end
    conn:clunk(f)
    conn:clunk(g)
    conn:clunk(conn.rootfid)
    tcp:close()
end
