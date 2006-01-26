#!/usr/bin/env ruby
# AutoInvoicer -- ydim -- 13.01.2006 -- hwyss@ywesee.com

require 'date'
require 'pdfinvoice/config'
require 'pdfinvoice/invoice'
require 'ydim/mail'

module YDIM
	class AutoInvoicer
		def initialize(serv)
			@serv = serv
		end
		def run
			@serv.debitors.each_value { |debitor| 
				autoinvoice(debitor)
			}
		end
		def autoinvoice(debitor)
			case debitor.debitor_type
			when 'dt_hosting'
				invoice_hosting(debitor)
			end
		end
		def invoice_hosting(debitor, date = Date.today)
			idate = debitor.hosting_invoice_date
			price = debitor.hosting_price.to_f
			if(date == idate && price > 0 \
				 && (intvl = debitor.hosting_invoice_interval))
				months = intvl.to_s[/\d+$/].to_i
				expdate = (date >> months)
				invoice_interval = sprintf("%s-%s", date.strftime('%d.%m.%Y'), 
																	 (expdate - 1).strftime('%d.%m.%Y'))
				description = sprintf("Hosting %s", invoice_interval)
				time = Time.now
				expiry_time = Time.local(expdate.year, expdate.month, expdate.day)
				data = {
					:text				=>	description,
					:item_type	=>	:hosting,
					:quantity		=>	months,
					:unit				=>	'Monate',
					:price			=>	price.to_f,
					:vat_rate		=>	@serv.config.vat_rate,
					:time				=>	time,
					:expiry_time=>	expiry_time
				}
				item = Item.new(data)
				ODBA.transaction {
					invoice = @serv.factory.create_invoice(debitor) { |inv|
						inv.date = date
						inv.description = description
						inv.add_item(item)
						debitor.hosting_items.each { |templ|
							data.update({
								:item_type=>	:domain_pointer,
								:text			=>	"Domain-Pointer: #{templ.text}",
								:price		=>	templ.price.to_f,
							})
							inv.add_item(Item.new(data))
						}
					}
					Mail.send_invoice(@serv.config, invoice) 
					debitor.hosting_invoice_date = expdate
					debitor.odba_store
				}
			end
		end
	end
end
