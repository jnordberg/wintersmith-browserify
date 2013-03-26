browserify = require 'browserify'
path       = require 'path'
coffeeify  = require 'coffeeify'

# -----

stripExtension = (filename) ->
  filename.replace /(.+)\.[^.]+$/, '$1'

# -----

module.exports = (wintersmith, callback) ->
  class BrowserifyPlugin extends wintersmith.ContentPlugin
    constructor: (@_filename, @_base) ->

    getFilename: ->
      "#{ stripExtension @_filename }.js"

    render: (locals, contents, templates, callback) ->
      # Set up browserify/transform stream
      brows = browserify path.join(@_base, @_filename)
      brows.transform coffeeify

      s = brows.bundle()

      # Set up buffer
      dbuf = []
      dbuf_fin =->
        callback null, new Buffer (dbuf.join "")

      # Catch events
      s.on 'data', (d)->
          dbuf.push d

      s.on 'error', (er) ->
          callback er

      s.on 'end',   dbuf_fin
      s.on 'close', dbuf_fin

  BrowserifyPlugin.fromFile = (filename, base, callback) ->
    callback null, new BrowserifyPlugin filename, base

  wintersmith.registerContentPlugin 'scripts', '**/*.*(js|coffee)', BrowserifyPlugin
  callback()
