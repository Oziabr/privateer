_ = require 'lodash'
fs = require 'fs'

router = (require 'express').Router()
uploader  = (require __dirname + '/../api/filetype').uploader()
debug  = (require 'debug') 'profile'

module.exports = (db) ->

  router.get '/', (req, res) ->
    return res.redirect '/' if !req.isAuthenticated()
    db.profile
    .findById req.user
    .then (profile) ->
      res.render 'profile/show', profile: profile

  router.post '/', uploader(db.profile), (req, res) ->
    return res.redirect '/' if !req.isAuthenticated()
    db.profile
    .findById req.user
    .then (profile) ->
      profile.update req.body
      .then () ->
        profiles = req.app.get 'profiles'
        profiles[req.user] = profile.get plain: true
        res.redirect '/profile'

  return router
