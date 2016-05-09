#!/usr/bin/env ruby
# Config -- pdfinvoice -- 28.07.2005 -- hwyss@ywesee.com

require 'rclconf'

module PdfInvoice
	def PdfInvoice.config(argv=[])
		default_dir = File.join(Dir.home, '.pdfinvoice')
		default_config_files = [
			File.join(default_dir, 'config.yml'),
			'/etc/pdfinvoice/config.yml',
		]
		defaults = {
			'colors'						=> {
				'items'						=> [0xFA, 0xFA, 0xFA],	
				'total'						=> [0xF0, 0xF0, 0xF0],	
			},
			'config'						=> default_config_files,
			'creditor_address'	=> "Please set creditor_address etc in: #{default_config_files}",
			'creditor_email'		=> '',
			'creditor_bank'			=> '',
			'due_days'					=> '',
			'font'							=> 'Helvetica',
			'font_b'						=> 'Helvetica-Bold',
			'formats'						=> {
				'currency'				=> "%1.2f",
				'total'						=> "%1.2f",
				'date'						=> "%d.%m.%Y",
				'invoice_number'	=> "<b>#%06i</b>",
				'quantity'				=> '%1.1f',
			},
			'logo_path'					=> nil,
			'logo_link'					=> nil,
			'tax'								=> 0,
			'texts'							=> {
				'date'						=> 'Date',	
				'description'			=> 'Description',
				'unit'						=> 'Unit',
				'quantity'				=> 'Quantity',
				'price'						=> 'Price',
				'item_total'			=> 'Item Total',
				'subtotal'				=> 'Subtotal',
				'tax'							=> 'Tax',
				'thanks'					=> nil,
				'total'						=> 'Total',
			},
			'text_options'			=> {:spacing => 1.25},
		}
		config = RCLConf::RCLConf.new(ARGV, defaults)
		config.load(config.config)
		config
	end
end
