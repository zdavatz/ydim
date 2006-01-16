#!/usr/bin/env ruby
# TestDebitors -- ydim -- 11.01.2006 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'flexmock'
require 'ydim/debitors'

module YDIM
	class TestDebitors < Test::Unit::TestCase
		def setup
			@debitors = Debitors.new
		end
		def test_by_email
			debitor = FlexMock.new
			debitor.mock_handle(:email) { 'test@ywesee.com' }
			@debitors.store(1, debitor)
			assert_equal([], @debitors.by_email('unknown@ywesee.com'))
			assert_equal([debitor], @debitors.by_email('test@ywesee.com'))
		end
		def test_by_name
			debitor = FlexMock.new
			debitor.mock_handle(:name) { 'Test' }
			@debitors.store(1, debitor)
			assert_equal([], @debitors.by_name('Unknown'))
			assert_equal([debitor], @debitors.by_name('Test'))
		end
		def test_values
			assert_equal([], @debitors.values)
			@debitors.store(1, 'debitor')
			assert_equal(['debitor'], @debitors.values)
		end
	end
end
