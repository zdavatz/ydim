#!/usr/bin/env ruby
# encoding: utf-8
# YDIM::Server -- ydim -- 09.12.2011 -- mhatakeyama@ywesee.com
# YDIM::Server -- ydim -- 10.01.2006 -- hwyss@ywesee.com

require 'rclconf'

module YDIM
	class Server
    ydim_default_dir = '/etc/ydim'
    default_config_files = [
      '/etc/ydim/ydimd.yml',
    ]
    defaults = {
      'autoinvoice_hour'      => 1,
      'config'                => default_config_files,
      'conf_dir'              => File.join(ydim_default_dir, 'conf'),
      'currencies'            => ['CHF', 'EUR', 'USD'],
      'currency_update_hour'  => 2,
      'data_dir'              => File.join(ydim_default_dir, 'data'),
      'server_url'            => 'druby://localhost:12375',
      'db_driver_url'         => 'DBI:Pg:ydim',
      'db_user'               => 'ydim',
      'db_auth'               => '',
      'detach'                => false,
      'home_country'          => 'Schweiz',
      'invoice_number_start'  => 10000,
      'log_level'             => 'INFO',
      'log_file'              => STDOUT,
      'mail_body'             => "%s %s\n%s",
      'mail_charset'          => 'iso-8859-1',
      'mail_from'             => '',
      'mail_recipients'       => [],
      'root_name'             => 'Root',
      'root_email'            => '',
      'root_key'              => 'root_dsa',
      'salutation'            => {
        ''                    =>  'Sehr geehrter Herr',
        'Herr'                =>  'Sehr geehrter Herr',
        'Frau'                =>  'Sehr geehrte Frau',
      },
      'smtp_from'             => '',
      'smtp_authtype'         => :plain,
      'smtp_domain'           => 'ywesee.com',
      'smtp_pass'             => nil,
      'smtp_port'             => 587,
      'smtp_server'           => 'localhost',
      'smtp_user'             => 'ydim@ywesee.com',
      'vat_rate'              => 8.1,
    }
    CONFIG =  RCLConf::RCLConf.new(ARGV, defaults)
    def Server.config
      CONFIG
    end
  end
end
