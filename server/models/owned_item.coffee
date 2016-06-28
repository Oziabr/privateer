module.exports = (sequelize, dt) ->
  sequelize.define 'owned_item', {
    title:        dt.STRING
    field1:       dt.TEXT
    field2:       dt.TEXT
  },
    defaultScope:
      include: [
        all: true
      ]
    classMethods:
      associate: (models) ->
        @.belongsTo models.profile, as: 'owner'
        return