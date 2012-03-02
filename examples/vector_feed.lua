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

    -- only audit the stuff passed to vector feed
    link_count_limit = 0
}

instance:call( 'modules.load', { 'xss', 'path_traversal', 'grep/*' } )

vectors = {}
-- add a link var (for GET params)
table.insert( vectors, {
    type = 'link',
    action = 'http://demo.testfire.net/default.aspx',
    inputs = {
        content = 'personal_deposit.htm'
    }
})

-- add a form var (for POST params)
table.insert( vectors, {
    type = 'form',
    method = 'get',
    action = 'http://demo.testfire.net/search.aspx',
    inputs = {
        txtSearch = 'param value'
    }
})

-- add a cookie var
table.insert( vectors, {
    type = 'cookie',
    action = 'http://demo.testfire.net',
    inputs = {
        session_id = 'param value'
    }
})


-- and for the grep modules you can pass the HTTP response as a page
table.insert( vectors, {
    type = 'page',
    url = 'http://testfire.net',
    code = 200,
    body = 'Response body goes here',
    headers = {
        ["Content-type"] = 'text/html; charset=utf-8',
        ["Internal-IP-Address"] = '192.168.0.1'
    }
})

plugins = {
    vector_feed = {
        vectors = vectors
    }
}
instance:call( 'plugins.load', plugins )

instance:call( 'opts.set', opts )
instance:call( 'framework.run' )

io.write( 'Scanning' )
while instance:call( 'framework.busy?' ) do
    io.write( '.' )
    io.flush()
    
    -- sleep for a sec
    t0 = os.clock()
    while os.clock() - t0 <= 1 do end
end

print( 'Done!' )

print 'Discovered issues:'
print( yaml.dump( instance:call( 'framework.report' ).issues ) )

instance:call( 'service.shutdown' )
print( '[Instance has been shut down.]' )

