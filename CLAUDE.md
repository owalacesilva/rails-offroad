# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Rails 8.1 · Ruby 3.4 · MySQL 8.4 · TailwindCSS 4 · Propshaft + Importmap.
A niche classifieds portal for the off-road world (4x4s, trail bikes, UTVs, parts).

## Everything runs in Docker

**There is no Ruby, Bundler, or MySQL on the host** — `ruby -v` fails, and `sudo`
requires a password. Every command must go through the `web` container.

```bash
docker compose up                      # starts the app (bin/dev) on :3000
docker compose exec web <command>      # against the running container
docker compose run --rm web <command>  # one-off, when the stack is down
```

Services: `web` :3000 · `db` :3306 · `phpmyadmin` :5050 · `minio` :9000 (console :9001) · `mailhog` :8025.
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
docker compose exec web bin/rails cities:import                    # only the municipalities
docker compose exec web bin/rails active_storage:purge_unattached # abandoned upload blobs
docker compose exec -e RAILS_ENV=test web bin/rails db:prepare
```

`reek` with no path argument **reads from STDIN and exits 0 having analysed nothing** —
silently useless in scripts and CI. Always pass `app lib`.

**`db/seeds.rb` returns immediately under `RAILS_ENV=test`.** This is load-bearing, not a
preference: `db:prepare` runs the seed file by itself whenever it *creates* the database,
which is exactly what CI does before RSpec. Without the guard the suite would start with
4 categories, 8 users, 36 ads and 5,571 cities already committed — outside any test
transaction — and every spec that counts records or builds a category with a known slug
would fail on a collision. Specs build what they need with factories; to populate a test
database deliberately, call the loader directly (`cities:import`).

CI lives in two places doing the same work: `.semaphore/semaphore.yml` and
`.github/workflows/ci.yml`. Changes to the test or lint commands must land in both.

## Conventions that are easy to get wrong

**Routes are Portuguese, code is English.** `/anuncios`, `/entrar`, `/cadastrar` map to
`AdsController`, `SessionsController`, `RegistrationsController`. Comments, locale
values, and spec descriptions are Portuguese; class and method names are English.

The advertiser dashboard is scoped under **`/anunciante`** while its helpers stay
`account_*` (`account_path` → `/anunciante`, `account_ads_path` → `/anunciante/anuncios`).
`spec/requests/account_prefix_spec.rb` is the only place that asserts the literal prefix —
everything else goes through the helpers, so without it a prefix change is invisible.
The four institutional routes follow the same split: `/sobre-nos`, `/como-anunciar`,
`/politica-de-privacidade` and `/termos-de-uso` map to `PagesController#about`,
`#how_to_advertise`, `#privacy` and `#terms`.

**The `POST /anunciante/anuncios` route is declared `as: nil`.** It shares its path with
the `GET`, so without that Rails would invent an `anuncios_path` helper out of the
Portuguese segment — a route helper in the wrong language.

**Mail templates are locale keys too.** `UserMailer#confirmation` and `ProposalMailer` render
an HTML *and* a text part, and a spec asserts the text part carries the link — a mail client
that shows only text does not render the anchor.

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
`ads.specifications.mileage_km`). Ad titles, cities, event titles, and user names are
user content: they stay literal in the database.

**The institutional pages are locale data, not templates.** `pages.about`,
`pages.how_to_advertise`, `pages.privacy` and `pages.terms` each hold a `title`, a `lead`
and a `sections` array of `{heading, body}`; `steps`, `items`, `cta` and `updated` are
optional and simply do not render where absent. `app/views/pages/_document.html.erb`
assembles all four, so a new section is a YAML entry in both locale files — never ERB.
`body` uses `\n\n` for paragraph breaks and goes through `simple_format`.
"Last updated" comes from `PagesController::LAST_UPDATED_ON`, not from the locale, so the
two languages cannot drift apart on the date.

**Money is stored in integer cents** — `ads.price_cents` and
`proposals.offered_value_cents`, both `int` (the "int(11)" of the data dictionary; MySQL
8.4 stopped printing the display width, but it is the same four-byte signed integer, good
to R$ 21.474.836,47). Both carry `> 0` check constraints in the database, not just model
validations.

