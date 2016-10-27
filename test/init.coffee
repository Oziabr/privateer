app = require '../server/api/app'
http = require 'http'
port = 9031

app.set 'port', port
server = http.createServer app

server.listen port
server.on 'listening', ->
  console.log "Server is on #{typeof (addr = server.address()) == 'string' ? 'pipe ' + addr : 'port ' + addr.port}"
server.on 'error', (err)->
  throw err if err.syscall != 'listen'
  console.error err.code, err
  process.exit 1







