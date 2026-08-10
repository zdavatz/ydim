# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`ydim` — ywesee distributed invoice manager. A Ruby gem (GPLv2) providing a DRb daemon that
stores debitors/invoices in PostgreSQL via ODBA, renders PDF invoices, and mails them.
Version lives in `lib/ydim/version.rb`; changes are recorded in `History.txt`.

## Commands

```bash
bundle install                       # gems come from ydim.gemspec via Gemfile
MT_COMPAT=1 bundle exec rake test    # full suite (test/suite.rb); this is what CI runs
MT_COMPAT=1 bundle exec ruby -Ilib -Itest test/test_invoice.rb   # a single test file
MT_COMPAT=1 bundle exec ruby -Ilib -Itest test/test_invoice.rb -n test_add_item  # one test
bundle exec rake                     # default: clobber + test + build gem into pkg/
```

`MT_COMPAT=1` is required — the tests use `flexmock/test_unit`, which needs minitest's
`Minitest::Unit::TestCase` compatibility shim. Without it (or with a too-new
flexmock/minitest) loading a test file dies with `undefined method 'teardown'`.
CI (`.github/workflows/ruby.yml`) runs Ruby 3.0/3.1/3.2 on ubuntu; `.travis.yml` is dead.
`Gemfile.lock` is gitignored — a stale one in the working tree will make `bundle exec` fail
with `Bundler::GemNotFound`; delete it and re-run `bundle install`.

`rake spec` exists (RSpec task) but there are no spec files.

## Architecture

Client/server over **DRb**, authenticated by DSA key challenge (`rrba`), persisted with
**ODBA** (object database over `ydbi`/`ydbd-pg` → PostgreSQL).

**Server side** (`lib/ydim/ydimd` is the daemon entry point, not `bin/`):
`ydimd` wires `ODBA.storage.dbi` to a connection pool, installs `ODBA::DRbIdConv`, then
serves a `YDIM::Server` over `druby://`. `Server#initialize` builds a **Needle registry**
(`@serv`) — the service locator threaded through nearly every class. Registered services:
`:auth_server`, `:clients`, `:config`, `:currency_converter`, `:factory`, `:id_server`,
`:logger`. Anything that takes a `serv` argument (`Factory`, `AutoInvoicer`,
`CurrencyUpdater`) reads its collaborators from this registry, so tests mock `serv` rather
than the individual dependencies.

`Server` also spawns daily background threads via `repeat_at(hour)`: AutoInvoicer,
CurrencyUpdater, and a StatusUpdater that re-saves every invoice so derived `status` stays
current in the DB.

**Session/API surface**: `Server#login` → `RootUser#new_session` → `RootSession` wrapped in
`ODBA::DRbWrapper`. **`RootSession` is the entire remote API** — every method a client can
call (`create_invoice`, `add_items`, `send_invoice`, `debitors`, `collect_garbage`,
`mark_paid`, `reconcile_camt`, …) is a public method there. Adding a client-callable
operation means adding it to `RootSession`. `Client#method_missing` forwards everything to
the session, so clients need no stubs.

**Domain**: `Debitor` (1→n `Invoice` and `AutoInvoice`) → `Item`. `Invoice#status` is
computed, not stored (`is_trash` / `is_paid` / `is_due` / `is_open`). `AutoInvoice` is a
recurring template: `AutoInvoicer#run` walks all debitors daily and, when `auto.date` is
today, calls `Factory#generate_invoice` to materialise a real `Invoice` from it (copying
items, stamping `expiry_time`, applying the current `vat_rate`) and mails it; a month ahead
it sends a reminder instead. `Factory` is the only place invoice IDs are allocated
(`id_server.next_id(:invoice, config.invoice_number_start)`).

**Persistence is declared in one file**: `lib/ydim/odba.rb` reopens the domain classes to
include `ODBA::Persistable`, list `ODBA_SERIALIZABLE` ivars, and declare `odba_index`
(e.g. `Debitor` by email/name/unique_id, `Invoice` by status/unique_id). Those indexes are
what power `find_by_unique_id` / `search_by_status` / `search_by_exact_email` used in
`RootSession`. New persisted classes or lookups must be registered here — and each
`odba_index` needs a matching `ydim_<class>_<attr>` table, see `set_initial_ydim_db.sql`.

**VAT**: `config.vat_rate` (currently 8.1, in `server_config.rb`) is applied when items are
added (`RootSession#add_items`), when autoinvoices are materialised (`Factory`), and reset
by `Invoice#suppress_vat=`. `Debitor#foreign?` (country != `config.home_country`) makes
`Factory` suppress VAT at creation time. Changing the rate touches all of these plus the
`texts.tax` string in pdfinvoice config.

**Payment reconciliation**: `lib/ydim/camt.rb` parses ISO-20022 camt.052/053/054 statements
(rexml only, no DB — the namespace is read off the document root, so any minor version
works), and `lib/ydim/reconciler.rb` matches booked credits against invoices. The CLI
(`ydim-camt`) parses client-side and sends `Camt::Entry` objects to
`RootSession#reconcile_camt`, so the daemon never touches the files. Results carry
`Reconciler::InvoiceRef`, not `Invoice::Info`, so a client can unmarshal them with
`ydim/reconciler` alone instead of loading the whole server.

