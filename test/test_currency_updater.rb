#!/usr/bin/env ruby
# TestCurrencyUpdater -- ydim -- 01.02.2006 -- hwyss@ywesee.com


$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'minitest/autorun'
require 'flexmock/test_unit'
require 'ydim/currency_updater'

module YDIM
	class TestCurrencyUpdater < Minitest::Test
    include FlexMock::TestCase
		def setup
			@serv = flexmock('Config')
			@updater = CurrencyUpdater.new(@serv)
		end
		def test_extract_conversion
			html = File.read(File.expand_path('data/search.html', 
											 File.dirname(__FILE__)))
			assert_equal('1.2864003', @updater.extract_conversion(html))
		end
    def test_run
      resp = flexmock('HttpResponse')
      resp.should_receive(:body)\
        .and_return(File.read(File.expand_path('data/search.html',
                                               File.dirname(__FILE__))))
      session = flexmock('HttpSession')
      session.should_receive(:get).with('/search?q=1+CHF+in+EUR')\
        .and_return(resp)
      flexstub(Net::HTTP).should_receive(:start)\
        .times(1).and_return { |host, block|
        block.call(session)
      }
      conv = flexmock('Converter')
      conv.should_receive(:odba_store).times(1)
      conv.should_receive(:store).times(1).times(1)
      config = flexmock('Config')
      config.should_receive(:currencies).and_return(['CHF', 'EUR'])
      @serv.should_receive(:currency_converter).and_return(conv)
      @serv.should_receive(:config).and_return(config)
      @updater.run
    end
	end
end
