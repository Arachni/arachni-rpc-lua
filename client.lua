--require "/home/zapotek/workspace/arachni-rpc-lua/connection" 
require "connection" 

--
-- Arachni RPC Client
--
-- Provides a simple way perform Arachni-RPC calls.
--
ArachniRPCClient = {}

--
-- opts:
--   * host = remote host address -- REQUIRED
--   * port = port number -- REQUIRED
--   * token = authentication token -- OPTIONAL
--   * key = SSL key in PEM format
--   * certificate = SSL cert in PEM format
--   * cafile = CA file in PEM format
--
function ArachniRPCClient:new( opts )
    opts = opts or {}
    setmetatable( opts, self )
    self.__index = self

    return opts
end

--
-- Performs a RPC call and returns the result
--
-- @param   String  method  the name of the remote to be called
-- @param   Array   args    arguments for the remote method
--
-- @return  Object
---
function ArachniRPCClient:call( method, args )
    -- make a copy of the opts in self before passing them on
    c_opts = {}
    for k, v in pairs( self ) do c_opts[k] = v end

    conn = ArachniRPCConnection:new( c_opts )
    conn:send_object({
        message = method,
        args = {args},
        token = self.token
    })
    res = conn:receive_object()
    conn:close()

    if type( res.obj ) == 'table' and res.obj.exception then
        error( res.obj.exception )
    else
        return res.obj
    end
end

