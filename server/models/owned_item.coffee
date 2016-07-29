_ = require 'lodash'

module.exports =
  attributes:
    title: 'STRING'
  owned: true
  public: true
  # include: [[ 'all' ]]
  # related: [
  #     item: type: 'm2m', as: 'lulz', of: 'some'
  #   , item: type: 'o2m', as: 'lapi', of: 'root'
  # ]

x = (sequelize, dt) ->
  sequelize.define 'owned_item', {
    title:        dt.STRING
    field1:       dt.TEXT
    field2:       dt.TEXT
  },
    defaultScope: include: [ all: true ]
    classMethods:
      find: (action) ->
        (req, res, next) =>
          req.action = action
          @.findById parseInt(req.params.id), req: req
          .then (item) ->
            req.item = item
            next()
          .catch (req.app.get 'errorHandler') res

      associate: (models) ->
        @.belongsTo models.profile, as: 'owner'

        @.beforeCreate 'bc', (data, opt) ->
          return throw type: 403, message: 'this action is not permitted' if !opt.req.isAuthenticated()
          data.owner_id = opt.req.user

        @.beforeUpdate 'bu', (data, opt) ->
          return throw type: 403, message: 'this action is not permitted' if !opt.req.isAuthenticated() || opt.req.user != data.owner_id

        @.beforeDestroy 'bd', (data, opt) ->
          return throw type: 403, message: 'this action is not permitted' if !opt.req.isAuthenticated() || opt.req.user != data.owner_id


        @.afterFind 'af', (list, opt) ->

          if _.isArray list
            opt.req.actions ?= {}
            opt.req.actions.c = 1 if opt.req.isAuthenticated()
            _.map list, (item) ->
              item.actions ?= {}
              item.actions.e = 1 if item.owner_id == opt.req.user
              item.actions.d = 1 if item.owner_id == opt.req.user
            return 0
          else
            return throw type: 404, message: 'no such record' if !list
            list.actions ?= {}
            list.actions.e = 1 if list.owner_id == opt.req.user
            list.actions.d = 1 if list.owner_id == opt.req.user
            return throw type: 403, message: 'this action is not permitted' if opt.req.action == 'edit' && !list.actions.e
            return throw type: 403, message: 'this action is not permitted' if opt.req.action == 'delete' && !list.actions.d

        return
