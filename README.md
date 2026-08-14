# OffRoad Classificados

Portal de classificados de nicho para o universo off-road: veículos 4x4, motos de trilha,
quadriciclos, UTVs e peças & acessórios.

- Rails 8.1 · Ruby 3.4 · PostgreSQL 16 · TailwindCSS 4 · Propshaft + Importmap

## Ambiente de desenvolvimento (Docker)

Esta máquina não tem Ruby nem PostgreSQL instalados nativamente, então o ambiente roda em
containers. `Dockerfile.dev` é a imagem de desenvolvimento; o `Dockerfile` na raiz é o de
produção, gerado pelo Rails (usado pelo Kamal).

Os containers rodam com uid/gid 1000, iguais aos do host — os arquivos gerados dentro do
container continuam seus e editáveis normalmente.

### Primeira execução

```bash
cp .env-example .env                         # opcional: há default para tudo
docker compose build
docker compose run --rm web bundle install   # popula o volume de gems
docker compose run --rm web bin/rails db:prepare
docker compose run --rm web bin/rails db:seed    # 4 categorias e 36 anúncios
docker compose up
```

O seed é idempotente: rodar de novo não duplica registros.

### Serviços

| Serviço     | URL                                            | Credenciais            |
| ----------- | ---------------------------------------------- | ---------------------- |
| Aplicação   | <http://localhost:3000>                        | —                      |
| PostgreSQL  | `localhost:5432`                               | `postgres` / `postgres`|
| pgAdmin     | <http://localhost:5050>                        | modo desktop, sem login|
| MinIO API   | <http://localhost:9000>                        | `offroad` / `offroad123`|
| MinIO console | <http://localhost:9001>                      | `offroad` / `offroad123`|
| MailHog     | <http://localhost:8025>                        | —                      |

A aplicação sobe via `bin/dev` (foreman: servidor Rails + `tailwindcss:watch`).

O pgAdmin já vem com a conexão do banco pré-registrada (`docker/pgadmin/servers.json`);
a senha é pedida no primeiro acesso.

O bucket do MinIO é criado automaticamente pelo serviço one-shot `minio_setup`, que também
libera leitura anônima — conveniência de desenvolvimento, não replicar em produção.

Em desenvolvimento **nenhum e-mail sai para destinatário real**: tudo é capturado pelo MailHog.

### Comandos do dia a dia

```bash
docker compose up                              # equivale ao bin/dev
docker compose exec web bin/rails console
docker compose run --rm web bin/rails generate model Listing
docker compose down                            # para tudo
```

## Testes e qualidade

```bash
docker compose exec web bin/rspec              # suíte completa
docker compose exec web bin/rspec spec/requests
docker compose exec web bin/rubocop            # estilo (omakase + cops de RSpec)
docker compose exec web bundle exec reek app lib   # code smells
docker compose exec web bin/brakeman --no-pager    # análise de segurança
docker compose exec web bin/bundler-audit check --update
```

**RSpec** substituiu o minitest — não existe mais `test/`, nem `bin/rails test`.

**Mocks são do Mocha**, não do rspec-mocks (`config.mock_with :mocha` em `spec/spec_helper.rb`).
Na prática: `Gateway.expects(:charge)` e `obj.stubs(:call)` funcionam; `double`,
`instance_double` e `allow(...).to receive` **não existem** nesta configuração.

**Nenhum spec alcança a rede real**: o WebMock bloqueia e o VCR grava/reproduz as respostas
em `spec/fixtures/vcr_cassettes`. Marque o exemplo com `:vcr` para usar uma cassete.
Como o VCR está plugado no WebMock, uma chamada não stubada levanta
`VCR::Errors::UnhandledHTTPRequestError`.

`reek` **precisa dos paths** (`reek app lib`): sem argumentos ele lê da STDIN e não analisa nada.

CI configurado em dois lugares — `.semaphore/semaphore.yml` (Semaphore) e
`.github/workflows/ci.yml` (GitHub Actions). Ambos rodam a mesma bateria; provavelmente
você vai querer manter só um.

