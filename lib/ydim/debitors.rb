#!/usr/bin/env ruby
# Debitors -- ydim -- 11.01.2006 -- hwyss@ywesee.com

module YDIM
	class Debitors < Hash
		def by_email(email)
			values.select { |debitor| debitor.email == email }
		end
		def by_name(name)
			values.select { |debitor| debitor.name == name }
		end
	end
end
