#!/usr/bin/env ruby
# CONFIG -- ydim -- 12.01.2006 -- hwyss@ywesee.com

require 'rclconf'
require 'fileutils'

module YDIM
	class Client
		ydim_default_dir = File.join(ENV['HOME'], '.ydim')
		default_config_files = [
			File.join(ydim_default_dir, 'ydim.yml'),
			'/etc/ydim/ydim.yml',
		]
		defaults = {
			'config'					=> default_config_files,
			'private_key'			=> File.join(ENV['HOME'], '.ssh', 'id_dsa'),
			'user'						=> nil,
		}
		config = RCLConf::RCLConf.new(ARGV, defaults)
		config.load(config.config)

		FileUtils.mkdir_p(config.ydim_dir)

		CONFIG = config
	end
end
