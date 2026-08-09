#!/usr/bin/env ruby
# encoding: utf-8
# TestCamt -- ydim -- 09.08.2026 -- zdavatz@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))
$: << File.dirname(__FILE__)

require 'minitest/autorun'
require 'ydim/camt'

module YDIM
  class TestCamt < Minitest::Test
    DATA = File.expand_path('data/camt053.xml', File.dirname(__FILE__))
    BUSINESS = 'CH1100000000000000001'
    PRIVATE  = 'CH2200000000000000002'
    def setup
      @statements = Camt.read(DATA)
      @entries = Camt.entries(DATA)
    end
    def entry(reference)
      @entries.find { |ntry| ntry.reference == reference }
    end
    def test_read__statements
      assert_equal(3, @statements.size)
      stmt = @statements.first
      assert_equal('TESTSTMT0001', stmt.id)
      assert_equal(BUSINESS, stmt.account_iban)
      assert_equal('CHF', stmt.currency)
      assert_equal('Test Business GmbH', stmt.owner)
      assert_equal(1000.00, stmt.opening_balance)
      assert_equal(4433.00, stmt.closing_balance)
      assert_equal(9, stmt.entries.size)
    end
    def test_read__entry
      ntry = entry('REFA1')
      assert_equal(BUSINESS, ntry.account_iban)
      assert_equal(500.00, ntry.amount)
      assert_equal(50000, ntry.amount_cents)
      assert_equal('CHF', ntry.currency)
      assert_equal(true, ntry.credit?)
      assert_equal(true, ntry.booked?)
      assert_equal(Date.new(2026, 7, 10), ntry.booking_date)
      assert_equal(Date.new(2026, 7, 10), ntry.value_date)
      assert_equal('Example AG', ntry.counterparty)
      assert_equal(['RG 10001 VOM 1.7.2026'], ntry.remittance)
    end
    def test_read__debit
      ntry = entry('REFA6')
      assert_equal(false, ntry.credit?)
      assert_equal('Supplier AG', ntry.counterparty)
      assert_equal(['102316851467000225775300000'], ntry.creditor_references)
    end
    def test_read__pending_is_not_booked
      assert_equal(false, entry('REFA7').booked?)
      assert_equal(true, entry('REFA1').booked?)
    end
    # A number a payer typed is a token; one a machine generated is not.
    def test_numeric_tokens__invoice_number
      assert_equal(%w{10001 1 7 2026}, entry('REFA1').numeric_tokens)
    end
    def test_numeric_tokens__two_invoices_run_together
      tokens = entry('REFA2').numeric_tokens
      assert_includes(tokens, '10002')
      assert_includes(tokens, '10003')
    end
    def test_numeric_tokens__ignores_hex_reference
      # "0ebf10004f364fc394da3e2776a05643" must not offer up "10004".
      assert_equal([], entry('REFA5').numeric_tokens)
    end
    def test_numeric_tokens__twint_phone_number
      # The phone numbers are tokens, they are just not invoice numbers; what
      # matters is that no shorter number is carved out of them.
      assert_equal(%w{41791234567 41790000000}, entry('REFA4').numeric_tokens)
    end
    def test_numeric_tokens__none
      assert_equal([], entry('REFA3').numeric_tokens)
    end
    def test_account
      ntry = entry('REFA1')
      assert_equal(true,  ntry.account?(BUSINESS))
      assert_equal(true,  ntry.account?([PRIVATE, BUSINESS]))
      assert_equal(false, ntry.account?(PRIVATE))
      assert_equal(true,  ntry.account?([]))
      # Written the way a human copies it out of e-banking.
      assert_equal(true, ntry.account?('ch11 0000 0000 0000 00001'))
    end
    def test_entries__keeps_duplicates
      assert_equal(11, @entries.size)
      assert_equal(2, @entries.count { |ntry| ntry.reference == 'REFA1' \
        && ntry.account_iban == BUSINESS })
    end
    def test_dedup
      unique = Camt.dedup(@entries)
      assert_equal(10, unique.size)
      assert_equal(1, unique.count { |ntry| ntry.reference == 'REFA1' \
        && ntry.account_iban == BUSINESS })
      # Same reference on a different account is a different movement.
      assert_equal(1, unique.count { |ntry| ntry.account_iban == PRIVATE })
    end
    def test_read__directory
      assert_equal(@statements.size,
        Camt.read(File.dirname(DATA)).size)
    end
    def test_parse__namespace_is_taken_from_the_document
      # camt.053.001.02 through .08 differ only in the namespace URI here.
      xml = File.read(DATA).gsub('camt.053.001.08', 'camt.053.001.04')
      assert_equal(3, Camt.parse(xml).size)
    end
    def test_parse__not_xml
      assert_raises(REXML::ParseException) { Camt.parse('not xml at all') }
    end
  end
end
