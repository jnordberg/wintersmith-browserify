
browserify = require 'browserify'

module.exports = (env, callback) ->

  class BrowserifyPlugin extends env.ContentPlugin

    constructor: (@filepath) ->

    getFilename: ->
      env.utils.stripExtension(@filepath.relative) + '.js'

    getView: ->
      return (env, locals, contents, templates, callback) ->
        options =
          cache: false
          watch: false

        for key, opt of env.config.browserify?
          options[key] = opt

        bundle = browserify options

        bundle.addListener 'syntaxError', (error) ->
          callback error
          # unset callback so we don't call it twice
          callback = null

        # wrap in try catch since coffeescript parse errors will throw..
        try
          bundle.addEntry @filepath.full
          callback? null, new Buffer bundle.bundle()
        catch error
          callback? error

  BrowserifyPlugin.fromFile = (filepath, callback) ->
    callback null, new BrowserifyPlugin filepath

  env.registerContentPlugin 'scripts', '**/*.*(js|coffee)', BrowserifyPlugin
  callback()
