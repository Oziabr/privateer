request = require 'request'
http    = require 'http'
expect  = require('chai').expect
debug   = require('debug') 'test'

app     = require '../server/api/app'

port    = 9031
path    = (link) -> "http://localhost:#{port}/#{link}"
server  = false
cookie  = request.jar()

describe 'server init', ->

  before (done) ->

    app.set 'port', port
    server = http.createServer app

    server.listen port
    server.on 'listening', -> done()
    server.on 'error', (err)-> done err

  it 'should be listening', ->
    expect(port).to.equal server.address().port

  describe 'basic requests', ->

    it 'should get index page', () ->
      request (path ''), (err, response, body) ->
        expect(response.statusCode).to.equal 200

    it 'should get an error', () ->
      request (path 'PageNotFound'), (err, response) ->
        expect(response.statusCode).to.equal 404

  describe 'orm', ->

    it 'should force sync', ->
      app.get('orm').sync force: true

    it 'should populate user', ->
      app.get('orm').models.user.create
        email: "admin@admin.tld"
        password: 'adminadmin'

    it 'should populate profile', ->
      app.get('orm').models.profile.findOne where: username: "admin@admin.tld"
      .then (profile) ->
        profile.update
          first_name: 'Adminus'
          last_name: 'Superuserus'
          userpic: '01QqB6dqdAXkqc0WhS6glD'

  describe 'basic auth', ->

    it 'shout redirect to root', (done) ->
      request (path 'auth'), (err, response, body) ->
        expect(response.request.uri.path).to.equal '/'
        done()

    it 'shout get login form', (done) ->
      request (path 'auth/login'), (err, response, body) ->
        expect(response.request.uri.path).to.equal '/auth/login'
        done()

    it 'should not login', (done) ->
      request.post (path 'auth/login'), (form: username: 'admin@admin.tld', password: 'bullshit'), (err, response, body) ->
        expect(body).to.equal 'Found. Redirecting to /auth/login'
        done()

    it 'should not have profile', (done) ->
      request (path 'profile'), (err, response, body) ->
        expect(response.request.uri.path).to.equal '/'
        done()

    it 'should login', (done) ->
      request.post (path 'auth/login'), (jar: cookie, form: username: 'admin@admin.tld', password: 'adminadmin'), (err, response, body) ->
        expect(body).to.equal 'Found. Redirecting to /'
        done()

    it 'should have profile', (done) ->
      request (jar: cookie, url: path 'profile'), (err, response, body) ->
        expect(response.request.uri.path).to.equal '/profile'
        done()

    it 'should logoff', (done) ->
      request (jar: cookie, url: path 'auth/logout'), (err, response, body) ->
        expect(response.request.uri.path).to.equal '/'
        expect(body).to.match /Log In<\/a>/
        done()


  describe 'shut down server', ->
    before (done) ->
      server.close -> done()

    it 'should be off', ->
      expect(server.address()).to.equal null






