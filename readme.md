# ydim

* https://github.com/zdavatz/ydim.git

## DESCRIPTION:

ywesee distributed invoice manager, Ruby.

A DRb daemon (`ydimd`) that keeps debitors, invoices and recurring auto-invoices in a
PostgreSQL database via ODBA, renders invoices as PDF and mails them out. Clients talk to
the daemon over `druby://` and authenticate with a DSA key.

## Install Ruby

* git clone https://github.com/rbenv/rbenv.git ~/.rbenv
* echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.bashrc
* git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build

Tested against Ruby 3.0, 3.1 and 3.2 (see `.github/workflows/ruby.yml`).

## Install Postgresql
```
* sudo apt-get install postgresql-10 postgresql-contrib-10
* wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
* sudo echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/postgresql-pgdg.list &gt; /dev/null
* sudo apt-get install postgresql-10
* sudo -u postgres psql -c 'create role ydim;'
* sudo su
* su - postgres
* dropdb ydim
* createdb ydim
* -> check DB
* psql
*  \l
* bzcat 22:00-postgresql_database-ydim-backup.bz2 | sudo -u postgres psql -p 5433 ydim
```

`set_initial_ydim_db.sql` creates the ODBA schema for an empty database. The
`get_db_ydim` script fetches the nightly dump from the backup host and restores it locally.

## INSTALL:

* gem install ydim

If you have a non standard path of postgres use something like

* gem install pg -- --with-pg-config=/usr/local/pgsql-10.1/bin/pg_config

Or if you are using bundler

* bundle config build.pg --with-pg-config=/usr/local/pgsql-10.1/bin/pg_config
* bundle install

## CONFIGURATION:

All server side configuration is read from `/etc/ydim` (since version 1.1.4/1.1.5):

* `/etc/ydim/ydimd.yml` — the daemon (database, SMTP, VAT rate, invoice numbering, log level).
  Defaults are in `lib/ydim/server_config.rb`.
* `/etc/ydim/ydim.yml` — the client (`server_url`, `private_key`, currency, payment period).
  Defaults are in `lib/ydim/config.rb`.
* `camt_accounts` (in both files) — the IBANs ydim invoices are paid into, used by
  `ydim-camt`. See *Checking payments* below.
* `/etc/ydim/conf/` — key material, e.g. the `root_dsa` public key used to authenticate.
* `~/.pdfinvoice/config.yml` or `/etc/pdfinvoice/config.yml` — creditor address, bank
  details, logo and texts of the generated PDF. Defaults are in `lib/pdfinvoice/config.rb`,
  and `test/data/config.yml` is a working example.

Any default may also be overridden on the command line, e.g. `--log_level DEBUG`.

## RUNNING:

* Start the daemon: `bundle exec ruby lib/ydim/ydimd` (listens on `druby://localhost:12375`)
* Interactive console against the live database: `bundle exec lib/ydim/ydim-edit`
  (gives you `$server` and the Needle registry as `$needle` inside IRB)
* Create and send an invoice from a YAML description: `bundle exec lib/ydim/ydim-inject < invoice.yml`

The daemon additionally runs three daily jobs: generating and mailing due auto-invoices,
updating currency conversion rates, and refreshing the stored invoice status.

## Checking payments

`ydim-camt` matches the credits on a bank statement against the open invoices. It reads the
ISO-20022 camt.053 files banks provide — the zip downloaded from UBS e-banking, an unpacked
directory, or a single xml:

```
bundle exec lib/ydim/ydim-camt ~/Downloads/statements.zip           # report only
bundle exec lib/ydim/ydim-camt --apply ~/Downloads/statements.zip   # and book them
```

Set `camt_accounts` to the IBAN(s) ydim invoices are paid into, or pass `--account IBAN`.
**This is required.** An e-banking download contains every account the login can see,
including private ones, and a credit there can look exactly like a payment on an invoice.
Rather than reconcile whatever it is given, `ydim-camt` refuses to run without being told
which account is the business one.

Without `--apply` nothing is modified. With it, only invoices whose number the payer wrote
in the remittance information **and** whose amount matches to the cent are marked paid; one
transfer settling several invoices counts when the amounts sum exactly. Everything else —
a payment with no reference, a partial payment, two open invoices over the same amount — is
listed under REVIEW and left to you. Duplicate deliveries of the same statement, debits and
pending entries are skipped and counted in the summary.

Marking a single invoice paid by hand, from `ydim-edit` or any client:

```ruby
$server.mark_paid(13363, Date.new(2026, 7, 10))
```

### Getting the statements without downloading them by hand

UBS e-banking offers no API for statements, so today they are fetched as a zip through the
browser. The automated channel in Switzerland is **EBICS**: order type `Z53` delivers exactly
these camt.053 files in a zip container (`Z52` is camt.052, `Z54` camt.054). UBS offers it
for business accounts as EBICS 3.0, where the classic order types are replaced by Business
Transaction Formats, so the bank has to state the BTF parameters for camt.053 alongside the
usual HostID, URL, partner and user id. Setting it up is a bank contract plus a key
ceremony (INI/HIA, a signed initialisation letter, then HPB) — not an API key.

Whatever fetches them, keep it **outside** ydim. Have it drop the files in a directory and
point `ydim-camt` at that:

```
ebics-fetch          →  /var/ydim/camt/     # separate process, own keys, cron
ydim-camt /var/ydim/camt/
```

That keeps the bank credentials out of the daemon and leaves the parser and reconciler
unchanged. Re-reading statements you have already processed is harmless: entries are
deduplicated by the bank's own `AcctSvcrRef`, and invoices already marked paid are reported
as such rather than booked twice.

Ask the bank to scope the EBICS access to the business account only. An e-banking login
that also sees private accounts will otherwise deliver those too, and while `camt_accounts`
filters them out, statements you never needed should not reach the server in the first place.

## DEVELOPMENT:

```
bundle install
MT_COMPAT=1 bundle exec rake test    # run the whole suite
```

`MT_COMPAT=1` is required because the tests use `flexmock/test_unit`, which needs the
minitest compatibility shim. A single test file or a single test case:

```
MT_COMPAT=1 bundle exec ruby -Ilib -Itest test/test_invoice.rb
MT_COMPAT=1 bundle exec ruby -Ilib -Itest test/test_invoice.rb -n test_add_item
```

`bundle exec rake` (the default task) cleans, runs the tests and builds the gem into `pkg/`.
The test suite needs no database — `test/stub/odba.rb` stubs out ODBA persistence.

## Migrating an old database

An old database can be migrated to UTF-8 by calling

    bundle install --path vendor
    bundle exec ./ydim_migrate_to_utf_8

## DEVELOPERS:

* Masaomi Hatakeyama
* Zeno R.R. Davatz
* Hannes Wyss (up to Version 1.0)
* Niklaus Giger (ported to Ruby 2.3.0)

## LICENSE:

* GPLv2
