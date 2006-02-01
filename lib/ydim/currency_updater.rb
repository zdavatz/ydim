#!/usr/bin/env ruby
# CurrencyUpdater -- ydim -- 01.02.2006 -- hwyss@ywesee.com

require 'net/http'

module YDIM
	class CurrencyUpdater
		def initialize(serv)
			@serv = serv
		end
		def run
			curr = @serv.config.currencies.dup
			while(origin = curr.shift)
				curr.each { |target|
					update_conversion(origin, target)
				}
			end
			@serv.currency_converter.odba_store
		end
		def extract_conversion(html)
			if(match = /1\s+[^<>=]+=\s+(\d+\.\d+)/.match(html))
				match[1]
			end
		end
		def get_conversion(origin, target)
			extract_conversion(get_html(origin, target)).to_f
		end
		def get_html(origin, target)
			## not in test-suite, test manually when modified
			Net::HTTP.start('www.google.com') { |session|
				session.get("/search?q=1+#{origin.upcase}+in+#{target.upcase}").body
			}
		end
		def update_conversion(origin, target)
			@serv.currency_converter.store(origin, target, 
																		 get_conversion(origin, target))
		end
	end
end
