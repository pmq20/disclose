# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'disclose/version'

Gem::Specification.new do |spec|
  spec.name          = "disclose"
  spec.version       = Disclose::VERSION
  spec.authors       = ["The rugged tests are fragile"]
  spec.email         = ["pmq2001@gmail.com"]

  spec.summary       = %q{Pack your Node.js project into an executable without compiling.}
  spec.description   = %q{Pack your Node.js project into an executable without compiling.}
  spec.homepage      = "https://github.com/pmq20/disclose"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
