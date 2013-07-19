Gem::Specification.new do |s|
  s.name          = 'wires-inotify'
  s.version       = '0.9.0'
  s.date          = '2013-07-18'
  s.summary       = "wires-inotify"
  s.description   = "Wires extension gem to integrate with inotify via rb-inotify."
  s.authors       = ["Joe McIlvain"]
  s.email         = 'joe.eli.mac@gmail.com'
  s.files         = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  s.require_path  = 'lib'
  s.homepage      = 'https://github.com/jemc/wires-inotify/'
  s.licenses      = "Copyright (c) Joe McIlvain. All rights reserved "
  
  s.add_dependency('wires', '~> 0.2.8')
  s.add_dependency('rb-inotify', '~> 0.9.0')
  
  s.add_development_dependency('rake')
  s.add_development_dependency('minitest')
  s.add_development_dependency('turn')
end