**The application still speaks reais everywhere.** `Ad#price` and `Proposal#offered_value`
are hand-written accessors over the `_cents` columns, and every view, form and spec uses
them; `ApplicationRecord.to_cents` / `.to_amount` are the only places the two units meet.
Validations sit on the reais reader, not the cents column, so the error message talks about
the number the person typed. Text that does not convert comes back out of the reader
unchanged (`ApplicationRecord.amount_or_input`) — that is what stops the form returning
with an emptied field after a validation error, which `_before_type_cast` used to do.

**Every primary key is a `bigint`.** They were `VARCHAR(36)` UUIDs generated in an
`ApplicationRecord` `before_create`; that hook is gone and the database assigns ids again.
`spec/models/schema_spec.rb` asserts it across every table, so a new migration that
reintroduces a string key fails the suite rather than passing unnoticed.

**An ad is addressed by its slug, not its id.** `ads.slug` is derived from the title
(`parameterize`, with a `-2`, `-3` suffix on collision) in a `before_validation`, and
`Ad#to_param` returns it — so every route helper puts the slug in the URL and every lookup
must be `find_by!(slug: params[:id])`, including the moderation queue. `Ad.find(params[:id])`
now silently means "id 0" on MySQL. The slug is generated once and never regenerated:
renaming a published ad must not break links already out in the world.

**`users.status` is `active` / `inactive` / `blocked`**, with an enum and a check
constraint. It reaches three places, and all three matter: login refuses anyone not active,
`Authentication#find_session_by_cookie` joins `User.active` so blocking someone ends the
session they already have open, and `Ad.published` filters by `User.active` so their ads
leave the catalog without touching a single ad row. The login failure message is
deliberately the same one a wrong password gets — saying "your account is blocked" to
someone who merely guessed an address confirms that the address exists.

**The default collation is case-insensitive** (`utf8mb4_0900_ai_ci`). Unique indexes and
every `where` on a string follow it, so `Category#slug` and `SpecAttribute#name` validate
uniqueness with `case_sensitive: false` — the model must not promise a distinction the
database does not make. Ordering follows MySQL too: `NULL` sorts as the smallest value, so
`AdFilter`'s `year_desc` needs no `NULLS LAST` clause to keep year-less parts at the end.

**`Admin` is a model, so the controller namespace is `Moderation`.** A Ruby constant cannot
be both a class and a module, so `app/controllers/moderation/` holds the backoffice while
`namespace :admin, module: "moderation"` keeps the URLs at `/admin` and the helpers at
`admin_*`. Because the controller path no longer matches the locale scope, those controllers
use **explicit** i18n keys (`t("admin.sessions.create.success")`), never lazy `t(".success")`.

**The password column is `password_hash`, not `password_digest`.** `User` and `Admin` both
declare `alias_attribute :password_digest, :password_hash` so `has_secure_password` finds
it. Drop the alias and authentication breaks with a confusing missing-method error.

## Front end

**One theme: light.** There is no dark mode and no `dark:` variant anywhere. Both the
`color-scheme: light` declaration in `app/assets/tailwind/application.css` and the
`<meta name="color-scheme" content="light">` in every layout are load-bearing — without
them a browser in dark mode repaints native controls (`select`, `input`, scrollbars) and a
light page shows up with black fields. The dark tokens that remain are deliberate: badges
floating **over photos** (`bg-stone-950/80`), the modal backdrop, active filter pills, and
the home hero, which is a banner meant to hold a photograph.

**Montserrat is self-hosted.** Two variable `woff2` files (latin, latin-ext) live in
`app/assets/fonts/`; `@font-face` sits in the Tailwind entry file and Propshaft rewrites
the relative `url()` into the digested path. Nothing is fetched from a third party — which
is what the Privacy Policy page promises, and what makes the font work offline. Changing
`--font-sans` in `@theme` changes the whole portal, because Tailwind's preflight pulls the
`html` family from it.

**The "Anunciar" button pulses.** `animate-pulse-slow` comes from `--animate-pulse-slow`
plus a `@keyframes` block inside `@theme`, with a `prefers-reduced-motion` override outside
any layer so it wins without `!important`. The button uses `transition-colors`, not
`transition`: the animation already drives `transform`, and transitioning the same property
on hover makes the two fight. Tailwind tree-shakes the keyframes, so the rule only appears
in the build while some template still carries the class.

### Shared form furniture

