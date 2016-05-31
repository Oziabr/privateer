_ = require 'lodash'
fs = require 'fs'
debug = (require 'debug') 'api'
Router = (require 'express').Router

list = (model) -> (req, res) ->
  debug model
  model.scope('full').findAll()
  .then (result) -> res.send result
  .catch (err) -> res.send err

show = (model) -> (req, res) ->
  debug model
  model.findById parseInt req.params.id
  .then (result) -> res.send result
  .catch (err) -> res.send err

create = (model) -> (req, res) ->
  model.create req.query
  .then (result) -> res.send result
  .catch (err) -> res.send err

update = (model) -> (req, res) ->
  model.findById parseInt req.params.id
  .then (instance) ->
    instance.update req.query
    .then (result) ->
      res.send result
    .catch (err) -> res.send err
  .catch (err) -> res.send err

remove = (model) -> (req, res) ->
  model.findById parseInt req.params.id
  .then (instance) ->
    instance.destroy()
    .then (result) ->
      res.send result
    .catch (err) -> res.send err
  .catch (err) -> res.send err



module.exports = (app, db) ->
  models = _.keys db.sequelize.models

  app.get '/api', (req, res) -> res.send models
  #app.get '/test', (req, res) -> db.sequelize.models

  models.forEach (key) ->
    router = Router()
    model = db.sequelize.models[key]
    debug model

    router.get "/", list model
    router.get "/:id", show model
    router.post "/", create model
    router.put "/:id", update model
    router.delete "/:id", remove model

    router.get "/create", create model
    router.get "/update/:id", update model
    router.get "/delete/:id", remove model

    app.use "/api/#{key}", router
