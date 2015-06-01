#Troubleshooting for CrashMonkey4IOS

CrashMonkey4IOS 安装环节中的问题总结和处理。

CrashMonkey4IOS 开发环境：OS X Yosemtie 10.10.x

**特殊强调：**写这个文档的目的是让大家顺利正确的安装CrashMonkey4IOS工具，建议大家根据reset.sh中的命令一步一步的进行工具安装和环境配置，那一步遇到问题都能即使的看见日志反馈的结果，我们开发reset.sh时也是出于提供一个简单便捷的一键安装操作，但现在看来各位的实际环境各有差异，后期也会进一步的优化 reset.sh 。

注意事项如下:

1.运行日志中包含: `warning: Insecure world writable dir /some/path in PATH, mode 040777`, 但不影响执行, **解决方案:**`chmod go-w /some/path`

2.不要使用sudo执行执行 sh reset.sh(具体原因参看下文)

3.确保被测app被移至后台后进程不会被强制杀死。


####安装过程使用reset.sh时(推荐执行前手动更新本地的ruby和homebrew版本)
***问题1: gem install erubis 需要用户本地的管理员权限***

如果没有安装成功这个erubis模块的话会在/CrashMonkey4IOS/bin下运行 ./smart_monkey 后ruby报错 erubis的错误：

日志截图:

a.直接运行 sh reset.sh(很容易被忽略)

<img alt="summary" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/img/geminstallerror.png">

b.如果没有安装成功这个erubis模块的话会在/CrashMonkey4IOS/bin下运行 ./smart_monkey 后ruby报错 erubis的错误：

<img alt="summary" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/img/erubisCannotFound.png">

解决方案: sudo gem install erubis

***问题2: brew update 如果本地的homebrew版本已经更新过可以直接忽略该问题***

当前的homebrew与OS X版本需要相互兼容，多数用户不会在OS X升级后也随之更新(需要手动更新)

解决方案:先执行 brew upgrade 后再 brew update


日志截图:

<img alt="summary" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/img/brewupdatesuccess.png">

***问题3: brew install libimobiledevice 需要用户本地的管理员权限***

日志截图:

<img alt="summary" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/img/sudobrewinstallerror.png">

解决方案:sudo chown -R $USER /usr/local 提取用户权限，而不要直接 sudo brew install libimobiledevice 这样会出现以上错误


***问题4: 出现脚本无法运行在iphone设备上运行***

日志截图:

<img alt="summary" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/img/enableUIAutomation.png">

解决方案:	该问题属于iphone设置问题，首先查看设置中“开发者”中启用“EnableUIAutomation”选项，如果没有“开发者”需要连接iphone和OS X 使用xcode进行设备识别。