Four partials in `app/views/shared/` carry the field decorations, and every form uses them
instead of rolling its own — a hand-built field is a field that will drift.

| Partial | Where | Gotcha |
| --- | --- | --- |
| `_leading_icon` | every email field | wraps the field via `render layout:`; the **caller** adds the `pl-*` that keeps the text off the icon |
| `_money_field` | `ad.price`, `proposal.offered_value` | the `R$` select carries **no `name` and no `id`** — it is not submitted, and the model still converts reais to the integer column |
| `_url_field` | `event.url`, `_cover_field` | the `https://` add-on is functional, not decoration (below) |
| `_city_select` | every city field | see below |

`_money_field` and `_url_field` take a form builder; `_leading_icon` and `_city_select` do
not — `_city_select` takes `name`/`value`/`label`, because the vitrine filter is a bare
`form_with url:` with no object.

**The `https://` add-on writes through the model.** `ApplicationRecord.with_http_scheme`
completes a missing scheme, and `Event#url=`, `Event#image_url=` and `Post#cover_url=` call
it, so `exemplo.com.br/evento` is stored as a real URL. It leaves anything that already has
a scheme alone — **including one the validation rejects**. Completing `javascript:alert(1)`
into `https://javascript:alert(1)` would sneak it past the http(s) validation that exists to
block it. `URL_SCHEME` ends in `(?!\d)` so `exemplo.com.br:8080` still counts as
scheme-less, because there the colon opens a port.

**City is a menu with its own search, not a `<datalist>`.**
`city_select_controller.js` hides the real text field and drives a button plus a panel; the
value never leaves `ads.city` / `users.city` / `events.city`, and with JS off the plain text
field is what remains. Two sources, chosen by whether `remote` is set: the forms fetch
`/municipios` per UF (`CitiesController::LIMIT`, capped so São Paulo's 645 do not descend at
once), while the vitrine filter embeds its options — there the list is *the cities that have
an ad*, not the 5.571 of the country.

The UF `select` and the city menu are **siblings, not parent and child**, so Stimulus scope
cannot connect them: the select is marked `data-city-select-state` and the controller finds
it with `closest("form")`. A new form with a city field must mark its UF select or the menu
never populates.

The hidden field is hidden with **`sr-only`, never `hidden`/`display:none`**. A `required`
field that is not focusable makes Chrome refuse to submit in silence — the same trap as
`required` inside a closed `<dialog>`. Clipped, it still validates and still shows the
native message.

### Pagination lives in a card footer

`shared/_pagination` renders a footer band — the "showing X–Y of Z" count on the left, the
page buttons on the right — and owns that count, which is why no listing prints it a second
time above the grid. `standalone: true` wraps the band in its own card (the vitrine and the
blog, whose content is a loose grid); without it the band closes a card that is already open
(the advertiser table). The key is `shared.pagination.showing`, not `ads.pagination.*`.

### Menu items all carry an icon

`IconHelper::UI_ICONS` holds the interface icons, and `dropdown_link` / `dropdown_button`
build a menu row from a path, an icon and a block. Every row in the three header menus takes
one, **including the language options**: `dropdown_item_class` sets `gap-3`, so a row without
an icon starts a column to the left of every other row and the menu reads as broken.
`dropdown_separator_class` adds the rule that opens a new block within a menu.

### The ad form

`app/views/dashboard/ads/new.html.erb` carries four Stimulus controllers and is the most
JavaScript in the project. Things worth knowing before editing it:

**`ad.description` is HTML now, sanitized on write.** `Ad#description=` runs
`Rails::HTML5::SafeListSanitizer` against `Ad::DESCRIPTION_TAGS` — the five editor controls
and the blocks they emit, with **no attributes at all**. Cleaning on the way in means the
column only ever holds allowed markup. Render it with `AdsHelper#ad_description`, never
`simple_format` directly: plain-text descriptions (every seeded ad, and anything typed with
JS off) still exist, and the helper tells them apart by looking for a `<` — after
sanitizing, a literal `<` can only be a tag, because text `<` came back as `&lt;`. Plain
text goes through `simple_format(..., sanitize: false)`; sanitizing it twice would turn
`&amp;` into `&amp;amp;`.

The `.ad-description` class in `app/assets/tailwind` is what gives those tags shape — the
Tailwind reset strips heading sizes and list markers, and there is no way to hang a utility
class on markup the editor generated. The same class dresses the editor itself.

