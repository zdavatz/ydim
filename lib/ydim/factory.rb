#!/usr/bin/env ruby
# encoding: utf-8
# Factory -- ydim -- 16.01.2006 -- hwyss@ywesee.com

require 'ydim/debitor'
require 'ydim/invoice'

module YDIM
	class Factory
		def initialize(serv)
			@serv = serv
		end
		def create_autoinvoice(debitor)
			id = @serv.id_server.next_id(:autoinvoice, 
                                   @serv.config.invoice_number_start)
			invoice = AutoInvoice.new(id)
			yield(invoice) if(block_given?)
      if debitor.foreign?
        invoice.suppress_vat = true
      end
			invoice.debitor = debitor
			debitor.autoinvoices.odba_store
			invoice
		end
		def create_invoice(debitor)
			id = @serv.id_server.next_id(:invoice, @serv.config.invoice_number_start)
			invoice = Invoice.new(id)
			yield(invoice) if(block_given?)
			invoice.debitor = debitor
      if debitor.foreign?
        invoice.suppress_vat = true
      end
			debitor.invoices.odba_store
			invoice
		end
    def generate_invoice(autoinvoice)
      create_invoice(autoinvoice.debitor) { |inv|
        date = autoinvoice.date || Date.today
        nextdate = autoinvoice.advance(date)
        inv.date = date
        inv.currency = autoinvoice.currency
        inv.description = sprintf("%s %s-%s", autoinvoice.description,
                                  date.strftime("%d.%m.%Y"),
                                  (nextdate - 1).strftime("%d.%m.%Y"))
        inv.precision = autoinvoice.precision
        inv.payment_period = autoinvoice.payment_period
        autoinvoice.items.each { |item|
          nitem = item.dup
          nitem.time = Time.now
          nitem.expiry_time = Time.local(nextdate.year, nextdate.month,
                                         nextdate.day)
          nitem.vat_rate = @serv.config.vat_rate
          inv.add_item(nitem)
        }
        autoinvoice.odba_store
      }
    end
	end
end
