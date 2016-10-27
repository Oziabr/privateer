_             = require 'lodash'
express       = require 'express'
favicon       = require 'serve-favicon'
cookieParser  = require 'cookie-parser'
bodyParser    = require 'body-parser'
jade          = require 'jade'
exSession     = require 'express-session'

path          = require 'path'
logger        = require 'morgan'

orm           = require './orm'
router        = require './router'
auth          = require './auth'
authRoutes    = require '../routes/auth'
filetype      = require './filetype'

module.exports = app = express()

# helpers
app.set 'errorHandler', (res) -> (err) ->
  console.log 'err', _.keys err
  res.render 'error', error: err

orm.init app

passport = auth.init app
filetype.init app, 'public/img'
session = exSession secret: '78UScJ80zW7XAfxwvHzsg9KpOY', resave: false, saveUninitialized: false

orm.process app

# view engine setup
app.set 'views', './server/views'
app.set 'view engine', 'jade'

app.use favicon './public/favicon.ico'
app.use logger 'dev' if process.env.NODE_ENV != 'test'
app.use express.static './public', maxAge: 86400000
app.use cookieParser()
app.use bodyParser.json()
app.use bodyParser.urlencoded extended: false
app.use session

app.use passport.initialize()
app.use passport.session()

app.use (req, res, next) ->
  return next() if !req.user
  res.locals.user = (req.app.get 'profiles')[req.user]
  next()

router app

app.get '/', (req, res) ->
  res.render 'index', locations: []

# error handlers

# app.use (req, res, next) ->
#   (req.app.get 'errorHandler')(res) message: 'Not Found', status: 404

# development error handler
# will print stacktrace
if app.get('env') == 'development'
  app.use (err, req, res, next) ->
    res.status err.status || 500
    res.render 'error',
      message: err.message
      error: err

# production error handler
# no stacktraces leaked to user
app.use (err, req, res, next) ->
  res.status err.status || 500
  res.render 'error',
    message: err.message
    error: {}
