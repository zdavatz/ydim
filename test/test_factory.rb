#!/usr/bin/env ruby
# TestFactory -- ydim -- 16.01.2006 -- hwyss@ywesee.com

$: << File.dirname(__FILE__)
$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'stub/odba'
require 'flexmock'
require 'ydim/factory'

module YDIM
	class TestFactory < Test::Unit::TestCase
    include FlexMock::TestCase
		def setup
      @id_server = flexmock('IdServer')
      @config = flexmock('Config')
			@serv = flexmock('Registry')
      @serv.should_receive(:id_server).and_return(@id_server)
      @serv.should_receive(:config).and_return(@config)
			@factory = Factory.new(@serv)
		end
		def test_create_invoice
			@config.should_receive(:invoice_number_start).and_return(13)
			@id_server.should_receive(:next_id).and_return { |key, start|
				assert_equal(13, start)
				assert_equal(:invoice, key)
				24
			}
			debitor = FlexMock.new
      debitor.should_receive(:foreign?).and_return(false)
			debitor.should_receive(:add_invoice).and_return { |inv|
				assert_instance_of(Invoice, inv)
			}
			dinvs = nil
			debitor.should_receive(:invoices).and_return {
				dinvs = FlexMock.new
				dinvs.should_receive(:odba_store, 1).and_return
				dinvs
			}
			invoice = nil
			assert_nothing_raised { invoice = @factory.create_invoice(debitor) }
			assert_instance_of(Invoice, invoice)
    end
		def test_create_autoinvoice
			@config.should_receive(:invoice_number_start).and_return(13)
			@id_server.should_receive(:next_id).and_return { |key, start|
				assert_equal(13, start)
				assert_equal(:autoinvoice, key)
				24
			}
			debitor = FlexMock.new
      debitor.should_receive(:foreign?).and_return(false)
			debitor.should_receive(:add_autoinvoice).and_return { |inv|
				assert_instance_of(AutoInvoice, inv)
			}
			dinvs = nil
			debitor.should_receive(:autoinvoices).and_return {
				dinvs = FlexMock.new
				dinvs.should_receive(:odba_store, 1).and_return
				dinvs
			}
			invoice = nil
			assert_nothing_raised {
        invoice = @factory.create_autoinvoice(debitor) }
			assert_instance_of(AutoInvoice, invoice)
	end
    def test_generate_invoice
      @config.should_receive(:vat_rate).and_return('current_vat_rate')
      invs = flexmock('Invoices')
      invs.should_receive(:odba_store).times(1)
      debitor = flexmock('Debitor')
      debitor.should_receive(:foreign?).and_return(false)
      debitor.should_receive(:invoices).and_return(invs)
      debitor.should_receive(:add_invoice).and_return { |invoice|
        assert_equal(24, invoice.unique_id)
        assert_equal(1, invoice.items.size)
        item = invoice.items.first
        assert_equal('current_vat_rate', item.vat_rate)
      }
      auto = AutoInvoice.new(1)
      auto.invoice_interval = 3
      item = Item.new
      auto.add_item(item)

      auto.instance_variable_set('@debitor', debitor)
      flexstub(auto).should_receive(:odba_store).and_return {
        assert_equal(Date.today >> 3, auto.date)
      }
			@config.should_receive(:invoice_number_start).and_return(13)
			@id_server.should_receive(:next_id).and_return { |key, start|
				assert_equal(13, start)
				assert_equal(:invoice, key)
				24
			}
      @factory.generate_invoice(auto)
    end
	end
end
