#!/usr/bin/env ruby
# User -- ydim -- 10.01.2006 -- hwyss@ywesee.com

require 'rrba/user'
require 'ydim/drbwrapper'
require 'ydim/root_session'

module YDIM
	class RootUser < RRBA::User
		def new_session
			YDIM::DRbWrapper.new(RootSession.new(self))
		end
	end
end
