#!/usr/bin/env ruby
# TestCurrencyUpdater -- ydim -- 01.02.2006 -- hwyss@ywesee.com


$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'ydim/currency_updater'
require 'flexmock'

module YDIM
	class TestCurrencyUpdater < Test::Unit::TestCase
		def setup
			@serv = FlexMock.new
			@updater = CurrencyUpdater.new(@serv)
		end
		def test_extract_conversion
			html = File.read(File.expand_path('data/search.html', 
											 File.dirname(__FILE__)))
			assert_equal('1.2864003', @updater.extract_conversion(html))
		end
	end
end
