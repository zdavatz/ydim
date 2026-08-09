#!/usr/bin/env ruby
# encoding: utf-8
# TestReconciler -- ydim -- 09.08.2026 -- zdavatz@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))
$: << File.dirname(__FILE__)

require 'minitest/autorun'
require 'ydim/reconciler'

module YDIM
  class TestReconciler < Minitest::Test
    DATA = File.expand_path('data/camt053.xml', File.dirname(__FILE__))
    BUSINESS = 'CH1100000000000000001'
    PRIVATE  = 'CH2200000000000000002'
    # Stands in for Invoice::Info, which needs the whole server to load.
    Info = Struct.new(:unique_id, :total_brutto, :currency, :date,
      :debitor_name, :payment_received, :deleted)
    def invoice(id, total, name, date = '2026-07-01', paid = nil)
      Info.new(id, total, 'CHF', Date.parse(date), name, paid, false)
    end
    # The invoice book the fixture statements are payments against.
    def setup
      @book = [
        invoice(10001, 500.00, 'Example AG'),
        invoice(10002, 100.00, 'Example AG'),
        invoice(10003, 200.00, 'Example AG'),
        invoice(10004, 777.00, 'Hexadecimal AG'),
        invoice(10006, 800.00, 'Partial AG'),
        invoice(10008, 250.00, 'Nameless AG'),
      ]
      # 10005 is named by a pending entry, 10007 was settled earlier; neither
      # is open, so both are only reachable through the resolver.
      @settled = {
        '10005' => invoice(10005, 123.00, 'Pending AG'),
        '10007' => invoice(10007, 1000.00, 'Prompt AG', '2026-07-01',
          Date.new(2026, 7, 5)),
      }
      @entries = Camt.entries(DATA)
    end
    def reconcile(book = @book, accounts = BUSINESS)
      resolver = lambda { |id| @settled[id] }
      Reconciler.new(book, accounts, resolver).reconcile(@entries)
    end
    def match(result, reference)
      result.matches.find { |m| m.entry.reference == reference }
    end

    def test_reconcile__requires_an_account
      # Without a filter the private account in the same download would be
      # matched against invoices, so this must fail rather than guess.
      error = assert_raises(ArgumentError) { reconcile(@book, []) }
      assert_match(/camt_accounts/, error.message)
      assert_raises(ArgumentError) { reconcile(@book, nil) }
    end
    def test_reconcile__ignores_other_accounts
      result = reconcile
      assert_equal(1, result.skipped[:other_account])
      assert_nil(match(result, 'REFB1'))
    end
    # The private account carries a credit that names invoice 10001 for the
    # right amount. Reconciling that account instead would settle it.
    def test_reconcile__business_and_private_do_not_mix
      business = reconcile(@book, BUSINESS)
      assert_equal([10001], match(business, 'REFA1').invoice_ids)
      private_only = reconcile(@book, PRIVATE)
      assert_equal(1, private_only.applicable.size)
      assert_equal(9, private_only.skipped[:other_account])
    end
    def test_reconcile__counts_every_entry
      result = reconcile
      counted = result.matches.size + result.skipped.values.inject(0) { |a, b|
        a + b }
      assert_equal(@entries.size, counted)
    end
    def test_reconcile__skips_duplicates_debits_and_pending
      result = reconcile
      assert_equal(1, result.skipped[:duplicate])
      assert_equal(1, result.skipped[:debit])
      assert_equal(1, result.skipped[:not_booked])
      assert_nil(match(result, 'REFA7'))
    end

    def test_match__exact
      found = match(reconcile, 'REFA1')
      assert_equal(:exact, found.state)
      assert_equal([10001], found.invoice_ids)
      assert_equal(true, found.applicable?)
    end
    def test_match__split_over_two_invoices
      found = match(reconcile, 'REFA2')
      assert_equal(:split, found.state)
      assert_equal([10002, 10003], found.invoice_ids.sort)
      assert_equal(true, found.applicable?)
    end
    def test_match__amount_and_name_only
      found = match(reconcile, 'REFA3')
      assert_equal(:amount_only, found.state)
      assert_equal([10008], found.invoice_ids)
      assert_equal(false, found.applicable?)
      assert_equal(true, found.review?)
    end
    # The hex reference contains "10004" and invoice 10004 is over exactly this
    # amount, so a looser reader would book it. It may be suggested, never
    # booked.
    def test_match__hex_reference_is_not_an_invoice_number
      found = match(reconcile, 'REFA5')
      assert_equal(:amount_only, found.state)
      assert_equal(false, found.applicable?)
    end
    def test_match__underpaid
      found = match(reconcile, 'REFA8')
      assert_equal(:underpaid, found.state)
      assert_equal([10006], found.invoice_ids)
      assert_equal(false, found.applicable?)
      assert_match(/640\.00 received, 800\.00 invoiced/, found.reason)
    end
    def test_match__overpaid
      found = match(reconcile(@book.collect { |info|
        info.unique_id == 10006 ? invoice(10006, 500.00, 'Partial AG') : info
      }), 'REFA8')
      assert_equal(:overpaid, found.state)
      assert_match(/640\.00 received, 500\.00 invoiced/, found.reason)
    end
    def test_match__not_open
      found = match(reconcile, 'REFA9')
      assert_equal(:not_open, found.state)
      assert_equal(false, found.applicable?)
      assert_match(/no longer open/, found.reason)
    end
    def test_match__twint_phone_number_settles_nothing
      found = match(reconcile, 'REFA4')
      assert_equal(:unmatched, found.state)
      assert_equal([], found.invoice_ids)
    end
    def test_match__ambiguous_amount
      book = @book + [invoice(10009, 250.00, 'Nameless AG')]
      found = match(reconcile(book), 'REFA3')
      assert_equal(:ambiguous, found.state)
      assert_equal([10008, 10009], found.invoice_ids.sort)
      assert_equal(false, found.applicable?)
    end
    # Same amount, but only one of them is from the payer.
    def test_match__debitor_name_breaks_the_tie
      book = @book + [invoice(10009, 250.00, 'Unrelated AG')]
      found = match(reconcile(book), 'REFA3')
      assert_equal(:amount_only, found.state)
      assert_equal([10008], found.invoice_ids)
    end
    def test_match__invoice_written_after_the_payment_is_no_candidate
      book = [invoice(10008, 250.00, 'Nameless AG', '2026-07-20')]
      assert_equal(:unmatched, match(reconcile(book), 'REFA3').state)
    end
    def test_match__currency_mismatch
      book = [Info.new(10001, 500.00, 'EUR', Date.parse('2026-07-01'),
        'Example AG', nil, false)]
      found = match(reconcile(book), 'REFA1')
      assert_equal(:currency_mismatch, found.state)
      assert_equal(false, found.applicable?)
    end
    def test_match__deleted_invoice_is_not_payable
      book = [Info.new(10001, 500.00, 'CHF', Date.parse('2026-07-01'),
        'Example AG', nil, true)]
      assert_equal(:not_open, match(reconcile(book), 'REFA1').state)
    end

    def test_result__groups
      result = reconcile
      assert_equal(%w{REFA1 REFA2},
        result.applicable.collect { |m| m.entry.reference }.sort)
      assert_equal(%w{REFA3 REFA5 REFA8 REFA9},
        result.review.collect { |m| m.entry.reference }.sort)
      assert_equal(%w{REFA4},
        result.unmatched.collect { |m| m.entry.reference })
      assert_equal([], result.applied)
    end
    def test_invoice_ref__carries_no_server_classes
      # Results travel back over DRb; a client must be able to load them with
      # ydim/reconciler alone.
      ref = Reconciler::InvoiceRef.new(@book.first)
      assert_equal(ref.to_s, Marshal.load(Marshal.dump(ref)).to_s)
      assert_equal(50000, ref.total_cents)
      assert_equal(true, ref.payable?)
    end
  end
end
