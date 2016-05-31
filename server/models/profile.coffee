module.exports = (sequelize, dt) ->
  sequelize.define 'profile', {
    username:   dt.STRING
    first_name: dt.STRING
    last_name:  dt.STRING
    userpic:    dt.FILE
  }, classMethods:
    associate: (models) ->
      @.hasMany models.user
      return

