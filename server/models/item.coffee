module.exports = (sequelize, dt) ->
  sequelize.define 'item', {
    title:        dt.STRING
    field1:       dt.TEXT
    field2:       dt.TEXT
  }, classMethods:
    associate: (models) ->
      return