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
          l == level}.size).and_return { assert(true) }
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
			invoices = {
				123 => invoice,	
			}
			@serv.mock_handle(:invoices) { invoices }
			@serv.mock_handle(:config) { config }
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
		def test_create_debitor
			id_server = FlexMock.new
			debitors = FlexMock.new
			@serv.mock_handle(:id_server) { id_server }
			@serv.mock_handle(:debitors) { debitors }
			id_server.mock_handle(:next_id) { |key|
				assert_equal(:debitor, key)
				23
			}
			stored = nil
			debitors.mock_handle(:store) { |id, stored|
				assert_equal(23, id)
				assert_instance_of(Debitor, stored)
				debitors.mock_handle(:odba_store, 1) {}
			}
			debitor = nil
			assert_logged(:info) {
				debitor = @session.create_debitor
			}
			assert_equal(stored, debitor)
			debitors.mock_verify
		end
		def test_create_invoice
			factory = FlexMock.new
			debitors = {}
			@serv.mock_handle(:factory) { factory }
			@serv.mock_handle(:debitors) { debitors }
			assert_logged(:debug, :debug, :error) {
				assert_raises(IndexError) { @session.create_invoice(2) }
			}
			debitor = FlexMock.new
			debitors.store(2, debitor)
			factory.mock_handle(:create_invoice) { |deb|
				assert_equal(debitor, deb)
				'invoice created by Factory'
			}
			invoice = nil
			assert_nothing_raised { invoice = @session.create_invoice(2) }
			assert_equal('invoice created by Factory', invoice)
		end
		def test_debitor
			debitors = {}
			@serv.mock_handle(:debitors) { debitors }
			assert_logged(:debug, :error) {
				assert_raises(IndexError) { @session.debitor(1) }
			}
			debitor = FlexMock.new
			debitors.store(1, debitor)
			assert_logged(:debug) { 
				assert_equal(debitor, @session.debitor(1))
			}
			assert_logged(:debug, :error) {
				assert_raises(IndexError) { @session.debitor(2) }
			}
		end
		def test_delete_item
			invoices = FlexMock.new
			invoice = FlexMock.new
			item1 = FlexMock.new
			item1.mock_handle(:index) { 0 }
			item2 = FlexMock.new
			item2.mock_handle(:index) { 1 }
			item3 = FlexMock.new
			item3.mock_handle(:index) { 2 }
			items = [item1, item2, item3]
			@serv.mock_handle(:invoices) { invoices }
			invoices.mock_handle(:fetch) { |id|
				assert_equal(3, id)
				invoice
			}
			invoice.mock_handle(:items) { items }
			invoice.mock_handle(:odba_store, 1) {}
			retval = nil
			assert_logged(:debug, :debug) {
				retval = @session.delete_item(3, 1)
			}
			assert_equal([item1,item3], retval)
			invoice.mock_verify
		end
		def test_search_debitors
			debitors = FlexMock.new
			@serv.mock_handle(:debitors) { debitors }
			debitor = FlexMock.new
			debitors.mock_handle(:by_email) { |email|
				res = []
				res.push(debitor) if(email == 'test@ywesee.com')
				res
			}
			debitors.mock_handle(:by_name) { |name|
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
	end
end
