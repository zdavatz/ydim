#!/usr/bin/env ruby
# encoding: utf-8
# YDIM::Reconciler -- ydim -- 09.08.2026 -- zdavatz@ywesee.com

require 'ydim/camt'

module YDIM
  # Matches booked bank credits (YDIM::Camt::Entry) against invoices. Works on
  # Invoice::Info structs rather than Invoice objects so that the result can
  # travel over DRb, and so that it can be unit-tested without a database.
  class Reconciler
    # Words that say nothing about who paid, and would otherwise make two
    # unrelated companies look like the same debitor.
    NOISE = %w{ag gmbh sa sarl srl inc ltd co kg the und and dr med prof}
    # Only these are safe to book without a human looking at them: the payer
    # named the invoice and the money adds up to the cent.
    APPLICABLE = [:exact, :split]

    # The bit of an invoice reconciliation cares about. Results travel back to
    # the client over DRb, and a client should not have to load the whole
    # server just to unmarshal them, so matches carry these rather than
    # Invoice::Info. Built from anything answering the same readers.
    class InvoiceRef
      KEYS = [:unique_id, :total_brutto, :currency, :date, :debitor_name,
        :payment_received, :deleted]
      attr_reader *KEYS
      def initialize(invoice)
        KEYS.each { |key|
          instance_variable_set("@#{key}", invoice.send(key))
        }
      end
      def payable?
        !@payment_received && !@deleted
      end
      def total_cents
        (@total_brutto.to_f * 100).round
      end
      def to_s
        sprintf('%s %s %.2f %s', @unique_id, @currency, @total_brutto.to_f,
          @debitor_name)
      end
    end

    # One bank entry and the invoices it was matched to.
    class Match
      attr_reader :entry, :invoices, :state
      attr_accessor :reason, :applied
      def initialize(entry, invoices, state, reason = nil)
        @entry = entry
        @invoices = invoices
        @state = state
        @reason = reason
        @applied = false
      end
      def applicable?
        APPLICABLE.include?(@state)
      end
      # Matched, but not well enough to book automatically.
      def review?
        !applicable? && !@invoices.empty?
      end
      def applied?
        @applied
      end
      def invoice_ids
        @invoices.collect { |info| info.unique_id }
      end
    end

    # What a reconciliation run found, including the entries that never made it
    # as far as matching -- silently dropping those would make the report look
    # like it had seen everything.
    class Result
      attr_reader :matches, :skipped
      def initialize
        @matches = []
        @skipped = Hash.new(0)
      end
      def applicable
        @matches.select { |match| match.applicable? }
      end
      def review
        @matches.select { |match| match.review? }
      end
      def unmatched
        @matches.select { |match| match.state == :unmatched }
      end
      def applied
        @matches.select { |match| match.applied? }
      end
    end

    attr_reader :accounts
    # infos    - Invoice::Info structs of the invoices still awaiting payment;
    #            these are the candidates for matching on amount alone.
    # accounts - IBANs ydim owns; entries on any other account are ignored.
    #            ydim only ever sees the ywesee business account, but the
    #            e-banking download also carries the private ones.
    # resolver - optional callable turning an invoice number into an Info, so
    #            that a payment naming an invoice that is already settled can
    #            be reported as such without loading the whole invoice book.
    def initialize(infos, accounts = nil, resolver = nil)
      @invoices = infos.collect { |info| InvoiceRef.new(info) }
      @accounts = [accounts].flatten.compact
      @resolver = resolver
      @by_id = {}
      @invoices.each { |ref| @by_id[ref.unique_id.to_s] = ref }
    end
    def reconcile(entries)
      if @accounts.empty?
        raise ArgumentError,
          "no account given -- set camt_accounts to the IBAN of the ywesee " \
          "business account, or the private accounts in the same download " \
          "would be matched against invoices too"
      end
      result = Result.new
      unique = YDIM::Camt.dedup(entries)
      result.skipped[:duplicate] = entries.size - unique.size
      unique.each { |entry|
        if !entry.account?(@accounts)
          result.skipped[:other_account] += 1
        elsif !entry.credit?
          result.skipped[:debit] += 1
        elsif !entry.booked?
          result.skipped[:not_booked] += 1
        else
          result.matches.push(match(entry))
        end
      }
      result
    end

    private
    def match(entry)
      referenced = entry.numeric_tokens.collect { |token|
        lookup(token.sub(/\A0+(?=\d)/, '')) || lookup(token)
      }.compact.uniq
      if referenced.empty?
        match_by_amount(entry)
      else
        match_by_reference(entry, referenced)
      end
    end
    def match_by_reference(entry, referenced)
      open, paid = referenced.partition { |ref| ref.payable? }
      if open.empty?
        return Match.new(entry, paid, :not_open,
          "invoice #{paid.collect { |ref| ref.unique_id }.join(', ')} " \
          "is no longer open")
      end
      wrong = open.reject { |ref| currency?(entry, ref) }
      unless wrong.empty?
        return Match.new(entry, open, :currency_mismatch,
          "paid in #{entry.currency}, invoiced in #{wrong.first.currency}")
      end
      total = open.inject(0) { |sum, ref| sum + ref.total_cents }
      if total == entry.amount_cents
        state = open.size == 1 ? :exact : :split
        reason = open.size == 1 ? 'invoice number and amount match' \
          : "invoice numbers found, amounts sum to #{money(entry)}"
        reason += ", #{paid.size} already paid" unless paid.empty?
        Match.new(entry, open, state, reason)
      elsif entry.amount_cents < total
        Match.new(entry, open, :underpaid,
          "#{money(entry)} received, #{format_cents(total)} invoiced")
      else
        Match.new(entry, open, :overpaid,
          "#{money(entry)} received, #{format_cents(total)} invoiced")
      end
    end
    # Nothing in the remittance information named an invoice -- fall back to
    # the amount, which is never good enough to book on its own.
    def match_by_amount(entry)
      candidates = @invoices.select { |ref|
        ref.payable? && currency?(entry, ref) \
          && ref.total_cents == entry.amount_cents \
          && !later_than?(ref, entry)
      }
      named = candidates.select { |ref| same_party?(entry, ref) }
      candidates = named unless named.empty?
      case candidates.size
      when 0
        Match.new(entry, [], :unmatched, 'no invoice number, no amount match')
      when 1
        Match.new(entry, candidates, :amount_only,
          named.empty? ? 'amount matches, no invoice number given' \
            : 'amount and debitor name match, no invoice number given')
      else
        Match.new(entry, candidates, :ambiguous,
          "#{candidates.size} open invoices over #{money(entry)}")
      end
    end
    def lookup(id)
      return @by_id[id] if @by_id.key?(id)
      found = @resolver && @resolver.call(id)
      @by_id[id] = found && InvoiceRef.new(found)
    end
    def currency?(entry, ref)
      ref.currency.nil? || entry.currency.nil? \
        || ref.currency.to_s.upcase == entry.currency.to_s.upcase
    end
    # An invoice cannot have been paid before it was written.
    def later_than?(ref, entry)
      ref.date && entry.booking_date && ref.date > entry.booking_date
    end
    def same_party?(entry, ref)
      left = words(entry.counterparty)
      right = words(ref.debitor_name)
      !left.empty? && !right.empty? && !(left & right).empty?
    end
    def words(str)
      str.to_s.downcase.split(/[^[[:alpha:]]]+/).reject { |word|
        word.size < 3 || NOISE.include?(word)
      }
    end
    def money(entry)
      sprintf('%s %.2f', entry.currency, entry.amount.to_f)
    end
    def format_cents(total)
      sprintf('%.2f', total / 100.0)
    end
  end
end
