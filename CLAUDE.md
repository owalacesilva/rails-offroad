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
docker compose exec web bin/rspec spec/models/ad_spec.rb
docker compose exec web bin/rspec spec/models/ad_spec.rb:42   # single example
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
`AdsController`, `SessionsController`, `RegistrationsController`. Comments, locale
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
`ads.specifications.mileage_km`). Ad titles, cities, and user names are
user content: they stay literal in the database.

**Money is `DECIMAL(12,2)` in reais** (`ads.price`, `proposals.offered_value`), with `> 0`
check constraints in the database, not just model validations. There are no `_cents`
columns — the form takes reais and `Proposal#offered_value=` only swaps a decimal comma
for a dot before Rails casts it.

**Every primary key is a UUID** (`gen_random_uuid()`), including join and moderation
tables. A spec that hardcodes an integer id will not match anything.

**`Admin` is a model, so the controller namespace is `Moderation`.** A Ruby constant cannot
be both a class and a module, so `app/controllers/moderation/` holds the backoffice while
`namespace :admin, module: "moderation"` keeps the URLs at `/admin` and the helpers at
`admin_*`. Because the controller path no longer matches the locale scope, those controllers
use **explicit** i18n keys (`t("admin.sessions.create.success")`), never lazy `t(".success")`.

**The password column is `password_hash`, not `password_digest`.** `User` and `Admin` both
declare `alias_attribute :password_digest, :password_hash` so `has_secure_password` finds
it. Drop the alias and authentication breaks with a confusing missing-method error.

## Architecture

### Domain

`Category` (slug + position only — display text comes from locales) → `Ad` → `Proposal`.
`User` owns ads **and is the authenticated identity**; `Session` is one active login.
`Admin` is a second, entirely separate identity that only moderates — it never advertises.

`Ad` also has `AdImage` (ordered photos) and, through `TechnicalSpecValue`, the EAV
specifications described below.

**A proposal has no required sender account.** `proposals.user_id` is nullable: anyone can
send an offer without signing in, and the name/email/phone are captured on the proposal row
itself. When the sender happens to be logged in, the controller links them.

### Moderation

`ads.status` is a string enum — `draft`, `pending`, `approved`, `rejected` — with a database
check constraint. **Only `approved` ads are public**: `Ad.published` is the scope every
public controller and `AdFilter` starts from, so a new ad is invisible until a
moderator clears it. `Ad#approve` records `admin_id` and `reviewed_at` and stamps
`published_at`; `Ad#reject` records the review without publishing.

Both return `false` instead of raising, because **an approved ad must carry 3 to 10 photos**
(`Ad::IMAGE_COUNT`) and the queue has to show that failure rather than 500. The validation
is skipped unless the ad is approved, so a draft can be incomplete.

### Specifications are EAV, not jsonb

`attributes` (model `SpecAttribute` — the constant cannot be `Attribute`, which collides
with `ActiveModel::Attribute`) defines the vocabulary: `name`, `data_type`, `is_required`
and `position`. `technical_spec_values` holds one row per ad/attribute pair with a
**composite primary key** `(ad_id, attribute_id)`, which is what stops an ad repeating an
attribute.

Values are always stored as text; `TechnicalSpecValue#typed_value` casts on read using the
attribute's `data_type` and falls back to the raw string when the value does not convert.
Display order comes from `attributes.position`, so adding a spec no longer means editing a
constant in the model.

### Query objects, not gems

`app/queries/` holds `AdFilter` (URL params → `Ad` scope) and `Pagination`
(offset paging, hand-written rather than pulling in a gem). The project's bias is to write
small objects instead of adding dependencies — follow it before reaching for a gem.

`AdFilter` only accepts `sort` values present in its `SORTS` hash; unknown input falls
back to the default and is never interpolated into SQL. It also **drops a `city` that does
not belong to the selected `state`**, so the user gets the state's results instead of an
unexplained empty list.

### Authentication

Two parallel, deliberately independent mechanisms:

`app/controllers/concerns/authentication.rb` is Rails 8's generated session pattern applied
to `User`. Session row in the database, id in the signed `session_id` cookie (`httponly`,
`same_site: :lax`, `secure` in production).

`app/controllers/concerns/admin_authentication.rb` is the same shape for `Admin`, with its
own `admin_sessions` table and its own `admin_session_id` cookie. **A user session is not an
admin session and never grants moderation.** `Moderation::BaseController` calls
`allow_unauthenticated_access` to drop the user filter and then includes the admin concern.

**The default is deny.** `ApplicationController` includes the user concern, which adds a
global `before_action :require_authentication`. Public controllers opt out explicitly with
`allow_unauthenticated_access`. A new controller is protected unless it says otherwise —
do not remove the global filter to make something public.

`User` normalizes input before validating: email is downcased, and phone is stored as
digits with country code (`(41) 98877-0011` → `5541988770011`) because that is what the
`wa.me` link requires. The country-code heuristic keys on **length, not prefix** — 10–11
digits means area code + number — because `55` is also the area code for Santa Maria (RS).

The 27-state whitelist is enforced twice: `User::BRAZILIAN_STATES` in the model and a check
constraint on `users.state`, so a direct SQL write cannot slip past it.

### Storage and mail

Photos are plain rows in `ad_images`: a `file_url` and a `sort_order`, no blobs, no
variants, no Active Storage. Ordering is explicit, which is exactly what Active Storage
could not give. Nothing resizes an upload — `file_url` is taken as-is.

`db/seeds.rb` generates placeholder PNGs through `lib/placeholder_image.rb`, which writes
the file byte by byte with `Zlib` — no image gem, no binary assets in the repo — and drops
them in `public/seed-images/` for `file_url` to point at.

All development mail is captured by MailHog; nothing reaches a real address.
**Mailers do not inherit application helpers the way controllers do** — `ApplicationMailer`
declares `helper AdsHelper` so `ad_price` resolves in mail templates. A missing
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

**`create(:ad)` is approved and builds 3 photos**, because approved is the only status the
portal shows and the photo count is validated. Use the `:pending`, `:draft` or `:rejected`
traits (all of which set `image_count` to 0) for moderation specs, or pass `image_count:`
to exercise the bounds. Specifications come from the `:with_specs` trait, which takes a
`specs:` hash and creates the `SpecAttribute` rows behind it.

**`Ad.delete_all` raises**; `ad_images` and `technical_spec_values` hold foreign keys and
the cascade lives in the model, so use `destroy_all`.

**Reek is a hard CI gate** (`bundle exec reek app lib`, exit 2 on any warning) and
`.reek.yml` excludes classes *by name* — renaming a class without updating the exclude list
turns a green build red.

`spec/system/` is empty but must keep existing: `.github/workflows/ci.yml` runs
`bundle exec rspec spec/system` as its own job, and RSpec errors on a missing directory.

## Known warts

`docker-compose.yaml` sits next to `compose.yaml` — an untracked, stale duplicate created
outside this history. Compose warns about it on every command and uses `compose.yaml`.
`compose.yaml` is the versioned one; the duplicate is safe to delete.

**MinIO and Active Storage are now dead weight.** Photos moved to the `ad_images` table, so
nothing attaches or reads a blob any more, but the `minio` service still starts and
`config.active_storage.*` is still set in all three environments. None of it is wired to
anything — removing the service, the config and the gem is safe whenever someone wants to.
