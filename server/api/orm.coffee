_         = require 'lodash'
fs        = require 'fs'
path      = require 'path'
inflection = require 'inflection'
express   = (require 'express')
debug     = (require 'debug') 'orm'

Router    = require './router'
filetype  = require './filetype'

Sequelize = require 'sequelize'
basename  = path.basename module.filename
env       = process.env.NODE_ENV || 'development'
config    = require(__dirname + '/../config/config.json')[env]


orm = new Sequelize config.db.database, config.db.username, config.db.password, config.db

tables = {}

fs.readdirSync "./server/models"
  .filter (fileName) ->
    debug "read model #{fileName}"
    return false if ! /\.(js|coffee)$/.test fileName
    return ! console.log "restricted table name #{fileName}" if /^(index|PrimaryKey|Attribute|TableName|Scope|One|Many|Association|Hook)/i.test fileName
    true
  .forEach (fileName) ->
    debug "process model #{fileName}"
    tables[fileName.split('.')[0]] = (require "./../models/#{fileName}")

configureAttrs = (options) ->
  result = {}
  _.each options.attributes, (type, name) ->
    opts = []
    if typeof type != 'string'
      opts = type.slice 1
      type = type[0]
    return result[name] = orm.Sequelize.STRING() if !orm.Sequelize[type]
    result[name] = (orm.Sequelize[type])(opts...)
  result

mixins = ->
  _.each tables, (opts, name) ->
    debug "mixing model #{name}"
    if opts.paranoid
      (opts.routes ?= []).push 'get  /:id/restore one:show': (req, res) -> res.render "#{res.locals.route}/delete", item: req.item
      opts.routes.push         'post /:id/restore one:show': (req, res) -> req.item.restore().then (item) -> res.redirect "/#{res.locals.route}/#{item.id}"
    if opts.owned && opts.public
      (opts.related ?= []).push profile: type: 'm2o', as: 'owner'
      (opts.hooks_def ?= []).push ['beforeCreate', 'setOwner', (data, opt) ->
        return if !opt.req
        return throw type: 403, message: 'this action is not permitted' if !opt.req.isAuthenticated()
        data.owner_id = opt.req.user
      ]
      (opts.include ?= []).push ['profile', as: 'owner']
    if opts.revisions
      (_rel = {})["#{name}"] = type: 'm2o', as: 'revisioned', of: 'revisions'
      tables["#{name}_revs"] = related: [ _rel ], attributes: _.cloneDeep opts.attributes
      #(opts.related ?= {})["#{name}_revs"] = type: 'o2m', as: 'revisions', of: 'revisioned'
      (opts.hooks_def ?= []).push ['beforeUpdate', 'log', (data, opt) ->
        data.createRevision _.omit data._previousDataValues, 'id'
      ]
    if opts.public
      opts.routes =  [ 'use': (req, res, next) -> next null, res.locals.route = res.locals.title = if opts.public == true then name else opts.public ].concat (opts.routes ?= [])
      opts.routes.push 'get  / list':                 (req, res) -> res.render "#{res.locals.route}/list", list: req.list, actions: req.actions
      opts.routes.push 'get  /create':                (req, res) -> res.render "#{res.locals.route}/create"
      opts.routes.push 'post /create':                (req, res) -> ((orm.models[name].create req.body, req: req).then (item) -> res.redirect "/#{res.locals.route}/#{item.id}").catch (req.app.get 'errorHandler') res
      opts.routes.push 'get  /:id        one:show':   (req, res) -> res.render "#{res.locals.route}/show", item: req.item
      opts.routes.push 'get  /:id/edit   one:edit':   (req, res) -> res.render "#{res.locals.route}/edit", item: req.item
      opts.routes.push 'post /:id/edit   one:edit':   (req, res) -> ((req.item.update req.body, req: req).then (item) -> res.redirect "/#{res.locals.route}/#{item.id}").catch (req.app.get 'errorHandler') res
      opts.routes.push 'get  /:id/delete one:delete': (req, res) -> res.render "#{res.locals.route}/delete", item: req.item
      opts.routes.push 'post /:id/delete one:delete': (req, res) -> ((req.item.destroy req: req).then -> res.redirect "/#{res.locals.route}").catch (req.app.get 'errorHandler') res

define = ->
  _.each tables, (options, tableName) ->
    debug "defining model #{tableName}"
    attributes = configureAttrs(options)
    orm.define tableName, attributes, options

