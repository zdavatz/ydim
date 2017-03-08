#!/usr/bin/env ruby

require 'ydim/server_config' # to pick up the configuration
require 'mail'

module YDIM
  module Mail
    config = YDIM::Server.config
    ::Mail.defaults do
      delivery_method :smtp, {
        :address => config.smtp_server,
        :port => config.smtp_port,
        :domain => config.smtp_domain,
        :user_name => config.smtp_user,
        :password => config.smtp_pass,
      }
    end
    def Mail.body(config, debitor, invoice)
      salutation = config.salutation[debitor.salutation.to_s]
      sprintf(config.mail_body, salutation, debitor.contact, invoice.description)
    end
    def Mail.send_invoice(config, invoice, sort_args={})
      debitor = invoice.debitor
      invoice_subject = sprintf('Rechnung %s #%i, %s', debitor.name,
              invoice.unique_id, invoice.description)
      @mail = ::Mail.new
      @mail.to      = debitor.email
      @mail.cc      = debitor.emails_cc
      @mail.from    = config.mail_from
      @mail.subject = invoice_subject
      @mail.body    = body(config, debitor, invoice)
      @mail.attachments['myfile.pdf'] = { :mime_type => 'application/x-pdf',
                                    :content => invoice.to_pdf(sort_args) }
      @mail.deliver
    rescue Timeout::Error
      retries ||= 3
      if retries > 0
        sleep 3 - retries
        retries -= 1
        retry
      else
        raise
      end
    end
    def Mail.send_reminder(config, autoinvoice)
      debitor = autoinvoice.debitor
      reminder_subject = autoinvoice.reminder_subject.to_s.strip
      reminder_subject.gsub! %r{<year>\s*}, ''
      reminder_subject.gsub! %r{\s*</year>}, ''
      mail_body = autoinvoice.reminder_body.to_s.strip
      mail_body.gsub! %r{<invoice>\s*}, ''
      mail_body.gsub! %r{\s*</invoice>}, ''
      return if reminder_subject.empty? || mail_body.empty?
      @mail = ::Mail.new
      @mail.to      = debitor.email
      @mail.cc      = debitor.emails_cc
      @mail.from    = config.mail_from
      @mail.subject = reminder_subject
      @mail.body    = mail_body
      @mail.deliver
    end
	end
end
