passport = require 'passport'

module.exports = [
  { 'get /': (req, res) -> res.redirect '/' }
  { 'get /login': (req, res) -> res.render 'auth/login' }

  { 'post /login': passport.authenticate('local', failureRedirect: '/auth/login', successRedirect: '/') }

  { 'get /logout': (req, res) -> req.logout(); res.redirect '/' }
  { 'get /register': (req, res) -> res.render 'auth/register' }

  { 'post /register': (req, res) ->
      req.app.get('orm').models.user.create req.body
      .then (user) ->
        req.body.username = req.body.email
        passport.authenticate('local', failureRedirect: '/', successRedirect: '/profile')(req, res)
      .catch (req.app.get 'errorHandler') res
  }
]
