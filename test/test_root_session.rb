#!/usr/bin/env ruby
# TestRootSession -- ydim -- 10.01.2006 -- hwyss@ywesee.com


$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'test/stub/odba'
require 'ydim/root_session'
require 'flexmock'

module YDIM
	class TestRootSession < Test::Unit::TestCase
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
			@user.mock_handle(:unique_id) { 'user' }
			@serv.mock_handle(:logger) { @mock_logger }
			block.call
			@mock_logger.mock_verify
		end
		def test_add_items
			config = FlexMock.new
			config.mock_handle(:vat_rate) { 7.6 }
			invoice = FlexMock.new
			@serv.mock_handle(:config) { config }
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
			invoice.mock_handle(:add_item) { |item|
				assert_instance_of(Item, item)
				added_items.push(item)	
			}
			invoice.mock_handle(:items) { added_items }
			invoice.mock_handle(:odba_store, 1) {}
			retval = nil
			assert_logged(:debug, :debug) { 
				retval = @session.add_items(123, items) 
			}
			assert_equal(added_items, retval)
			invoice.mock_verify
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
      @serv.mock_handle(:factory) { factory }
      assert_logged(:debug, :debug, :error) {
        assert_raises(IndexError) { @session.create_autoinvoice(1) }
      }
      debitor = flexmock('Debitor')
      flexstub(Debitor).should_receive(:find_by_unique_id).with("2")\
        .and_return(debitor)
      factory.mock_handle(:create_autoinvoice) { |deb|
        assert_equal(debitor, deb)
        'invoice created by Factory'
      }
      invoice = nil
      assert_nothing_raised { invoice = @session.create_autoinvoice(2) }
      assert_equal('invoice created by Factory', invoice)
    end
    def test_create_debitor
      id_server = FlexMock.new
      @serv.mock_handle(:id_server) { id_server }
      id_server.mock_handle(:next_id) { |key|
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
      @serv.mock_handle(:factory) { factory }
      assert_logged(:debug, :debug, :error) {
        assert_raises(IndexError) { @session.create_invoice(1) }
      }
      debitor = flexmock('Debitor')
      flexstub(Debitor).should_receive(:find_by_unique_id).with("2")\
        .and_return(debitor)
      factory.mock_handle(:create_invoice) { |deb|
        assert_equal(debitor, deb)
        'invoice created by Factory'
      }
      invoice = nil
      assert_nothing_raised { invoice = @session.create_invoice(2) }
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
			item1.mock_handle(:index) { 0 }
			item2 = FlexMock.new
			item2.mock_handle(:index) { 1 }
			item3 = FlexMock.new
			item3.mock_handle(:index) { 2 }
			items = [item1, item2, item3]
      flexstub(Invoice).should_receive(:find_by_unique_id)\
        .with('3').and_return(invoice)
			invoice.mock_handle(:items) { items }
			invoice.mock_handle(:odba_store, 1) {}
			retval = nil
			assert_logged(:debug, :debug) {
				retval = @session.delete_item(3, 1)
			}
			assert_equal([item1,item3], retval)
			invoice.mock_verify
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
    def test_invoice__error
      flexstub(Invoice).should_receive(:find_by_unique_id)
      assert_logged(:debug, :error) {
        assert_raises(IndexError) {
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
      flexstub(Mail).should_receive(:send_invoice).with('cnf', inv)
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
	end
end
