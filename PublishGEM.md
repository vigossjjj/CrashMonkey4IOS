### 1.生成 xxx-version.gem 文件
`gem build xxx.gemspec`
### 2.发布到rubygems.org 
`gem push xxx-0.0.1.gem`
### 3.删除错误的发布，记住版本号一定要加
`gem yank xxx -v 0.01`
