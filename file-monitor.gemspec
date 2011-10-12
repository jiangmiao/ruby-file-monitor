Gem::Specification.new do |s|
  s.name        = 'file-monitor'
  s.summary     = 'File Monitor Library'
  s.description = 'Ruby File Monitor is a easy way to watch the directories and files, do anything when them changed.'
  s.version     = '0.1.0'
  s.author      = 'JiangMiao'
  s.email       = 'jiangfriend@gmail.com'
  s.homepage    = 'https://github.com/jiangmiao/ruby-file-monitor'
  s.rubyforge_project = 'file-monitor'
  s.add_dependency('rb-inotify', '>= 0.8.8')
  
  s.files = [
    'lib/file-monitor.rb', 
    'examples/use-block.rb', 
    'examples/use-inherit.rb', 
    'examples/f5.rb',
    'README.md'
  ]
end
