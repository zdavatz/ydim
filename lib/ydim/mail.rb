#!/usr/bin/env ruby
# Mail -- ydim -- 18.01.2006 -- hwyss@ywesee.com

require 'net/smtp'
require 'rmail'

module YDIM
	module Mail
		def Mail.send_invoice(config, invoice)
			to = invoice.debitor.email
			subject = sprintf('Rechnung %s #%i, %s', invoice.debitor.name,
							invoice.unique_id, invoice.description)
			invoice_name = sprintf("%s.pdf", subject.tr(' /', '_-'))
			fpart = RMail::Message.new
			header = fpart.header
			header.to = to
			header.from = config.mail_from
			header.subject = subject
			header.add('Content-Type', 'application/pdf')
			header.add('Content-Disposition', 'attachment', nil,
				{'filename' => invoice_name })
			header.add('Content-Transfer-Encoding', 'base64')
			fpart.body = [invoice.to_pdf].pack('m')
			smtp = Net::SMTP.new(config.smtp_server)
			recipients = config.mail_recipients.dup.push(to).uniq
			smtp.start {
				recipients.each { |recipient|
					smtp.sendmail(fpart.to_s, config.smtp_from, recipient)
				}
			}
			recipients
		end
	end
end
