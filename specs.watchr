#!/usr/bin/env watchr

# --------------------------------------------------
# Rules
# --------------------------------------------------
watch( '^test.*_test\.rb'      ) {|m| ruby m[0] }
watch( '^lib/(.*)\.rb'         ) {|m| ruby "test/#{m[1]}_test.rb" }

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------
Signal.trap('QUIT') { ruby tests  } # Ctrl-\
Signal.trap('INT' ) { abort("\n") } # Ctrl-C

# --------------------------------------------------
# Helpers
# --------------------------------------------------
def ruby(*paths)
  paths = paths.flatten.select {|p| File.exist?(p) && !File.directory?(p) }.join(' ')
  run "ruby #{gem_opt} -I.:lib:test -e'%w( #{paths} ).each {|p| require p }'" unless paths.empty?
end

def tests
  Dir['test/**/*_test.rb']
end

def run( cmd )
  puts   cmd
  system cmd
end

def gem_opt
  defined?(Gem) ? "-rubygems" : ""
end

