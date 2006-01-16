#!/usr/bin/env ruby
# TestSuite -- ydim -- 27.01.2005 -- hwyss@ywesee.com

$: << File.dirname(File.expand_path(__FILE__))

Dir.foreach(File.dirname(__FILE__)) { |file|
	require file if /^test_.*\.rb$/o.match(file)
}
