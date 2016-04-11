#!/usr/bin/env ruby
# TestServer -- ydim -- 10.01.2006 -- hwyss@ywesee.com
$: << File.expand_path('../lib', File.dirname(__FILE__))
$: << File.expand_path('..', File.dirname(__FILE__))

require 'test/unit'
require 'test/stub/odba'
require 'flexmock'
require 'ydim/server'

module YDIM
	class TestServer < Test::Unit::TestCase
		def setup
			@config = FlexMock.new
			@config.should_receive(:autoinvoice_hour).and_return { nil }
			@config.should_receive(:currency_update_hour).and_return { nil }
			@logger = FlexMock.new('logger')
      @logger.should_ignore_missing
			@server = Server.new(@config, @logger)
			@needle = @server.instance_variable_get('@serv')
			@datadir = File.expand_path('tmp', File.dirname(__FILE__))
		end
		def test_config
			assert_equal(@config, @needle.config)
		end
		def test_root_user__file_relative
			FileUtils.mkdir_p(@datadir)
			@config.should_receive(:root_name).and_return { 'Root' }
			@config.should_receive(:root_email).and_return { 'test@ywesee.com' }
			@config.should_receive(:root_key).and_return { "root_dsa.pub" }
			@config.should_receive(:conf_dir).and_return { @datadir }
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
			@config.should_receive(:root_name).and_return { 'Root' }
			@config.should_receive(:root_email).and_return { 'test@ywesee.com' }
			@config.should_receive(:root_key).and_return {
				File.join(@datadir, "absolute_dsa.pub")
			}
			@config.should_receive(:conf_dir).and_return { @datadir }
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
			@config.should_receive(:root_name).and_return { 'Root' }
			@config.should_receive(:root_email).and_return { 'test@ywesee.com' }
			@config.should_receive(:root_key).and_return {
				key.public_key.to_s
			}
			@config.should_receive(:conf_dir).and_return { @datadir }
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
			@logger.should_receive(:debug).and_return { |msg, block|
				debug_messages << msg << "\n" }
			@logger.should_receive(:info).and_return { |msg, block|
				info_messages << msg << "\n" }
			@logger.should_receive(:error).and_return { |msg, block|
				error_messages << msg << "\n" }
			@logger.should_receive(:error).and_return { |msg, block| flunk(msg) }
			key = OpenSSL::PKey::DSA.new(8)
			@config.should_receive(:root_name).and_return { 'Root' }
			@config.should_receive(:root_email).and_return { 'test@ywesee.com' }
			@config.should_receive(:root_key).and_return {
				key.public_key.to_s
			}
			@config.should_receive(:conf_dir).and_return { @datadir }
			client = FlexMock.new
			client.should_receive(:__drburi).and_return { 'druby://localhost:0' }
			session = @server.login(client, :root) { |challenge|
				key.syssign(challenge)
			}
			assert_instance_of(RootSession, session)
		end
		def test_login_fail
			debug_messages = ''
			info_messages = ''
			error_messages = ''
			@logger.should_receive(:debug).and_return { |msg, block|
				debug_messages << msg << "\n" }
			@logger.should_receive(:info).and_return { |msg, block|
				info_messages << msg << "\n" }
			@logger.should_receive(:error).and_return { |msg, block|
				error_messages << msg << "\n" }
			key = OpenSSL::PKey::DSA.new(8)
			@config.should_receive(:root_name).and_return { 'Root' }
			@config.should_receive(:root_email).and_return { 'test@ywesee.com' }
			@config.should_receive(:root_key).and_return {
				key.public_key.to_s
			}
			@config.should_receive(:conf_dir).and_return { @datadir }
			client = FlexMock.new
			client.should_receive(:__drburi).and_return { 'druby://localhost:0' }
			assert_raises(OpenSSL::PKey::DSAError) {
				@server.login(client, :root) { |challenge| challenge }
			}
		end
	end
end
