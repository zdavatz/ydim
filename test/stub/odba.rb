#!/usr/bin/env ruby
# ODBA Stub -- ydim -- 24.01.2005 -- hwyss@ywesee.com

require 'odba/odba'

module ODBA
	def ODBA.transaction(&block)
		block.call
	end
	module Persistable
		attr_reader :odba_stored
		def odba_store
			@odba_stored = @odba_stored.to_i.next
		end
	end
	class Cache
		def fetch_named(*args, &block)
			block.call
		end
	end
end
