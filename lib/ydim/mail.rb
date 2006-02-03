#!/usr/bin/env ruby
# Mail -- ydim -- 18.01.2006 -- hwyss@ywesee.com

require 'net/smtp'
require 'rmail'

module YDIM
	module Mail
		def Mail.body(config, debitor, invoice)
			salutation = config.salutation[debitor.salutation.to_s]
			sprintf(config.mail_body, salutation, debitor.contact, invoice.description)
		end
		def Mail.send_invoice(config, invoice)
			debitor = invoice.debitor
			to = debitor.email
			subject = sprintf('Rechnung %s #%i, %s', debitor.name,
							invoice.unique_id, invoice.description)
			invoice_name = sprintf("%s.pdf", subject.tr(' /', '_-'))
			mpart = RMail::Message.new
			header = mpart.header
			header.to = to
			header.from = config.mail_from
			header.subject = subject
			tpart = RMail::Message.new
			mpart.add_part(tpart)
			tpart.body = body(config, debitor, invoice)
			fpart = RMail::Message.new
			mpart.add_part(fpart)
			header = fpart.header
			header.add('Content-Type', 'application/pdf')
			header.add('Content-Disposition', 'attachment', nil,
				{'filename' => invoice_name })
			header.add('Content-Transfer-Encoding', 'base64')
			fpart.body = [invoice.to_pdf].pack('m')
			smtp = Net::SMTP.new(config.smtp_server)
			recipients = config.mail_recipients.dup.push(to).uniq
			smtp.start {
				recipients.each { |recipient|
					smtp.sendmail(mpart.to_s, config.smtp_from, recipient)
				}
			}
			recipients
		end
	end
end
