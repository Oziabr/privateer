fs = require 'fs'
spawn = require('child_process').spawn
debug = (require 'debug') 'app'

module.exports = (app) ->
  db = app.get 'orm'
  app.get '/', (req, res) ->
    res.render 'index', locations: []
  #app.get '/admin', (req, res) -> res.render 'admin'
  #app.get '/template/:instance/:action', (req, res) -> res.render "template/#{req.params.instance}/#{req.params.action}"
  #app.get '/dev-reset', (req, res) ->
  #  return res.render 'dev-reset', msg: 'server reset is not available' if !process.env.GIT_RESET && !process.env.pm_id
  #  res.render 'dev-reset', msg: "server reseting #{process.env.pm_id}"
  #  spawn "./bin/dev-reset #{process.env.pm_id} #{process.env.GIT_RESET}", detached: true, stdio: ['ignore']

  fs.readdirSync "#{__dirname}"
  .filter (fname) -> fname != 'index.coffee' && /\.(js|coffee)$/.test fname
  .forEach (fname) ->
    path = fname.slice 0, fname.lastIndexOf '.'
    debug "using routes from #{__dirname}/#{fname}"
    app.use "/#{path}", (require "#{__dirname}/#{path}")(db)
