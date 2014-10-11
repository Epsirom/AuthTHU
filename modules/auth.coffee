superagent = require "superagent"
iconv = require "iconv-lite"

logger = require "./logger.js"

stableAuth = (data, callback) ->
  agent = superagent.agent()
  agent
    .post("https://learn.tsinghua.edu.cn/MultiLanguage/lesson/teacher/loginteacher.jsp")
    .type("form")
    .send(
      userid: data.username
      userpass: data.password
      submit1: "登录"
    ).end((res) ->
      if res.statusCode is 200
        if res.text.indexOf("loginteacher_action.jsp") >= 0
          rtn =
            code: 0
            message: "Success"
            data:
              type: getUsernameType data.username
          logger.authSuccess data.username, rtn

          agent.saveCookies(res)
          agent
            .get("http://learn.tsinghua.edu.cn/MultiLanguage/vspace/vspace_userinfo1.jsp")
            .end((res) ->
              if res.statusCode is 200
                updateDataByUserinfoFromStable(rtn.data, res.text)
              else
                logger.updateUserinfoError data.username, res
              callback rtn
            )

        else
          rtn =
            code: 1
            message: "Wrong username or password."
          logger.authFailed data.username, rtn
          callback rtn
      else
        logger.authError data.username, res
        callback
          code: -1
          message: "Unknown error."
    )
  updateDataByUserinfoFromStable = (data, html) ->
    data["ID"] = /编号<\/td>\s*<td\s[^>]*>([^<]*)<\/td>/.exec(html)[1]
    data["name"] = /姓名<\/td>\s*<td\s[^>]*>([^<]*)<\/td>/.exec(html)[1]
    data["usertype"] = /name=user_type\s*value="([\u4e00-\u9fa5]*)">/.exec(html)[1]

safeAuth = (data, callback) ->
  superagent
    .post("http://student.tsinghua.edu.cn/checkUser.do?redirectURL=/")
    .type("form")
    .send(
      username: data.username
      password: data.password
    )
    .end((res) ->
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
  if /^20\d{8}$/g.test(username) then "ID" else "Email"


module.exports =
  stableAuth: stableAuth
  safeAuth: safeAuth
