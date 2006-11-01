#!/usr/bin/env ruby
# Client -- ydim -- 12.01.2006 -- hwyss@ywesee.com

require 'drb'

module YDIM
	class Client
		include DRb::DRbUndumped
		attr_reader :session
		def initialize(config)
			@config = config
			DRb.start_service(config.client_url)
		end
		def login(server, private_key)
			@server = server
			@session = @server.login(self, @config.user) { |challenge|
				if(private_key.respond_to?(:syssign))
					private_key.syssign(challenge)
				end
			}
		end
		def logout
			@server.logout(@session) if(@server)
		end
		def method_missing(meth, *args, &block)
			@session.send(meth, *args, &block)
		end
	end
end
