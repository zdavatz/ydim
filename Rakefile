#!/usr/bin/env ruby
# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ydim/version'
require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

# dependencies are now declared in ydim.gemspec

desc 'Offer a gem task like hoe'
task :gem => :build do
  Rake::Task[:build].invoke
end

task :spec => :clean
require 'rake/testtask'

task :default => [:clobber, :test, :gem]

dir = File.dirname(__FILE__)
Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = Dir.glob("#{dir}/test/suite.rb")
  t.warning = false
  t.verbose = false
end

require 'rake/clean'
CLEAN.include FileList['pkg/*.gem']
