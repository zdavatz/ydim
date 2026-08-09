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


  spec.add_dependency 'net-smtp'
  spec.add_dependency 'net-imap'
  spec.add_dependency 'net-pop'
  spec.add_dependency "rexml"
  spec.add_dependency "odba",    '>= 1.1.2'
  spec.add_dependency "ydbd-pg", '>= 0.5.5'
  spec.add_dependency "ydbi",    '>= 0.5.5'
  spec.add_dependency "syck"
  spec.add_dependency "mail"
  spec.add_dependency "rclconf"
  spec.add_dependency "needle"
  spec.add_dependency "ypdf-writer"
  # ypdf-writer allows color >= 1.4.0, but color 2.0 removed the named
  # constants it refers to while loading (Color::RGB::Blue), so a fresh
  # install cannot even require pdf/writer and no invoice renders.
  spec.add_dependency "color", "< 2"
  spec.add_dependency "rrba"
  spec.add_dependency "hpricot"
  spec.add_dependency "pkg-config"
  spec.add_runtime_dependency 'deprecated', '= 2.0.1'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "rake"
  # test_root_session.rb's assert_logged relies on flexmock passing the block
  # to and_return as a trailing argument; flexmock 3 stopped doing that and
  # every test using it dies with "undefined method `call' for nil".
  spec.add_development_dependency "flexmock", "< 3"
  spec.add_development_dependency "test-unit"
  # The suite runs on flexmock/test_unit, which needs the
  # Minitest::Unit::TestCase shim that MT_COMPAT=1 enables. Minitest 6 dropped
  # it, and every test file then fails to load with "undefined method
  # `teardown'".
  spec.add_development_dependency "minitest", "< 6"
  spec.add_development_dependency "rspec"
end

