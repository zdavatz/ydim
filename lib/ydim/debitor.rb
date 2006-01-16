#!/usr/bin/env ruby
# Debitor -- ydim -- 10.01.2006 -- hwyss@ywesee.com

module YDIM
	class Debitor
		attr_reader :unique_id, :invoices
		attr_accessor :email, :name, :contact, :address_lines, :location,
			:debitor_type, :hosting_price, :hosting_invoice_interval, 
			:hosting_invoice_date
		def initialize(unique_id)
			@unique_id = unique_id
			@address_lines = []
			@invoices = []
		end
		def add_invoice(invoice)
			@invoices.push(invoice)
			invoice
		end
		def address
			lns = [@name]
			lns.push("z.H. #@contact") if(@contact)
			lns.concat(@address_lines)
			lns.push(@email)
			lns.compact!
			lns
		end
		def delete_invoice(invoice)
			@invoices.delete(invoice)
		end
		def invoice(unique_id)
			@invoices.each { |inv|
				return inv if(inv.unique_id == unique_id)
			}
			nil
		end
	end
end