Three rules that the real UBS data forces and that are easy to break:
- **Filter by IBAN.** An e-banking download holds every account the login sees, private ones
  included; `config.camt_accounts` says which are ydim's, and `Reconciler#reconcile` raises
  rather than run without it.
- **Dedup by `AcctSvcrRef`.** UBS re-sends the same day under a new `MsgId`; in the sample
  set 60 of 142 entries were redeliveries.
- **Whole digit runs only** (`Camt::Entry::TOKEN_PATTERN`) — never a substring, and never a
  run touching a letter. TWINT credits carry the payer's phone number, and bank
  `EndToEndId`s are hex that happens to contain 5-digit sequences.

Only `:exact` and `:split` matches (invoice named *and* amount equal to the cent) are ever
applied; everything else is reported for review.

Fetching the statements is deliberately **not** ydim's job. The automated route is EBICS
(`Z53` is camt.053 in a zip; UBS runs EBICS 3.0, where order types give way to Business
Transaction Formats), and it needs a bank contract, its own keys and an INI/HIA/HPB key
ceremony. Any such fetcher belongs in a separate process that drops files into a directory —
`ydim-camt <dir>` then works unchanged and the bank credentials stay out of the daemon.

That fetcher now exists: **https://github.com/zdavatz/ebics-fetch** (Ruby, GPLv3), written
against the EBICS Working Group's H005 schemas, which it vendors and validates every request
against. Do not reach for a gem instead — `railslove/epics` is EBICS 2.5 only, with no
`Z53`/FDL/BTD and no Swiss banks. Two things it learned the hard way and ydim should not
re-derive: EBICS 3.0 carries keys only as `ds:X509Data` (the `PubKeyValue` of EBICS 2.x is
gone from every H005 schema, so subscribers need self-signed certificates), and the XML
signature uses *inclusive* canonicalization, not the exclusive one most XMLDSig profiles
default to. As of August 2026 it is complete but has never spoken to a real bank — UBS had
not yet delivered the connection parameters.

**PDF**: `lib/pdfinvoice/` is a vendored sub-library (PDF::Writer based) with its own config;
`Invoice#pdf_invoice` maps ydim items onto it and overrides `formats`/`texts.tax` per invoice.

**Mail**: `lib/ydim/mail.rb` configures `::Mail.defaults` with SMTP settings at load time.

## Configuration

Three independent `rclconf` config objects, all merging ARGV over defaults:

| Object | Defaults defined in | YAML read from |
| --- | --- | --- |
| `YDIM::Server.config` (daemon) | `lib/ydim/server_config.rb` | `/etc/ydim/ydimd.yml` |
| `YDIM::Client::CONFIG` | `lib/ydim/config.rb` | `/etc/ydim/ydim.yml` |
| `PdfInvoice.config` | `lib/pdfinvoice/config.rb` | `~/.pdfinvoice/config.yml`, `/etc/pdfinvoice/config.yml` |

Gotcha: `server_config.rb` only builds `CONFIG` with defaults — the YAML file is actually
loaded by the `config.load(config.config)` call at the top of `lib/ydim/mail.rb`, which is
why `mail` is required early in the daemon's require chain. Don't reorder those requires.
Since 1.1.4/1.1.5 all server paths are rooted at `/etc/ydim` by design; keep them there.

## Executables

`bin/ydim-edit` and `bin/ydim-inject` are **byte-identical copies** of `lib/ydim/ydim-edit`
and `lib/ydim/ydim-inject` (the gemspec takes executables from `bin/`, but the working
copies live in `lib/ydim/` — see History.txt 1.0.3). Edit both, or the gem and the checkout
diverge. Note `ydim-edit` carries its own duplicated defaults hash, separate from
`server_config.rb`.

- `ydim-edit` — IRB console with a live `$server` / `$needle` (Needle registry) against the DB.
- `ydim-inject` — reads a YAML invoice on stdin, creates and mails it through a `Client`.
- `ydim-camt` — reconciles a camt.053 zip/directory/file against the open invoices; reports
  by default, books only with `--apply`. Config overrides are RCLConf's `key=value` form,
  not `--key value`, so the OptionParser call filters those out of the file arguments.
- `ydim_migrate_to_utf_8` — one-off LATIN1→UTF-8 DB migration (repo root, not `bin/`).
- `get_db_ydim` — shell script pulling a nightly Postgres dump and restoring it locally.

`install.rb` is a generated setup.rb-style installer; `Manifest.txt` is stale (lists
`bin/ydimd`, `lib/ydim/smtp_tls.rb`, `README.txt` — none exist).

## Testing conventions

Minitest + FlexMock, no DB. `test/stub/odba.rb` replaces `ODBA.transaction` with a plain
yield and `odba_store` with a counter, so tests that touch persistence require it
(`require 'stub/odba'`) *before* the class under test. Tests mock the Needle registry with a
bare `FlexMock` and stub `serv.config` / `serv.logger` individually. `test/suite.rb` just
globs `test_*.rb`; SimpleCov is present but disabled (`if false`).

## Style

Existing code is hard-tabbed in the older files and two-space indented in the newer ones,
often mixed within a single file. Match the surrounding block rather than reformatting.
