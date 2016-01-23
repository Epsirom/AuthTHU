http = require "http"
url = require "url"
querystring = require "querystring"
port = require("../package.json").port

logger = require "./logger.js"
auth = require "./auth.js"

httpEntry = (req, res) ->
  try
    req_url = url.parse req.url
    pathname = req_url.pathname
    if pathname == "/v1/time" and req.method is "GET"
      logger.requestReceived req, true
      res.writeHead 200
      res.write(new Date().getTime().toString())
      res.end()
      return
    auth_method = if pathname in ["/v1"] then auth.stableAuth #else if pathname in ["/safe"] then auth.safeAuth
    if not auth_method or req.method isnt "POST"
      logger.requestReceived req, false
      res.writeHead 404
      res.write "404"
      res.end()
      return

    logger.requestReceived req, true
    body = ""
    req.setEncoding "utf8"
    req.addListener "data", (chunk) ->
      body += chunk
    req.addListener "end", () ->
      res.writeHead 200, "Content-Type": "application/json"
      data = querystring.parse body
      auth_method(data, (result) ->
        res.write JSON.stringify(result)
        res.end()
      )

  catch err
    logger.log_http err

http.createServer(httpEntry).listen port, "localhost"
