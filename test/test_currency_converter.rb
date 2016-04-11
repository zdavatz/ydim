#!/usr/bin/env ruby
# TestCurrencyConverter -- ydim -- 01.02.2006 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'ydim/currency_converter'

module YDIM
	class TestCurrencyConverter < Test::Unit::TestCase
		def setup
			@converter = CurrencyConverter.new
		end
		def test_known_currencies
			assert_equal(0, @converter.known_currencies)
			@converter.store('EUR', 'CHF', 1.55474)
			assert_equal(2, @converter.known_currencies)
			@converter.store('USD', 'CHF', 1.28640)
			assert_equal(3, @converter.known_currencies)
		end
		def test_convert
			@converter.store('EUR', 'CHF', 1.55474)
			assert_equal(1.55474, @converter.convert(1, 'EUR', 'CHF'))
			assert_equal(1, @converter.convert(1, 'CHF', 'CHF'))
			assert_equal(1/1.55474, @converter.convert(1, 'CHF', 'EUR'))
			assert_raises(RuntimeError) {
				@converter.convert(1, 'RND', 'CHF')	
			}
		end
    def test_drb_dup
			@converter.store('EUR', 'CHF', 1.55474)
      dup = @converter.drb_dup
      assert_instance_of(MobileCurrencyConverter, dup)
      assert_equal(1.55474, dup.convert(1, 'EUR', 'CHF'))
    end
	end
end
