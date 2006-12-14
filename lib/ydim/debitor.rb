#!/usr/bin/env ruby
# Debitor -- ydim -- 10.01.2006 -- hwyss@ywesee.com

require 'ydim/item'

module YDIM
	class Debitor
		attr_reader :autoinvoices, :unique_id, :invoices
    attr_accessor :address_lines, :contact, :contact_firstname,
      :contact_title, :debitor_type, :email, :location, :name,
      :salutation, :phone
		def initialize(unique_id)
			@unique_id = unique_id
			@address_lines = []
			@invoices = []
      @autoinvoices = []
		end
    def autoinvoice(unique_id)
      @autoinvoices.find { |invoice| invoice.unique_id == unique_id }
    end
    def autoinvoice_infos
      @autoinvoices.collect { |inv| inv.info }
    end
    def add_autoinvoice(invoice)
      @autoinvoices.push(invoice)
      invoice
    end
		def add_invoice(invoice)
			@invoices.push(invoice)
			invoice
		end
		def address
			lns = [@name]
			lns.push(["z.H.", @salutation, 
							 @contact_firstname, @contact].compact.join(' '))
			lns.push(@contact_title)
			lns.concat(@address_lines)
			lns.push(@location, @email)
			lns.compact!
			lns
		end
    def delete_autoinvoice(invoice)
      @autoinvoices.delete(invoice)
    end
		def delete_invoice(invoice)
			@invoices.delete(invoice)
		end
		def invoice(unique_id)
			@invoices.find { |invoice| invoice.unique_id == unique_id }
		end
		def invoice_infos(status)
			@invoices.select { |inv| 
				inv.status == status 
			}.collect { |inv| inv.info }
		end
		def next_invoice_date
			@autoinvoices.collect { |inv| inv.date }.compact.min
		end
		private
		include ItemId
	end
end
