#!/usr/bin/env ruby
# RootSession -- ydim -- 10.01.2006 -- hwyss@ywesee.com

require 'drb'
require 'ydim/autoinvoicer'
require 'ydim/debitor'
require 'ydim/invoice'
require 'ydim/item'
require 'ydim/mail'
require 'ydim/reconciler'
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
      rate = invoice.suppress_vat ? 0 : @serv.config.vat_rate
			items.each { |data|
				item = Item.new({:vat_rate => rate}.update(data))
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
		def collect_garbage(debitor_id=nil)
			@serv.logger.info(whoami) { "collect_garbage" }
			deleted = []
      Invoice.odba_extent { |inv|
				if([nil, inv.debitor_id].include?(debitor_id) && inv.deleted)
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
				Debitor.new(id).odba_store
			}
		end
		def create_invoice(debitor_id)
			@serv.logger.debug(whoami) { "create_invoice(#{debitor_id})" }
			ODBA.transaction {
				@serv.factory.create_invoice(debitor(debitor_id))
			}
		end
		def currency_converter
			@serv.logger.debug(whoami) { "currency_converter" }
			@serv.currency_converter.drb_dup
		end
		def debitor(debitor_id)
			@serv.logger.debug(whoami) { "debitor #{debitor_id}" }
      Debitor.find_by_unique_id(debitor_id.to_s)\
      or begin
        msg = "invalid debitor_id: #{debitor_id}"
        @serv.logger.error(whoami) { msg }
        raise IndexError, msg
      end
		end
    def debitors
      @serv.logger.debug(whoami) { "debitors" } if @serv &&  @serv.respond_to?(:logger)
      Debitor.odba_extent
    end
    def invoices
      @serv.logger.debug(whoami) { "invoices" } if @serv &&  @serv.respond_to?(:logger)
      Invoice.odba_extent
    end
    def autoinvoices
      @serv.logger.debug(whoami) { "autoinvoices" } if @serv &&  @serv.respond_to?(:logger)
      AutoInvoice.odba_extent
    end
    def delete_autoinvoice(invoice_id)
			@serv.logger.debug(whoami) { 
				"delete_autoinvoice(#{invoice_id})" }
      if(invoice = autoinvoice(invoice_id))
        invoice.odba_delete
      end
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
    Invoice.find_by_unique_id(invoice_id.to_s) \
    or begin
      msg = "invalid invoice_id: #{invoice_id}"
      @serv.logger.error(whoami) { msg }
      raise IndexError, msg
    end
  end
		def invoice_infos(status=nil)
			@serv.logger.debug(whoami) { "invoice_infos(#{status})" }
			Invoice.search_by_status(status).collect { |inv| inv.info }
		end
    # The invoices a payment could still be settling. Both statuses are asked
    # for because the status index is only refreshed once a day, so an invoice
    # that has just fallen due may still be indexed as open.
    def open_invoice_infos
      @serv.logger.debug(whoami) { "open_invoice_infos" }
      (Invoice.search_by_status('is_open') \
        | Invoice.search_by_status('is_due')).collect { |inv| inv.info }
    end
    # Marks an invoice as paid. Stores the date the money was booked rather
    # than a plain true, so that a later reconciliation run can tell an
    # already-booked payment from a fresh one.
    def mark_paid(invoice_id, date=Date.today)
      @serv.logger.info(whoami) { "mark_paid(#{invoice_id}, #{date})" }
      ODBA.transaction {
        inv = invoice(invoice_id)
        inv.payment_received = date
        inv.odba_store
        inv.info
      }
    end
    # Matches booked bank credits against the invoice book. `entries` are
    # YDIM::Camt::Entry objects, parsed client-side -- the daemon never needs
    # to see the statement files. Read-only unless :apply is given, in which
    # case only unambiguous matches (invoice number named *and* amount to the
    # cent) are booked; everything else is left for a human.
    def reconcile_camt(entries, opts={})
      @serv.logger.info(whoami) {
        "reconcile_camt(#{entries.size} entries, #{opts.inspect})" }
      accounts = opts[:accounts] || @serv.config.camt_accounts
      resolver = lambda { |id|
        inv = Invoice.find_by_unique_id(id.to_s)
        inv && inv.info
      }
      result = Reconciler.new(open_invoice_infos, accounts, resolver)\
        .reconcile(entries)
      if opts[:apply]
        result.applicable.each { |match|
          match.invoices.each { |info|
            mark_paid(info.unique_id, match.entry.booking_date)
          }
          match.applied = true
        }
      end
      result
    end
		def search_debitors(email_or_name)
			@serv.logger.debug(whoami) { "search_debitors(#{email_or_name})" }
			Debitor.search_by_exact_email(email_or_name) |
				Debitor.search_by_exact_name(email_or_name)
		end
		def send_invoice(invoice_id, sort_args={})
			@serv.logger.info(whoami) { "send_invoice(#{invoice_id})" }
			Mail.send_invoice(@serv.config, invoice(invoice_id), sort_args)
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
