module.exports = [
  { 'get /': (req, res) ->
      return res.redirect '/' if !req.isAuthenticated()
      req.app.get('orm').models.profile.findById req.user
      .then (profile) -> res.render 'profile/show', profile: profile
  }
  { 'post /': (req, res) ->
      return res.redirect '/' if !req.isAuthenticated()
      req.app.get('orm').models.profile.findById req.user
      .then (profile) ->
        profile.update req.body
        .then () ->
          profiles = req.app.get 'profiles'
          profiles[req.user] = profile.get plain: true
          res.redirect '/profile'
  }
]
