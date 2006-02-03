#!/usr/bin/env ruby
# TestDebitor -- ydim -- 10.01.2006 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'ydim/debitor'
require 'flexmock'

module YDIM
	class TestDebitor < Test::Unit::TestCase
		def setup
			@debitor = Debitor.new(1)
		end
		def test_address
			@debitor.name = 'Name'
			@debitor.contact = 'Contact'
			@debitor.contact_firstname = 'Firstname'
			@debitor.contact_title = 'Title'
			@debitor.address_lines = %w{Line1 Line2}
			@debitor.email = 'Email'
			expected = [
				'Name',
				'z.H. Firstname Contact',
				'Title', 
				'Line1',
				'Line2',
				'Email',
			]
			assert_equal(expected, @debitor.address)
		end
		def test_add_invoice
			invoice = FlexMock.new()
			invoice.mock_handle(:unique_id) { 17 }
			retval = @debitor.add_invoice(invoice)
			assert_equal(invoice, retval)
			assert_equal([invoice], @debitor.invoices)
			assert_equal(invoice, @debitor.invoice(17))
		end
		def test_delete_invoice
			invoice = FlexMock.new()
			invoice.mock_handle(:unique_id) { 17 }
			@debitor.invoices.push(invoice)
			retval = @debitor.delete_invoice(invoice)
			assert_equal(invoice, retval)	
			assert_equal([], @debitor.invoices)
			assert_nil(@debitor.delete_invoice(invoice))
		end
		def test_next_invoice_date
			assert_nil(@debitor.next_invoice_date)
			date = Date.today + 1
			@debitor.hosting_invoice_date = date
			assert_equal(date, @debitor.next_invoice_date)
		end
	end
end
