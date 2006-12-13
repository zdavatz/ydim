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
      today = Date.today
      next_month = today >> 1
      debitor.autoinvoices.each { |auto|
        if(auto.total_netto > 0)
          case auto.date
          when today
            Mail.send_invoice(@serv.config, generate(auto)) 
          when next_month
            Mail.send_reminder(@serv.config, auto)
          end
        end
      }
		end
		def generate(autoinvoice)
      ODBA.transaction {
        @serv.factory.generate_invoice(autoinvoice)
      }
		end
    ## migratory code
		def hosting_autoinvoice(debitor, date=nil)
      date = debitor.instance_variable_get('@hosting_invoice_date')
      intvl = debitor.instance_variable_get('@hosting_invoice_interval')
      items = debitor.instance_variable_get('@hosting_items')
			price = debitor.instance_variable_get('@hosting_price').to_f
			if(price > 0 && intvl && items)
				months = intvl.to_s[/\d+$/].to_i
				time = Time.now
        description = 'Hosting'
				data = {
					:text				=>	description,
					:quantity		=>	months,
					:unit				=>	'Monate',
					:price			=>	price.to_f,
				}
				item = Item.new(data)
				ODBA.transaction {
					invoice = @serv.factory.create_autoinvoice(debitor) { |inv|
						inv.date = date
						inv.description = description
						inv.precision = 2
						inv.add_item(item)
						items.each { |templ|
							data.update({
								:item_type=>	:domain_pointer,
								:text			=>	"Domain-Pointer: #{templ.text}",
								:price		=>	templ.price.to_f,
							})
							inv.add_item(Item.new(data))
						}
					}
          debitor.add_autoinvoice(invoice)
					debitor.odba_store
          invoice
				}
			end
		end
	end
end
