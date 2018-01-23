# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ydim/version'

Gem::Specification.new do |spec|
  spec.name        = "ydim"
  spec.version     = YDIM::VERSION
  spec.author      = "Masaomi Hatakeyama, Zeno R.R. Davatz, Niklaus Giger"
  spec.email       = "mhatakeyama@ywesee.com, zdavatz@ywesee.com, ngiger@ywesee.com"
  spec.description = "ywesee distributed invoice manager. A Ruby gem"
  spec.summary     = "ywesee distributed invoice manager"
  spec.homepage    = "https://github.com/zdavatz/ydim"
  spec.license       = "GPL-v2"
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "odba",    '>= 1.1.2'
  spec.add_dependency "ydbd-pg", '>= 0.5.5'
  spec.add_dependency "ydbi",    '>= 0.5.5'
  spec.add_dependency "syck"
  spec.add_dependency "mail"
  spec.add_dependency "rclconf"
  spec.add_dependency "needle"
  spec.add_dependency "ypdf-writer"
  spec.add_dependency "rrba"
  spec.add_dependency "hpricot"
  spec.add_runtime_dependency 'deprecated', '= 2.0.1'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "flexmock"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rspec"
end

