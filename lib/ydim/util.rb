#!/usr/bin/env ruby
# Util -- ydim -- 10.01.2006 -- hwyss@ywesee.com

require 'openssl'
require 'fileutils'

module YDIM
	module Util
		def Util.load_key(key)
			if(File.exist?(key))
				key = File.read(key)
			end
			key = OpenSSL::PKey::DSA.new(key)
		end
	end
end
