#!/usr/bin/env ruby
# coding: utf-8
# File: examples/simple.rb
require 'rubygems'
require 'file-monitor'

FileMonitor.watch '.' do
    # missing 'dirs' file-monitor will watch all sub directories
  
    # only record ruby file
    files /\.rb$/
    exec {
        system('rake test')
    }
end
