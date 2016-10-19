superagent = require "superagent"
iconv = require "iconv-lite"

logger = require "./logger.js"
db = require "./db.js"
rsa = require "../rsa/RSA.js"

RSAkey = new rsa.RSA("10001", "1560391ac82b001c5321efa005e2f6350381ac58589a65b65f41b130a4f9d1f00530a0e435966b4d552fb7141217b95b0c166b13c94579291eeffa2e2521680328924d9af73ea31158a70c9d7855d278e4cfeea047eac06a74c8f3af36eeb580ea108a0f3906ebf4afd5d7a2f6190b2d46e31ac8853b8f8897384fb5289d6d89", "89323ab0fba8422ba79b2ef4fb4948ee5158f927f63daebd35c7669fc1af6501ceed5fd13ac1d236d144d39808eb8da53aa0af26b17befd1abd6cfb1dcfba937438e4e95cd061e2ba372d422edbb72979f4ccd32f75503ad70769e299a4143a428380a2bd43c30b0c37fda51d6ee7adbfec1a9d0ad1891e1ae292d8fb992821b")

stableAuth = (data, callback) ->
  if typeof(data.secret) isnt "string"
    callback
      code: -2
      message: "Wrong format."
    return

  decrypted = rsa.decrypt(RSAkey, data.secret).split("|")
  if decrypted.length < 3
    callback
      code: -2
      message: "Wrong format."
    return

  timestamp = parseInt(decrypted[0])
  username = decrypted[1]
  password = decrypted[2]
  if isNaN(timestamp)
    callback
      code: -2
      message: "Wrong format."
    return

  if not db.applyLogin(username, timestamp)
    callback
      code: -3
      message: "Out of date."
    return

  agent = superagent.agent()
  agent
    .post("https://learn.tsinghua.edu.cn/MultiLanguage/lesson/teacher/loginteacher.jsp")
    .type("form")
    .send(
      userid: username
      userpass: password
      submit1: "登录"
    ).end((res, obj) ->
      res ||= obj.res
      if res.statusCode is 200
        if res.text.indexOf("loginteacher_action.jsp") >= 0
          rtn =
            code: 0
            message: "Success"
            data:
              type: getUsernameType username
          logger.authSuccess username, rtn

          agent.saveCookies(res)
          agent
            .get("http://learn.tsinghua.edu.cn/MultiLanguage/vspace/vspace_userinfo1.jsp")
            .end((res, obj) ->
              res ||= obj.res
              if res.statusCode is 200
                updateDataByUserinfoFromStable(rtn.data, res.text)
              else
                logger.updateUserinfoError username, res
              callback rtn
              return
            )

        else
          rtn =
            code: 1
            message: "Wrong username or password."
          logger.authFailed username, rtn
          callback rtn
          return
      else
        logger.authError username, res
        callback
          code: -1
          message: "Unknown error."
        return
    )

  updateDataByUserinfoFromStable = (data, html) ->

    exec_reg = (reg, idx) ->
      result = reg.exec(html)
      return if result and result.length > 1 then result[idx].trim() else null

    get_input = (name) ->
      # for only chinese:
      # exec_reg(new RegExp("name=#{name}[^v]*value=\"([\u4e00-\u9fa5]*)", 1)
      exec_reg(new RegExp("name=['\"]?#{name}['\"]?[^v]*value=\"([^\"]*)\""), 1)

    data["ID"] = exec_reg(/编号<\/td>[^<]*<td\s[^>]*>([^<]*)<\/td>/, 1)
    data["name"] = exec_reg(/姓名<\/td>[^<]*<td\s[^>]*>([^<]*)<\/td>/, 1)
    data["zzmm"] = exec_reg(/政治面貌<\/td>[^<]*<td\s[^>]*>(?:<input\b[^>]*>)?([^<]*)<\/td>/, 1)
    data["gender"] = get_input('gender')
    data["usertype"] = get_input('user_type')
    #data["email"] = get_input('email')
    #data["phone"] = get_input('phone')
    #data["address"] = get_input('address')
    # data["title"] = get_input('title')
    #data["zip_code"] = get_input('zip_code')
    #data["work_place"] = get_input('work_place')
    data["folk"] = get_input('folk')

safeAuth = (data, callback) ->
  superagent
    .post("http://student.tsinghua.edu.cn/checkUser.do?redirectURL=/")
    .type("form")
    .send(
      username: data.username
      password: data.password
    )
    .end((res, obj) ->
      res ||= obj.res
      if res.statusCode is 200
        rtn =
          code: 1
          message: "Wrong username or password."
        logger.authFailed data.username, rtn
        callback rtn
      else if res.statusCode is 302
        rtn =
          code: 0
          messge: "Success"
          data:
            type: getUsernameType data.username
        logger.authSuccess data.username, rtn
        callback rtn
      else
        logger.authError data.username, res
        callback
          code: -1
          message: "Unknown error."
    )

getUsernameType = (username) ->
  if /^\d{10}$/g.test(username) then "ID" else "Email"


module.exports =
  stableAuth: stableAuth
  safeAuth: safeAuth
