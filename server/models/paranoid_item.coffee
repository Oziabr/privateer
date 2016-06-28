module.exports = (sequelize, dt) ->
  sequelize.define 'paranoid_item',
    title:        dt.STRING
    field1:       dt.TEXT
    field2:       dt.TEXT
  ,
    scopes:
      all:
        paranoid: false
      deleted:
        where: deleted_at: $ne: null
        paranoid: false
    paranoid: true
    classMethods:
      associate: (models) ->
        return
