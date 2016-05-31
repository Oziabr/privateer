bcrypt        = require 'bcrypt'
passport      = require 'passport'
LocalStrategy = require 'passport-local'

module.exports = (app, db) ->

  app.set 'profiles', {}
  profiles = app.get 'profiles'

  passport.use new LocalStrategy (username, password, cb) ->
    return cb null, false, message: 'no password provided' if !password

    db.user.findOne where: email: username
    .then (user) ->
      #return cb new Error 'user not exists' if !user
      return cb null, false, message: 'user not exists' if !user || !user.password
      bcrypt.compare password, user.password, (err, result) ->
        return cb null, false, message: 'password does not match' if err
        cb null, user


  passport.serializeUser (user, cb) ->
    user.getProfile()
    .then (profile) ->
      profiles[profile.id] = profile.get plain: true
      cb null, profile.id

  passport.deserializeUser (user, cb) ->
    #console.log 'des', user, profiles
    return cb null, user

  return passport


