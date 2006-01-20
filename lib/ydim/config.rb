#!/usr/bin/env ruby
# CONFIG -- ydim -- 12.01.2006 -- hwyss@ywesee.com

require 'rclconf'
require 'fileutils'

module YDIM
	class Client
		home_dir = ENV['HOME'] || '/tmp'
		ydim_default_dir = File.join(home_dir, '.ydim')
		default_config_files = [
			File.join(ydim_default_dir, 'ydim.yml'),
			'/etc/ydim/ydim.yml',
		]
		defaults = {
			'config'					=> default_config_files,
			'private_key'			=> File.join(home_dir, '.ssh', 'id_dsa'),
			'user'						=> nil,
			'server_url'			=> 'druby://localhost:12375', 
		}
		config = RCLConf::RCLConf.new(ARGV, defaults)
		config.load(config.config)

		CONFIG = config
	end
end
