_         = require 'lodash'
fs        = require 'fs'
debug     = (require 'debug') 'router'
express   = (require 'express')
uploader  = (require __dirname + '/../api/filetype').uploader()

module.exports = (app) ->
  _one = (model, action) -> (req, res, next) ->
    req.action = action
    model.findById parseInt(req.params.id), req: req
    .then (item) ->
      req.item = item
      next()
    .catch (req.app.get 'errorHandler') res
  _list = (model) -> (req, res, next) ->
    model.findAll req: req
    .then (list) ->
      req.list = list
      next()
    .catch (req.app.get 'errorHandler') res

  routes = {}
  fs.readdirSync "./server/routes"
  .filter (fileName) -> /\.(js|coffee)$/.test fileName
  .forEach (fileName) ->
    route = fileName.slice 0, fileName.indexOf '.'
    return if !(router = require "./../routes/#{fileName}") || !router.length
    debug "reading routes from file #{fileName}, #{router.length}"
    routes[route] = router

  for modelName, model of app.get("orm").models when model.options.routes
    debug "reading routes from model #{model.tableName}"
    model.options.routes.splice 1, 0, (routes[modelName] ?= [])...
    routes[modelName] = model.options.routes

  for routeName, defs of routes
    debug "using #{defs.length} paths for route #{routeName}"
    _.each defs, (def) -> _.each def, (fn, key) ->
      debug "#{routeName} has path #{key}"
      [action, actionPath, preload] = key.split /\s+/
      app.use "/#{routeName}", (router = express.Router()) if routeName != 'index'
      app.use (router = express.Router()) if routeName == 'index'
      return router[action] fn if !actionPath
      return router[action] actionPath, fn if !preload
      return if !(model = app.get("orm").models[routeName])
      return router[action] actionPath, (uploader model), fn if preload == 'uploader'
      return router[action] actionPath, (_list model), fn if preload == 'list'
      return router[action] actionPath, (_one model, preload.split(':')[1]), fn if preload.match /^one:/
