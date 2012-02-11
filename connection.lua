require 'socket'
require 'ssl'
require 'yaml'

--
-- Arachni RPC Connection handler
--
-- Takes care of:
--   * SSL
--   * Buffering
--   * Object serialization and transmission
--
ArachniRPCConnection = {}

--
-- opts:
--   * host
--   * port
--
function ArachniRPCConnection:new( opts )
    opts = opts or {}
    setmetatable( opts, self )
    self.__index = self

    -- create SSL socket
    conn = socket.tcp()

    opts.mode = 'client'
    opts.protocol = 'tlsv1'

    conn:connect( opts.host, opts.port )
    conn = ssl.wrap( conn, opts )
    conn:dohandshake()

    self.socket = conn

    -- this will be our receive buffer
    self.buffer = ''

    return self
end

function ArachniRPCConnection:close()
    self.socket:close()
end

--
-- Serializes, packs and sends an object
--
function ArachniRPCConnection:send_object( obj )
    self.socket:send( self:pack_with_size( yaml.dump( obj ) ) )
end

--
-- Waits until done receiving an object and returns said object
--
function ArachniRPCConnection:receive_object()
    local serialized = self:receive_data()
--    print( serialized )
    return yaml.load( serialized )
end


--
-- Pay no attention to the man behind the curtain,
-- i.e. don't count on the following functions.
--

--
-- Waits until a serialized object has been received and returns
-- the serialized version.
--
function ArachniRPCConnection:receive_data()
    -- wait until the header, which is basically the size
    -- of the response, arrives
    header = nil
    while not header do
        header = self.socket:receive( 4 )
    end

    -- wait until the whole response arrives
    return self.socket:receive( self:get_size( header ) )
end

--
-- Unpacks the received payload and returns its size. 
--
function ArachniRPCConnection:get_size( payload )
    local size = ""

    -- first 4 chars are the size packed as
    -- null-padded, 32-bit unsigned, network (big-endian) byte order
    -- so we need to convert them from binary to proper ASCII...
    for i=1, 4 do
        size = size .. payload:byte( i, i )
    end

    -- ...and convert the ASCII string to a usable integer.
    return tonumber( size )
end

--
-- Prepares a payload for transmission by packing it with its size.
--
function ArachniRPCConnection:pack_with_size( payload )
    local bin = ''

    -- get the size as a binary string
    -- (not sure if this is a good way to do this)
    bin = string.char( payload:len() )

    -- null-pad the remaining space
    for i = 1, 4 - bin:len() do
        bin = bin .. string.char( 0x0 )
    end

    -- prefix the payload with its size packed as
    -- 4 char, null-padded, 32-bit unsigned, network (big-endian) byte order
    return string.reverse( bin ) .. payload
end