hooks = ->
  _.each orm.models, (model, name) ->
    debug "hooking model #{name}"
    # defined hooks
    if model.options.hooks_def?.length
      _.each model.options.hooks_def, (hook) ->
        [hookType, hookName, fn] = hook
        return console.log "unindentified hook #{hookType}" if !model[hookType]
        model[hookType] hookName, fn
    # defaultScope includes
    if model.options.include?.length
      'some'
      # model.addScope 'defaultScope', (include: [model: orm.models.profile, as: 'owner']), override: true
      model.addScope 'defaultScope', (include: _.compact _.map model.options.include, (include) ->
        [table, opt] = include
        return all: true if table == 'all'
        return _.extend (opt ?= {}), model: orm.models[table] if orm.models[table]
        console.log "include #{table} on #{name} doesn't make sense" if !(foreign = orm.models[table])
        false
      ), override: true

    model.afterFind 'getActions', (list, opt) ->
      return if !opt.req

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


relate = ->
  _.each orm.models, (model, name) ->
    return if !(relations = model.options.related)
    debug "relating model #{name}"
    # console.log 'model', name, relations, model.options.include
    _.each relations, (def) -> _.each def, (relation, table) ->
      return console.log "error relating ro table #{table}" if !(foreign = orm.models[table])
      switch relation.type
        when 'o2o'
          relation.as ?= foreign.tableName
          relation.of ?= model.tableName
          foreign.belongsTo model, onDelete: 'cascade', as: relation.as
          model.hasMany foreign, foreignKey: "#{relation.as}_id", as: relation.of
        when 'm2o'
          relation.as ?= foreign.tableName
          relation.of ?= model.tableName
          relation.of = inflection.pluralize relation.of
          return console.log "can't pluralize source table #{model.tableName} alias #{relation.of}" if relation.of == inflection.singularize relation.of
          model.belongsTo foreign, as: relation.as, onDelete: 'cascade'
          foreign.hasMany model, foreignKey: "#{relation.as}_id", as: relation.of
        when 'o2m'
          relation.as ?= model.tableName
          relation.of ?= foreign.tableName
          relation.as = inflection.pluralize relation.as
          return console.log "can't pluralize destination table #{foreign.tableName} alias #{relation.as}" if relation.as == inflection.singularize relation.as
          foreign.belongsTo model, onDelete: 'cascade', as: relation.of
          model.hasMany foreign, foreignKey: "#{relation.of}_id", as: relation.as
        when 'm2m'
          relation.of ?= model.tableName
          relation.as ?= foreign.tableName
          relation.as = inflection.pluralize relation.as
          relation.of = inflection.pluralize relation.of
          return console.log "can't pluralize destination table #{foreign.tableName} alias #{relation.as}" if relation.as == inflection.singularize relation.as
          return console.log "can't pluralize source table #{model.tableName} alias #{relation.of}" if relation.of == inflection.singularize relation.of
          relation.through ?= "#{model.tableName}2#{foreign.tableName}"
          through = orm.define relation.through if !(through = orm.models[relation.through]) && _.isString relation.through
          foreign.belongsToMany model, through: through, as: relation.of, foreignKey: "#{relation.as}_id"
          model.belongsToMany foreign, through: through, as: relation.as, foreignKey: "#{relation.of}_id"
          debug "made relation #{relation.through} with: ", _.omit orm.models[relation.through].options, 'sequelize'
        else console.log "undefined relation type #{relation.type}"

sync = ->
  return
  orm.sync force: true
  .then ->
    orm.models.paranoid_item.create
      title: 'Paranoid item 1'
    orm.models.user.create
      email: "admin@admin.tld"
      password: 'adminadmin'
    .then (user) ->
      # console.log "> user has key #{key}" for key of user when key.match /^(create|remove)/
      user.getProfile()
      .then (profile) ->
        profile.update
          first_name: 'Adminus'
          last_name: 'Superuserus'
          userpic: '01QqB6dqdAXkqc0WhS6glD'
        # console.log "> profile has key #{key}" for key of profile when key.match /^(create|remove)/
      orm.models.owned_item.create
        title: 'New Title'
        owner_id: user.profile_id
      .then (owned_item) ->
        # console.log "> owned_item has key #{key}" for key of owned_item when key.match /^(create|remove)/
    orm.models.revisioned_item.create
      title: "related revision 0"
    .then (revisioned_item) ->
      revisioned_item.update
        title: "related revision 1"
      .then (revisioned_item) ->
        revisioned_item.update
          title: "related revision 2"
        .then (revisioned_item) ->
          revisioned_item.getRevisions()
          .then (rev) ->
            # console.log "> revisioned_item has key #{key}" for key of revisioned_item when key.match /^(create|remove)/
            # console.log "> revisioned_item_rev has key #{key}" for key of rev[0] when key.match /^(create|remove)/

module.exports =
  process: (app) ->
    do mixins
    do define
    do hooks
    do relate
    do sync
  init: (app) ->
    app.set 'orm', orm
