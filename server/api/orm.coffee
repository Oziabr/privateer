_         = require 'lodash'
fs        = require 'fs'
path      = require 'path'
inflection = require 'inflection'
express   = (require 'express')
debug     = (require 'debug') 'orm'

Router    = require './router'
filetype  = require './filetype'
#sync      = require './sync'

Sequelize = require 'sequelize'
basename  = path.basename module.filename
env       = process.env.NODE_ENV || 'development'
config    = require(__dirname + '/../config/config.json')[env]


orm = new Sequelize config.db.database, config.db.username, config.db.password, config.db

tables = {}

helpers =
  oneOf: (modelName, action) -> (req, res, next) ->
    return next "model doesnt exist" if !(model = orm.models[modelName])
    req.action = action
    options = req: req
    _.defaults options, req["modelScope_#{modelName}"] if req["modelScope_#{modelName}"]
    model.findById parseInt(req.params.id), options
    .then (item) ->
      req.item = item
      next()
    .catch (req.app.get 'errorHandler') res
  listOf: (modelName) -> (req, res, next) ->
    return next "model doesnt exist" if !(model = orm.models[modelName])
    options = req: req
    _.defaults options, req["modelScope_#{modelName}"] if req["modelScope_#{modelName}"]
    model.findAll options
    .then (list) ->
      req.list = list
      next()
    .catch (req.app.get 'errorHandler') res

fs.readdirSync "./server/models"
.filter (fileName) -> fileName.match /\.(js|coffee)$/i
.filter (fileName) -> ! fileName.match /^(index|PrimaryKey|Attribute|TableName|Scope|One|Many|Association|Hook)/i
.forEach (fileName) ->
  debug "process model #{fileName}"
  tables[fileName.split('.')[0]] = (require "./../models/#{fileName}")

configureAttrs = (options) ->
  result = {}
  _.each options.attributes, (type, name) ->
    opts = []
    if ! _.isString type
      opts = type.slice 1
      type = type[0]
    return result[name] = orm.Sequelize.STRING() if !orm.Sequelize[type]
    result[name] = options.extra[name] if options.extra?[name]
    (result[name] ?= {}).type = (orm.Sequelize[type])(opts...)
  result

mixin_def = require('./orm/mixins') orm, tables, helpers

mixins = (app) ->
  _.each tables, (opts, name) ->
    debug "mixing model #{name}"
    _.each mixin_def, (fn, def) ->
      fn(opts, name) if opts[def]

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
      # model.addScope 'defaultScope', (include: [model: orm.models.profile, as: 'owner']), override: true
      model.addScope 'defaultScope', (include: _.compact _.map model.options.include, (include) ->
        [table, opt] = include
        return all: true if table == 'all'
        return _.extend (opt ?= {}), model: orm.models[table] if orm.models[table]
        console.log "include #{table} on #{name} doesn't make sense" if !(foreign = orm.models[table])
        false
      ), override: true

    if model.options.owned
      model.afterFind 'getActions', (list, opt) ->
        return if !opt.req

        if _.isArray list
          opt.req.actions ?= {}
          opt.req.actions.c = 1 if opt.req.isAuthenticated()
          _.map list, (item) ->
            # debug item.owner_id == opt.req.user, item.owner_id, opt.req.user
            actions = {}
            item.setDataValue 'actions', actions
            actions.e = 1 if item.owner_id == opt.req.user
            actions.d = 1 if item.owner_id == opt.req.user
          return 0

        else
          return throw type: 404, message: 'no such record' if !list
          list.setDataValue 'actions', (actions = {})
          actions.e = 1 if list.owner_id == opt.req.user
          actions.d = 1 if list.owner_id == opt.req.user
          return throw type: 403, message: 'this action is not permitted' if opt.req.action == 'edit' && !actions.e
          return throw type: 403, message: 'this action is not permitted' if opt.req.action == 'delete' && !actions.d


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
          debug "made m2m relation #{relation.through} for #{model.tableName} and #{foreign.tableName} as #{relation.as} of #{relation.of}"
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

scoping = ->
  _.each orm.models, (model, name) ->
    return if !(scopes = model.options.scope_def)
    debug "scoping model #{name}", model.options.scopes
    model.addScope 'noscope', deleted: true
    _.each scopes, (scope) ->
      # debug "!!!!!!!!!!!!!!!!!!!!! scope is ", scope, model.options.defaultScope, model.options.scope
      # debug "scope is ", key for key of model.options when key.match /scope/i  #'defaultScope'
      model.addScope scope...
      debug "!!!!!!!!!!!!!!!!!!!!! scope is ", scope, model.options.defaultScope, model.options.scope

module.exports =
  process: (app) ->
    mixins app
    do define
    do hooks
    do relate
    do scoping
    sync orm
  init: (app) ->
    app.set 'helpers', helpers
    app.set 'orm', orm
