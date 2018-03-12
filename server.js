//console.log("server listening on: " + process.env.PORT)

var http = require('http'),
    httpProxy = require('http-proxy');

//
// Create your proxy server and set the target in the options.
//
var proxy = httpProxy.createProxyServer({
    target:'http://localhost:9000',
    auth:process.env.ES_USER + ':' + process.env.ES_PW
  }).listen(process.env.PORT || 8080);

// Handle it if kibana isn't up yet.
proxy.on('error', function (err, req, res) {
  res.writeHead(204, {
    'Content-Type': 'text/plain'
  });

  res.end('Kibana is not up yet.');
});

