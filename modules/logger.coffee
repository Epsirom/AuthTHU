
formatDate = (t) ->
  y = t.getFullYear()
  o = t.getMonth() - 1
  d = t.getDate()
  h = t.getHours()
  m = t.getMinutes()
  s = t.getSeconds()
  ms = t.getMilliseconds()
  o = if o < 10 then "0#{o}" else o
  h = if h < 10 then "0#{h}" else h
  m = if m < 10 then "0#{m}" else m
  s = if s < 10 then "0#{s}" else s
  ms = if ms < 10 then "00#{ms}" else if ms < 100 then "0#{ms}" else ms
  "#{y}/#{o}/#{d} #{h}:#{m}:#{s}.#{ms}"

logger =
  header: (owner) ->
    console.log "\n[#{formatDate new Date()}]#{if owner then "[#{owner}]" else ""}"
  content: (args) ->
    console.log.apply console.log, args

log = () ->
  logger.header null
  logger.content arguments

log_http = () ->
  logger.header "HTTP"
  logger.content arguments

log_auth = () ->
  logger.header "Auth"
  logger.content arguments

log_guard = () ->
  logger.header "Guard"
  logger.content arguments

module.exports =
  log: log
  log_http: log_http
  log_guard: log_guard

  guardStart: () ->
    log_guard "Guard start."

  guardReady: () ->
    log_guard "Child is running"

  guardError: (data) ->
    log_guard "[CHILD ERROR]#{data.toString()}"

  guardRestart: (code) ->
    log_guard "[EXIT]Child process exited with code #{code}, guard is restarting."


  requestReceived: (req, isAccepted) ->
    req_from = inst for inst in [
      req.headers["x-real_ip"]
      req.headers['x-forwarded-for']
      req.connection.remoteAddress if req.connection?
      req.socket.remoteAddress if req.socket?
      req.connection.socket.remoteAddress if req.connection? and req.connection.socket?
    ] when inst?
    log_http "From: #{req_from}\nUrl: #{req.url}\nMethod: #{req.method}\nAccept: #{isAccepted}"


  authFailed: (username, rtn) ->
    log_auth "Auth failed: #{username}\nError ##{rtn.code}: #{rtn.message}"

  authSuccess: (username, rtn) ->
    log_auth "Auth by #{rtn.data.type} success: #{username}"

  authError: (username, res) ->
    log_auth "Error occured when auth: #{username}", res

  updateUserinfoError: (username, res) ->
    log_auth "Warning: can not update info of user: #{username}", res
