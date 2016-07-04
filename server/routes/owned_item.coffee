_ = require 'lodash'
router    = (require 'express').Router()
debug     = (require 'debug') 'item'

title = 'Owned Item'
table_name = route = 'owned_item'

module.exports = (db) ->
  table = db[table_name]

  router.use (req, res, next) ->
    res.locals.route = route
    res.locals.title = title
    next()

  # lists

  router.get '/', (req, res, next) ->
    table.findAll req: req
    .then (list) ->
      req.list = list
      next()
    .catch (req.app.get 'errorHandler') res

  router.get '/', (req, res) ->
    res.render "#{route}/list", list: req.list, actions: req.actions

  # items

  router.get '/create', (req, res) ->
    res.render "#{route}/create"

  router.post '/create', (req, res) ->
    table.create req.body, req: req
    .then (item) ->
      res.redirect "/#{route}/#{item.id}"
    .catch (req.app.get 'errorHandler') res

  router.get '/:id', table.find('show'), (req, res) ->
    res.render "#{route}/show", item: req.item

  router.get '/:id/edit', table.find('edit'), (req, res) ->
    res.render "#{route}/edit", item: req.item

  router.post '/:id/edit', table.find('edit'), (req, res) ->
    req.item.update req.body, req: req
    .then (item) ->
      res.redirect "/#{route}/#{item.id}"
    .catch (req.app.get 'errorHandler') res

  router.get '/:id/delete', table.find('delete'), (req, res) ->
    res.render "#{route}/delete", item: req.item

  router.post '/:id/delete', table.find('delete'), (req, res) ->
    req.item.destroy req: req
    .then ->
      res.redirect "/#{route}"
    .catch (req.app.get 'errorHandler') res

  return router
