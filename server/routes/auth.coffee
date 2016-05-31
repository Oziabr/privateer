router = (require 'express').Router()
debug  = (require 'debug') 'auth'
passport = require 'passport'

module.exports = (db) ->

  router.get '/', (req, res) ->
    res.redirect '/'

  router.get '/login', (req, res) ->
    res.render 'auth/login'

  router.post '/login', passport.authenticate('local', failureRedirect: '/auth/login'), (req, res) ->
    res.redirect '/'

  router.get '/logout', (req, res) ->
    req.logout()
    res.redirect '/'

  router.get '/register', (req, res) ->
    res.render 'auth/register'

  router.post '/register', (req, res) ->
    db.user.create req.body
    .then (data) ->
      res.redirect '/'
    .catch (err) ->
      res.send 'error: ' + JSON.stringify err

  return router
