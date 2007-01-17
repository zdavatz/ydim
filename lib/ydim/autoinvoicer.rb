#!/usr/bin/env ruby
# AutoInvoicer -- ydim -- 13.01.2006 -- hwyss@ywesee.com

require 'date'
require 'pdfinvoice/config'
require 'pdfinvoice/invoice'
require 'ydim/mail'

module YDIM
	class AutoInvoicer
		def initialize(serv)
			@serv = serv
		end
		def run
			@serv.debitors.each_value { |debitor| 
				autoinvoice(debitor)
			}
		end
		def autoinvoice(debitor)
      today = Date.today
      next_month = today >> 1
      debitor.autoinvoices.each { |auto|
        if(auto.total_netto > 0)
          case auto.date
          when today
            Mail.send_invoice(@serv.config, generate(auto)) 
          when next_month
            Mail.send_reminder(@serv.config, auto)
          end
        end
      }
		end
		def generate(autoinvoice)
      ODBA.transaction {
        @serv.factory.generate_invoice(autoinvoice)
      }
		end
	end
end
