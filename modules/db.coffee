user_last_login = {}

module.exports =
  applyLogin: (username, timestamp) ->
    current_timestamp = new Date().getTime()
    if not user_last_login[username]
      user_last_login[username] = timestamp
      return true
    else if user_last_login[username] >= timestamp
      return false
    else if timestamp < current_timestamp
      user_last_login[username] = timestamp
      return true
    else
      return false
