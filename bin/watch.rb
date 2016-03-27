#!/usr/bin/env ruby

require 'rubygems'
require 'file-monitor'
require 'getoptlong'

opts = GetoptLong.new(
  ['--dir', '-d',  GetoptLong::OPTIONAL_ARGUMENT],
  ['--file', '-f', GetoptLong::OPTIONAL_ARGUMENT],
  ['--exec', '-e', GetoptLong::OPTIONAL_ARGUMENT],
  ['--help', '-h', GetoptLong::OPTIONAL_ARGUMENT]
)

$dirs  = []
$files = []
$command = 'echo do something'
opts.each do|opt, arg|
  case opt
  when '--dir'
    $dirs.push Regexp.new arg
  when '--file'
    $files.push Regexp.new arg
  when '--exec'
    $command = arg
  when '--help'
    puts <<EOT

Usage: watch.rb [options] [directory]

  -d, --dir     the directory regexp to watch
  -e, --exec    the command will be execuate
  -f, --file    the file regexp to watch
  -h, --help    display this help message

Example:

  Watch current working dir and  sub directory lib and src, 
  if any ruby file(match \.rb$) changes
  then execute 'ls' command

    watch.rb -d 'lib$' -d 'src$' -f '.rb$' -e 'ls'

EOT
    exit(0)
  end
end

dir = ARGV[0] || '.'

print 'dirs:  '
puts $dirs.inspect
print 'files: '
puts $files.inspect

FileMonitor.watch dir do
  dirs *$dirs
  files *$files
  exec do
    system $command
  end
end
