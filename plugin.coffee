
browserify = require 'browserify'
path = require 'path'

module.exports = (wintersmith, callback) ->

  class BrowserifyPlugin extends wintersmith.ContentPlugin

    constructor: (@_filename, @_base) ->

    getFilename: ->
      @_filename

    render: (locals, contents, templates, callback) ->
      bundle = browserify
        cache: false
        watch: false

      bundle.addListener 'syntaxError', (error) ->
        callback error
        # unset callback so we don't call it twice
        callback = null

      # wrap in try catch since coffeescript parse errors will throw..
      try
        bundle.addEntry path.join(@_base, @_filename)
        callback? null, new Buffer bundle.bundle()
      catch error
        callback? error

  BrowserifyPlugin.fromFile = (filename, base, callback) ->
    callback null, new BrowserifyPlugin filename, base

  wintersmith.registerContentPlugin 'scripts', '**/*.js', BrowserifyPlugin
  callback()
