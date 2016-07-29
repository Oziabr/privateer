bcrypt        = require 'bcrypt'
passport      = require 'passport'
LocalStrategy = require 'passport-local'

hashPassword = (user, options, next) ->
  return next 'password too short' if user.password.length < 6
  bcrypt.genSalt 11, (err, salt) ->
    bcrypt.hash user.password, salt, (err, hash) ->
      return next 'password hashing error' if err
      user.password = hash
      next null, user

defaultProfile = (user, options, next) ->
  return next null, user if user.profile_id != null
  user.createProfile username: user.email
  .then -> next null, user

module.exports =
  init: (app) ->
    orm = app.get 'orm'

    app.set 'profiles', profiles = {}
    app.use (req, res, next) ->
      return next() if req.user == undefined
      profiles = req.app.get 'profiles'
      res.locals.user = profiles[req.user]
      next()

    orm.define 'profile',
      username: orm.Sequelize.STRING,
      first_name: orm.Sequelize.STRING,
      last_name: orm.Sequelize.STRING,
      userpic: orm.Sequelize.FILE
    orm.define 'user',
      email:    type: orm.Sequelize.STRING, unique: true, validate: isEmail: true
      password: type: orm.Sequelize.STRING
    , related: [ profile: type: 'm2o' ]
    orm.define 'role',
      title:    type: orm.Sequelize.STRING, unique: true, required: true
    , related: [ profile: type: 'm2m', as: 'member' ]
    orm.models.user.beforeCreate 'hashPassword', hashPassword
    orm.models.user.beforeUpdate 'hashPassword', hashPassword
    orm.models.user.afterCreate 'defaultProfile', defaultProfile


    passport.use new LocalStrategy (username, password, cb) ->
      return cb null, false, message: 'no password provided' if !password

      orm.models.user.findOne where: email: username
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
