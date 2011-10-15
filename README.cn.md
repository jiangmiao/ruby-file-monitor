Ruby File Monitor
=================

Ruby File Monitor是一个非常容易使用的一个用于监控目录或文件变化, 并执行指定指令的库. 可用于浏览器自动刷新，单元测试自动执行，自动编译CoffeeScript, Haml等场, 由于Ruby File Monitor基于[rb-inotify](https://github.com/nex3/rb-inotify), 因此它仅工作于支持inotify的系统，比如Linux.

需求
----

Ruby >= 1.8.7

Linux Kernel >= 2.6.13

特性
----

1. 自动递归监测
    
    如果在被监测目录中新建目录, 那么新目录会自动被监测.

2. 支持忽略指定目录: 

    任何匹配ignored_dirs的目录都将不被监测

3. 支持忽略指定文件:

    任何匹配ignored_firs的文件都将不被记录

4. 事件缓冲机制:

    为避免执行指令太频繁, 比如当同时删除20个文件, 如果没有缓冲机制将执行指定指令20次, 引入缓冲机制后, 每隔frequency时间, 缺省为0.2秒, 执行一次指令.

5. 高性能

    由于使用了inotify机制, 所以在监控数百上千目录时, 仍可以高效快速的运行.


安装
----

从源码安装
    
    git clone https://github.com/jiangmiao/ruby-file-monitor
    cd ruby-file-monitor
    gem build file-monitor.gemspec
    gem install file-monitor-0.1.0.gem --user-install

从gem server 安装

    gem install file-monitor

使用
----
### 使用block

    #!/usr/bin/env ruby
    # coding: utf-8
    # File: examples/use-block.rb

    require 'file-monitor'

    dir = ARGV[0] || '.'
    m = FileMonitor.new(dir)

    # 忽略目录名中包含 .git 或 .svn 的目录
    m.ignored_dirs = /\.git|\.svn/

    # 忽略文件名中包含 .swp 或 ~ 的文件
    m.ignored_files = /\.swp|~/

    # events包含最后小于0.2秒内发生的所有事件
    m.run do|events|
      puts "#{events.size} events"
      puts "do something"
    end

### 使用继承

    #!/usr/bin/env ruby
    # coding: utf-8
    # File: examples/use-inherit.rb

    require 'file-monitor'

    class MyFileMonitor < FileMonitor
      def check(events)
        puts "#{events.size} events"
        puts "do something"
      end
    end

    dir = ARGV[0] || '.'
    m = MyFileMonitor.new(dir)
    m.ignored_dirs = /\.git|\.svn/
    m.ignored_files = /\.swp|~/
    m.run

如果block存在, 那么check方法将会被忽略

例子
----
### 自动刷新浏览器 Auto F5

Auto F5 会自动刷新浏览器中网页, 如果所监控的文件发生变化.

f5.rb 需要额外的 sinatra 库

#### 限制:

    1. 被监测的文件必须包含 </body> 标签. 
       f5.rb 会在 </body> 前插入一小段脚本用于当文件物理变化后刷新页面.

    2. 只支持 GET 请求

#### 使用:

    假设存在以下环境
    网站的物理路径为 /var/www/foo
    主机为 www.foo.com
    首页为 www.foo.com/index.html

    开始监控网站
    ruby examples/f5.rb /var/www/foo

    在浏览器中打开 www.foo.com:4567/index.html 
    可以看到与 www.foo.com/index.html 一致的页面
    改变 /var/www/foo/index.html 并保存
    或者在 /var/www/foo 新建或修改文件
    www.foo.com/index.html 将自动刷新.

### examples/use-block.rb

    $ ruby examples/use-block.rb 
    watching .
    watching ./lib/
    ignore ./.git/
    watching ./examples/

编辑 README.md 并保存, examples/use-block 输出

    +  ./4913
    -  ./4913
    -  ./README.md
    +  ./README.md
    #  ./README.md
    5 events
    do something
