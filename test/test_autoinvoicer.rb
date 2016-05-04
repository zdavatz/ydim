#!/usr/bin/env ruby
# TestAutoInvoicer -- ydim -- 01.02.2007 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'minitest/autorun'
require 'flexmock/test_unit'
require 'ydim/autoinvoicer'
require 'ydim/invoice'

module YDIM
  class TestAutoInvoicer < Minitest::Test
    include FlexMock::TestCase
    def setup
      @serv = flexmock('Registry')
      @autoinvoicer = AutoInvoicer.new(@serv)
    end
    def test_run
      deb1 = flexmock('Debitor1')
      deb1.should_receive(:autoinvoices).and_return([])
      deb2 = flexmock('Debitor2')
      inv1 = flexmock('AutoInvoice1')
      inv1.should_receive(:total_netto).and_return(1)
      inv1.should_receive(:date).and_return(Date.today)
      inv2 = flexmock('AutoInvoice2')
      inv2.should_receive(:total_netto).and_return(1)
      inv2.should_receive(:date).and_return(Date.today >> 1)
      inv3 = flexmock('AutoInvoice3')
      inv3.should_receive(:total_netto).and_return(0)
      deb2.should_receive(:autoinvoices).and_return([inv1, inv2, inv3])
      debitors = { 0 => deb1, 1 => deb2 }
      flexstub(Debitor).should_receive(:odba_extent).and_return { |blk|
        debitors.each_value(&blk)
      }
      @serv.should_receive(:config).and_return('configuration')
      factory = flexmock('Factory')
      factory.should_receive(:generate_invoice).with(inv1)\
        .times(1).and_return(:generated_invoice)
      @serv.should_receive(:factory).and_return(factory)
      ODBA.cache = cache = flexmock('ODBA')
      cache.should_receive(:transaction).and_return { |bl| bl.call }
      mail = flexstub(Mail)
      mail.should_receive(:send_invoice)\
        .with('configuration', :generated_invoice)\
        .and_return { assert(true) }
      mail.should_receive(:send_reminder).with('configuration', inv2)\
        .and_return { assert(true) }
      @autoinvoicer.run
    end
  end
end
