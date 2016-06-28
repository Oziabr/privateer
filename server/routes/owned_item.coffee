_ = require 'lodash'
router    = (require 'express').Router()
debug     = (require 'debug') 'item'

title = 'Owned Item'
table_name = route = 'owned_item'

errorHandler = (res) -> (err) -> res.render 'error', error: err

module.exports = (db) ->
  table = db[table_name]

  router.use (req, res, next) ->
    console.log 'u', req.user, req.isAuthenticated()
    req.scope = {}
    res.locals.route = route
    res.locals.title = title
    next()
  router.all '/create', (req, res, next) ->
    return errorHandler(res) type: 403, message: 'not authenticated to do that' if !req.isAuthenticated()
    req.body.owner_id = req.user if req.body
    next()
  router.all '/:id/edit', (req, res, next) ->
    return errorHandler(res) type: 403, message: 'not authenticated to do that' if !req.isAuthenticated()
    next()
  router.all '/:id/delete', (req, res, next) ->
    return errorHandler(res) type: 403, message: 'not authenticated to do that' if !req.isAuthenticated()
    next()

  # lists

  router.get '/', (req, res, next) ->
    table.findAll()
    .then (list) ->
      req.list = list
      next()
    .catch errorHandler res

  router.get '/', (req, res) ->
    res.render "#{route}/list", list: req.list

  # items

  router.param 'id', (req, res, next, id) ->
    table.findById parseInt id
    .then (item) ->
      return errorHandler(res) type: 404, message: 'No such record exists' if !item
      req.item = item
      next()
    .catch errorHandler res

  router.get '/create', (req, res) ->
    res.render "#{route}/create"

  router.post '/create', (req, res) ->
    table.create req.body
    .then (item) ->
      res.redirect "/#{route}/#{item.id}"
    .catch errorHandler res

  router.get '/:id', (req, res) ->
    res.render "#{route}/show", item: req.item

  router.get '/:id/edit', (req, res) ->
    return errorHandler(res) type: 403, message: 'not an owner' if req.user != req.item.owner_id
    res.render "#{route}/edit", item: req.item

  router.post '/:id/edit', (req, res) ->
    return errorHandler(res) type: 403, message: 'not an owner' if req.user != req.item.owner_id
    req.item.update req.body
    .then (item) ->
      res.redirect "/#{route}/#{item.id}"
    .catch errorHandler res

  router.get '/:id/delete', (req, res) ->
    return errorHandler(res) type: 403, message: 'not an owner' if req.user != req.item.owner_id
    res.render "#{route}/delete", item: req.item

  router.post '/:id/delete', (req, res) ->
    return errorHandler(res) type: 403, message: 'not an owner' if req.user != req.item.owner_id
    req.item.destroy()
    .then ->
      res.redirect "/#{route}"
    .catch errorHandler res

  return router
