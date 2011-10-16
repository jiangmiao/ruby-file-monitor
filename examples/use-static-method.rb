#!/usr/bin/env ruby
# coding: utf-8
# File: examples/use-filter.rb

require 'rubygems'

lib_dir = File.join File.dirname(__FILE__), '../lib'
$:.unshift lib_dir unless $:.include? lib_dir

require 'file-monitor.rb'

FileMonitor.watch '.' do
  dirs {
    disallow /git|svn/
  }

  files {
    disallow /.*/
    allow /.rb$/
  }

  exec {|events|
    puts events.size()
    puts "do something"
  }
end
