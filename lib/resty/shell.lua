local str_format = string.format
local str_match  = string.match
local tab_concat = table.concat

local ngx_socket_tcp = ngx.socket.tcp

local _M = { _VERSION = '0.01' }

local mt = { __index = _M }

function _M.new()
    local socket, err = ngx_socket_tcp()
    if not socket then
        return nil, err
    end
    return setmetatable({sock = socket, keepalive = true}, mt)
end

function _M.connect(self, ...)
    local sock = self.sock
    if not sock then
        return nil, 'not init'
    end

    self.keepalive = true

    return sock:connect(...)
end

function _M.set_timeout(self, ...)
    local sock = self.sock
    if not sock then
        return nil, 'not init'
    end
    return sock:settimeout(...)
end

function _M.set_keepalive(self, ...)
    local sock = self.sock
    if not sock then
        return nil, 'not init'
    end

    if self.keepalive == true then
        return sock:keepalive(...)
    else
        local res, err = sock:close()
        if res then
            return 2, 'connection must close'
        else
            return res, err
        end
    end
end

function _M.close(self)
    local sock = self.sock
    if not sock then
        return nil, 'not init'
    end
    return sock:close()
end

local function _format_request(params)
    local cmd = params.cmd
    local data = params.data or ''
    if not cmd then
        return nil, 'not cmd'
    end

    local num = str_format('%d', #data)

    local tt = {
        cmd,
        "\r\n",
        num,
        "\r\n",
        data
    }

    return tab_concat(tt)
end

local function _receive_status(sock)
    local data, err = sock:receive('*l')
    if not data then
        return nil, err
    end

    return str_match(data, "status:([-%d]+)")
end

local function _receive_stream(sock)
    local data, err = sock:receive('*l')
    if not data then
        return nil, err
    end

    local byte_num, content
    byte_num = tonumber(data) or 0
    if byte_num > 0 then
        content = sock:receive(byte_num)
    end
    return byte_num, content
end

function _M.send_command(self, params)
    local sock = self.sock

    local req, err = _format_request(params)
    if not req then
        return nil, err
    end

    local bytes, err = sock:send(req)
    if not bytes then
        return nil, err
    end
    return true
end

function _M.read_response(self)
    local sock = self.sock
    local status, out, errout, err
    status, err = _receive_status(sock)
    if not status then
        return -1, nil, err
    end
    
    out, err = _receive_stream(sock)
    if not out then
        return -1, nil , err
    end

    errout, err = _receive_stream(sock)
    if not errout then
        return -1, nil, err
    end
    return status, out, errout
end

return _M
