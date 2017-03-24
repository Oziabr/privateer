_         = require 'lodash'
fs        = require 'fs'
debug     = (require 'debug') 'router'
express   = (require 'express')

module.exports = (app) ->
  orm = app.get("orm")

  routes = {}
  fs.readdirSync "./server/routes"
  .filter (fileName) -> /\.(js|coffee)$/.test fileName
  .forEach (fileName) ->
    route = fileName.slice 0, fileName.indexOf '.'
    return if !(router = require "./../routes/#{fileName}") || !router.length
    debug "reading routes from file #{fileName}, #{router.length}"
    routes[route] = [{ 'use': (req, res, next) -> next null, res.locals.route = res.locals.title = route }].concat router

  for modelName, model of orm.models when model.options.routes
    debug "reading routes from model #{model.tableName}"
    routeName =  if model.options.public == true || !model.options.public then modelName else model.options.public
    model.options.routes.splice 1, 0, (routes[modelName] ?= [])...
    routes[routeName] = model.options.routes

  for routeName, defs of routes
    debug "using #{defs.length} paths for route #{routeName}"
    _.each defs, (def) -> _.each def, (fn, key) ->
      debug "#{routeName} has path #{key}"
      [action, actionPath] = key.split /\s+/
      app.use "/#{routeName}", (router = express.Router()) if routeName != 'index'
      app.use (router = express.Router()) if routeName == 'index'
      return router[action] fn if !actionPath
      return router[action] actionPath, fn... if _.isArray fn
      return router[action] actionPath, fn
