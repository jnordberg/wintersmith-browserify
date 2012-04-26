
bar = require './foo/bar'
http = require 'http'
url = require 'url'

exports.main =  ->
  log = (message) ->
    @el ?= document.getElementById 'log'
    @el.innerHTML += "#{ message }\n"

  # log messages comming from other files
  log message for message in bar.messages

  # setup a http request using browserify's http module (which works exactly like nodes)
  request = http.get
    path: '/message.txt'
  , (response) ->
    buffer = []
    response.on 'data', (chunk) ->
      buffer.push chunk
    response.on 'end', () ->
      log buffer.join ''
