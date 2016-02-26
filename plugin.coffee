### browserify plugin for wintersmith ###

browserify = require 'browserify'

readStream = (stream, callback) ->
  chunks = []
  stream.on 'error', callback
  stream.on 'data', (chunk) -> chunks.push chunk
  stream.on 'end', -> callback null, Buffer.concat chunks

module.exports = (env, callback) ->
  options = env.config.browserify or {}
  options.transforms ?= ['coffeeify']
  options.debug ?= (env.mode is 'preview')
  options.externals ?= {}
  options.requires ?= {}
  options.static ?= []
  options.ignore ?= []
  options.staticLibs ?= []
  options.staticLibsFilename ?= 'scripts/libs.js'
  options.extensions ?= ['.js', '.coffee']

  # fileGlob for matching - default to provided extensions
  exts = options.extensions
    .map (ext) -> ext[1..]
    .join '|'
  options.fileGlob ?= "**/*.*(#{ exts })"

  staticCache = {}

  # watchify speeds up builds by only rebundling files that have changed
  useWatchify = if options.watchify? then options.watchify else (env.mode is 'preview')

  if useWatchify
    watchify = require 'watchify'
    options.cache = {}
    options.packageCache = {}

  for transform, i in options.transforms
    options.transforms[i] = require transform

  staticLibs = []
  for lib in options.staticLibs
    if typeof lib is 'string'
      lib = {require: lib, expose: lib}
    unless lib.require? and lib.expose?
      throw new Error '
        Library requires should be in the format:
        {"require": "some-module", "expose": "some-name"}
      '
    staticLibs.push lib

  class BrowserifyStaticLibs extends env.ContentPlugin

    constructor: ->
      @bundler = browserify()
      for lib in staticLibs
        @bundler.require lib.require, {expose: lib.expose}
      return

    getFilename: -> options.staticLibsFilename

    getView: -> (env, locals, contents, templates, callback) ->
      if @_cache?
        callback null, @_cache
      else
        stream = @bundler.bundle()
        readStream stream, (error, result) =>
          unless error?
            @_cache = result
          callback error, result

  class BrowserifyPlugin extends env.ContentPlugin

    constructor: (@filepath) ->
      @bundler = browserify options
      if useWatchify
        @bundler = watchify @bundler

      @bundler.add @filepath.full

      @bundler.external lib.expose for lib in staticLibs

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

    getBundleView: -> (env, locals, contents, templates, callback) ->
      stream = @bundler.bundle()
      stream.on 'error', @formatParseError
      callback null, stream

    getStaticView: -> (env, locals, contents, templates, callback) ->
      if staticCache[@filepath.relative]?
        callback null, staticCache[@filepath.relative]
      else
        stream = @bundler.bundle()
        stream.on 'error', @formatParseError
        readStream stream, (error, result) =>
          unless error?
            staticCache[@filepath.relative] = result
          callback null, result

    formatParseError: (error) =>
      # add better debuginfo to parse errors
      if error.annotated?
        error.message = error.annotated

    getView: ->
      if @filepath.relative in options.static
        return @getStaticView()
      else
        return @getBundleView()

  BrowserifyPlugin.fromFile = (filepath, callback) ->
    callback null, new BrowserifyPlugin filepath

  env.registerContentPlugin 'scripts', options.fileGlob, BrowserifyPlugin

  libraryContent = new BrowserifyStaticLibs
  env.registerGenerator 'browserify', (contents, callback) ->
    callback null, {browserifyLibs: libraryContent}

  callback()
