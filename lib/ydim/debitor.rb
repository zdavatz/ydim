#!/usr/bin/env ruby
# Debitor -- ydim -- 10.01.2006 -- hwyss@ywesee.com

require 'ydim/item'

module YDIM
	class Debitor
		attr_reader :unique_id, :invoices, :hosting_items
		attr_accessor :address_lines, :contact, :contact_firstname, :contact_title,
			:debitor_type, :email, :hosting_invoice_date, :hosting_invoice_interval,
			:hosting_price, :location, :name, :salutation
		def initialize(unique_id)
			@unique_id = unique_id
			@address_lines = []
			@invoices = []
			@hosting_items = []
		end
		def add_invoice(invoice)
			@invoices.push(invoice)
			invoice
		end
		def add_hosting_item(item)
			item.index = next_item_id
			@hosting_items.push(item)
			item
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
		def delete_invoice(invoice)
			@invoices.delete(invoice)
		end
		def hosting_item(index)
			@hosting_items.find { |item| item.index == index }
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
			@hosting_invoice_date
		end
		private
		include ItemId
	end
end
