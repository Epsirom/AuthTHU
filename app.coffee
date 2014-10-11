logger = require "./modules/logger.js"

logger.guardStart()

start = () ->
  ls = require("child_process").spawn "node", ["modules/http.js"]
  ls.stdout.pipe process.stdout

  ls.stderr.on "data", (data) ->
    logger.guardError data

  ls.on "exit", (code) ->
    logger.guardRestart code
    setTimeout start, 2000

  logger.guardReady()

start()