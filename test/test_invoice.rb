#!/usr/bin/env ruby
# encoding: utf-8

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
      @invoice = Invoice.new(23)

      debitor = FlexMock.new
      debitor.should_receive(:add_invoice, 1).and_return { |arg|
        assert_equal(@invoice, arg)
      }
      debitor.should_receive(:address).and_return { ['address'] }
      @invoice.debitor = debitor
      @invoice.description = 'description'
      item = flexmock('item')
      item_id = 0
      item.should_receive(:index=).and_return { |idx| item_id += 1 }
      item.should_receive(:vat_rate).and_return(7.6)
      item.should_receive(:text).and_return('item text')
      item.should_receive(:unit).and_return('hours')
      item.should_receive(:quantity).and_return(3)
      item.should_receive(:price).and_return(13)
      item.should_receive(:vat).and_return(4)
      @invoice.date = Date.new(2015, 1, 30)
      item.should_receive(:time).and_return( @invoice.date.to_time)
      @invoice.add_item(item)
      user_pdfinvoice = File.join(Dir.home, '.pdfinvoice')
      FileUtils.rm_rf(user_pdfinvoice)
      FileUtils.makedirs(user_pdfinvoice)
      FileUtils.cp(File.join(File.dirname(__FILE__), 'data', 'config.yml'), user_pdfinvoice)
      FileUtils.cp(File.join(File.dirname(__FILE__), 'data', 'logo.png'), '/tmp/ywesee_logo.png')
      pdf = @invoice.pdf_invoice({})
      assert_instance_of(PdfInvoice::Invoice, pdf)
      pdf_output = 'tst.pdf'
      pdf_as_txt = 'tst.txt'
      FileUtils.rm(pdf_output) if File.exist?(pdf_output)
      FileUtils.rm(pdf_as_txt) if File.exist?(pdf_as_txt)
      content = pdf.to_pdf
      File.open(pdf_output, 'w+') {|f| f.write content } if $VERBOSE
      assert_match(/Bedingungen/, content)
      assert_match(/Rechnung 23/, content)
      assert_match(/30.01.2015/, content)
      assert_match(/Clearing/, content)
      assert_match(/Beschreibung/, content)
      assert_match(/Ohne Ihre Gegenmeldung/, content)
      assert_match(/Mit freundlichen/, content)
      assert_match(/MwSt/, content)
      assert_equal(['address'], pdf.debitor_address)
      assert_equal(23, pdf.invoice_number)
      assert_equal('description', pdf.description)
      assert(content.size > 10000, "PDF output must be > 10 Kb, or the Logo is missing. Is #{content.size} bytes. ")
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
