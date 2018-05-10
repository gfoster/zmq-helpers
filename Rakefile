require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

desc "build a TAGS file with etags"
task :buildtags do
  %x{ find . -name \*.rb -print | etags - }
end

RSpec::Core::RakeTask.new do |task|
  task.pattern = Dir['**/spec/*_spec.rb'].sort
  task.rspec_opts = Dir.glob("[0-9][0-9][0-9]_*").collect { |x| "-I#{x}" }
  task.rspec_opts << '--color -f d'
end