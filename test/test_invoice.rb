#!/usr/bin/env ruby
# TestInvoice -- ydim -- 11.01.2006 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'minitest/autorun'
require 'flexmock/test_unit'
require 'ydim/invoice'

module YDIM
	class TestInvoice < Minitest::Test
    include FlexMock::TestCase
		def setup
			@invoice = Invoice.new(23)
		end
		def test_add_item
			assert_equal([], @invoice.items)
			item_id = 0
			item = FlexMock.new
			item.should_receive(:index=, 2).and_return { |idx|
				assert_equal(item_id, idx)
				item_id += 1
			}
			retval = @invoice.add_item(item)
			assert_equal([item], @invoice.items)
			assert_equal(item, retval)
			retval = @invoice.add_item(item)
			assert_equal([item, item], @invoice.items)
			assert_equal(item, retval)
		end
		def test_item
			item = flexmock('item')
			item.should_receive(:index).and_return(4)
      @invoice.items.push(item)
      assert_nil(@invoice.item(0))
      assert_equal(item, @invoice.item(4))
		end
		def test_debitor_writer
			debitor = FlexMock.new
			debitor.should_receive(:add_invoice, 1).and_return { |arg|
				assert_equal(@invoice, arg)
			}
			@invoice.debitor = debitor
			debitor2 = FlexMock.new
			debitor.should_receive(:delete_invoice, 1).and_return { |arg|
				assert_equal(@invoice, arg)
			}
			debitor2.should_receive(:add_invoice, 1).and_return { |arg|
				assert_equal(@invoice, arg)
			}
			@invoice.debitor = debitor2
		end
		def test_due_date
			@invoice.payment_period = nil
			assert_nil(@invoice.due_date)
			today = Date.today
			@invoice.date = today
			assert_equal(today, @invoice.due_date)
			@invoice.payment_period = 10
			assert_equal(today + 10, @invoice.due_date)
			@invoice.payment_received = true
			assert_nil(@invoice.due_date)
		end
		def test_pdf_invoice
			debitor = FlexMock.new
			debitor.should_receive(:add_invoice, 1).and_return { |arg|
				assert_equal(@invoice, arg)
			}
			debitor.should_receive(:address).and_return { ['address'] }
			@invoice.debitor = debitor
			@invoice.description = 'description'
			pdf = @invoice.pdf_invoice
			assert_instance_of(PdfInvoice::Invoice, pdf)
			assert_equal(['address'], pdf.debitor_address)
			assert_equal(23, pdf.invoice_number)
			assert_equal('description', pdf.description)
		end
		def test_status
			@invoice.date = Date.today
			assert_equal('is_open', @invoice.status)
			@invoice.date -= 2
			@invoice.payment_period = 1
			assert_equal('is_due', @invoice.status)
			@invoice.payment_received = true
			assert_equal('is_paid', @invoice.status)
			@invoice.deleted = true
			assert_equal('is_trash', @invoice.status)
		end
		def test_info
			info = @invoice.info
			assert_instance_of(Invoice::Info, info)
		end
    def test_empty
      assert_equal(true, @invoice.empty?)
      item = flexmock('item')
      @invoice.items.push(item)
      assert_equal(false, @invoice.empty?)
    end
    def test_date_must_be_current
      refute_nil(@invoice.date, 'A new invoice must have the current year by default')
      assert_equal(Date.today.year, @invoice.date.year)
    end
    def test_date_must_be_fixed
      @invoice.date= Date.new(-4712, 1, 1)
      item = Item.new({:time => Time.now})
      @invoice.add_item(Item.new({:time => Time.now}))
      assert_equal(Date.today.year, @invoice.date.year)
    end
	end
  class TestAutoInvoice < Minitest::Test
		def setup
			@invoice = AutoInvoice.new(23)
		end
    def test_advance
      assert_equal 10, @invoice.payment_period
      today = Date.today
      subj = 'Reminder for <year>2008, 2009</year> and <year>2010</year>'
      @invoice.reminder_subject = subj
      retval = @invoice.advance(today)
      assert_equal(today, @invoice.date)
      assert_equal(@invoice.date, retval)
      assert_equal subj, @invoice.reminder_subject
      @invoice.invoice_interval = "inv_3"
      retval = @invoice.advance(today)
      assert_equal(today >> 3, @invoice.date)
      assert_equal(@invoice.date, retval)
      assert_equal subj, @invoice.reminder_subject
      @invoice.invoice_interval = "inv_12"
      retval = @invoice.advance(today - 2)
      assert_equal((today - 2) >> 12, @invoice.date)
      assert_equal(@invoice.date, retval)
      subj = 'Reminder for <year>2009, 2010</year> and <year>2011</year>'
      assert_equal subj, @invoice.reminder_subject
      assert_equal 10, @invoice.payment_period
      @invoice.invoice_interval = "inv_24"
      subj = 'Reminder for <year>2011, 2012</year> and <year>2013</year>'
      retval = @invoice.advance(today - 2)
      assert_equal subj, @invoice.reminder_subject
    end
  end
end
