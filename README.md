# Full Stack Viltrum Template

Clean teaching app on [Viltrum](https://github.com/Tuntii/viltrum):

- **Web UI** — server-rendered HTML (`$tmpl`) + session cookie  
- **JSON API** — `/api/v1` (Bearer token **or** same cookie)  
- **In-memory store** — no ORM, no Docker, no React build  

Inspired by [fastapi/full-stack-fastapi-template](https://github.com/fastapi/full-stack-fastapi-template). **Not a port.**

---

## Run

```bash
git clone https://github.com/Tuntii/full-stack-viltrum-template.git
cd full-stack-viltrum-template
bash scripts/setup.sh   # links Viltrum → ~/.vmodules/viltrum
v run .
```

| | |
|--|--|
| UI | http://127.0.0.1:8090/login |
| API | `GET /api/v1/health` |
| Demo | `admin@example.com` / `changethis` |
| Bind | `VILTRUM_ADDR` (default `127.0.0.1:8090`) |

---

## Layout

```text
.
  main.v            # wire middleware, routes, listen
  models.v          # User, Item, Session
  store.v           # in-memory persistence
  auth.v            # bearer + cookie session
  respond.v         # json/html/redirect helpers
  views.v           # $tmpl wrappers
  routes_web.v      # browser pages + forms
  routes_api.v      # /api/v1 JSON
  templates/        # HTML shells (V $tmpl)
  static/style.css
  scripts/setup.sh
```

| Layer | Responsibility |
|-------|----------------|
| `models` | Types only |
| `store` | Data + passwords + tokens |
| `auth` | Who is calling (API or browser) |
| `routes_web` | HTML + forms + redirects |
| `routes_api` | JSON for tools/clients |
| `views` + `templates` | Presentation |

Swap `store.v` for a real database later; keep handlers thin.

---

## API (v1)

| Method | Path | Auth |
|--------|------|------|
| GET | `/api/v1/health` | no |
| POST | `/api/v1/login/access-token` | no → bearer token |
| POST | `/api/v1/logout` | yes |
| GET | `/api/v1/users/me` | yes |
| GET/POST | `/api/v1/users/` | superuser |
| GET/POST | `/api/v1/items/` | yes |
| GET/PUT/DELETE | `/api/v1/items/:id` | owner or superuser |

```bash
TOKEN=$(curl -s -X POST http://127.0.0.1:8090/api/v1/login/access-token \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin@example.com","password":"changethis"}' \
  | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

curl -s http://127.0.0.1:8090/api/v1/items/ -H "Authorization: Bearer $TOKEN"
```

Web login uses `POST /login` (form) and sets an `HttpOnly` `session` cookie. The API accepts that cookie too.

---

## Templates

HTML is compiled with V’s built-in [`$tmpl`](https://github.com/vlang/v/blob/master/vlib/v/TEMPLATES.md).

- Shell pages live under `templates/`
- Literal `@` in HTML must be written as `@@` (e.g. emails)
- List bodies are built in `views.v` (escape + join) so templates stay simple shells

No third-party template package.

---

## Deliberately skipped

ORM, email recovery, OAuth, Docker/Traefik, React/Vite, HTTP/2–3, ACME in-process.

Edge TLS: put Caddy/nginx in front ([Viltrum deploy](https://github.com/Tuntii/viltrum/blob/main/docs/deploy.md)).

---

## Attribution

- Inspiration: [fastapi/full-stack-fastapi-template](https://github.com/fastapi/full-stack-fastapi-template) (MIT)  
- Engine: [Tuntii/viltrum](https://github.com/Tuntii/viltrum) (MIT)  

## License

[MIT](LICENSE)
