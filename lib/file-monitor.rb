#!/usr/bin/env ruby
# coding: utf-8

require 'rb-inotify'

class FileMonitor
  # the ignored list
  attr_accessor :ignored_dirs, :ignored_files

  # do the action every @frequency second, to avoid check too frequently
  attr_accessor :frequency

  def initialize(project_dir)
    @notifier    = INotify::Notifier.new
    @project_dir = project_dir

    @events      = []
    @ignores     = []
    @frequency   = 0.2
  end

  def ignored?(path, pattern)
    for ignore in Array(pattern)
      if path =~ ignore
        return true
      end
    end
    return false
  end

  def ignored_dir?(path)
    ignored? path, @ignored_dirs
  end

  def ignored_file?(path)
    ignored? path, @ignored_files
  end

  # TODO combine events maybe it's not nesscary
  # moved_from + moved_to = rename
  # create + delete       = delete
  # delete + create       = modify
  # rename + delete       = delete
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
      info = ''
      if flags.include? :moved_from
        info += '-'
      elsif flags.include? :moved_to
        info += '+'
      else
        case flags[0]
        when :create
          info += '+'
        when :modify
          info += '#'
        when :delete
          info += '-'
        when :ignored
          info += 'stop watching'
        end
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
      Dir.glob(File.join(dir, "*/"), File::FNM_DOTMATCH).each do|dir|
        name = File.basename(dir)
        next if name == ".." or name == "."
        watch_recursive dir
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
end
