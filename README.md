### 欢迎使用AuthTHU——清华大学账号认证Private API

本API为非官方提供，对于使用API可能导致的任何后果，我们一律不负责。

对此我们只能保证：不会保存任何账号信息。

在非清华校园网内，本API不定期开放。在清华校园网内，本API始终开放。

<a href="http://auth.igeek.asia" target=_blank>Demo</a>

### 使用AuthTHU进行清华大学账号认证

向以下URL发送一个POST请求：`http://auth.igeek.asia/v1`

POST请求的Content-Type为`application/x-www-form-urlencoded`，内容为：

```json
{
    "secret": "经加密的包含账号密码信息的密文"
}
```

该请求的返回数据格式为json，内容为：

```json
{
    "code": 0,
    "message": "Success",
    "data": {
        "type": "ID",
        "ID": "2011013xxx",
        "name": "陈华榕",
        "usertype": "本科生"
    }
}
```

`code`为0表示成功，否则表示错误代号。

`message`为错误提示，若成功则为`"Success"`。此外，它还可能是：`"Wrong username or password."`或`"Unknown error."`或`Wrong format.`或`Out of date.`，对应的错误代号为`1`、`-1`、`-2`、`-3`。

`data`只在成功时提供。`data.type`可能为`"ID"`或`"Email"`，前者代表认证的`username`为学号（或教师工号），后者代表认证的`username`为校园邮箱账号。`data.ID`为获取到的该用户的学号（或工号）。`data.name`为该用户的真实姓名。`data.usertype`为该用户的类型，如`本科生`、`硕士生`等。`data.type`字段只要认证成功就会提供，其他字段则有一定可能无法提供（因为认证和获取信息是独立的两个步骤，有可能认证成功了但获取信息失败）。

#### 加密传输
使用RSA加密传输，公钥为：

```json
{
	"e": "0x10001",
	"n": "0x89323ab0fba8422ba79b2ef4fb4948ee5158f927f63daebd35c7669fc1af6501ceed5fd13ac1d236d144d39808eb8da53aa0af26b17befd1abd6cfb1dcfba937438e4e95cd061e2ba372d422edbb72979f4ccd32f75503ad70769e299a4143a428380a2bd43c30b0c37fda51d6ee7adbfec1a9d0ad1891e1ae292d8fb992821b"}
```

被加密的字符串格式为`时间戳|用户名|密码`，即将时间戳、用户名与密码用竖线（`|`）分隔形成的字符串。将该字符串使用上述公钥加密后就是POST请求的`secret`密文。

<a href="http://auth.igeek.asia/js/RSA.js" target=_blank>点此下载实现RSA的js文件</a>

通过以上链接下载的js文件，在前端引入后即可在前端进行加密，关键代码为：

```javascript
var key = new RSAKeyPair("10001", "", "89323ab0fba8422ba79b2ef4fb4948ee5158f927f63daebd35c7669fc1af6501ceed5fd13ac1d236d144d39808eb8da53aa0af26b17befd1abd6cfb1dcfba937438e4e95cd061e2ba372d422edbb72979f4ccd32f75503ad70769e299a4143a428380a2bd43c30b0c37fda51d6ee7adbfec1a9d0ad1891e1ae292d8fb992821b");
var encrypted = {
	secret: encryptedString(key, timestamp + "|" + username + "|" + password)
};
```

时间戳可以由你的服务器给出，也可GET`http://auth.igeek.asia/v1/time`得到认证服务器的时间戳。

请注意不要使用用户浏览器的时间戳，因为不能保证用户设备的时间是正确的。

若出现`Out of date.`错误，说明使用了过时的时间戳进行验证，应更新时间戳后重试。

### 注意事项
任何接入本Private API的应用，都有保护用户数据安全的义务！
