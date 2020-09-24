get_dir = function(host_info, path)
    local tcp = socket:tcp()
    local connection, err = tcp:connect(host_info["host"], host_info["port"])
    if (err ~= nil) then
        print("Connection error: " .. dump(err))
        tcp:close()
        return
    end
    local conn = np.attach(tcp, "root", "")
    print("dump")
    local result, dir = pcall(readdir, conn, path == "/" and "./" or path)
    if not result then
        tcp:close()
        return
    end
    local content = {}
    for n, file in pairs(dir) do
        table.insert(content, {
            name = file.name,
            path = (path == "/" and "/" .. file.name or path .. "/" .. file.name),
            -- if not dir, than file
            type = (file.qid.type == 128 and 128 or 0)
        })
    end
    return content
end
