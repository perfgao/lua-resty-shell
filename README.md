Name
====

lua-resty-shell - for the ngx_lua based on the cosocket API

Description
===========

The library relies on third party programs - [**sockproc**](https://github.com/juce/sockproc).


Synopsis
========

Should run sockproc first and listenning on a UNIX socket:

```
    $ ./sockproc /tmp/shell.sock
```

openresty config:

```
    lua_package_path "/path/to/lua-resty-shell/lib/?.lua;;";

    server {
        location /test {
            content_by_lua_block {
                local shell = require 'resty.shell'

                local sock = 'unix:/tmp/shell.sock'
                local params = {
                    cmd = "uname -a",
                }

                local sl = shell.new()
                if not sl then
                    return
                end

                local res, err = sl:connect(sock)
                if not res then
                    return
                end

                local res, err = sl:send_command(params)
                if not res then
                    return
                end

                local status, out, err = sl:read_response()

                sl:close()
            }
        }
    }
```

Methods
=======

new
---
`syntax: sl = shell.new()`

Creates a shell object. In case of failures, returns nil and a string describing the error.

connect
-------
`syntax: ok, err = sl:connect("unix:/path/to/unix.sock", options_table?)`

connect to a local unix domain socket file listened by then sockproc server.

Before connect then local unix domain socket， this method will always look up the
connection pool for matched idle connections created by previous calls of this method.

set_timeout
-----------
`syntax: sl:set_timeout(time)`

Sets the timeout (in ms) protection for subsequent operations, including the connect method.

set_keepalive
-------------
`syntax: ok, err = sl:set_keepalive(max_idle_timeout, pool_size)`

Puts the current connection immediately into the ngx_lua cosocket connection pool.

In case of success, returns 1. In case of errors, returns nil with a string describing the error.

close
-----
`syntax: ok, err = sl:close()`

Closes the current connection.

In case of success, returns 1. In case of errors, returns nil with a string describing the error.

send_command
------------
`syntax: ok, err = sl:send_command(params)`

Send the system commands to be executed to the local unix domain socket.

* `params`
it is a lua table. The *cmd* field specifies the command to execute.

read_response
-------------
`syntax: status, out, err = sl:read_response()`

To receive the result of the executed command.

See Also
========
* the ngx_lua module: https://github.com/openresty/lua-nginx-module/#readme
* the Sockproc daemon: https://github.com/juce/sockproc