## Internacionalização

`pt-BR` é o locale padrão e `en-US` está disponível. As traduções de Rails/Active Record vêm
da gem `rails-i18n`; os textos da interface ficam em `config/locales/pt-BR.yml` e
`config/locales/en-US.yml`. Chave ausente em `en-US` cai para `pt-BR`.

`I18n.available_locales` inclui um terceiro locale, `:en`, que **não** é oferecido ao
usuário: ele existe como base de fallback (`en-US` decompõe para `en`) e é onde
`rails-i18n` e `faker` guardam seus dados. Os idiomas escolhíveis são
`ApplicationController::SUPPORTED_LOCALES`, então `?locale=en` cai no padrão.

A troca acontece em `ApplicationController#set_locale`, nesta ordem: `?locale=` na URL,
depois o `Accept-Language` do navegador, senão o padrão.

```bash
curl "http://localhost:3000/?locale=en-US"
curl -H "Accept-Language: en-US" http://localhost:3000/
```

Nomes de categoria e badges são taxonomia fixa e vivem nos arquivos de locale. Já título e
localização dos anúncios são conteúdo do usuário: ficam literais e não se traduzem.

### Variáveis de ambiente

`.env-example` é o template versionado; `cp .env-example .env` para customizar. Todas as
variáveis têm default no `compose.yaml`, então o ambiente sobe sem `.env`.

Os endereços internos (`DB_HOST=db`, `MINIO_ENDPOINT=http://minio:9000`, `SMTP_ADDRESS=mailhog`)
ficam fixos no `compose.yaml`, fora do `.env`, de propósito: dentro da rede do Compose valem os
nomes dos serviços, enquanto no host valeria `localhost`. Colocá-los no `.env` quebraria um dos dois.

### Rodando sem Docker

`config/database.yml` lê `DB_HOST`, `DB_PORT`, `DB_USERNAME` e `DB_PASSWORD`, com padrão
`localhost:5432` / `postgres`. `config/storage.yml` e o Action Mailer seguem a mesma lógica,
com default em `localhost`. Com Ruby 3.4 e os serviços locais, `bin/setup` e `bin/dev`
funcionam normalmente.

## Domínio

Quatro models, sem autenticação nem cadastro ainda:

- `Category` — só `slug` e `position`. Nome e descrição são taxonomia traduzível e
  vivem em `config/locales`, indexados pelo slug. `to_param` devolve o slug, então
  as URLs de filtro são legíveis.
- `Listing` — preço em `price_cents` (inteiro, com check constraint no banco),
  `state` (UF) e `city` como colunas, e `badge` como enum. O badge de novidade se
  chama `new_arrival` porque `new` colidiria com `Listing.new`. As fotos são
  `has_many_attached` no MinIO; as especificações ficam em `jsonb`.
- `Advertiser` — dono dos anúncios e também a identidade autenticada
  (`has_secure_password`). `phone` guarda só dígitos com código do país, validado
  por regex, porque é o formato que o link do `wa.me` exige.
- `Proposal` — proposta recebida em um anúncio. Valor também em centavos.
- `Session` — sessão ativa de um anunciante, com user agent e IP.

Especificações usam `jsonb` porque variam por categoria (4x4 tem câmbio, peça tem
material). Como o `jsonb` **não preserva a ordem das chaves**, a ordem de exibição
é definida em `Listing::SPECIFICATION_ORDER`, não no banco.

## Página de anúncios

`/anuncios` (`ListingsController#index`) lista o acervo com filtro por categoria,
estado, cidade e ordenação.

- `app/queries/listing_filter.rb` traduz os parâmetros da URL em um scope. Valor
  desconhecido é ignorado, nunca interpolado — `sort` só aceita as chaves de `SORTS`.
- Cidade que não pertence ao estado escolhido é **descartada**, em vez de produzir
  uma lista vazia sem explicação.
- Ordenar por ano usa `NULLS LAST`: peça não tem ano e o Postgres jogaria os nulos
  na frente no `DESC`.
