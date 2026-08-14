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
docker compose build
docker compose run --rm web bundle install   # popula o volume de gems
docker compose run --rm web bin/rails db:create
docker compose up
```

A aplicação sobe em <http://localhost:3000> via `bin/dev` (foreman: servidor Rails +
`tailwindcss:watch`). O PostgreSQL fica exposto em `localhost:5432` (usuário/senha `postgres`).

### Comandos do dia a dia

```bash
docker compose up                              # equivale ao bin/dev
docker compose exec web bin/rails console
docker compose exec web bin/rails test
docker compose exec web bin/rubocop
docker compose run --rm web bin/rails generate model Listing
docker compose down                            # para tudo
```

### Rodando sem Docker

`config/database.yml` lê `DB_HOST`, `DB_PORT`, `DB_USERNAME` e `DB_PASSWORD`, com padrão
`localhost:5432` / `postgres`. Com Ruby 3.4 e um PostgreSQL local, `bin/setup` e `bin/dev`
funcionam normalmente.

## Estado atual

Mockup estático da home, sem models nem persistência:

- `app/views/layouts/application.html.erb` — layout base com header fixo e footer
- `app/views/shared/_header.html.erb` — logo, busca central e CTA "Anunciar"
- `app/views/shared/_footer.html.erb` — links institucionais, contato e redes sociais
- `app/views/home/index.html.erb` — hero, grid de categorias e vitrine "Anúncios Recentes"
- `app/controllers/home_controller.rb` — dados mockados em `CATEGORIES` e `RECENT_LISTINGS`
- `app/assets/tailwind/application.css` — paleta da marca (`brand-50` a `brand-950`)