**The editor is `contenteditable` + `document.execCommand`.** Obsolete on paper, with no
implemented replacement; it is what the off-the-shelf editors still run on. The `<textarea>`
stays the real form field — the controller hides it and mirrors the HTML into it — so the
form still posts with JS off.

**Photo upload is JS-only, deliberately.** The submit button ships `disabled` and only the
photo controller unlocks it, once `Ad::IMAGE_COUNT.min` photos are up. Without JS there is
no way to send a file anyway, so the form says so instead of pretending.

**`PhotoUpload` is the last word on image limits**, shared by the advertiser's ad photos and
the moderator's covers — same dimensions, same byte cap, same libvips check, different
session. Its constants are what the ad form reads (`PhotoUpload::MAX_WIDTH`), and its
messages live under `uploads.errors.*`.

**`Dashboard::AdPhotosController` applies those limits.** Dropzone resizes to
fit `MAX_WIDTH × MAX_HEIGHT` in the browser before uploading, and never upscales, but the
controller re-measures with libvips and rejects anything over — nothing from a browser
counts as a guarantee. Content type is checked against the header *and* against whether
libvips can open the file at all.

**Category is a radio group painted as badges**, not a `<select>` and not JavaScript: the
inputs are `peer sr-only` and Tailwind's `peer-checked:` styles the label. Keyboard and
screen reader still see an ordinary radio group. `peer-checked:` only reaches siblings of
the input, so the colour lives on the label and the icon inherits it via `currentColor`.

**The rich-text editor is shared.** `shared/_rich_text_field` renders the toolbar,
the contenteditable and the backing `<textarea>` for both the ad description and the post
body; the allowlist behind it is `ApplicationRecord::RICH_TEXT_TAGS`, and
`ApplicationHelper#rich_text` is the matching renderer. Adding a sixth control means
touching the partial, the tag list and `rich_text_controller.js` together — the three are
one feature.

**`shared/_pagination` takes a lambda**, not a path helper: the ads listing has to carry its
filters into every page link and the blog has nothing to carry, so each caller passes
`page_path: ->(page) { ... }`. `paginated_page_numbers` lives in `ApplicationHelper` for the
same reason, and returns `:gap` where the ruler skips — the partial draws those as an
ellipsis. Up to seven pages it lists them all; beyond that it keeps the first, the last and a
window around the current one.

**Specifications are filled in a modal.** All four categories render a block of spec
fields inside one `<dialog>`; `category_specs_controller.js` shows the selected category's
block and **disables** every other, because a disabled field is neither submitted nor
validated by the browser. The same attribute (`condition`) appears in several blocks under
the same `specs[<id>]` name — only the enabled copy travels. A closed `<dialog>` is merely
`display: none`, so its inputs still submit.

**Nothing in that dialog may be `required`.** Chrome refuses to submit a form containing a
required control it cannot focus, and a required field inside a closed dialog is exactly
that — the submit would fail silently with no message anywhere. Completeness is enforced
the same way the photo minimum is: `Ad`'s `:submission` validation decides, and the publish
button stays disabled until `category-specs` reports the set is full.

`submit_controller.js` gates on **two** signals now (photos and specs), each with its own
hint line. It has to be connected before either child dispatches on `connect`, which is why
it is listed first in the form's `data-controller` and why the photo controller sits on a
descendant — both give Stimulus the connection order this depends on.

**Input masks are comfort, never validation.** `mask_controller.js` formats currency
(`45.000,50`, typed as cents) and phone (`(11) 9 8765-4321`, falling back to the 8-digit
landline shape). What actually normalizes is `User.normalize_phone` and
`ApplicationRecord.to_cents`. Money fields are `text_field`, not `number_field` — a number
input rejects `45.000,50` outright.

**Sharing is server-rendered anchors first.** `AdsHelper#ad_share_links` builds the
WhatsApp / Facebook / X / Telegram URLs, so sharing works with JavaScript off;
`share_controller.js` only adds what needs it — `navigator.share` on touch devices and
copy-to-clipboard. It also adds the display class itself rather than toggling `hidden`
against `inline-flex` in the HTML, since which of the two wins depends on the order
Tailwind happens to emit them.

