module.exports = [
  { 'get /': (req, res) -> res.render 'index', locations: [] }
]
  #app.get '/admin', (req, res) -> res.render 'admin'
  #app.get '/template/:instance/:action', (req, res) -> res.render "template/#{req.params.instance}/#{req.params.action}"
  #app.get '/dev-reset', (req, res) ->
