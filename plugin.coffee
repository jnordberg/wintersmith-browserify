### browserify plugin for wintersmith ###

browserify = require 'browserify'

readStream = (stream, callback) ->
  chunks = []
  stream.on 'error', callback
  stream.on 'data', (chunk) -> chunks.push chunk
  stream.on 'end', -> callback null, Buffer.concat chunks

resolveOption = (option) ->
  ### Resolve transform or plugin module option. Allows either a string for the
      module name or an array where the first item is the module name and the
      second is the options. E.g. `['coffeeify', {header: true}]` ###
  if Array.isArray option
    return {module: require(option[0]), options: option[1]}
  else if typeof option is 'string'
    return {module: require option}
  else
    throw new Error "Invalid option: #{ option }"

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
  options.staticLibsBundle ?= false
  options.extensions ?= ['.js', '.coffee']
  options.plugins ?= []

  # fileGlob for matching - default to provided extensions
  exts = options.extensions
    .map (ext) -> ext[1..]
    .join '|'
  options.fileGlob ?= "**/*.*(#{ exts })"

  staticCache = {}

  # watchify speeds up builds by only rebundling files that have changed
  useWatchify = if options.watchify? then options.watchify else (env.mode is 'preview')

  # whether to include static libs in the main bundle when building
  bundleStaticLibs = options.staticLibsBundle is true and env.mode isnt 'preview'

  if useWatchify
    watchify = require 'watchify'
    options.cache = {}
    options.packageCache = {}

  for transform, i in options.transforms
    options.transforms[i] = resolveOption transform

  for plugin, i in options.plugins
    options.plugins[i] = resolveOption plugin

  staticLibs = []
  unless bundleStaticLibs
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
      if staticLibs.length is 0
        callback null, null
        return
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
      @bundler.plugin p.module, p.options for p in options.plugins
      @bundler.transform t.module, t.options for t in options.transforms

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

  if staticLibs.length > 0
    libraryContent = new BrowserifyStaticLibs
    env.registerGenerator 'browserify', (contents, callback) ->
      callback null, {browserifyLibs: libraryContent}
    env.locals.browserifyLibs = """<script src="#{ options.staticLibsFilename }"></script>"""

  callback()
