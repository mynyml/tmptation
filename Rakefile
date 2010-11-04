task :default => :test

desc "Run tests"
task :test do
  system "ruby -rubygems -I.:lib:test -e'%w( #{Dir['test/**/*_test.rb'].join(' ')} ).each {|p| require p }'"
end

