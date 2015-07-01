
browserify = require 'browserify'

module.exports = (env, callback) ->
  options = env.config.browserify or {}
  options.transforms ?= ['coffeeify']
  options.debug ?= (env.mode is 'preview')
  options.externals ?= {}
  options.requires ?= {}
  options.ignore ?= []
  options.extensions ?= ['.js', '.coffee']

  # watchify speeds up builds by only rebundling files that have changed
  useWatchify = if options.watchify? then options.watchify else (env.mode is 'preview')

  if useWatchify
    watchify = require 'watchify'
    options.cache = {}
    options.packageCache = {}

  for transform, i in options.transforms
    options.transforms[i] = require transform

  class BrowserifyPlugin extends env.ContentPlugin

    constructor: (@filepath) ->
      @bundler = browserify options
      if useWatchify
        @bundler = watchify @bundler

      @bundler.add @filepath.full

      for item in options.externals[@filepath.relative] or []
        @bundler.external item

      for item in options.requires[@filepath.relative] or []
        name = item.name ? item.require ? item
        opts = {}
        opts.expose = item.expose if item.expose?
        @bundler.require name, opts

      @bundler.ignore file for file in options.ignore
      @bundler.transform transform for transform in options.transforms

    @property 'source', ->
      require('fs').readFileSync(@filepath.full).toString()

    getFilename: ->
      env.utils.stripExtension(@filepath.relative) + '.js'

    getView: -> (env, locals, contents, templates, callback) ->
      stream = @bundler.bundle()
      stream.on 'error', (error) =>
        # add better debuginfo to parse errors
        msg = ''
        if error.file?
          msg += env.relativeContentsPath error.file
        else
          msg += @filepath.relative
        msg += ':'
        if error.location?.first_line?
          msg += "#{ error.location.first_line }"
        msg += " #{ error.message }"
        if error.body? and error.location?.first_line? and error.location?.first_column?
          line = error.body.split('\n')[error.location.first_line]
          pad = (' ' for i in [0...error.location.first_column]).join('')
          msg += "\n\n  #{ line }\n  #{ pad }^\n"
        error.message = msg
      callback null, stream

  BrowserifyPlugin.fromFile = (filepath, callback) ->
    callback null, new BrowserifyPlugin filepath

  exts = options.extensions
    .map (ext) -> ext[1..]
    .join '|'

  env.registerContentPlugin 'scripts', "**/*.*(#{ exts })", BrowserifyPlugin
  callback()
