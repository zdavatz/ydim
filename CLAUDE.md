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
call (`create_invoice`, `add_items`, `send_invoice`, `debitors`, `collect_garbage`, …) is a
public method there. Adding a client-callable operation means adding it to `RootSession`.
`Client#method_missing` forwards everything to the session, so clients need no stubs.

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
