#!/usr/bin/env ruby
# RootSession -- ydim -- 10.01.2006 -- hwyss@ywesee.com

require 'drb'
require 'ydim/autoinvoicer'
require 'ydim/debitor'
require 'ydim/invoice'
require 'ydim/item'
require 'ydim/mail'
require 'odba'

module YDIM
	class RootSession
		attr_accessor :serv, :client
		def initialize(user)
			@user = user
		end
		def add_items(invoice_id, items, invoice_key=:invoice)
			@serv.logger.debug(whoami) { 
				size = (items.respond_to?(:size)) ? items.size : nil
				"add_items(#{invoice_id}, #{items.class}[#{size}], #{invoice_key})" }
			invoice = self.send(invoice_key, invoice_id)
			items.each { |data|
				item = Item.new({:vat_rate => @serv.config.vat_rate}.update(data))
				invoice.add_item(item)
			}
			invoice.odba_store
			invoice.items
		end
    def autoinvoice(invoice_id)
      @serv.logger.debug(whoami) { "autoinvoice #{invoice_id}" }
      AutoInvoice.find_by_unique_id(invoice_id.to_s) \
      or begin
        msg = "invalid invoice_id: #{invoice_id}"
        @serv.logger.error(whoami) { msg }
        raise IndexError, msg
      end
    end
		def collect_garbage
			@serv.logger.info(whoami) { "collect_garbage" }
			deleted = []
			@serv.invoices.each_value { |inv|
				if(inv.deleted)
					deleted.push(inv.info)
					inv.odba_delete
				end
			}
			deleted unless(deleted.empty?)
		end
    def create_autoinvoice(debitor_id)
      @serv.logger.debug(whoami) { "create_autoinvoice(#{debitor_id})" }
      ODBA.transaction {
        @serv.factory.create_autoinvoice(debitor(debitor_id))
      }
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
			@serv.logger.debug(whoami) { "create_invoice(#{debitor_id})" }
			ODBA.transaction {
				@serv.factory.create_invoice(debitor(debitor_id))
			}
		end
		def create_hosting_item(debitor_id)
			@serv.logger.debug(whoami) { 
				"create_hosting_item(#{debitor_id})" }
			debitor = debitor(debitor_id)
			item = Item.new
			debitor.add_hosting_item(item)
			debitor.odba_store
			debitor.hosting_items
		end
		def currency_converter
			@serv.logger.debug(whoami) { "currency_converter" }
			@serv.currency_converter.drb_dup
		end
		def debitor(debitor_id)
			@serv.logger.debug(whoami) { "debitor #{debitor_id}" }
			@serv.debitors.fetch(debitor_id)
		rescue IndexError
			@serv.logger.error(whoami) { "invalid debitor_id: #{debitor_id}" }
			raise
		end
		def debitors
			@serv.logger.debug(whoami) { "debitors" }
			@serv.debitors.values
		end
    def delete_autoinvoice(invoice_id)
			@serv.logger.debug(whoami) { 
				"delete_autoinvoice(#{invoice_id})" }
      if(invoice = autoinvoice(invoice_id))
        invoice.odba_delete
      end
    end
		def delete_hosting_item(debitor_id, index)
			@serv.logger.debug(whoami) { 
				"delete_hosting_item(#{debitor_id}, #{index})" }
			debitor = debitor(debitor_id)
			debitor.hosting_items.delete_if { |item| item.index == index }
			debitor.odba_store
			debitor.hosting_items
		end
		def delete_item(invoice_id, index, invoice_key=:invoice)
			@serv.logger.debug(whoami) { 
        "delete_item(#{invoice_id}, #{index}, #{invoice_key})" }
			invoice = self.send(invoice_key, invoice_id)
			invoice.items.delete_if { |item| item.index == index }
			invoice.odba_store
			invoice.items
		end
		def generate_invoice(invoice_id)
			@serv.logger.info(whoami) { "generate_invoice(#{invoice_id})" }
      invoice = autoinvoice(invoice_id)
			AutoInvoicer.new(@serv).generate(invoice)
		end
		def invoice(invoice_id)
			@serv.logger.debug(whoami) { "invoice #{invoice_id}" }
			@serv.invoices.fetch(invoice_id)
		rescue IndexError
			@serv.logger.error(whoami) { "invalid invoice_id: #{invoice_id}" }
			raise
		end
		def invoices
			@serv.logger.debug(whoami) { "invoices" }
			@serv.invoices.values
		end
		def invoice_infos(status=nil)
			@serv.logger.debug(whoami) { "invoice_infos(#{status})" }
			@serv.invoices.values.select { |inv| 
				inv.status == status 
			}.collect { |inv| inv.info }
		end
		def search_debitors(email_or_name)
			@serv.logger.debug(whoami) { "search_debitors(#{email_or_name})" }
			@serv.debitors.by_email(email_or_name) |
				@serv.debitors.by_name(email_or_name)
		end
		def send_invoice(invoice_id)
			@serv.logger.info(whoami) { "send_invoice(#{invoice_id})" }
			Mail.send_invoice(@serv.config, invoice(invoice_id))
		end
		def update_hosting_item(debitor_id, index, data)
			@serv.logger.debug(whoami) { 
				"update_hosting_item(#{debitor_id}, #{index}, #{data.inspect})" }
			debitor = debitor(debitor_id)
			item = debitor.hosting_item(index)
			item.update(data)
			debitor.odba_store
			item
		end
		def update_item(invoice_id, index, data, invoice_key=:invoice)
			@serv.logger.debug(whoami) { 
				"update_item(#{invoice_id}, #{index}, #{data.inspect})" }
			invoice = self.send(invoice_key, invoice_id)
			item = invoice.item(index)
			item.update(data)
			invoice.odba_store
			item
		end
		def whoami
			@user.unique_id.to_s
		end
	end
end
