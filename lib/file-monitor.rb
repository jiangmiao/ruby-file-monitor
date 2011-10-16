#!/usr/bin/env ruby
# coding: utf-8

require 'rb-inotify'

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
end

class FileMonitor
  # do the action every @frequency second, to avoid check too frequently
  attr_accessor :frequency

  def initialize(project_dir = '.')
    @notifier    = INotify::Notifier.new
    @project_dir = project_dir

    @events      = []
    @ignores     = []
    @frequency   = 0.2

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
  def filter(type, &block)
    @filters[type].instance_eval &block
  end

  def filter_files(&block)
    filter :files, &block
  end

  def filter_dirs(&block)
    filter :dirs, &block
  end

  def ignored_dir?(path)
    @filters[:dirs].ignored? path
  end

  def ignored_file?(path)
    @filters[:files].ignored? path
  end

  def push_event event
    @events << event
  end
  
  # Watch a directory
  def watch(dir)
    if ignored_dir?(dir)
      puts "ignore #{dir}"
      return false
    else
      puts "watching #{dir}"
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

      if ignored_file?(event.absolute_name)
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
