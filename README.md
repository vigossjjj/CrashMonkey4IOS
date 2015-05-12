# CrashMonkey4IOS
iOS Monkey Test Tool.

本项目主要是基于以下项目修改：

https://github.com/mokemokechicken/CrashMonkey

https://github.com/jonathanpenn/ui-auto-monkey

###改进点:
1. 原先的CrashMonkey只支持iPhone Simulator测试，修改后**支持真机测试**(目前模拟器的兼容没有做)
2. 支持真机收集**系统日志(Systemlog)**，利用[deviceconsole][dc]实现
3. 支持真机收集**崩溃日志(Crashlog)**，利用[libimobiledevice][lidvc]的**idevicecrashreport**实现
4. 解决在iPhone5及以上分辨率的设备上测试报告截图手势坐标绘制错误的问题
5. 解决判定crash出现失败的情况。
6. 测试报告中添加设备信息及应用信息(Summary下)
7. 使用最新版的[UIAutoMonkey][uiatmonkey]，加入`UI Holes`与`Application Not Repsonding ("ANR")`的处理，添加[custom.js][custom]作为入口脚本.
8. 加入[tuneup][tp]依赖
9. 修改**UIAutoMonkey.js**中截图策略，为每个Event Action进行截图
10. 修改**CrashMonkey**中测试报告显示截图策略，增加至最近的50张
11. 解决大家一直所诟病的iOS App执行Monkey测试过程当中跳出程序后，导致脚本block，App无法自动返回的问题，解决方案：利用一个线程去监听instruments执行过程当中的日志，每隔20s进行前后比对，如果日志没有更新则说明App hanged，利用**idevicedebug**恢复App至前台。
  [lidvc]:https://github.com/libimobiledevice/libimobiledevice
  [dc]:https://github.com/rpetrich/deviceconsole
  [uiatmonkey]: https://github.com/jonathanpenn/ui-auto-monkey/blob/master/UIAutoMonkey.js
  [custom]:https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/lib/ui-auto-monkey/custom.js
  [tp]:https://github.com/vigossjjj/CrashMonkey4IOS/tree/master/lib/ui-auto-monkey/tuneup

###依赖及安装:
1. 安装Ruby运行环境，建议不要使用OS X自带版本，可自行使用RVM安装最新版的Ruby。建议使用淘宝镜像安装，速度比较快，`$ sed -i -e 's/ftp\.ruby-lang\.org\/pub\/ruby/ruby\.taobao\.org\/mirrors\/ruby/g' ~/.rvm/config/db`
2. 确保gem可用，也建议使用淘宝镜像 `gem sources --remove https://rubygems.org/;gem sources -a http://ruby.taobao.org/;gem sources -l`
3. 安装**Homebrew** `ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`

###使用说明:
1. 运行`sh reset.sh`安装相关依赖
2. 执行前需要先配置[custom.js][custom]相关参数
3. 执行命令`/CrashMonkey4IOS/bin/crash_monkey -a ${App_BunnelID} -w ${iPhone_UDID} -n 1`

###参数变更:
1. -a 填写应用的BundleID
2. -w 填写iPhone的UDID
修改后的CrashMonkey较之前并无太大差异
```
Usage: crash_monkey [options]
    -a app_name                      Target Application, abs path to simulator-compiled .app file or the bundle_id of the desired target on device(Required)
    -w device                        Target Device UDID(Required)
    -n run_count                     How many times monkeys run(default: 2)
    -d result_dir                    Where to output result(default: ./crash_monkey_result)
    -t time_limit_sec                Time limit of running(default: 100 sec)
    -s dsym_file                     Use .dSYM file to symbolicating crash logs
    -c config_path                   Configuration JSON Path
    -e extend_javascript_path        Extend Uiautomation Javascript for such Login scripts
        --show-config                Show Current Configuration JSON
        --list-app                   Show List of Installed Apps in iOS Simulator
        --list-devices               Show List of Devices
        --reset-iPhone-Simulator     Reset iPhone Simulator
        --version                    print crash monkey version                  print crash monkey version
```

###TODO List:
1. 适配iPhone Simulator
2. 添加symbolicatecrash解析crash为明文。

###Troubleshooting:
1.运行日志中包含: `warning: Insecure world writable dir /some/path in PATH, mode 040777`, 但不影响执行, **解决方案:**`chmod go-w /some/path`

###测试报告:
***Summary:***
<img alt="summary" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/pic/summary.jpg">
***Detail:***
<img alt="detail" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/pic/detail.jpg">
***SystemLog:***
<img alt="detail" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/pic/systemlog.jpg">
***CrashLog:***
<img alt="detail" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/pic/crashlog.jpg">
