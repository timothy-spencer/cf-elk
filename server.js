//console.log("server listening on: " + process.env.PORT)

var http = require('http'),
    httpProxy = require('http-proxy');
//
// Create your proxy server and set the target in the options.
//
httpProxy.createProxyServer({target:'http://localhost:9000'}).listen(process.env.PORT || 8080);

