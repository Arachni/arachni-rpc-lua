require "./connection" 

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
     conn = ArachniRPCConnection:new( { host = self.host, port = self.port } )
     conn:send_object({
         message = method,
         args = args,
         token = self.token
     })
     obj = conn:receive_object()
     conn:close()
     return obj
end

