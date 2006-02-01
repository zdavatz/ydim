#!/usr/bin/env ruby
# TestServer -- ydim -- 10.01.2006 -- hwyss@ywesee.com


$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'test/stub/odba'
require 'flexmock'
require 'ydim/server'

module YDIM
	class TestServer < Test::Unit::TestCase
		def setup
			@config = FlexMock.new
			@config.mock_handle(:autoinvoice_hour) { nil }
			@config.mock_handle(:currency_update_hour) { nil }
			@logger = FlexMock.new
			@server = Server.new(@config, @logger)
			@needle = @server.instance_variable_get('@serv')
			@datadir = File.expand_path('tmp', File.dirname(__FILE__))
		end
		def test_config
			assert_equal(@config, @needle.config)
		end
		def test_root_user__file_relative
			FileUtils.mkdir_p(@datadir)
			@config.mock_handle(:root_name) { 'Root' }
			@config.mock_handle(:root_email) { 'test@ywesee.com' }
			@config.mock_handle(:root_key) { "root_dsa.pub" }
			@config.mock_handle(:conf_dir) { @datadir }
			filepath = File.join(@datadir, "root_dsa.pub")
			key = OpenSSL::PKey::DSA.new(8)
			File.open(filepath, 'w') { |fh|
				fh.puts(key.public_key.to_s)
			}
			auth_server = nil
			assert_nothing_raised { 
				auth_server = @needle.auth_server
			}
			assert_instance_of(RRBA::Server, auth_server)
			root = auth_server.instance_variable_get('@root')
			assert_equal('Root', root.name)
			assert_equal('test@ywesee.com', root.email)
			assert(root.public_key.sysverify('test', key.syssign('test')))
		ensure
			FileUtils.rm_r(@datadir) if File.exist?(@datadir)
		end
		def test_root_user__file_absolute
			FileUtils.mkdir_p(@datadir)
			@config.mock_handle(:root_name) { 'Root' }
			@config.mock_handle(:root_email) { 'test@ywesee.com' }
			@config.mock_handle(:root_key) { 
				File.join(@datadir, "absolute_dsa.pub") 
			}
			@config.mock_handle(:conf_dir) { @datadir }
			filepath = File.join(@datadir, "absolute_dsa.pub")
			key = OpenSSL::PKey::DSA.new(8)
			File.open(filepath, 'w') { |fh|
				fh.puts(key.public_key.to_s)
			}
			auth_server = nil
			assert_nothing_raised { 
				auth_server = @needle.auth_server
			}
			assert_instance_of(RRBA::Server, auth_server)
			root = auth_server.instance_variable_get('@root')
			assert_equal('Root', root.name)
			assert_equal('test@ywesee.com', root.email)
			assert(root.public_key.sysverify('test', key.syssign('test')))
		ensure
			FileUtils.rm_r(@datadir) if File.exist?(@datadir)
		end
		def test_root_user__dump
			key = OpenSSL::PKey::DSA.new(8)
			@config.mock_handle(:root_name) { 'Root' }
			@config.mock_handle(:root_email) { 'test@ywesee.com' }
			@config.mock_handle(:root_key) { 
				key.public_key.to_s	
			}
			@config.mock_handle(:conf_dir) { @datadir }
			auth_server = nil
			assert_nothing_raised { 
				auth_server = @needle.auth_server
			}
			assert_instance_of(RRBA::Server, auth_server)
			root = auth_server.instance_variable_get('@root')
			assert_equal('Root', root.name)
			assert_equal('test@ywesee.com', root.email)
			assert(root.public_key.sysverify('test', key.syssign('test')))
		end
		def test_login_ok
			debug_messages = ''
			info_messages = ''
			error_messages = ''
			@logger.mock_handle(:debug) { |msg, block| 
				debug_messages << msg << "\n" }
			@logger.mock_handle(:info) { |msg, block| 
				info_messages << msg << "\n" }
			@logger.mock_handle(:error) { |msg, block| 
				error_messages << msg << "\n" }
			@logger.mock_handle(:error) { |msg, block| flunk(msg) }
			key = OpenSSL::PKey::DSA.new(8)
			@config.mock_handle(:root_name) { 'Root' }
			@config.mock_handle(:root_email) { 'test@ywesee.com' }
			@config.mock_handle(:root_key) { 
				key.public_key.to_s	
			}
			@config.mock_handle(:conf_dir) { @datadir }
			client = FlexMock.new
			client.mock_handle(:__drburi) { 'druby://localhost:0' }
			session = @server.login(client, :root) { |challenge|
				key.syssign(challenge)
			}
			assert_instance_of(RootSession, session)
		end
		def test_login_fail
			debug_messages = ''
			info_messages = ''
			error_messages = ''
			@logger.mock_handle(:debug) { |msg, block| 
				debug_messages << msg << "\n" }
			@logger.mock_handle(:info) { |msg, block| 
				info_messages << msg << "\n" }
			@logger.mock_handle(:error) { |msg, block| 
				error_messages << msg << "\n" }
			key = OpenSSL::PKey::DSA.new(8)
			@config.mock_handle(:root_name) { 'Root' }
			@config.mock_handle(:root_email) { 'test@ywesee.com' }
			@config.mock_handle(:root_key) { 
				key.public_key.to_s	
			}
			@config.mock_handle(:conf_dir) { @datadir }
			client = FlexMock.new
			client.mock_handle(:__drburi) { 'druby://localhost:0' }
			assert_raises(OpenSSL::PKey::DSAError) { 
				@server.login(client, :root) { |challenge| challenge }
			}
		end
	end
end
