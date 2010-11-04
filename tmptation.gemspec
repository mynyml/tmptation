require 'lib/tmptation'

Gem::Specification.new do |s|
  s.name                = "tmptation"
  s.version             =  Tmptation::VERSION
  s.summary             = "Classes that help safely manipulate temporary files and directories"
  s.description         = "Classes that help safely manipulate temporary files and directories."
  s.author              = "Martin Aumont"
  s.email               = "mynyml@gmail.com"
  s.homepage            = "http://github.com/mynyml/tmptation"
  s.rubyforge_project   = ""
  s.require_path        = "lib"
  s.files               = `git ls-files`.strip.split("\n")

  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rr'
end
