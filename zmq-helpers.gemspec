# -*- ruby -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zmq-helpers/version'

Gem::Specification.new do |gem|
  gem.name          = "zmq-helpers"
  gem.version       = Zmq::Helpers::VERSION
  gem.authors       = ["Gary Foster"]
  gem.email         = ["gary.foster@gmail.com"]
  gem.description   = %q{ZeroMQ helper classes and utility methods}
  gem.summary       = %q{various 0mq utilities}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency "logging"
end
