#Troubleshooting for CrashMonkey4IOS

CrashMonkey4IOS 安装环节中的问题总结和处理。

CrashMonkey4IOS 开发环境：OS X Yosemtie 10.10.x

注意:

1.运行日志中包含: `warning: Insecure world writable dir /some/path in PATH, mode 040777`, 但不影响执行, **解决方案:**`chmod go-w /some/path`

2.不要使用sudo执行执行 sh reset.sh(具体原因参看下文)

3.确保被测app被移至后台后进程不会被强制杀死。

####安装过程使用reset.sh时(推荐执行前手动更新本地的ruby和homebrew版本)
***问题1: gem install erubis 需要用户本地的管理员权限***

日志截图:

<img alt="summary" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/pic/geminstallerror.png">

解决方案: sudo gem install erubis

***问题2: brew update 如果本地的homebrew版本已经更新过可以直接忽略该问题***

当前的homebrew与OS X版本需要相互兼容，多数用户不会在OS X升级后也随之更新(需要手动更新)

解决方案:先执行 brew upgrade 后再 brew update


日志截图:

<img alt="summary" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/pic/brewupdatesuccess.png">

***问题3: brew install libimobiledevice 需要用户本地的管理员权限***

日志截图:

<img alt="summary" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/pic/sudobrewinstallerror.png">

解决方案:sudo chown -R $USER /usr/local 提取用户权限，而不要直接 sudo brew install libimobiledevice 这样会出现以上错误


####CrashMonkey4IOS运行时(后续待优化)
***问题1: 出现脚本无法运行在iphone设备上运行***

日志截图:

<img alt="summary" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/pic/enableUIAutomation.png">

解决方案:	该问题属于iphone设置问题，首先查看设置中“开发者”中启用“EnableUIAutomation”选项，如果没有“开发者”需要连接iphone和OS X 使用xcode进行设备识别。

***问题2: 有时会出现点击的坐标区域超出范围***

问题原因: 通过下图日志中的信息__target.setDeviceOrientation("4")__

日志截图:

<img alt="summary" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/pic/runsetorientation.png">

解决方案: 该问题属于monkey执行中对于特殊事件流（旋屏）引发的场景变化处理，下一版本中处理