**Ad year may not be in the future** — `less_than_or_equal_to: Date.current.year`. This
tightened an earlier rule of `year + 1`, which existed for the industry's habit of selling
next model year early; a 2027 truck listed in 2026 is now rejected.

**Social links come from the environment**, via `lib/social_links.rb`: `SOCIAL_INSTAGRAM_URL`,
`SOCIAL_YOUTUBE_URL`, `SOCIAL_FACEBOOK_URL`, `SOCIAL_WHATSAPP_URL`. A network with no
variable set disappears from the footer instead of rendering an icon that links to `#`,
so a bare checkout shows no social row at all — that is the intended behavior, not a bug.

## Architecture

### Domain

`Category` (slug + position only — display text comes from locales) → `Ad` → `Proposal`.
`User` owns ads **and is the authenticated identity**; `Session` is one active login.
`Admin` is a second, entirely separate identity that only moderates — it never advertises.

`Ad` also has `AdImage` (ordered photos) and, through `TechnicalSpecValue`, the EAV
specifications described below.

`City` is the one piece of **reference** data: the 5,570 Brazilian municipalities plus
Fernando de Noronha, which IBGE lists alongside them though it is a state district of PE.
It is the only seeded table that also belongs in production, which is why it loads from
`lib/brazilian_cities.rb` and has its own `cities:import` task rather than living only in
`db/seeds.rb`. The data is versioned at `db/cities.csv` so initialization never depends on
the IBGE API being up.

The primary key is a bigint like everywhere else; `ibge_code` is the **natural** key and
carries the unique index, so `import` is an upsert that only touches `name` and `state` —
a municipality renamed by IBGE is corrected without its `id` changing under anything that
already referenced it. The second unique index is `(state, name)`, not `name`: 240 names
repeat across the country (there are five "Bom Jesus"), but none repeats inside one state,
including under the accent- and case-insensitive collation.

`db/cities.csv` is parsed by hand rather than with the `csv` gem — `csv` stopped being a
default gem in Ruby 3.4 and would have to enter the Gemfile, while the file is generated by
us and provably has three flat columns. `BrazilianCities::ROW` is the guard: a line that
does not match raises `InvalidRow` with a `file:line` reference instead of landing crooked
in the database.

**`cities` feeds the city menu**, through `GET /municipios?state=PR&q=curi`
(`CitiesController`, public, JSON, capped at `LIMIT`). It returns names only, because
`ads.city` still stores the name as a string — there is no foreign key, and wiring one up
is a separate change with a data migration for existing rows. The accent- and
case-insensitive collation is what lets `q=sao` find "São Paulo" with no normalized column.

`Post` is the blog: portal content written by the team, so it belongs to an `Admin`
(the author, `NOT NULL`) rather than to a `User`. **There is no status column** —
`published_at` says everything: nil is a draft, a future timestamp is scheduled, a past one
is live. The three admin tabs are exactly the `drafts` / `scheduled` / `published` scopes,
and a spec asserts they partition the table so nothing can hide between them. Only
`published` reaches `/blog` and the home page; a draft or a scheduled post 404s publicly.

`Event` and `NewsletterSubscription` hang off nothing: they are portal content, not an
advertiser's. **Advertisers are managed from `/admin/anunciantes`** — a sortable, paginated table with a
collapsible filter panel (`UserFilter` in `app/queries/`, same shape as `AdFilter`) and
per-row checkboxes driving a bulk status change. Deliberately read-only on personal data:
name, email and phone belong to the advertiser, who edits them in their own profile.
Changing status is the whole point, because `Ad.published` filters by `User.active`, so
blocking one account pulls all of its listings at once.

Three things about that page are easy to break:

- **The checkboxes live outside their form.** A `<table>` cannot sit inside a `<form>` and
  stay valid HTML, so the bulk form is the table's *sibling* and every checkbox carries
  `form="bulk-status-form"`. Wrapping the table in the form renders fine and then submits
  nothing predictable.
- **Filtering by ad count reads `users.ads_count`**, a counter cache maintained by
  `Ad belongs_to :user, counter_cache: true`. Without it, sorting and filtering on the count
  would need a `GROUP BY` that offset pagination has to count twice.
- **`UserFilter#to_params` is what keeps state together.** Sort links, page links and the
  status buttons all round-trip it, so filtering never silently drops the sort and paging
  never drops the filter. The status actions carry it back under `list[...]`.

