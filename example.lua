require 'client'

rpc = ArachniRPCClient:new( { host = 'localhost', port = 7331, token = nil } )
--print( rpc:call( 'bench.foo', { 'test' } ).obj )
print( rpc:call( 'dispatcher.dispatch' ).obj.url )

