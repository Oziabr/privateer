_ = require 'lodash'
router    = (require 'express').Router()
uploader  = (require __dirname + '/../api/filetype').uploader()
debug     = (require 'debug') 'item'


module.exports = (db) ->
  table = db.item

  errorHandler = (err) -> res.render 'error', error: err

  router.get '/', (req, res, next) ->
    table.findAll()
    .then (list) ->
      req.list = list
      next()
    .catch errorHandler

  router.param 'id', (req, res, next, id) ->
    table.findById parseInt id
    .then (item) ->
      return res.render 'error', error: type: 404, message: 'No such record exist' if !item
      req.item = item
      next()
    .catch errorHandler

  router.get '/', (req, res) ->
    res.render 'item/list', list: req.list

  router.get '/create', (req, res) ->
    res.render 'item/create'

  router.post '/create', (req, res) ->
    table.create req.body
    .then (item) ->
      res.redirect "/item/#{item.id}"
    .catch errorHandler

  router.get '/:id', (req, res) ->
    res.render 'item/show', item: req.item

  router.get '/:id/edit', (req, res) ->
    res.render 'item/edit', item: req.item

  router.post '/:id/edit', (req, res) ->
    req.item.update req.body
    .then ->
      res.redirect '/item/#{item.id}'
    .catch errorHandler

  router.get '/:id/delete', (req, res) ->
    res.render 'item/delete', item: req.item

  router.post '/:id/delete', (req, res) ->
    req.item.destroy()
    .then ->
      res.redirect '/item'
    .catch errorHandler


  return router
