#!/usr/bin/env ruby
# TestDebitor -- ydim -- 10.01.2006 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'ydim/debitor'
require 'flexmock'
require 'date'

module YDIM
	class TestDebitor < Test::Unit::TestCase
    include FlexMock::TestCase
		def setup
			@debitor = Debitor.new(1)
		end
		def test_address
			@debitor.name = 'Name'
			@debitor.contact = 'Contact'
			@debitor.contact_firstname = 'Firstname'
			@debitor.contact_title = 'Title'
			@debitor.address_lines = %w{Line1 Line2}
			@debitor.emails = ['Email', 'OtherEmail']
			expected = [
				'Name',
				'z.H. Firstname Contact',
				'Title',
				'Line1',
				'Line2',
				'To: Email',
        'Cc: OtherEmail',
			]
			assert_equal(expected, @debitor.address)
		end
		def test_add_invoice
			invoice = FlexMock.new()
			invoice.should_receive(:unique_id).and_return { 17 }
			retval = @debitor.add_invoice(invoice)
			assert_equal(invoice, retval)
			assert_equal([invoice], @debitor.invoices)
			assert_equal(invoice, @debitor.invoice(17))
		end
		def test_delete_invoice
			invoice = FlexMock.new()
			invoice.should_receive(:unique_id).and_return { 17 }
			@debitor.invoices.push(invoice)
			retval = @debitor.delete_invoice(invoice)
			assert_equal(invoice, retval)
			assert_equal([], @debitor.invoices)
			assert_nil(@debitor.delete_invoice(invoice))
		end
		def test_add_autoinvoice
			invoice = flexmock('autoinvoice')
			invoice.should_receive(:unique_id).and_return(17)
			retval = @debitor.add_autoinvoice(invoice)
			assert_equal(invoice, retval)
			assert_equal([invoice], @debitor.autoinvoices)
			assert_equal(invoice, @debitor.autoinvoice(17))
		end
		def test_delete_autoinvoice
			invoice = flexmock('autoinvoice')
			invoice.should_receive(:unique_id).and_return(17)
			@debitor.autoinvoices.push(invoice)
			retval = @debitor.delete_autoinvoice(invoice)
			assert_equal(invoice, retval)
			assert_equal([], @debitor.autoinvoices)
			assert_nil(@debitor.delete_autoinvoice(invoice))
		end
    def test_autoinvoice_infos
			invoice = flexmock('autoinvoice')
      invoice.should_receive(:info).and_return('info')
			@debitor.autoinvoices.push(invoice)
      assert_equal(['info'], @debitor.autoinvoice_infos)
    end
    def test_invoice_infos
			inv1 = flexmock('invoice')
      inv1.should_receive(:info).and_return('info1')
      inv1.should_receive(:status).and_return('selectable')
			inv2 = flexmock('invoice')
      inv2.should_receive(:info).and_return('info2')
      inv2.should_receive(:status).and_return('not selectable')
			@debitor.invoices.push(inv1, inv2)
      assert_equal(['info1'], @debitor.invoice_infos('selectable'))
    end
    def test_next_autoinvoice_date
			inv1 = flexmock('autoinvoice')
      inv1.should_receive(:date).and_return(Date.today >> 1)
			inv2 = flexmock('autoinvoice')
      inv2.should_receive(:date).and_return(Date.today >> 2)
			inv3 = flexmock('autoinvoice')
      inv3.should_receive(:date)
			@debitor.autoinvoices.push(inv1, inv2, inv3)
      assert_equal(Date.today >> 1, @debitor.next_invoice_date)
    end
	end
end
