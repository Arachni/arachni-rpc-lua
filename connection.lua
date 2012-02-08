require 'socket'
require 'ssl'
require 'yaml'

--
-- Arachni RPC Connection handler
--
-- Takes care of:
--   * SSL
--   * Buffering
--   * Object serialization andtransmitionn
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
    socket = socket.tcp()
    socket:connect( opts.host, opts.port )
    socket = ssl.wrap( socket, { mode = 'client', protocol = 'tlsv1'} )
    socket:dohandshake()

    self.socket = socket

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
    while true  do

        -- Ridiculously inefficient, we can't keep receiving
        -- 1 byte at a time.
        --
        -- However, this won't work any other way without patching
        -- the LuaSec lib or getting dirty with the original FD.
        --
        -- I'll update this to use the raw FD down the line
        -- for more efficient buffering though.
        --
        self.buffer = self.buffer .. (self.socket:receive( 1 ) or '' )

        -- once we have enough data to figure out the size of the whole 
        -- responce move deeper
        if self.buffer:len() >= 4 then

            -- calc the size
            size = self:get_size( self.buffer )

            -- once we've buffered the whole response, return it
            if self.buffer:len() >= 4 + size then
                serialized_obj = self.buffer:sub( 5, self.buffer:len() )
                return serialized_obj
            end
        end
    end
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
        size = size .. self.buffer:sub( i, i ):byte( 1,1 )
    end

    -- ...and convert the ASCII string to a usable integer.
    return tonumber( size )
end

--
-- Prepares a payload for transmition by packing it with its size.
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

