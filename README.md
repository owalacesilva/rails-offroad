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
docker compose run --rm web bin/rails db:create
docker compose up
```

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

## Estado atual

Mockup estático da home, sem models nem persistência:

- `app/views/layouts/application.html.erb` — layout base com header fixo e footer
- `app/views/shared/_header.html.erb` — logo, busca central e CTA "Anunciar"
- `app/views/shared/_footer.html.erb` — links institucionais, contato e redes sociais
- `app/views/home/index.html.erb` — hero, grid de categorias e vitrine "Anúncios Recentes"
- `app/controllers/home_controller.rb` — dados mockados em `CATEGORIES` e `RECENT_LISTINGS`
- `app/assets/tailwind/application.css` — paleta da marca (`brand-50` a `brand-950`)
- `spec/` — 15 exemplos cobrindo a home, os helpers e o isolamento de rede

`spec/factories/` está vazio de propósito: não há models ainda.
