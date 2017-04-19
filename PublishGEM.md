### Publish
1. 生成 xxx-version.gem 文件`gem build xxx.gemspec`
2. 发布到rubygems.org `gem push xxx-0.0.1.gem`

### Troubleshooting
1. 删除错误的发布，记住版本号一定要加`gem yank xxx -v 0.01`

### Help
1. 查看本地安装的gem `gem list`
2. 安装gem `gem install ${gem_name}`
3. 卸载gem `gem uninstall ${gem_name}`
4. 更新所有gem `gem update`
5. 更新指定gem `gem update ${gem_name}`
6. 查看某一命令详细解释, 如查看`yank`： `gem help yank`

