#!/usr/bin/env ruby
# coding: utf-8

require 'rb-inotify'
require 'stringio'

class FileMonitorFilter
  def initialize
    @patterns = []
  end

  def ignored?(path)
    status = :allow
    for mode, pattern in @patterns
      if path =~ pattern
        status = mode
      end
    end
    return status == :disallow
  end
  
  alias_method :disallow?, :ignored?

  def disallow(pattern)
    @patterns << [:disallow, pattern]
  end

  def allow(pattern)
    @patterns << [:allow, pattern]
  end

  def reset
    @patterns = []
  end

  def to_s
    str = StringIO.new
    for pattern in @patterns
      str.puts "#{pattern[0].to_s} #{pattern[1].inspect}"
    end
    str.string
  end

  alias_method :d, :disallow
  alias_method :a, :allow
end

class FileMonitor
  # do the action every @frequency second, to avoid check too frequently
  def frequency=(frequency)
    @frequency = frequency
  end

  def frequency(*args)
    if args.size()
      @frequency = args[0]
    end
    @frequency
  end

  # options
  def follow_symlink=(follow_symlink)
    @follow_symlink = follow_symlink
  end

  def follow_symlink(*args)
    @follow_symlink = args[0] if args.size()
    @follow_symlink
  end

  def initialize(project_dir = '.')
    @notifier    = INotify::Notifier.new
    @project_dir = project_dir

    @events         = []
    @ignores        = []
    @frequency      = 0.2
    @follow_symlink = false

    @filters = {
      :files => FileMonitorFilter.new,
      :dirs => FileMonitorFilter.new 
    }
  end

  # Compatible to old ignored_dirs and ignored_files mode
  def ignore_dirs(path)
    self.ignored_dirs= path
  end

  def ignore_files(pattern)
    self.ignored_files = pattern
  end

  def ignored_dirs=(pattern)
    @filters[:dirs].disallow pattern
  end

  def ignored_files=(pattern)
    @filters[:files].disallow pattern
  end

  # New Filter mode
  def filter(type, args = [], &block)
    @filters[type].reset()
    if block_given?
      if args.size() > 0
        $stderr.puts "filter's params #{args.to_s} has been ignored for the block is given"
      end
      @filters[type].instance_eval &block
    elsif args.size()
      @filters[type].instance_eval do
        disallow //
        for arg in args
          allow arg
        end
      end
    else
      raise 'filter needs params or block'
    end
  end

  def filter_files(*args, &block)
    filter :files, args, &block
  end

  def filter_dirs(*args, &block)
    filter :dirs, args, &block
  end

  def ignored_dir?(path)
    if path == '.'
      return false
    end
    @filters[:dirs].ignored? path
  end

  def ignored_file?(path)
    @filters[:files].ignored? path
  end

  def push_event event
    @events << event
  end

  def trim_dir(path)
    if path =~ /(.*)\/$/
      path = $1
    end
    path
  end

  
  # Watch a directory
  def watch(dir)
    # always allow watching @project_dir
    if dir != @project_dir
      dir = trim_dir(dir)
      if !@follow_symlink and File.symlink? dir
        puts "ignore symlink directory #{dir}"
        return false
      end
      if ignored_dir?(dir)
        puts "ignore #{dir}"
        return false
      else
        puts "watching #{dir}"
      end
    end

    @notifier.watch dir, :modify, :create, :move, :delete, :onlydir do|event|
      flags = event.flags

      # display event info
      # + created or moved_to
      # - deleted or moved_from
      # # modified
      # 'stop watching' ignored
      info = ''
      flag = flags[0]
      flag = :moved_from if flags.include? :moved_from
      flag = :moved_to   if flags.include? :moved_to

      case flag
      when :moved_from, :delete
        info += '-'
      when :moved_to, :create
        info += '+'
      when :modify
        info += '#'
      when :ignored
        info += 'stop watching'
      else
        info += 'unknown ' + flags.to_s
      end

      is_dir = flags.include?(:isdir)
      if is_dir and ignored_dir?(event.absolute_name) or 
        !is_dir and ignored_file?(event.absolute_name)
        # the ignored info will not put currently
        info += "i #{event.absolute_name}"
        next
      else
        info += "  #{event.absolute_name}"
        puts info
      end

      if flags.include? :isdir
        if flags.include? :ignore?
          @notifier.watchers.delete watcher.id
        elsif flags.include? :create or flags.include? :move
          watch_recursive event.absolute_name
        else
          push_event event
        end
      else
        push_event event
      end
    end

    return true
  end

  # Watch directory recursive
  # use our recursive instead rb-inotify's :recursive to filter the directory
  def watch_recursive(dir)
    if watch dir
      # if watch current directory succeeded, then continue watching the sub-directories
      Dir.glob(File.join(dir, "*/"), File::FNM_DOTMATCH).each do|subdir|
        name = File.basename(subdir)
        next if name == ".." or name == "."
        watch_recursive subdir
      end
    end
  end

  # check the events received
  def check(events)
    if !@check_warning_notified
      puts "[NOTICE] Inherit from FileMonitor and override method check(events) or\n         use file_monitor_instance.run do|events| end to do anything when any file changes"
      @check_warning_notified = true
    end
  end

  # start watching
  # if block given, check method will be ignored
  def run(&block)
    watch_recursive @project_dir

    while true
      if IO.select([@notifier.to_io], [], [], @frequency)
        @notifier.process
      elsif @events.size > 0
        if block_given?
          yield @events
        else
          check @events
        end
        @events = []
      end
    end
  end

  alias_method :dirs, :filter_dirs
  alias_method :files, :filter_files
  alias_method :exec, :run

  def self.create(dir = '.', &block)
    m = FileMonitor.new(dir)
    m.instance_eval &block
    m
  end

  def self.watch(dir = '.', &block)
    self.create(dir, &block)
  end

end