- `app/queries/pagination.rb` pagina por offset, sem gem. Página fora do intervalo
  é corrigida para a borda mais próxima (`?page=999` cai na última).
- O painel de filtros recolhe via `app/javascript/controllers/filters_controller.js`:
  fechado no mobile, aberto a partir de `lg`. O HTML renderiza **aberto**, então
  sem JavaScript o filtro continua funcionando.

## Autenticação

`/entrar` e `/cadastrar`. Quem se cadastra **já é anunciante** — não existe um
`User` separado, a identidade autenticada é o próprio `Advertiser`, que já era
dono dos anúncios. Comprador manda proposta sem conta.

A sessão vive em tabela, com o id em cookie assinado (`httponly`, `same_site: :lax`,
e `secure` em produção). É o mesmo desenho do gerador de autenticação do Rails 8,
aplicado ao `Advertiser` — sem gem além do `bcrypt`.

**O padrão é negar.** `ApplicationController` inclui `Authentication`, que exige
sessão em toda action; quem é público declara `allow_unauthenticated_access`.
Controller nova nasce protegida.

Entrada normalizada antes de validar: e-mail vira minúsculas, e o telefone aceita
`(41) 98877-0011` e é guardado como `5541988770011`. O comprimento decide se falta
o código do país — 10 ou 11 dígitos é DDD + número; o prefixo seria ambíguo, já que
55 também é o DDD de Santa Maria.

Os anunciantes do seed usam a senha **`trilha123`** (só desenvolvimento). Ex.:
`contato@trilhalivre.com.br` / `trilha123`.

## Página de detalhe

`/anuncios/:id` traz galeria, descrição, especificações, dados do anunciante,
contato por WhatsApp, modal de proposta e anúncios relacionados.

- **Fotos** são Active Storage de verdade, guardadas no MinIO. `Dockerfile.dev`
  inclui `libvips42` porque as variantes (miniatura, card) passam por ele.
  O seed gera os PNGs de placeholder com `lib/placeholder_image.rb`, que escreve
  o arquivo na mão com `Zlib` — sem gem de imagem e sem binário no repositório.
- **WhatsApp**: `ListingsHelper#whatsapp_url` monta `wa.me` com o telefone do
  anunciante e a mensagem já preenchida com título e URL do anúncio.
- **Modal de proposta** usa o `<dialog>` nativo, que já dá Esc e prisão de foco;
  o Stimulus só abre e fecha. Validação que falha responde **422**, e o modal
  reabre sozinho com os erros via `data-modal-open-value`.
- **Proposta enviada** dispara `ProposalMailer` para o e-mail do anunciante, com
  `reply_to` do interessado — em desenvolvimento cai no MailHog.
- **Relacionados**: mesma categoria, exceto o próprio anúncio, mais recentes
  primeiro. Deliberadamente simples — não pondera estado nem faixa de preço.

## Estado atual

- `app/views/layouts/application.html.erb` — layout base com header fixo e footer
- `app/views/shared/_header.html.erb` — logo, busca central e CTA "Anunciar"
- `app/views/shared/_footer.html.erb` — links institucionais, contato e redes sociais
- `app/views/home/index.html.erb` — hero, grid de categorias e vitrine "Anúncios Recentes"
- `app/views/listings/_card.html.erb` — card de anúncio, compartilhado pelas três telas
- `app/views/listings/show.html.erb` — detalhe do anúncio
- `app/views/sessions/new.html.erb` e `app/views/registrations/new.html.erb` — login e cadastro
- `app/assets/tailwind/application.css` — paleta da marca (`brand-50` a `brand-950`)
- `spec/` — 204 exemplos cobrindo models, filtros, paginação, requests, mailer, autenticação e helpers

A busca do header ainda é estática, e **nenhuma tela é exclusiva de quem está
logado**: entrar hoje só muda o header. Não há tela para o anunciante criar ou
editar anúncio, nem recuperação de senha — o acervo vem do seed.
