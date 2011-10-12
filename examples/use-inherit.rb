#!/usr/bin/env ruby
# coding: utf-8
# File: examples/use-inherit.rb

require 'rubygems'

lib_dir = File.join File.dirname(__FILE__), '../lib'
$:.unshift lib_dir unless $:.include? lib_dir

require 'file-monitor.rb'

class MyFileMonitor < FileMonitor
  def check(events)
    puts "#{events.size} events"
    puts "do something"
  end
end

dir = ARGV[0] || '.'
m = MyFileMonitor.new(dir)
# ignore any dirs end with .git on .svn
m.ignored_dirs = /\.git|\.svn$/

# ignore any files end with .swp or ~
m.ignored_files = /\.swp|~$/

m.run
