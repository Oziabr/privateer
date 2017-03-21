_         = require 'lodash'

module.exports = (orm, tables, helpers) ->

  paranoid: (opts, name) ->
    opts.routes = opts.routes || []
    opts.routes.push 'get  /:id/restore': [
      helpers.oneOf(name, 'show')
      (req, res) -> res.render "#{res.locals.route}/delete", item: req.item
    ]
    opts.routes.push 'post /:id/restore': [
      helpers.oneOf(name, 'show')
      (req, res) -> req.item.restore().then (item) -> res.redirect "/#{res.locals.route}/#{item.id}"
    ]

  owned: (opts, name) ->
    return if !opts.public
    opts.related = opts.related || []
    opts.hooks_def = opts.hooks_def || []
    opts.include = opts.include || []
    opts.related.push profile: type: 'm2o', as: 'owner'
    opts.hooks_def.push ['beforeCreate', 'setOwner', (data, opt) ->
      return if !opt.req
      return throw type: 403, message: 'this action is not permitted' if !opt.req.isAuthenticated()
      data.owner_id = opt.req.user
    ]
    opts.include.push ['profile', as: 'owner']
  revisions: (opts, name) ->
    (_rel = {})["#{name}"] = type: 'm2o', as: 'revisioned', of: 'revisions'
    tables["#{name}_revs"] = related: [ _rel ], attributes: _.cloneDeep opts.attributes
    #(opts.related ?= {})["#{name}_revs"] = type: 'o2m', as: 'revisions', of: 'revisioned'
    (opts.hooks_def ?= []).push ['beforeUpdate', 'log', (data, opt) ->
      data.createRevision _.omit data._previousDataValues, 'id'
    ]

  public: (opts, name) ->
    opts.routes = opts.routes || []
    opts.routes =  [ 'use': [ (req, res, next) -> (res.locals.route = res.locals.title = if opts.public == true then name else opts.public); next null ] ].concat (opts.routes ?= [])
    opts.routes.push 'get  /':            [ helpers.listOf(name),          (req, res) -> res.render "#{res.locals.route}/list", list: (req.list.map (item) -> item.get plain: true), actions: req.actions ]
    opts.routes.push 'get  /create':      [                                           (req, res) -> res.render "#{res.locals.route}/create" ]
    opts.routes.push 'post /create':      [                                           (req, res) -> ((orm.models[name].create req.body, req: req).then (item) -> res.redirect "/#{res.locals.route}/#{item.id}").catch (req.app.get 'errorHandler') res ]
    opts.routes.push 'get  /:id':         [ helpers.oneOf(name, 'show'),   (req, res) -> res.render "#{res.locals.route}/show", item: req.item.get plain: true ]
    opts.routes.push 'get  /:id/edit':    [ helpers.oneOf(name, 'edit'),   (req, res) -> res.render "#{res.locals.route}/edit", item: req.item.get plain: true ]
    opts.routes.push 'post /:id/edit':    [ helpers.oneOf(name, 'edit'),   (req, res) -> ((req.item.update req.body, req: req).then (item) -> res.redirect "/#{res.locals.route}/#{item.id}").catch (req.app.get 'errorHandler') res ]
    opts.routes.push 'get  /:id/delete':  [ helpers.oneOf(name, 'delete'), (req, res) -> res.render "#{res.locals.route}/delete", item: req.item.get plain: true ]
    opts.routes.push 'post /:id/delete':  [ helpers.oneOf(name, 'delete'), (req, res) -> ((req.item.destroy req: req).then -> res.redirect "/#{res.locals.route}").catch (req.app.get 'errorHandler') res ]
