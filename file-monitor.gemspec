Gem::Specification.new do |s|
  s.name        = 'file-monitor'
  s.summary     = 'File Monitor Library'
  s.description = 'Ruby File Monitor is a easy way to watch the directories and files, execute commands when them changed.'
  s.version     = '0.1.5'
  s.author      = 'JiangMiao'
  s.licenses    = 'MIT'
  s.email       = 'jiangfriend@gmail.com'
  s.homepage    = 'https://github.com/jiangmiao/ruby-file-monitor'
  s.bindir      = 'bin'
  s.has_rdoc    = false
  s.rubyforge_project = 'file-monitor'
  s.required_ruby_version = '>= 1.8.7'
  s.add_dependency('rb-inotify', '>= 0.8.8')
  
  s.files = [
    'lib/file-monitor.rb', 
    'examples/use-block.rb', 
    'examples/use-inherit.rb', 
    'examples/use-filter.rb',
    'examples/use-creator.rb',
    'examples/simple.rb',
    'examples/f5.rb',
    'bin/f5.rb',
    'bin/watch.rb',
    'README.md'
  ]
  s.executables = [
    'f5.rb',
    'watch.rb'
  ]
end
