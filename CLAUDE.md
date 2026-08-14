# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Rails 8.1 · Ruby 3.4 · PostgreSQL 16 · TailwindCSS 4 · Propshaft + Importmap.
A niche classifieds portal for the off-road world (4x4s, trail bikes, UTVs, parts).

## Everything runs in Docker

**There is no Ruby, Bundler, or PostgreSQL on the host** — `ruby -v` fails, and `sudo`
requires a password. Every command must go through the `web` container.

```bash
docker compose up                      # starts the app (bin/dev) on :3000
docker compose exec web <command>      # against the running container
docker compose run --rm web <command>  # one-off, when the stack is down
```

Services: `web` :3000 · `db` :5432 · `pgadmin` :5050 · `minio` :9000 (console :9001) · `mailhog` :8025.
`Dockerfile.dev` is the development image; the root `Dockerfile` is Rails' production one.
Containers run as uid/gid 1000 so generated files stay editable on the host.

**Two restart triggers that produce misleading errors:**

| Change | Symptom | Fix |
| --- | --- | --- |
| Added a gem | `LoadError: cannot load such file` | `docker compose restart web` |
| Added a new directory under `app/` | `NameError: uninitialized constant` | `docker compose restart web` |

Both happen because the long-running `bin/dev` process resolved its bundle and its
`app/*` autoload paths at boot.

## Commands

```bash
# tests
docker compose exec web bin/rspec
docker compose exec web bin/rspec spec/models/listing_spec.rb
docker compose exec web bin/rspec spec/models/listing_spec.rb:42   # single example
docker compose exec web bin/rspec --only-failures

# quality
docker compose exec web bin/rubocop
docker compose exec web bundle exec reek app lib                   # paths REQUIRED
docker compose exec web bin/brakeman --no-pager
docker compose exec web bin/bundler-audit check --update

# database
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails db:seed                          # idempotent
docker compose exec -e RAILS_ENV=test web bin/rails db:prepare
```

`reek` with no path argument **reads from STDIN and exits 0 having analysed nothing** —
silently useless in scripts and CI. Always pass `app lib`.

CI lives in two places doing the same work: `.semaphore/semaphore.yml` and
`.github/workflows/ci.yml`. Changes to the test or lint commands must land in both.

## Conventions that are easy to get wrong

**Routes are Portuguese, code is English.** `/anuncios`, `/entrar`, `/cadastrar` map to
`ListingsController`, `SessionsController`, `RegistrationsController`. Comments, locale
values, and spec descriptions are Portuguese; class and method names are English.

**Locale keys must be added to both `config/locales/pt-BR.yml` and `en-US.yml`.**
Several request specs assert `response.body` does not include `"translation missing"`,
so a one-sided key fails the suite.

**`I18n.available_locales` has three entries, but only two are offered.** `:en` exists
purely as the fallback base that `en-US` decomposes to, and is where `rails-i18n` and
`faker` keep their data. The user-selectable list is
`ApplicationController::SUPPORTED_LOCALES` (`pt-BR`, `en-US`); `?locale=en` falls back to
the default. Removing `:en` from `available_locales` breaks Faker in the whole test suite.

**Taxonomy is translated, user content is not.** Category names, badge labels, and
specification labels live in the locale files keyed by slug (`categories.veiculos-4x4.name`,
`listings.specifications.mileage_km`). Listing titles, cities, and advertiser names are
user content: they stay literal in the database.

**Money is always integer cents** (`price_cents`, `amount_cents`), with `>` 0 check
constraints in the database, not just model validations. `Listing#price` and
`Proposal#amount` convert to BigDecimal reais for display.

## Architecture

### Domain

`Category` (slug + position only — display text comes from locales) → `Listing` → `Proposal`.
`Advertiser` owns listings **and is the authenticated identity**; `Session` is one active
login. There is no separate `User` model.

`Listing#specifications` is `jsonb` because specs vary by category (a 4x4 has a gearbox, a
part has a material). **jsonb does not preserve key order**, so display order comes from
`Listing::SPECIFICATION_ORDER`, never from the stored hash.

### Query objects, not gems

`app/queries/` holds `ListingFilter` (URL params → `Listing` scope) and `Pagination`
(offset paging, hand-written rather than pulling in a gem). The project's bias is to write
small objects instead of adding dependencies — follow it before reaching for a gem.

`ListingFilter` only accepts `sort` values present in its `SORTS` hash; unknown input falls
back to the default and is never interpolated into SQL. It also **drops a `city` that does
not belong to the selected `state`**, so the user gets the state's results instead of an
unexplained empty list.

### Authentication (`app/controllers/concerns/authentication.rb`)

Rails 8's generated session pattern applied to `Advertiser` instead of a `User`. Session
row in the database, id in a signed cookie (`httponly`, `same_site: :lax`, `secure` in
production).

**The default is deny.** `ApplicationController` includes the concern, which adds a global
`before_action :require_authentication`. Public controllers opt out explicitly with
`allow_unauthenticated_access`. A new controller is protected unless it says otherwise —
do not remove the global filter to make something public.

`Advertiser` normalizes input before validating: email is downcased, and phone is stored as
digits with country code (`(41) 98877-0011` → `5541988770011`) because that is what the
`wa.me` link requires. The country-code heuristic keys on **length, not prefix** — 10–11
digits means area code + number — because `55` is also the area code for Santa Maria (RS).

### Storage and mail

Photos are Active Storage backed by MinIO. Development uses
`config.active_storage.resolve_model_to_route = :rails_storage_proxy` because the container
endpoint (`http://minio:9000`) is not resolvable from the host browser; proxying keeps
image URLs on `localhost:3000`. Variants need `libvips`, installed in `Dockerfile.dev`.

`db/seeds.rb` generates placeholder PNGs through `lib/placeholder_image.rb`, which writes
the file byte by byte with `Zlib` — no image gem, no binary assets in the repo.

All development mail is captured by MailHog; nothing reaches a real address.
**Mailers do not inherit application helpers the way controllers do** — `ApplicationMailer`
declares `helper ListingsHelper` so `listing_price` resolves in mail templates. A missing
helper here fails inside an async job, so the request still returns 302 and the only
evidence is the log.

## Testing

RSpec replaced Minitest; there is no `test/` directory and `bin/rails test` does not work.

**Mocks are Mocha, not rspec-mocks** (`config.mock_with :mocha` in `spec/spec_helper.rb`).
`Foo.expects(:bar)` and `obj.stubs(:baz)` work; `double`, `instance_double`, and
`allow(...).to receive` **do not exist**. `spec/support/active_job_matchers.rb` exists
solely because `have_enqueued_mail` needs one class from rspec-mocks that is otherwise
never loaded — expect similar friction from other rspec-rails matchers.

**No spec reaches the real network.** WebMock blocks it and VCR records cassettes into
`spec/fixtures/vcr_cassettes`. Because VCR is hooked into WebMock, an unstubbed request
raises `VCR::Errors::UnhandledHTTPRequestError`, **not** `WebMock::NetConnectNotAllowedError`.

Factories use real category slugs via traits (`create(:category, :vehicles)`). The default
factory generates a sequenced slug that has no translation, which will trip the
"no translation missing" assertions in request specs.

`spec/system/` is empty but must keep existing: `.github/workflows/ci.yml` runs
`bundle exec rspec spec/system` as its own job, and RSpec errors on a missing directory.

## Known wart

`docker-compose.yaml` sits next to `compose.yaml` — an untracked, stale duplicate created
outside this history. Compose warns about it on every command and uses `compose.yaml`.
`compose.yaml` is the versioned one; the duplicate is safe to delete.
