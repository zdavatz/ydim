#!/usr/bin/env ruby
# Invoice -- ydim -- 11.01.2006 -- hwyss@ywesee.com

require 'pdfinvoice/config'
require 'pdfinvoice/invoice'
require 'ydim/item'

module YDIM
	class Invoice
		class Info
			KEYS = [:unique_id, :date, :description, :payment_received, :currency,
				:payment_status, :debitor_name, :debitor_email, :debitor_id, :due_date,
				:total_netto, :total_brutto ]
			attr_reader *KEYS
			def initialize(invoice)
				KEYS.each { |key|
					instance_variable_set("@#{key}", invoice.send(key))
				}
			end
		end
		attr_reader :unique_id, :debitor, :items
		attr_accessor :precision, :date, :description, :payment_period, 
			:payment_received, :currency
		def Invoice.sum(key)
			define_method(key) {
				@items.inject(0.0) { |value, item| value + item.send(key) }
			}
		end
		def initialize(unique_id)
			@unique_id = unique_id
			@items = []
			@precision = 0
		end
		def add_item(item)
			item.index = next_item_id
			@items.push(item)
			item
		end
		def debitor=(debitor)
			if(@debitor)
				@debitor.delete_invoice(self)
			end
			if(debitor)
				debitor.add_invoice(self)
			end
			@debitor = debitor
		end
		def debitor_email
			@debitor.email if(@debitor)
		end
		def debitor_id
			@debitor.unique_id if(@debitor)
		end
		def debitor_name
			@debitor.name if(@debitor)
		end
		def due_date
			if(@date && !@payment_received)
				@date + @payment_period.to_i
			end
		end
		def info
			Info.new(self)
		end
		def item(index)
			@items.find { |item| item.index == index }
		end
		def payment_status
			if(@payment_received)
				'ps_paid'
			elsif(@date && @payment_period \
						&& ((@date + @payment_period) < Date.today))
				'ps_due'
			else
				'ps_open'
			end
		end
		def pdf_invoice
			config = PdfInvoice.config
			config.formats['quantity'] = "%1.#{@precision}f"
			invoice = PdfInvoice::Invoice.new(config)
			invoice.date = @date
			invoice.invoice_number = @unique_id
			invoice.description = @description
			invoice.debitor_address = @debitor.address
			invoice.items = @items.collect { |item|
				[ item.time, item.text, item.unit, item.quantity.to_f, item.price.to_f ]
			}
			invoice
		end
		def to_pdf
			pdf_invoice.to_pdf
		end
		sum :total_brutto
		sum :total_netto
		sum :vat
		private
		include ItemId
	end
end
