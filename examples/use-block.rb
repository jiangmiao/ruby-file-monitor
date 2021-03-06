#!/usr/bin/env ruby
# coding: utf-8
# File: examples/use-block.rb

require 'rubygems'

lib_dir = File.join File.dirname(__FILE__), '../lib'
$:.unshift lib_dir unless $:.include? lib_dir

require 'file-monitor'

dir = ARGV[0] || '.'
m = FileMonitor.new(dir)
# ignore any dirs end with .git on .svn
# The alias of m.filter_dirs {
#   disallow /\.git|\.svn/
# }
m.ignore_dirs /\.git|\.svn/

# ignore any files end with .swp or ~
# The alias of m.filter_files {
#   disallow /\.swp|~/
# }
m.ignore_files /\.swp|~/

# the block's events contains all file modified infomation in last 0.2 second
m.run do|events|
  puts "#{events.size} events"
  puts "do something"
end
