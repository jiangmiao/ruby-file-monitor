Ruby File Monitor
=================

Ruby File Monitor is a easy way to watch the directories and files, do anything when them changed. Use for situation like Auto refresh webpage, Auto execute unit tests, Auto compile CoffeeScript, Haml and so on. It's base on [rb-inotify](https://github.com/nex3/rb-inotify), So it only works in inotify supported system such as Linux.

Requirements
------------

Ruby >= 1.8.7

Linux Kernel >= 2.6.13

Features
--------

1. Auto watching recursively:

    If make a new directory in the watched directory, the new directory will be watched automatically.

2. Support Filter:

    Support filter directories or files.
 
3. Events Buffer Mechanism:

    To avoid run the check methods too quickly, for example, when delete 20 files at the same time, if without Events Buffer will run the check methods 20 times. the frequency of file-monitor is 0.2 second

4. High Performance

    For Ruby File Monitor use inotify library, so it's very fast, even watching thousands of directories.

Installation
------------
Install from source
    
    git clone https://github.com/jiangmiao/ruby-file-monitor
    cd ruby-file-monitor
    gem build file-monitor.gemspec
    gem install file-monitor-0.1.0.gem --user-install

Install from gem server

    gem install file-monitor

Usage
-----

    require 'rubygems'

    # watch current working directory
    FileMonitor.watch '.' do

      # do not watch directory end with git or svn
      # the last charactor '/' has been trimmed already
      dirs {
        disallow /git$|svn$/
      }

      # record ruby files only
      # it equals files /\.rb$/
      files {
        disallow //
        allow /\.rb$/
      }

      # The commands will be runned when file changed
      # the events contains all file modified infomation in last 0.2 second
      exec {|events|
        puts events.size()
        puts "do something"
      }

    end

Examples
--------
### Auto F5

Auto F5 will auto refresh the webpage in browser when any watched files changed. It's simple but very useful.

f5.rb requires sinatra.

#### Limitation:

    1. The watched page MUST have </body> tag. 
       f5.rb will insert script  before </body> to refresh the page 
       when physical file changed.

    2. Only support GET requests.

#### Usage

    Environment:
    the website physical path is /var/www/foo
    the host is www.foo.com
    homepage is www.foo.com/index.html

    start watching the directory
    ruby examples/f5.rb /var/www/foo

    open www.foo.com:4567/index.html in browser
    you will see the page same as www.foo.com/index.html
    do some changes on /var/www/foo/index.html then save the file.
    or create or modify any file in /var/www/foo
    www.foo.com/index.html will refresh automatically.

### examples/use-block.rb

    $ ruby examples/use-block.rb 
    watching .
    watching ./lib
    ignore ./.git
    watching ./examples

Edit and save README.md by gvim, examples/use-block outputs

    +  ./4913
    -  ./4913
    -  ./README.md
    +  ./README.md
    #  ./README.md
    5 events
    do something
