require 'client'

dispatcher = ArachniRPCClient:new( { host = 'localhost', port = 7331 } )
instance_info = dispatcher:call( 'dispatcher.dispatch' )

instance = ArachniRPCClient:new({
    host  = 'localhost',
    port  = instance_info.port,
    token = instance_info.token
})

opts = {
    url = 'http://demo.testfire.net',
    audit_links = true,
    audit_forms = true,
    audit_cookies = true,
    link_count_limit = 1
}

instance:call( 'modules.load', { 'xss' } )
instance:call( 'opts.set', opts )
instance:call( 'framework.run' )

local clock = os.clock
function sleep( n )
    local t0 = clock()
    while clock() - t0 <= n do end
end

io.write( 'Scanning' )
while instance:call( 'framework.busy?' ) do
    io.write( '.' )
    io.flush()
    sleep( 1 )
end

print( 'Done!' )

print 'Discovered issues:'
print( yaml.dump( instance:call( 'framework.report' ).issues ) )

instance:call( 'service.shutdown' )
print( '[Instance has been shut down.]' )
