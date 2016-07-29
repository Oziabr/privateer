_               = require 'lodash'
fs              = require 'fs'
util            = require 'util'
sequelizeErrors = require 'sequelize/lib/errors'
dt              = require 'sequelize/lib/data-types'
multer          = require 'multer'
uuidb62         = require 'uuid-base62'
debug           = (require 'debug') 'filetype'

FILE = dt.ABSTRACT.inherits()
FILE.prototype.key = FILE.key = 'FILE'
FILE.prototype.toSql = ->
  return 'CHAR(22)'
FILE.prototype.validate = (value) ->
  if Object.prototype.toString.call(value) != '[object String]'
    throw new sequelizeErrors.ValidationError util.format '%j is not a valid string', value
  true
dt.FILE = FILE

root_path = 'uploads'

storage = multer.diskStorage
  destination: (req, file, cb) ->
    console.log 'file', file
    cb null, "#{root_path}/#{file.fieldname}"
  filename: (req, file, cb) ->
    cb null, uuidb62.v4()


module.exports =
  init: (app, path) ->
    models = app.get('orm').models
    root_path = path if path
    #console.log 'path', path, y, fs.readdirSync(path.split('/')[0])
    fs.mkdirSync path if !fs.existsSync path


    _.filter models, (model) -> _.some model.attributes, ['type.key', 'FILE']
    .forEach (model) ->
      fields = _.filter model.attributes, ['type.key', 'FILE']

      fields.forEach (field) ->
        name = field.field
        fs.mkdirSync dir if !fs.existsSync dir = "#{root_path}/#{name}"

      model.afterUpdate "filetypeGC", (one, opt) ->
        fields.forEach (field) ->
          name = field.field
          return if one._previousDataValues[name] == null || one.dataValues[name] == one._previousDataValues[name]
          collect = "#{root_path}/#{name}/#{one._previousDataValues[name]}"
          fs.access collect, (err) ->
            #fs.unlink collect, model.sequelize.Promise.resolve if !err
            fs.unlink collect, (-> debug "done cleaning #{name}") if !err


  uploader: ->
    (model) ->
      (req, res, next) ->
        options = _.filter model.attributes, ['type.key', 'FILE']
        .map (field) -> name: field.field, maxCount: 1
        multer(storage: storage).fields(options) req, res, () ->
          _.each req.files, (file, key) ->
            req.body[key] = file[0].filename if _.isArray file
          do next
