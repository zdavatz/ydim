#!/usr/bin/env ruby
# CurrencyConverter -- ydim -- 01.02.2006 -- hwyss@ywesee.com

module YDIM
	class MobileCurrencyConverter
		def initialize(conversions={})
			@conversions = conversions
		end
		def convert(amount, origin, target)
			return amount if(origin == target)
			amount.to_f * @conversions.fetch([origin, target]) { 
				raise "Unknown Conversion '#{origin}' -> '#{target}'"
			}
		end
	end
	class CurrencyConverter < MobileCurrencyConverter
		def drb_dup
			MobileCurrencyConverter.new(@conversions)
		end
		def known_currencies
			@conversions.keys.collect { |origin, target| origin }.uniq.size
		end
		def store(origin, target, rate)
			@conversions.store([target, origin], 1.0/rate)
			@conversions.store([origin, target], rate)
		end
	end
end
