#!/usr/bin/env ruby
# encoding: utf-8
# CONFIG -- ydim -- 12.01.2006 -- hwyss@ywesee.com

require 'rclconf'
require 'fileutils'

module YDIM
	class Client
		home_dir = ENV['HOME'] || '/tmp'
		ydim_default_dir = '/etc/ydim'
		default_config_files = [
			File.join(ydim_default_dir, 'ydim.yml'),
		]
		defaults = {
			'client_url'					=> 'druby://localhost:0',
			'config'							=> default_config_files,
			'private_key'					=> File.join(home_dir, '.ssh', 'id_dsa'),
			'user'								=> nil,
			'server_url'					=> 'druby://localhost:12375', 
			'currency'						=> 'EUR',
			'invoice_description'	=> 'Auto-Invoice',
      'mail_charset'        => 'iso-8859-1',
			'payment_period'			=> 30,
		}
		config = RCLConf::RCLConf.new(ARGV, defaults)
		config.load(config.config)

		CONFIG = config
	end
end
