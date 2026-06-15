# portfolio

Open source developer portfolio with admin panel and REST API.

## Stack

- **Site** — Nuxt 4, TypeScript, Tailwind CSS
- **API** — Hono, Bun, PostgreSQL, Drizzle ORM
- **Admin** — Nuxt 4, TypeScript, Tailwind CSS
- **Infrastructure** — Docker, PostgreSQL, Redis

## Repositories

- [portfolio-site](https://github.com/AristarhKenebas/portfolio-site)
- [portfolio-api](https://github.com/AristarhKenebas/portfolio-api)
- [portfolio-admin](https://github.com/AristarhKenebas/portfolio-admin)

## Quick Start

### Linux / macOS

```bash
git clone https://github.com/AristarhKenebas/portfolio.git
cd portfolio
./setup.sh
```

### Windows

```powershell
irm https://raw.githubusercontent.com/AristarhKenebas/portfolio/main/setup.ps1 | iex
```

## Manual Setup

```bash
git clone https://github.com/AristarhKenebas/portfolio.git
cd portfolio
cp .env.example .env
# edit .env
git clone https://github.com/AristarhKenebas/portfolio-api.git api
git clone https://github.com/AristarhKenebas/portfolio-site.git site
git clone https://github.com/AristarhKenebas/portfolio-admin.git admin
docker compose up -d --build
```

## Configuration

Copy `.env.example` to `.env` and set:

| Variable | Description |
|---|---|
| POSTGRES_PASSWORD | Database password |
| SESSION_SECRET | Random 32+ character string |
| ADMIN_USERNAME | Admin panel username |
| ADMIN_PASSWORD | Admin panel password |
| GITHUB_USERNAME | Your GitHub username |
| GITHUB_TOKEN | GitHub token (optional, increases rate limit) |

## Ports

| Service | Default |
|---|---|
| Site | 3000 |
| API | 3001 |
| Admin | 3002 |
