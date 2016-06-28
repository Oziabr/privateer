_ = require 'lodash'
router    = (require 'express').Router()
debug     = (require 'debug') 'item'

title = 'Item'
table_name = route = 'item'

module.exports = (db) ->
  table = db[table_name]

  router.use (req, res, next) ->
    req.scope = {}
    res.locals.route = route
    res.locals.title = title
    next()
  router.all '/create', (req, res, next) ->
    next()
  router.all '/:id/edit', (req, res, next) ->
    next()
  router.all '/:id/delete', (req, res, next) ->
    next()

  errorHandler = (res) -> (err) -> res.render 'error', error: err

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
    res.render "#{route}/edit", item: req.item

  router.post '/:id/edit', (req, res) ->
    req.item.update req.body
    .then (item) ->
      res.redirect "/#{route}/#{item.id}"
    .catch errorHandler res

  router.get '/:id/delete', (req, res) ->
    res.render "#{route}/delete", item: req.item

  router.post '/:id/delete', (req, res) ->
    req.item.destroy()
    .then ->
      res.redirect "/#{route}"
    .catch errorHandler res

  return router
