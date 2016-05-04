#!/usr/bin/env ruby
# TestRootUser -- ydim -- 10.01.2006 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'minitest/autorun'
require 'flexmock/test_unit'
require 'ydim/root_user'

module YDIM
	class TestRootUser < Minitest::Test
		def setup
			@user = RootUser.new(:root)
		end
		def test_session
			session = @user.new_session
			assert_instance_of(RootSession, session)
			assert_equal('root', session.whoami)
		end
	end
end
