#!/usr/bin/env ruby
# TestMail -- ydim -- 01.02.2007 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'minitest/autorun'
require 'flexmock/test_unit'
require 'ydim/mail'

module YDIM
  class TestMail < Minitest::Test
    include FlexMock::TestCase
    def setup_config
      config = flexmock('Config')
      config.should_receive(:mail_body).and_return <<-MAIL
        %s %s
        %s
      MAIL
      config.should_receive(:mail_charset).and_return('utf-8')
      config.should_receive(:mail_from).and_return('from@ywesee.com')
      config.should_receive(:mail_recipients)\
        .and_return(['cc@ywesee.com'])
      config.should_receive(:salutation).and_return {
        {
          ''										=>	'Sehr geehrter Herr',
          'Herr'								=>	'Sehr geehrter Herr',
          'Frau'								=>	'Sehr geehrte Frau',
        }
      }
      config.should_receive(:smtp_from).and_return('smtp@ywesee.com')
      config.should_receive(:smtp_server).and_return('localhost')
      config.should_receive(:smtp_port).and_return('123')
      config.should_receive(:smtp_domain).and_return('ywesee.com')
      config.should_receive(:smtp_user).and_return('user')
      config.should_receive(:smtp_pass).and_return('pass')
      config.should_receive(:smtp_authtype).and_return('plain')
      config
    end
    def test_body
      debitor = flexmock('Debitor')
      debitor.should_receive(:salutation).and_return('Frau')
      debitor.should_receive(:contact).and_return('Melanie Esterhazy')
      invoice = flexmock('Invoice')
      invoice.should_receive(:description).and_return('Description')
      body = Mail.body(setup_config, debitor, invoice)
      assert_equal <<-EXPECTED, body
        Sehr geehrte Frau Melanie Esterhazy
        Description
      EXPECTED
    end
    def test_send_invoice
      debitor = flexmock('Debitor')
      debitor.should_receive(:email).and_return('test@ywesee.com')
      debitor.should_receive(:emails_cc).and_return(['test.cc@ywesee.com'])
      debitor.should_receive(:salutation).and_return('Herr')
      debitor.should_receive(:name).and_return('Company-Name')
      debitor.should_receive(:contact).and_return('Contact-Name')
      invoice = flexmock('Invoice')
      invoice.should_receive(:debitor).and_return(debitor)
      invoice.should_receive(:unique_id).and_return(12345)
      invoice.should_receive(:description).and_return('Description')
      invoice.should_receive(:to_pdf).times(1).and_return('pdf-document')
      smtp = flexmock('SMTP')
      flexstub(Net::SMTP).should_receive(:new).and_return(smtp)
      smtp.should_receive(:start)
      smtp.should_receive(:sendmail).with(String,
        'smtp@ywesee.com', 'cc@ywesee.com').and_return { assert(true) }
      smtp.should_receive(:sendmail).with(String,
        'smtp@ywesee.com', 'test@ywesee.com').and_return { assert(true) }
      smtp.should_receive(:sendmail).with(String,
        'smtp@ywesee.com', 'test.cc@ywesee.com').and_return { assert(true) }
      Mail.send_invoice(setup_config, invoice)
    end
    def test_send_reminder
      debitor = flexmock('Debitor')
      debitor.should_receive(:email).and_return('test@ywesee.com')
      debitor.should_receive(:emails_cc).and_return(['test.cc@ywesee.com'])
      debitor.should_receive(:salutation).and_return('Herr')
      debitor.should_receive(:name).and_return('Company-Name')
      debitor.should_receive(:contact).and_return('Contact-Name')
      invoice = flexmock('Invoice')
      invoice.should_receive(:debitor).and_return(debitor)
      invoice.should_receive(:unique_id).and_return(12345)
      invoice.should_receive(:description).and_return('Description')
      invoice.should_receive(:reminder_subject).and_return('Reminder')
      invoice.should_receive(:reminder_body).and_return('Reminder Body')
      smtp = flexmock('SMTP')
      flexstub(Net::SMTP).should_receive(:new).and_return(smtp)
      smtp.should_receive(:start)
      smtp.should_receive(:sendmail).with(String,
        'smtp@ywesee.com', 'cc@ywesee.com').and_return { assert(true) }
      smtp.should_receive(:sendmail).with(String,
        'smtp@ywesee.com', 'test@ywesee.com').and_return { assert(true) }
      smtp.should_receive(:sendmail).with(String,
        'smtp@ywesee.com', 'test.cc@ywesee.com').and_return { assert(true) }
      Mail.send_reminder(setup_config, invoice)
    end
  end
end
