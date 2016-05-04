#!/usr/bin/env ruby
# TestSuite -- ydim -- 27.01.2005 -- hwyss@ywesee.com
require 'simplecov'

$: << File.dirname(File.expand_path(__FILE__))
SimpleCov.start :rails do
  add_filter do |src|
     src.filename =~ /vendo/
  end
end
Dir.foreach(File.dirname(__FILE__)) do |file|
  if /^test_.*\.rb$/o.match(file)
    require file
  end
end
