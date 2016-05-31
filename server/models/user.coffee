bcrypt = require 'bcrypt'

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

module.exports = (sequelize, dt) ->
  sequelize.define 'user', {
    email:
      type:   dt.STRING
      unique: true
      validate: isEmail: true
    password:
      type:   dt.STRING
  }, {
    classMethods:
      associate: (models) ->
        @.belongsTo models.profile
        return
    hooks:
      beforeCreate: hashPassword
      beforeUpdate: hashPassword
      afterCreate: defaultProfile
  }