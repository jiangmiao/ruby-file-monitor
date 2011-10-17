#!/usr/bin/env ruby
# coding: utf-8
# File: examples/use-creator.rb

require 'rubygems'

lib_dir = File.join File.dirname(__FILE__), '../lib'
$:.unshift lib_dir unless $:.include? lib_dir

require 'file-monitor'

dir = ARGV[0] || '.'

# watch current working directory
FileMonitor.watch dir do

  # set frequency 0.2 second (optional default is 0.2)
  # frequency 0.2

  # do not follow the symlink (optional default is false)
  # follow_symlink false


  # do not watch directory contains git and svn
  # the last charactor '/' has been trimmed
  dirs {
    disallow /git$|svn$/
  }

  # record ruby files only
  # it equals files /\.rb$/
  files {
    disallow /.*/
    allow /\.rb$/
  }

  # The commands will be runned when file changed
  # the events contains all file modified infomation in last 0.2 second
  exec {|events|
    puts events.size()
    puts "do something"
  }
end
