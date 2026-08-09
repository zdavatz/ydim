#!/usr/bin/env ruby
# encoding: utf-8
# TestRootSession -- ydim -- 10.01.2006 -- hwyss@ywesee.com
$: << File.expand_path('../lib', File.dirname(__FILE__))
$: << File.dirname(__FILE__)

require 'minitest/autorun'
require 'flexmock/test_unit'
require 'stub/odba'
require 'ydim/root_session'

module YDIM
	class TestRootSession < Minitest::Test
    include FlexMock::TestCase
		def setup
			@user = FlexMock.new
			@session = RootSession.new(@user)
			@serv = FlexMock.new
			@session.serv = @serv
		end
		def assert_logged(*levels, &block)
			@mock_logger = flexmock("logger")
			levels.uniq.each { |level|
				@mock_logger.should_receive(level).times(levels.select { |l| 
          l == level}.size).and_return { |usr, blc| 
            assert_equal('user', usr) 
            blc.call
          }
			}
			@user.should_receive(:unique_id).and_return { 'user' }
			@serv.should_receive(:logger).and_return { @mock_logger }
			block.call
		end
		def test_add_items
			config = FlexMock.new('config')
			config.should_receive(:vat_rate).and_return { 7.6 }
			invoice = FlexMock.new('invoice')
			invoice.should_receive(:suppress_vat).and_return { false }
			@serv.should_receive(:config).and_return { config }
      flexstub(Invoice).should_receive(:find_by_unique_id)\
        .with('123').and_return(invoice)
			items = [
				{	:quantity => 1, :unit => 'Stück', :text => 'Item 1', :price => 10.00,
					:vat_rate => 7.6, :data => {}, :time => Time.now, :expiry_time => nil},
				{	:quantity => 2, :unit => 'Stück', :text => 'Item 2', :price => 20.00,
					:vat_rate => 7.6, :data => {}, :time => Time.now, :expiry_time => nil},
				{	:quantity => 3, :unit => 'Stück', :text => 'Item 3', :price => 30.00,
					:vat_rate => 7.6, :data => {}, :time => Time.now, :expiry_time => nil},
				{	:quantity => 4, :unit => 'Stück', :text => 'Item 4', :price => 40.00,
					:vat_rate => 7.6, :data => {}, :time => Time.now, :expiry_time => nil},
			]
			added_items = []
			invoice.should_receive(:add_item).and_return { |item|
				assert_instance_of(Item, item)
				added_items.push(item)	
			}
			invoice.should_receive(:items).and_return { added_items }
			invoice.should_receive(:odba_store, 1).and_return {}
			retval = nil
			assert_logged(:debug, :debug) { 
				retval = @session.add_items(123, items) 
			}
			assert_equal(added_items, retval)
		end
    def test_autoinvoice
      inv = flexmock('autoinvoice')
      flexstub(AutoInvoice).should_receive(:find_by_unique_id)\
        .with("123").times(1).and_return(inv)
      retval = nil
      assert_logged(:debug) { 
        retval = @session.autoinvoice(123) 
      }
      assert_equal(inv, retval)
    end
    def test_autoinvoice__invalid_id
      inv = flexmock('autoinvoice')
      flexstub(AutoInvoice).should_receive(:find_by_unique_id)\
        .times(1)
      retval = nil
      assert_logged(:debug, :error) { 
        assert_raises(IndexError) {
          @session.autoinvoice(123) 
        }
      }
    end
    def test_collect_garbage
      inv1 = flexmock('Invoice1')
      inv1.should_receive(:deleted).and_return(true)
      inv1.should_receive(:info).and_return('info1')
      inv1.should_receive(:odba_delete).times(1)\
        .and_return { assert(true) }
      inv1.should_receive(:debitor_id).and_return(2)
      inv2 = flexmock('Invoice2')
      inv2.should_receive(:deleted).and_return(false)
      inv2.should_receive(:debitor_id).and_return(3)
      flexstub(Invoice).should_receive(:odba_extent)\
        .and_return { |blk| [inv1, inv2].each(&blk) }
      res = nil
      assert_logged(:info) {
        res = @session.collect_garbage
      }
      assert_equal(['info1'], res)
    end
    def test_collect_garbage__debitor
      inv1 = flexmock('Invoice1')
      inv1.should_receive(:deleted).and_return(true)
      inv1.should_receive(:info).and_return('info1')
      inv1.should_receive(:odba_delete).times(1)\
        .and_return { assert(true) }
      inv1.should_receive(:debitor_id).and_return(2)
      inv2 = flexmock('Invoice2')
      inv2.should_receive(:deleted).and_return(true)
      inv2.should_receive(:debitor_id).and_return(3)
      flexstub(Invoice).should_receive(:odba_extent)\
        .and_return { |blk| [inv1, inv2].each(&blk) }
      res = nil
      assert_logged(:info) {
        res = @session.collect_garbage(2)
      }
      assert_equal(['info1'], res)
    end
    def test_create_autoinvoice
      factory = FlexMock.new
      flexstub(Debitor).should_receive(:find_by_unique_id).with("1")
      @serv.should_receive(:factory).and_return { factory }
      assert_logged(:debug, :debug, :debug, :debug, :error) {
        assert_raises(IndexError) { @session.create_autoinvoice(1) }
      }
      debitor = flexmock('Debitor')
      flexstub(Debitor).should_receive(:find_by_unique_id).with("2")\
        .and_return(debitor)
      factory.should_receive(:create_autoinvoice).and_return { |deb|
        assert_equal(debitor, deb)
        'invoice created by Factory'
      }
      invoice = nil
      invoice = @session.create_autoinvoice(2)
      assert_equal('invoice created by Factory', invoice)
    end
    def test_create_debitor
      id_server = FlexMock.new
      @serv.should_receive(:id_server).and_return { id_server }
      id_server.should_receive(:next_id).and_return { |key|
        assert_equal(:debitor, key)
        23
      }
      debitor = nil
      deb = flexmock('Debitor')
      flexstub(Debitor).should_receive(:new).and_return(deb)
      deb.should_receive(:odba_store).times(1).and_return { 
        assert(true)
        deb
      }
      assert_logged(:info) {
        debitor = @session.create_debitor
      }
      assert_equal(deb, debitor)
    end
    def test_create_invoice
      factory = FlexMock.new
      flexstub(Debitor).should_receive(:find_by_unique_id).with("1")
      @serv.should_receive(:factory).and_return { factory }
      assert_logged(:debug, :debug, :debug, :debug, :error) {
        assert_raises(IndexError) { @session.create_invoice(1) }
      }
      debitor = flexmock('Debitor')
      flexstub(Debitor).should_receive(:find_by_unique_id).with("2")\
        .and_return(debitor)
      factory.should_receive(:create_invoice).and_return { |deb|
        assert_equal(debitor, deb)
        'invoice created by Factory'
      }
      invoice = nil
      invoice = @session.create_invoice(2)
      assert_equal('invoice created by Factory', invoice)
    end
    def test_currency_converter
      conv = flexmock('converter')
      conv.should_receive(:drb_dup).and_return { 
        assert(true)
        'duplicate'
      }
      @serv.should_receive(:currency_converter).and_return(conv)
      res = nil
      assert_logged(:debug) { res = @session.currency_converter }
      assert_equal('duplicate', res)
    end
    def test_debitor
      flexstub(Debitor).should_receive(:find_by_unique_id).with("1")
      assert_logged(:debug, :error) {
        assert_raises(IndexError) { @session.debitor(1) }
      }
      debitor = flexmock('Debitor')
      flexstub(Debitor).should_receive(:find_by_unique_id).with("2")\
        .and_return(debitor)
      assert_logged(:debug) { 
        assert_equal(debitor, @session.debitor(2))
      }
    end
    def test_debitors
      flexstub(Debitor).should_receive(:odba_extent).and_return(['deb1'])
      res = nil
      assert_logged(:debug) { res = @session.debitors }
      assert_equal(['deb1'], res)
    end
    def test_delete_autoinvoice
      inv = flexmock('autoinvoice')
      inv.should_receive(:odba_delete).times(1)
      flexstub(AutoInvoice).should_receive(:find_by_unique_id)\
        .with("17").times(1).and_return(inv)
      assert_logged(:debug, :debug) {
        @session.delete_autoinvoice(17)
      }
    end
		def test_delete_item
			invoice = FlexMock.new
			item1 = FlexMock.new
			item1.should_receive(:index).and_return { 0 }
			item2 = FlexMock.new
			item2.should_receive(:index).and_return { 1 }
			item3 = FlexMock.new
			item3.should_receive(:index).and_return { 2 }
			items = [item1, item2, item3]
      flexstub(Invoice).should_receive(:find_by_unique_id)\
        .with('3').and_return(invoice)
			invoice.should_receive(:items).and_return { items }
			invoice.should_receive(:odba_store, 1).and_return {}
			retval = nil
			assert_logged(:debug, :debug) {
				retval = @session.delete_item(3, 1)
			}
			assert_equal([item1,item3], retval)
		end
    def test_generate_invoice
      factory = flexmock('factory')
      @serv.should_receive(:factory).and_return(factory)
      generated = flexmock('invoice')
      inv = flexmock('autoinvoice')
      factory.should_receive(:generate_invoice)\
        .with(inv).times(1).and_return {
        assert(true)
        generated
      }
      flexstub(AutoInvoice).should_receive(:find_by_unique_id)\
        .with("17").times(1).and_return(inv)
      res = nil
      assert_logged(:info, :debug) {
        res = @session.generate_invoice(17) 
      }
      assert_equal(generated, res)
    end
    def test_invoice__error
      inv = flexmock('invoice')
      flexstub(Invoice).should_receive(:find_by_unique_id)\
        .and_return(inv)
      res = nil
      assert_logged(:debug) {
        res = @session.invoice(17)
      }
      assert_equal(inv, res)
    end
    def test_invoice__error_raises
      flexstub(Invoice).should_receive(:find_by_unique_id)
        assert_raises(IndexError) {
      assert_logged(:debug, :error) {
          @session.invoice(17)
        }
      }
    end
    def test_invoice_infos
      inv1 = flexmock('invoice1')
      inv1.should_receive(:status).and_return('selectable')
      inv1.should_receive(:info).and_return('info1')
      inv2 = flexmock('invoice2')
      inv2.should_receive(:status).and_return('not selectable')
      flexstub(Invoice).should_receive(:search_by_status)\
        .with('selectable').and_return([inv1])
      res = nil
      assert_logged(:debug) {
        res = @session.invoice_infos('selectable')
      }
      assert_equal(['info1'], res)
    end
		def test_search_debitors
			debitors = flexstub(Debitor)
			debitor = FlexMock.new
			debitors.should_receive(:search_by_exact_email).and_return { |email|
				res = []
				res.push(debitor) if(email == 'test@ywesee.com')
				res
			}
			debitors.should_receive(:search_by_exact_name).and_return { |name|
				res = []
				res.push(debitor) if(name == 'ywesee GmbH')
				res
			}
			assert_logged(:debug) {
				assert_equal([], @session.search_debitors('Unknown Name'))
			}
			assert_logged(:debug) {
				assert_equal([], @session.search_debitors('unknown@ywesee.com'))
			}
			assert_logged(:debug) {
				assert_equal([debitor], @session.search_debitors('ywesee GmbH'))
			}
			assert_logged(:debug) {
				assert_equal([debitor], @session.search_debitors('test@ywesee.com'))
			}
		end
    def test_send_invoice
      inv = flexmock('invoice')
      flexstub(Invoice).should_receive(:find_by_unique_id)\
        .with('17').and_return(inv)
      @serv.should_receive(:config).and_return('cnf')
      flexstub(Mail).should_receive(:send_invoice).with('cnf', inv, {})
      assert_logged(:info, :debug) {
        @session.send_invoice(17)
      }
    end
    def test_update_item__invoice
      item = flexmock('item')
      inv = flexmock('invoice')
      inv.should_receive(:item).with(4).and_return(item)
      inv.should_receive(:odba_store).times(1)\
        .and_return { assert(true) }
      flexstub(Invoice).should_receive(:find_by_unique_id)\
        .with('12').and_return(inv)
      item.should_receive(:update).with({:foo => 'bar'})
      assert_logged(:debug, :debug) {
        @session.update_item(12, 4, {:foo => 'bar'})
      }
    end
    def test_update_item__autoinvoice
      item = flexmock('item')
      inv = flexmock('invoice')
      inv.should_receive(:item).with(4).and_return(item)
      inv.should_receive(:odba_store).times(1)\
        .and_return { assert(true) }
      flexstub(AutoInvoice).should_receive(:find_by_unique_id)\
        .with('12').and_return(inv)
      item.should_receive(:update).with({:foo => 'bar'})
      assert_logged(:debug, :debug) {
        @session.update_item(12, 4, {:foo => 'bar'}, :autoinvoice)
      }
    end
    def test_mark_paid
      inv = flexmock('invoice')
      date = Date.new(2026, 7, 10)
      inv.should_receive(:payment_received=).with(date).times(1)
      inv.should_receive(:odba_store).times(1)
      inv.should_receive(:info).and_return('info')
      flexstub(Invoice).should_receive(:find_by_unique_id)\
        .with('12').and_return(inv)
      res = nil
      assert_logged(:info, :debug) {
        res = @session.mark_paid(12, date)
      }
      assert_equal('info', res)
    end
    def test_open_invoice_infos
      open = flexmock('open')
      open.should_receive(:info).and_return('open info')
      due = flexmock('due')
      due.should_receive(:info).and_return('due info')
      flexstub(Invoice).should_receive(:search_by_status)\
        .with('is_open').and_return([open])
      flexstub(Invoice).should_receive(:search_by_status)\
        .with('is_due').and_return([due])
      res = nil
      assert_logged(:debug) {
        res = @session.open_invoice_infos
      }
      assert_equal(['open info', 'due info'], res)
    end
    # The entries come from the client, already parsed; the daemon never reads
    # the statement files itself.
    def entry(amount, remittance)
      ntry = YDIM::Camt::Entry.new
      ntry.account_iban = 'CH1100000000000000001'
      ntry.amount = amount
      ntry.currency = 'CHF'
      ntry.credit = true
      ntry.status = 'BOOK'
      ntry.booking_date = Date.new(2026, 7, 10)
      ntry.reference = "REF#{amount}"
      ntry.remittance.push(remittance)
      ntry
    end
    def invoice_info(id, total, paid = nil)
      info = flexmock("info#{id}")
      info.should_receive(:unique_id).and_return(id)
      info.should_receive(:total_brutto).and_return(total)
      info.should_receive(:currency).and_return('CHF')
      info.should_receive(:date).and_return(Date.new(2026, 7, 1))
      info.should_receive(:debitor_name).and_return('Example AG')
      info.should_receive(:payment_received).and_return(paid)
      info.should_receive(:deleted).and_return(false)
      info
    end
    def stub_invoice_book
      config = flexmock('config')
      config.should_receive(:camt_accounts)\
        .and_return(['CH1100000000000000001'])
      @serv.should_receive(:config).and_return { config }
      open = flexmock('open invoice')
      open.should_receive(:info).and_return(invoice_info(10001, 500.00))
      flexstub(Invoice).should_receive(:search_by_status)\
        .with('is_open').and_return([open])
      flexstub(Invoice).should_receive(:search_by_status)\
        .with('is_due').and_return([])
    end
    def test_reconcile_camt
      stub_invoice_book
      flexstub(Invoice).should_receive(:find_by_unique_id).and_return(nil)
      entries = [entry(500.00, 'RG 10001'), entry(42.00, 'RG 99999')]
      res = nil
      assert_logged(:info, :debug) {
        res = @session.reconcile_camt(entries)
      }
      assert_equal(1, res.applicable.size)
      assert_equal([10001], res.applicable.first.invoice_ids)
      assert_equal(1, res.unmatched.size)
      # Read-only without :apply.
      assert_equal([], res.applied)
    end
    def test_reconcile_camt__apply
      stub_invoice_book
      paid = flexmock('invoice to settle')
      paid.should_receive(:payment_received=).with(Date.new(2026, 7, 10))\
        .times(1)
      paid.should_receive(:odba_store).times(1)
      paid.should_receive(:info).and_return('settled')
      flexstub(Invoice).should_receive(:find_by_unique_id)\
        .with('10001').and_return(paid)
      res = nil
      assert_logged(:info, :debug, :info, :debug) {
        res = @session.reconcile_camt([entry(500.00, 'RG 10001')],
          :apply => true)
      }
      assert_equal(1, res.applied.size)
    end
    # A credit on a private account must never settle an invoice, however
    # exactly it matches.
    def test_reconcile_camt__other_account
      stub_invoice_book
      ntry = entry(500.00, 'RG 10001')
      ntry.account_iban = 'CH2200000000000000002'
      res = nil
      assert_logged(:info, :debug) {
        res = @session.reconcile_camt([ntry])
      }
      assert_equal([], res.applicable)
      assert_equal(1, res.skipped[:other_account])
    end
	end
end
