#!/usr/bin/env ruby
# ODBA Stub -- ydim -- 24.01.2005 -- hwyss@ywesee.com

require 'odba'

=begin
module YDIM 
	class CacheServerStub
		attr_reader :store_calls
		def initialize
			@store_calls = []
		end
		def fetch_named(name, caller, &block)
			block.call
		end
		def store(*args)
			@store_calls.push(args)
		end
		def transaction(&block)
			block.call
		end
		def next_id
			ODBA.storage.next_id
		end
	end
	class StorageStub
		def next_id
			@odba_id = @odba_id.to_i.next
		end
		def transaction(&block)
			block.call
		end
	end
end
=end
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
