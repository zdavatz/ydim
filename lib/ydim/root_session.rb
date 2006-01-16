#!/usr/bin/env ruby
# RootSession -- ydim -- 10.01.2006 -- hwyss@ywesee.com

require 'drb'
require 'ydim/debitor'
require 'ydim/invoice'
require 'ydim/item'
require 'odba'

module YDIM
	class RootSession
		attr_accessor :serv, :client
		def initialize(user)
			@user = user
		end
		def add_items(invoice_id, items)
			@serv.logger.debug(whoami) { 
				size = (items.respond_to?(:size)) ? items.size : nil
				"add_items(#{invoice_id}, #{items.class}[#{size}])" }
			invoice = @serv.invoices.fetch(invoice_id)
			items.each { |data|
				item = Item.new(data)
				invoice.add_item(item)
			}
			invoice.odba_store
			invoice.items
		end
		def create_debitor
			@serv.logger.info(whoami) { "create_debitor" }
			ODBA.transaction {
				id = @serv.id_server.next_id(:debitor)
				debitor = Debitor.new(id)
				@serv.debitors.store(id, debitor)
				@serv.debitors.odba_store
				debitor
			}
		end
		def create_invoice(debitor_id)
			@serv.logger.debug(whoami) { "create_debitor(#{debitor_id})" }
			ODBA.transaction {
				@serv.factory.create_invoice(debitor(debitor_id))
			}
		end
		def debitor(debitor_id)
			@serv.debitors.fetch(debitor_id)
		rescue IndexError
			@serv.logger.error(whoami) { "invalid debitor_id: #{debitor_id}" }
			raise
		end
		def debitors
			@serv.debitors.values
		end
		def invoice(invoice_id)
			@serv.invoices.fetch(invoice_id)
		rescue IndexError
			@serv.logger.error(whoami) { "invalid invoice_id: #{invoice_id}" }
			raise
		end
		def invoices
			@serv.invoices.values
		end
		def search_debitors(email_or_name)
			@serv.debitors.by_email(email_or_name) |
				@serv.debitors.by_name(email_or_name)
		end
		def whoami
			@user.unique_id.to_s
		end
	end
end
