# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'disclose/version'

Gem::Specification.new do |spec|
  spec.name          = "disclose"
  spec.version       = Disclose::VERSION
  spec.authors       = ["The rugged tests are fragile"]
  spec.email         = ["pmq2001@gmail.com"]

  spec.summary       = %q{Pack your Node.js project into an executable without recompiling Node.js.}
  spec.description   = %q{Pack your Node.js project into an executable without recompiling Node.js.}
  spec.homepage      = "https://github.com/pmq20/disclose"
  spec.license       = "MIT"

  spec.files         = [
                         '.gitignore',
                         '.rspec',
                         '.travis.yml',
                         'Gemfile',
                         'LICENSE',
                         'README.md',
                         'Rakefile',
                         'bin/console',
                         'bin/setup',
                         'disclose.gemspec',
                         'exe/disclose',
                         'lib/disclose.rb',
                         'lib/disclose/c.rb',
                         'lib/disclose/libiconv_2_dll.h',
                         'lib/disclose/libintl_2_dll.h',
                         'lib/disclose/tar_exe.h',
                         'lib/disclose/version.rb',
                         'lib/disclose/windows.rb',
                       ]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
end
