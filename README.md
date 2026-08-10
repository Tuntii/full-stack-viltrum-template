# Full Stack Viltrum Template

Same-process web app on [Viltrum](https://github.com/Tuntii/viltrum): JSON API + static SPA, bearer auth, users, and items.

**Inspired by** [fastapi/full-stack-fastapi-template](https://github.com/fastapi/full-stack-fastapi-template). This is **not** a port of that stack. It is the Viltrum teaching equivalent: own HTTP engine, zero third-party deps in the app, in-memory store, no Docker/Traefik/Postgres/React build.

| FastAPI template | This template |
|------------------|---------------|
| FastAPI + SQLModel + PostgreSQL | [Viltrum](https://github.com/Tuntii/viltrum) + in-memory `Store` |
| React + Vite + Tailwind + shadcn | Static HTML/CSS/JS (no build) |
| JWT + password recovery + Mailcatcher | Opaque bearer tokens, demo login only |
| Docker Compose + Traefik + HTTPS | Single `v run .` on cleartext (proxy TLS yourself) |

Engine docs and roadmap live in the [Viltrum](https://github.com/Tuntii/viltrum) repo. This repository is only the starter app.

---

## Requirements

- [V](https://github.com/vlang/v) on `PATH` (`v version`)
- Linux/macOS (Windows untested)

## Setup

```bash
git clone https://github.com/Tuntii/full-stack-viltrum-template.git
cd full-stack-viltrum-template
bash scripts/setup.sh   # clones/links Viltrum into ~/.vmodules/viltrum
v run .
```

Open http://127.0.0.1:8090/

| | |
|--|--|
| UI | http://127.0.0.1:8090/ |
| API health | `GET /api/v1/health` |
| Demo login | `admin@example.com` / `changethis` |
| Bind | `VILTRUM_ADDR` (default `127.0.0.1:8090`) |

Change the demo password before any shared or public host.

### Point at a local Viltrum checkout

```bash
export VILTRUM_PATH=/path/to/viltrum
bash scripts/setup.sh
```

Or symlink yourself:

```bash
ln -sfn /path/to/viltrum ~/.vmodules/viltrum
```

---

## Layout

```text
.
  main.v           # App wire-up, seed superuser, listen
  store.v          # Users, items, sessions (shared memory)
  api.v            # /api/v1 routes
  frontend/
    index.html
    app.css
    app.js
  scripts/setup.sh # install Viltrum module link
  README.md
```

### API (v1)

| Method | Path | Auth | Notes |
|--------|------|------|--------|
| GET | `/api/v1/health` | no | liveness |
| POST | `/api/v1/login/access-token` | no | `{"username","password"}` → bearer token |
| POST | `/api/v1/logout` | bearer | revoke token |
| GET | `/api/v1/users/me` | bearer | current user |
| GET | `/api/v1/users/` | superuser | list users |
| POST | `/api/v1/users/` | superuser | create user |
| GET/POST | `/api/v1/items/` | bearer | list / create (owner-scoped) |
| GET/PUT/DELETE | `/api/v1/items/:id` | bearer | owner or superuser |

Passwords are salted SHA-256 for the demo. Sessions are opaque strings in a map. **Not** production identity.

### Curl smoke

```bash
curl -s http://127.0.0.1:8090/api/v1/health

TOKEN=$(curl -s -X POST http://127.0.0.1:8090/api/v1/login/access-token \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin@example.com","password":"changethis"}' \
  | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

curl -s http://127.0.0.1:8090/api/v1/users/me -H "Authorization: Bearer $TOKEN"
curl -s http://127.0.0.1:8090/api/v1/items/ -H "Authorization: Bearer $TOKEN"
curl -s -X POST http://127.0.0.1:8090/api/v1/items/ \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"title":"Ship docs","description":"from curl"}'
```

---

## What we deliberately skipped

- ORM / SQL migrations / multi-tenant admin platforms  
- Email recovery, OAuth providers, cookie session frameworks  
- HTTP/2–3, ACME inside the process  
- Feature parity with the FastAPI full-stack monorepo  

Deploy cleartext behind Caddy or nginx for edge TLS: [Viltrum deploy notes](https://github.com/Tuntii/viltrum/blob/main/docs/deploy.md).

---

## Attribution

- **Inspiration:** [fastapi/full-stack-fastapi-template](https://github.com/fastapi/full-stack-fastapi-template) (MIT)  
- **Engine:** [Tuntii/viltrum](https://github.com/Tuntii/viltrum) (MIT)  
- App code and UI in this repo are original; only the *product idea* (API + dashboard + auth + items in one starter) is shared.

## License

[MIT](LICENSE)
