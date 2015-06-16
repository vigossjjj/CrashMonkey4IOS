# CrashMonkey4IOS
iOS Monkey Test Tool.

###简要说明:
1. 支持**真机测试、模拟器测试**
2. 支持收集**系统日志(Systemlog)**、**崩溃日志(Crashlog)**、***instrument行为日志***
3. 支持测试报告截图，绘制行为轨迹
4. 支持测试设备信息收集
5. 使用最新版的[UIAutoMonkey][uiatmonkey]，加入`UI Holes`与`Application Not Repsonding ("ANR")`的处理，添加[custom.js][custom]作为入口脚本.
6. 加入[tuneup][tp]依赖
7. 修改**UIAutoMonkey.js**中截图策略，为每个Event Action进行截图
8. 支持测试执行过程中App进入后台，自动恢复(测试不会block)
  [lidvc]:https://github.com/libimobiledevice/libimobiledevice
  [dc]:https://github.com/rpetrich/deviceconsole
  [uiatmonkey]: https://github.com/jonathanpenn/ui-auto-monkey/blob/master/UIAutoMonkey.js
  [custom]:https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/lib/ui-auto-monkey/custom.js
  [tp]:https://github.com/vigossjjj/CrashMonkey4IOS/tree/master/lib/ui-auto-monkey/tuneup
  [troubleshooting]:https://github.com/vigossjjj/CrashMonkey4IOS/tree/master/Troubleshooting.md

###系统及环境要求:
1. 安装Ruby运行环境，建议不要使用OS X自带版本，可自行使用RVM安装最新版的Ruby。建议使用淘宝镜像安装，速度比较快，`$ sed -i -e 's/ftp\.ruby-lang\.org\/pub\/ruby/ruby\.taobao\.org\/mirrors\/ruby/g' ~/.rvm/config/db`
2. 确保gem可用，也建议使用淘宝镜像 `gem sources --remove https://rubygems.org/;gem sources -a http://ruby.taobao.org/;gem sources -l`
3. 安装**Homebrew** `ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
4. 建议Xcode 6.x +

###必要依赖安装:
1. `brew install -HEAD ideviceinstaller`
2. `brew install libimobiledevice`
3. `brew install imagemagick`

###使用说明:
###### 安装Release版
`gem install smart_monkey`, 执行入口: 终端下直接使用`smart_monkey`
###### 安装开发版
直接clone本项目, 执行入口: `/CrashMonkey4IOS/bin/smart_monkey`

###### 执行命令
`smart_monkey -a ${App_BunnelID} -w ${iPhone_UDID}`

###参数说明:

* **`-a`**: 指向被测程序的**BundleID**(不可缺省)。e.g.`-a com.mytest.app`
* **`-w`**: 指向测试设备的**UDID**，可以通过`$instruments -s devices`进行设备id的查看，若缺省则默认指向第一台设备(模拟器或真机)。e.g.`-w 26701a3a5bc17038ca0465186407b912375b35a7`
* **`-n`**: monkey测试的执行次数，默认为1次。e.g.`-n 3`
* **`-d`**: 测试报告地址，默认为当前目录下的**smart_monkey_result**文件夹下。e.g.`-d ~/my-monkey-test-result`
* **`-t`**: 执行时间，单位为秒。e.g.`-t 60`
* **`-s`**: 指向被测app的**.dSYM**文件，若出现crash，解析crash为明文。e.g.`-s testapp.dSYM`
* **`-c`**: 自定义的配置集路径，**参数必须为目录**，目录下必须包含`custom.js`，若使用handler，目录下需存在名为**handler**的文件夹，用于存放相关文件。e.g.`-c /my/path/custom_cfg`

	**如果使用custom_cfg必须遵守如下目录结构**：

	```
	custom_cfg
    	├── custom.js
    	└── handler
        	├── buttonHandler.js
        	└── wbScrollViewButtonHandler.js
	```
* **`--event-number`**: 定义Monkey测试的总事件数，默认为50。e.g.`--event-number 100`
* **`--compress-result`**: 对测试过程中截取的图片进行压缩，以节省空间开销。e.g.`--compress-result 50%`
* **`--detail-count`**: 定义报告详情中记录的事件总数，默认为50，即在报告当中展示最近的50次随机事件，且进行操作示意绘制。e.g.`--detail-count 100`
* **`--show-config`**: 打印当前的配置信息，即**custom.js**。e.g.`--show-config`
* **`--drop-useless-img`**: 删除除展示在报告当中的其余截图，以节省空间开销，如，一轮Monkey测试共产出截图100张，参数`--detail-count`设置为20，那么使用`--drop-useless-img`会删除其余80张截图。e.g.`--drop-useless-img`
* **`--list-app`**: 打印当前连接的真机及模拟器中所安装的app。e.g.`--list-app`
* **`--list-devices`**: 打印当前所有可用设备。e.g.`--list-devices`
* **`--reset-ios-sim`**: 重启模拟器。e.g.`--reset-ios-sim`
* **`--version`**: 打印smart_monkey的版本号。e.g.`--version`

```
⇒  CrashMonkey4IOS/bin/smart_monkey -h
Usage: smart_monkey [options]
    -a app_name                      Bundle ID of the desired target on device(Required)
    -w device                        Target Device UDID(Required)
    -n run_count                     How many times monkeys run(default: 1)
    -d result_dir                    Where to output result(default: ./smart_monkey_result)
    -t time_limit_sec                Time limit of running
    -s dsym_file                     Use .dSYM file to symbolicating crash logs
    -c custom_cfg_path               Indicate confige lib directory path, not a file path.
        --event-number event_number  The monkey event number(default: 50)
        --compress-result compress_rate
                                     compress the screenshot images to save disk space!(example: 50%)
        --detail-count detail_event_count
                                     How many events to show in detail result page(default 50)
        --show-config                Show Current Configuration custom.js
        --drop-useless-img           Delete the un-displayed images of detial page.
        --list-app                   Show List of Installed Apps in iPhone/iPhone Simulator
        --list-devices               Show List of Devices
        --reset-ios-sim              Reset iPhone Simulator
        --version                    print smart monkey version
```

###Troubleshooting:
安装和执行测试遇到的问题解决方案请参看:[Troubleshooting.md][troubleshooting]

###测试报告:
***Summary:***
<img alt="summary" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/img/summary.jpg">
***Detail:***
<img alt="detail" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/img/detail.jpg">
***SystemLog:***
<img alt="systemlog" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/img/systemlog.jpg">
***CrashLog:***
<img alt="crashlog" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/img/crashlog.jpg">
***uiautotrace:***
<img alt="uiautotrace" src="https://github.com/vigossjjj/CrashMonkey4IOS/blob/master/img/uiauto_trace.jpg">

###参考文献：
1. https://github.com/mokemokechicken/CrashMonkey
2. https://github.com/jonathanpenn/ui-auto-monkey