**Blog and events are both managed from the moderation area** (`Moderation::PostsController`
at `/admin/blog`, `Moderation::EventsController` at
`/admin/eventos`) — full CRUD with no approval queue, because what the portal's own team
publishes is already trusted, unlike an advertiser's ad. The list has two tabs backed by the
`upcoming` and `past` scopes, which partition the table between them; only `upcoming` reaches
the home page. `Event` is the home calendar (`Event.upcoming` uses
`COALESCE(ends_on, starts_on) >= today`, so a three-day meet stays listed on its second
day). **Event and post covers are uploads now**, attached with `has_one_attached :cover_image`
through `Moderation::UploadsController`. The `image_url` / `cover_url` columns survive as a
fallback — the seed still uses them, and an image already hosted elsewhere is still valid —
and the readers prefer the attachment. `CoverAttachment` is what wires the form's
`cover_signed_id` to the record: **absent means "leave it alone", empty means "remove it"**,
which is what lets an edit that only changes the title keep the picture. It purges
synchronously, because `purge_later` enqueues the blob deletion without detaching, and the
cover would keep showing until the job ran.

**One event at a time can be `featured`**, and that one becomes the home page banner
(`Event.banner`, which also requires the event not to have passed). Exclusivity lives in an
`after_save` callback rather than in a method, because the flag is also set straight from
the admin form's checkbox — both paths need the same guarantee.

`Event#external_url` and `#cover_url` whitelist `http(s)` before the card turns them into an
`href` and an `img src`; `Event::HTTP_URL` validates the same thing on write, so the scheme is
checked twice — a row written by hand in SQL still cannot put `javascript:` on the home page.

### Home page section order is a requirement, not a layout choice

Recent ads (12, as **two explicit rows of six**) · photo gallery · most viewed (12) ·
upcoming events (4) · newsletter · photo gallery again. The hero with the search box sits
above all of it; the old "Navegue por categoria" grid was removed, and categories are
reached from the header dropdown and the footer. `spec/requests/home_spec.rb` asserts the
order by slicing the body between section headings — reordering the view fails the suite.

Both galleries are **one query sliced in two** (`HomeController#gallery_photos`), so the
bottom one continues where the top stopped instead of repeating a photo.

**"Most viewed" runs on `ads.views_count`**, a denormalized counter bumped by
`Ad#record_view` in `AdsController#show`. It is an atomic `increment_counter`: no
validation, no callbacks, and deliberately naive — a reload and a bot both count. Unique
visits would need a visits table, which is exactly what the counter avoids. The ordering
falls back to `published_at` so a freshly seeded catalog, where everyone is at zero, is not
left in MySQL's undefined order.

**A proposal has no required sender account.** `proposals.user_id` is nullable: anyone can
send an offer without signing in, and the name/email/phone are captured on the proposal row
itself. When the sender happens to be logged in, the controller links them.

### Moderation

`ads.status` is a string enum — `draft`, `pending`, `approved`, `rejected` — with a database
check constraint. **Only `approved` ads are public**: `Ad.published` is the scope every
public controller and `AdFilter` starts from, so a new ad is invisible until a
moderator clears it. `Ad#approve` records `admin_id` and `reviewed_at` and stamps
`published_at`; `Ad#reject` records the review without publishing.

**Moderation talks back through `ads.moderation_note`.** Rejecting requires a reason (the
queue asks for it in a modal), and the advertiser sees that text on their own listing page.
The same column carries the note when a blocked photo drops an ad below the photo minimum.

**Photos can be blocked individually** — `ad_images.blocked_at`, set from the queue. A
blocked photo disappears from the whole portal: `Ad#visible_images` is what every public
view and `Ad.with_photos` use, and the 3-to-10 validation counts only visible ones. If
blocking leaves an **approved** ad short, `Ad#block_image` sends it back to `pending` with
the note; a draft or rejected ad keeps its status, because promoting it to pending would
undo a decision moderation already made.

Both return `false` instead of raising, because **an approved ad must carry 3 to 10 photos**
(`Ad::IMAGE_COUNT`) and the queue has to show that failure rather than 500. The validation
is skipped unless the ad is approved, so a draft can be incomplete.

### Specifications are EAV, not jsonb

