#!/usr/bin/env ruby
# encoding: utf-8
# YDIM::Camt -- ydim -- 09.08.2026 -- zdavatz@ywesee.com

require 'date'
require 'fileutils'
require 'rexml/document'
require 'tmpdir'

module YDIM
  # Reader for ISO-20022 bank-to-customer statements (camt.052/053/054), as
  # delivered by UBS and the other Swiss banks. This is pure parsing: no DB and
  # no ODBA, so it can run on the client side. The matching of entries against
  # invoices lives in YDIM::Reconciler.
  module Camt
    class Error < StandardError; end

    # A single booked movement on an account (a camt <Ntry>).
    class Entry
      attr_accessor :account_iban, :account_currency, :amount, :currency,
        :credit, :status, :booking_date, :value_date, :reference,
        :counterparty, :additional_info, :source
      attr_reader :remittance, :end_to_end_ids, :creditor_references
      def initialize
        @remittance = []
        @end_to_end_ids = []
        @creditor_references = []
        @credit = false
      end
      def credit?
        @credit
      end
      # ydim invoices are only ever paid into the ywesee business account --
      # the private accounts share the same e-banking download, so entries have
      # to be filtered by IBAN before anything is matched. An empty filter
      # accepts everything here; refusing to run without one is the
      # Reconciler's job, since only it knows the entries are about to be
      # matched against invoices.
      def account?(ibans)
        ibans = [ibans].flatten.compact
        ibans.empty? || ibans.any? { |iban|
          normalize_iban(iban) == normalize_iban(@account_iban)
        }
      end
      # Only BOOK entries have actually hit the account; PDNG ones can still
      # disappear, so they must never mark an invoice as paid.
      def booked?
        @status.nil? || @status == 'BOOK'
      end
      # Money as an integer so that amounts can be compared without float
      # rounding surprises.
      def amount_cents
        (@amount.to_f * 100).round
      end
      # Every string a payer might have put an invoice number into.
      def texts
        (@remittance + @end_to_end_ids + @creditor_references \
          + [@additional_info]).compact
      end
      # Runs of digits found in the remittance information. Whole runs only --
      # never substrings, or the phone number in a TWINT payment
      # ("+41796723413") would match half the invoices in the database. A run
      # touching a letter is machine noise rather than something a human typed:
      # this drops the hex EndToEndIds that banks generate
      # ("0ebf22116f364fc394da3e2776a05643" would otherwise offer up "22116"),
      # while "RG 13363 VOM 26.6.2026" and "ISO 13368" still yield their
      # invoice number.
      TOKEN_PATTERN = /(?<![0-9A-Za-z])\d+(?![0-9A-Za-z])/
      def numeric_tokens
        texts.flat_map { |text| text.scan(TOKEN_PATTERN) }.uniq
      end
      # Two statements can deliver the same entry (UBS re-sends a day under a
      # new MsgId), so entries are identified by the bank's own reference.
      def dedup_key
        [@account_iban, @reference || texts.join('|'), amount_cents, @credit,
          @booking_date]
      end
      def to_s
        sprintf("%s %s %s %s %s", @booking_date, @credit ? 'CRDT' : 'DBIT',
          @currency, sprintf('%.2f', @amount.to_f), @counterparty)
      end
      private
      def normalize_iban(iban)
        iban.to_s.gsub(/\s+/, '').upcase
      end
    end

    # A camt <Stmt> -- one account over one period.
    class Statement
      attr_accessor :id, :account_iban, :currency, :owner, :created_at,
        :opening_balance, :closing_balance, :source
      attr_reader :entries
      def initialize
        @entries = []
      end
    end

    class << self
      # Reads whatever the bank handed you: a single xml file, a directory of
      # them, or the zip you downloaded from e-banking. Returns Statements.
      def read(path)
        if File.directory?(path)
          read_files(Dir[File.join(path, '**', '*.[xX][mM][lL]')].sort)
        elsif path =~ /\.zip\z/i
          read_zip(path)
        else
          read_files([path])
        end
      end
      def read_files(paths)
        paths.flat_map { |path|
          parse(File.read(path), File.basename(path))
        }
      end
      def read_zip(path)
        Dir.mktmpdir('ydim-camt') { |dir|
          unless system('unzip', '-q', '-o', path, '-d', dir)
            raise Error,
              "unable to unzip #{path} -- extract it and pass the directory"
          end
          read_files(Dir[File.join(dir, '**', '*.[xX][mM][lL]')].sort)
        }
      end
      # Parses one camt document into its Statements.
      def parse(xml, source = nil)
        doc = REXML::Document.new(xml)
        root = doc.root or raise Error, "#{source}: not an XML document"
        # camt.053.001.02 through .08 differ only in the namespace URI for
        # everything we read, so take whatever the document declares.
        ns = { 'c' => root.namespace }
        REXML::XPath.match(doc, '//c:Stmt | //c:Rpt | //c:Ntfctn', ns).collect { |node|
          parse_statement(node, ns, source)
        }
      end
      # All entries of all statements below path, duplicates included -- the
      # Reconciler drops those, and it can only report how many deliveries were
      # doubled up if it gets to see them.
      def entries(path)
        read(path).flat_map { |stmt| stmt.entries }
      end
      def dedup(entries)
        seen = {}
        entries.select { |entry| !seen.key?(entry.dedup_key) \
          && seen[entry.dedup_key] = true }
      end

      private
      def parse_statement(node, ns, source)
        stmt = Statement.new
        stmt.source = source
        stmt.id = text(node, 'c:Id', ns)
        stmt.account_iban = text(node, 'c:Acct/c:Id/c:IBAN', ns)
        stmt.currency = text(node, 'c:Acct/c:Ccy', ns)
        stmt.owner = text(node, 'c:Acct/c:Ownr/c:Nm', ns)
        stmt.created_at = date(text(node, 'c:CreDtTm', ns))
        stmt.opening_balance = balance(node, ns, 'OPBD')
        stmt.closing_balance = balance(node, ns, 'CLBD')
        REXML::XPath.each(node, 'c:Ntry', ns) { |entry_node|
          stmt.entries.push(parse_entry(entry_node, ns, stmt))
        }
        stmt
      end
      def parse_entry(node, ns, stmt)
        entry = Entry.new
        entry.source = stmt.source
        entry.account_iban = stmt.account_iban
        entry.account_currency = stmt.currency
        amount = REXML::XPath.first(node, 'c:Amt', ns)
        entry.amount = amount && amount.text.to_f
        entry.currency = (amount && amount.attributes['Ccy']) || stmt.currency
        entry.credit = text(node, 'c:CdtDbtInd', ns) == 'CRDT'
        entry.status = text(node, 'c:Sts/c:Cd', ns) || text(node, 'c:Sts', ns)
        entry.booking_date = date(text(node, 'c:BookgDt/c:Dt', ns) \
          || text(node, 'c:BookgDt/c:DtTm', ns))
        entry.value_date = date(text(node, 'c:ValDt/c:Dt', ns) \
          || text(node, 'c:ValDt/c:DtTm', ns))
        entry.reference = text(node, 'c:AcctSvcrRef', ns) \
          || text(node, 'c:NtryRef', ns)
        entry.additional_info = text(node, 'c:AddtlNtryInf', ns)
        # The party on the other side: for money coming in that is the debtor,
        # for money going out the creditor. Either can be given as a name or as
        # loose address lines.
        side = entry.credit? ? 'Dbtr' : 'Cdtr'
        entry.counterparty = collect(node,
          ".//c:#{side}/c:Pty/c:Nm | .//c:#{side}/c:Pty/c:PstlAdr/c:AdrLine",
          ns).first
        # An entry can bundle several transactions (a batch booking), so the
        # remittance information of all of them counts.
        entry.remittance.concat(collect(node, './/c:RmtInf/c:Ustrd', ns))
        entry.remittance.concat(collect(node, './/c:Strd/c:AddtlRmtInf', ns))
        entry.end_to_end_ids.concat(collect(node, './/c:EndToEndId', ns)\
          .reject { |id| id == 'NOTPROVIDED' })
        entry.creditor_references.concat(
          collect(node, './/c:CdtrRefInf/c:Ref', ns))
        entry
      end
      def balance(node, ns, code)
        amount = REXML::XPath.first(node,
          "c:Bal[c:Tp/c:CdOrPrtry/c:Cd='#{code}']/c:Amt", ns)
        amount && amount.text.to_f
      end
      def collect(node, path, ns)
        REXML::XPath.match(node, path, ns).collect { |el|
          el.text.to_s.strip
        }.reject { |str| str.empty? }.uniq
      end
      def text(node, path, ns)
        el = REXML::XPath.first(node, path, ns)
        str = el && el.text.to_s.strip
        str unless str.nil? || str.empty?
      end
      def date(str)
        Date.parse(str) if str
      rescue ArgumentError
        nil
      end
    end
  end
end
