#!/usr/bin/env ruby
# DRb -- ydim -- 11.01.2006 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'flexmock'
require 'ydim/drbwrapper'

module YDIM
	class TestDRb < Test::Unit::TestCase
		def setup
			@obj = FlexMock.new
			@wrapper = DRbWrapper.new(@obj)
		end
		def test_dont_rewrap
			orig = Object.new
			@obj.mock_handle(:foo) { orig }
			obj = @wrapper.foo
			assert_equal(orig, obj)
			assert_nothing_raised { Marshal.dump(obj) }
		end
		def test_rewrap
			orig = Object.new 
			orig.extend(ODBA::Persistable)
			@obj.mock_handle(:foo) { orig }
			obj = @wrapper.foo
			assert_raises(TypeError) { Marshal.dump(obj) }
		end
	end
end
