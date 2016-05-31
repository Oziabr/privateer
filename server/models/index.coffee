_         = require 'lodash'
fs        = require 'fs'
path      = require 'path'

filetype  = require __dirname + '/../api/filetype'

Sequelize = require 'sequelize'
basename  = path.basename module.filename
env       = process.env.NODE_ENV || 'development'
config    = require(__dirname + '/../config/config.json')[env]
db        = {};
#epilogue  = require 'epilogue'

if config.use_env_variable
  sequelize = new Sequelize process.env[config.use_env_variable]
else
  sequelize = new Sequelize config.db.database, config.db.username, config.db.password, config.db

fs
  .readdirSync __dirname
  .filter (file) ->
    file.indexOf('.') != 0 && file != 'index.coffee' && file.slice(-7) == '.coffee'
  .forEach (file) ->
    model = sequelize['import'](path.join __dirname, file)
    db[model.name] = model

Object.keys(db).forEach (modelName) ->
  db[modelName]?.associate db
  db[modelName]?.addScope 'full', include: [ all: true ]

filetype.init sequelize.models, 'public/img'

db.sequelize = sequelize
db.Sequelize = Sequelize
#db.epilogue = epilogue

module.exports = db

#db.location.scope('full').findAll() #include: db.tour
#.then (set) ->
#  set = _.map set, (val) -> val.get plain: true
#  console.log 'location', set
#  _.each set, (val) -> console.log 'pos', val.tours

sequelize
#.sync()
.sync {force: true}
#.drop()
.then ->
  #return
  db.user.create
    email: "admin@youradmin.tld"
    password: 'redcvbgtf'
  .then (u) ->
    u.getProfile()
    .then (profile) ->

      profile.update
        first_name: 'Админус'
        last_name: 'Системикус'
        userpic: '76CTMWO8MQS2mrxIbL7qEd'

      profile.createUser
        email: 'same@admin.guy'
        password: 'okaoka'

  db.user.create
    email: 'some@other.guy'
    password: '1234321'
  .then (u) ->
    u.getProfile()
    .then (profile) ->
      profile.update
        first_name: 'other'
        last_name: 'guy'
        userpic: '0cgRaQ3FlPYabIhkTjs7me'

  db.user.create
    email: 'one@more.guy'
    password: '321321321'
  .then (u) ->
    u.getProfile()
    .then (profile) ->
      profile.update
        first_name: 'other'
        last_name: 'guy'
        userpic: '1dD1bBt0Kq5GRon7Nsasc9'