`attributes` (model `SpecAttribute` — the constant cannot be `Attribute`, which collides
with `ActiveModel::Attribute`) defines the vocabulary: `name`, `data_type` and `position`.
`technical_spec_values` holds one row per ad/attribute pair with a **composite primary key**
`(ad_id, attribute_id)`, which is what stops an ad repeating an attribute.

**Which specs an ad must carry is a property of its category, not of the attribute.**
`attribute_categories` joins the two, and being joined *is* the requirement — the ad form
asks for every attribute of the chosen category and `Ad` enforces it in the `:submission`
context. There is no `attributes.is_required` column any more: it was global, so it could
never say "4x4 needs an engine, a part needs a material". An attribute that does not apply
to a category simply is not linked to it.

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

### Email confirmation

**`users.confirmed_at` is a column of its own, not a fourth `users.status`.** The two are
independent: moderation blocks accounts that confirmed long ago, and a confirmed account can
be blocked later. Nil means "has not proved the address is theirs".

**There is no token column.** `User.generates_token_for :email_confirmation` signs the id
together with the email and a two-day window (`User::CONFIRMATION_WINDOW`), so the link
expires on its own and **changing the email invalidates a link still sitting in the old
inbox**. `ConfirmationsController#show` is idempotent — mail clients that prefetch links open
them twice, and the second visit must not be an error.

Registration no longer signs anyone in: `RegistrationsController` mails the link and sends
the person to `/entrar`. The gate is in two places — `SessionsController#create` refuses an
unconfirmed login, and `Authentication#find_session_by_cookie` merges `User.active.confirmed`
so a confirmation that stops being valid ends the session already open, the same way blocking
does.

**The "unconfirmed" message is the one exception to the deliberately vague login failure.**
It appears only *after* the right password, which is proof of possession — there is nothing
left to reveal. Wrong password and blocked account still share the generic text. The resend
form (`/confirmar`) answers the same way whether or not the address exists, which is what
keeps it from being a "who is registered here" oracle.

`spec/factories/users.rb` sets `confirmed_at` by default and offers `:unconfirmed`, because
confirmed is where an advertiser spends their whole life; the seed confirms too, since there
the address was typed by us.

### Sign in with Google or Facebook

Hand-written in `lib/oauth_provider.rb`, no OmniAuth. The portal already writes its own
authentication instead of using Devise, and the confidential-client authorization code flow
is two HTTP calls: trade the code for a token, ask who owns the token.

**Credentials come from the environment, like the footer links.** A provider without both
`*_CLIENT_ID`/`*_APP_ID` and its secret does not exist: the button is not rendered and the
route 404s. An install that only wants password login shows no buttons rather than one that
would fail. Unknown provider and unconfigured provider return the same 404 — from outside
they are the same thing.

**Starting the flow is `POST /entrar/:provider`, not `GET`.** The button needs the CSRF
token: over GET, a third-party page can start the flow and land the victim inside the
attacker's account. The callback is GET because the provider is the one redirecting back.

**`state` is single-use and lives in the session.** `OauthController#callback` consumes it
before anything else — including when the person cancelled at the provider — because leaving
it behind would keep it valid for a later callback. A mismatch is refused with the same
message as any other failure.

**Only a verified email is accepted.** `OauthProfile.from_provider` requires Google's
`email_verified`; Facebook omits the field and only returns `email` for an address it already
confirmed, so a missing field counts as verified. This check is what stops someone opening a
provider account with another person's address and signing in as them here.

**Signing up through a provider takes two steps.** Google gives a name and an email; a
classifieds portal also needs phone, city and state, which no provider knows. The callback
parks the profile in `session[:oauth]` and sends the person to the ordinary signup form,
which then hides the password fields and marks the email read-only. **The email is read back
out of the session, never out of the POST** — trusting the form would let someone sign in
with one Google address and come out registered, already confirmed, under someone else's.

`oauth_identities` holds the link, never a token: the portal acts on nobody's behalf at
Google or Facebook, so the access token dies with the request. Two unique indexes carry the
rules — `(provider, uid)` stops two portal accounts pointing at the same Google, and
`(user_id, provider)` stops one account collecting several. `OauthAuthentication#connect`
returns `false` for that second case instead of guessing which one wins.

