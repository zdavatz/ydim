#!/usr/bin/env ruby
# AutoInvoicer -- ydim -- 13.01.2006 -- hwyss@ywesee.com

require 'date'
require 'net/smtp'
require 'rmail'
require 'pdfinvoice/config'
require 'pdfinvoice/invoice'

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
				item = Item.new
				item.text = description
				item.item_type = :hosting
				item.quantity = months
				item.unit = 'Monate'
				item.price = price.to_f
				item.vat_rate = @serv.config.vat_rate
				item.time = time
				item.expiry_time = expiry_time
				ODBA.transaction {
					invoice = @serv.factory.create_invoice(debitor) { |inv|
						inv.date = date
						inv.description = description
						inv.add_item(item)
					}
					send_invoice(date, invoice) 
					debitor.hosting_invoice_date = expdate
					debitor.odba_store
				}
			end
		end
		def send_invoice(date, invoice)
			to = invoice.debitor.email
			subject = sprintf('Rechnung %s #%i, %s', invoice.debitor.name,
							invoice.unique_id, invoice.description)
			invoice_name = sprintf("%s.pdf", subject.tr(' /', '_-'))
			fpart = RMail::Message.new
			header = fpart.header
			header.to = to
			header.from = @serv.config.mail_from
			header.subject = subject
			header.add('Content-Type', 'application/pdf')
			header.add('Content-Disposition', 'attachment', nil,
				{'filename' => invoice_name })
			header.add('Content-Transfer-Encoding', 'base64')
			fpart.body = [invoice.to_pdf].pack('m')
			smtp = Net::SMTP.new(@serv.config.smtp_server)
			recipients = @serv.config.mail_recipients.dup.push(to).uniq
			smtp.start {
				recipients.each { |recipient|
					smtp.sendmail(fpart.to_s, @serv.config.smtp_from, recipient)
				}
			}
		end
	end
end
