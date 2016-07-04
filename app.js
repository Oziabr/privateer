require('coffee-script/register');

var _             = require('lodash');
var express       = require('express');
var path          = require('path');
var favicon       = require('serve-favicon');
var logger        = require('morgan');
var cookieParser  = require('cookie-parser');
var bodyParser    = require('body-parser');
var jade          = require('jade');

var db            = require('./server/models/index');
var app           = express();

app.set('orm', db);
app.set('errorHandler', function(res) {
  return function(err) {
    res.render('error', {error: err})
  }
});

//var api           = require('./server/api/index');
var routes        = require('./server/routes/index');
var passport      = require('./server/api/auth')(app, db);

var session = require('express-session')({secret: '78UScJ80zW7XAfxwvHzsg9KpOY', resave: false, saveUninitialized: false});

// view engine setup
app.set('views', path.join(__dirname, 'server/views'));
app.set('view engine', 'jade');

// uncomment after placing your favicon in /public
app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
app.use(logger('dev'));
app.use(express.static(path.join(__dirname, 'public'),{ maxAge: 86400000 }));
app.use(cookieParser());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(session);

app.use(passport.initialize());
app.use(passport.session());

app.use(function(req, res, next) {
  profiles = req.app.get('profiles');
  res.locals.user = profiles[req.user];
  next();
});

//api(app, db);

routes(app, db);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handlers

// development error handler
// will print stacktrace
if (app.get('env') === 'development') {
  app.use(function(err, req, res, next) {
    res.status(err.status || 500);
    res.render('error', {
      message: err.message,
      error: err
    });
  });
}

// production error handler
// no stacktraces leaked to user
app.use(function(err, req, res, next) {
  res.status(err.status || 500);
  res.render('error', {
    message: err.message,
    error: {}
  });
});


module.exports = app;