Provider-only accounts still need a value in the `NOT NULL` `password_hash`, so they get
`User.random_password` — unguessable and told to no one. Whoever also wants a password sets
one in their own profile.

### Storage and mail

**`ad_images` rows own the ordering; Active Storage owns the bytes.** The row keeps
`sort_order` — explicit ordering is the reason the table exists instead of a bare
`has_many_attached` — and the photo itself arrives one of two ways:

- **an attached blob** (`has_one_attached :file`), for anything uploaded through the ad
  form, stored on MinIO in development;
- **a `file_url` string**, which is how `db/seeds.rb` points at `/seed-images`.

Both coexist and `AdImage#url` picks: attachment first, `file_url` otherwise. Every view
calls `#url`, never `file_url` directly. `file_url` is nullable for exactly this reason.

**Blob URLs are proxy paths, never direct MinIO URLs.** Inside Compose the endpoint is
`http://minio:9000`, which the host's browser cannot resolve — the proxy makes Rails fetch
the object instead (`config.active_storage.resolve_model_to_route = :rails_storage_proxy`).
`AdImage#url` must pass `only_path: true`: Active Storage's route is a direct route, and
outside a request (console, job) it otherwise tries to build an absolute URL and raises
"Missing host to link to".

**Preload with `Ad.with_photos`**, not `includes(:ad_images)`. `AdImage#url` asks whether a
blob is attached, so without `includes(ad_images: { file_attachment: :blob })` every listing
costs one query per photo. `AdImage.with_attached_file` is the equivalent for a bare photo
query, as in `HomeController#gallery_photos`.

**Uploads never touch `AdsController#create` directly.** Dropzone posts one photo at a time
to `Dashboard::AdPhotosController`, which validates and returns a blob `signed_id`; the form
submits those ids as `photo_signed_ids[]` and the create action attaches them in array
order. A blob whose form is abandoned stays unattached — `bin/rails
active_storage:purge_unattached` is what collects them, and nothing runs it automatically.

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
turns a green build red. `TooManyConstants` caps a class at five, which is why
`HomeController` keeps `RECENT_ROW` and derives the twelve from it instead of holding a
second constant.

**Brakeman is a hard CI gate too**, and it exits 3 on any warning. `config/brakeman.ignore`
holds one reviewed finding: `LinkToHref` on the event card, where the `href` is already
scheme-whitelisted by `Event#external_url`. Brakeman flags any model attribute in a
`link_to` href and cannot see the whitelist — hence the `note` in that file. Add to it only
with a written justification.

`spec/factories/ads.rb` draws photo URLs from a shared `:ad_photo_url` sequence, so two ads
never share a `file_url`; the home gallery specs rely on telling one ad's photo from
another's.

**`:oauth` on an example puts provider credentials in the environment.**
`spec/support/oauth.rb` sets and restores the four variables around the example, because
`OauthProvider` reads `ENV` — without them the provider does not exist and the routes 404,
which is itself worth a couple of examples. The HTTP is stubbed with plain `stub_request`;
no cassette, since the request bodies carry the client secret.

**`travel` / `freeze_time` come from `spec/support/time_helpers.rb`**, not from rspec-rails —
the same friction as `have_enqueued_mail`: the project mocks with Mocha, so what rspec-rails
wires up by itself is thin.

**Upload specs need real image bytes.** `spec/support/photo_uploads.rb` builds them with the
same `PlaceholderImage` the seed uses — `AdPhotosController` measures the file with libvips,
so a `StringIO` of junk is rejected as unreadable rather than accepted. `photo_signed_ids(n)`
is the shortcut for "n photos already uploaded", which is the state the ad form posts from.

`spec/system/` is empty but must keep existing: `.github/workflows/ci.yml` runs
`bundle exec rspec spec/system` as its own job, and RSpec errors on a missing directory.

## Known warts

`docker-compose.yaml` sits next to `compose.yaml` — an untracked, stale duplicate created
outside this history. Compose warns about it on every command and uses `compose.yaml`.
`compose.yaml` is the versioned one; the duplicate is safe to delete.

**MinIO and Active Storage are load-bearing again.** They were dead weight while photos were
plain URLs; the ad form's Dropzone upload put them back in the path, so the `minio` service,
`config.active_storage.*` and the `aws-sdk-s3` gem are all wired to something now. Removing
them would break photo upload.
