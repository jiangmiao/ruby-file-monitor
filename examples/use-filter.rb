#!/usr/bin/env ruby
# coding: utf-8
# File: examples/use-filter.rb

require 'rubygems'

lib_dir = File.join File.dirname(__FILE__), '../lib'
$:.unshift lib_dir unless $:.include? lib_dir

require 'file-monitor.rb'

dir = ARGV[0] || '.'

m = FileMonitor.new(dir)
m.filter_dirs {
  disallow /\.git|\.svn/
}

# record .rb files only
m.filter_files {
  disallow  /.*/
  allow /\.rb$/
}
  
m.run do|events|
  puts events.size()
  puts "do something"
end

