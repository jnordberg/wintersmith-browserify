
browserify = require 'browserify'

module.exports = (env, callback) ->
  options = env.config.browserify or {}
  options.transforms ?= ['caching-coffeeify']
  options.debug ?= (env.mode is 'preview')
  options.externals ?= {}
  options.ignore ?= []

  for transform, i in options.transforms
    options.transforms[i] = require transform

  class BrowserifyPlugin extends env.ContentPlugin

    constructor: (@filepath) ->
      @bundler = browserify()
      @bundler.add @filepath.full
      externals = options.externals[@filepath.relative] or []
      @bundler.external file for file in externals
      @bundler.ignore file for file in options.ignore
      @bundler.transform transform for transform in options.transforms

    @property 'source', ->
      require('fs').readFileSync(@filepath.full).toString()

    getFilename: ->
      env.utils.stripExtension(@filepath.relative) + '.js'

    getView: -> (env, locals, contents, templates, callback) ->
      stream = @bundler.bundle options
      callback null, stream

  BrowserifyPlugin.fromFile = (filepath, callback) ->
    callback null, new BrowserifyPlugin filepath

  env.registerContentPlugin 'scripts', '**/*.*(js|coffee)', BrowserifyPlugin
  callback()
