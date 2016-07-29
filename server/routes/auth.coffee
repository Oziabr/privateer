passport = require 'passport'

module.exports = [
  { 'get /': (req, res) -> res.redirect '/' }
  { 'get /login': (req, res) -> res.render 'auth/login' }

  { 'post /login': passport.authenticate('local', failureRedirect: '/auth/login') }
  { 'post /login': (req, res) -> res.redirect '/' }

  { 'get /logout': (req, res) -> req.logout(); res.redirect '/' }
  { 'get /register': (req, res) -> res.render 'auth/register' }

  { 'post /register': (req, res) ->
      req.app.get('orm').models.user.create req.body
      .then (data) ->
        res.redirect '/'
      .catch (err) ->
        res.send 'error: ' + JSON.stringify err
  }
]
