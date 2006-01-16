#!/usr/bin/env ruby
# ODBA -- ydim -- 10.01.2006 -- hwyss@ywesee.com

require 'odba'
require 'ydim/debitor'
require 'ydim/invoice'

module YDIM
	class Debitor
		include ODBA::Persistable
		ODBA_SERIALIZABLE = ['@address_lines']
	end
	class Invoice
		include ODBA::Persistable
		ODBA_SERIALIZABLE = ['@items']
	end
end
