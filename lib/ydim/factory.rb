#!/usr/bin/env ruby
# Factory -- ydim -- 16.01.2006 -- hwyss@ywesee.com

require 'ydim/debitor'
require 'ydim/invoice'

module YDIM
	class Factory
		def initialize(serv)
			@serv = serv
		end
		def create_invoice(debitor)
			id = @serv.id_server.next_id(:invoice, @serv.config.invoice_number_start)
			invoice = Invoice.new(id)
			yield(invoice) if(block_given?)
			invoice.debitor = debitor
			@serv.invoices.store(id, invoice)
			@serv.invoices.odba_store
			debitor.invoices.odba_store
			invoice
		end
	end
end
