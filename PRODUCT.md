# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

- **Developers evaluating Viltrum**, the HTTP framework for the V language. They land on the public demo
  (https://v.rustapi.cloud) from the Viltrum README, HttpArena, or a link, and want to judge in a minute
  whether the framework is real, fast, and pleasant to build with.
- **Developers starting a project from this template**: they clone it, run `v run .`, and extend the
  server-rendered admin UI and the JSON API with their own models.

## Product Purpose

A full-stack starter on Viltrum 1.x (>= 1.5.0) in one process: server-rendered pages with V `$tmpl`, a
cookie session for the browser, a JSON API under `/api/v1` (Bearer token or the same cookie), and an
in-memory store. The public deployment doubles as Viltrum's live demo: its root page introduces the
framework (confirmed by the user, 2026-10-23), and signing in opens the template's admin dashboard.

Success: a visitor understands what Viltrum is from the landing page, signs in with the demo credentials,
and uses a dashboard that looks like a real admin product, not a toy.

## Positioning

Viltrum owns the wire: its own HTTP/1.1 engine, one epoll worker per CPU, pipelining, no allocation per
request inside the framework, and no third-party dependency anywhere. The demo is that claim running: the
page, the dashboard, and the API are all answered by one small V binary.

## Operating Context

- Demo host: hostlab behind nginx (TLS at the edge), systemd service with 2 workers, MemoryMax 256M,
  restarted every 6 hours so the demo data resets. Anyone can sign in as the seeded superuser.
- Starter: `v run .` on Linux (serving is epoll-only), `v test .` anywhere through `handle_raw`.

## Capabilities and Constraints

- Pages: landing (`/`), sign in, items (CRUD), users (superuser), account. API: health, login, logout,
  users/me, users, items CRUD.
- No JavaScript framework, no build step, no third-party packages, no hosted assets: every byte the page
  needs is served by the binary from `templates/` and `static/` (zero-dependency rule).
- Request strings are views; whatever outlives a handler is cloned. Every user string reaching a
  template is escaped.
- Data is in memory and resets on restart; there is no sign-up, email, or password recovery.

## Brand Commitments

- Viltrum logo (`assets/logo.svg` in the viltrum repo): black square, white circle, a constant-width
  geometric black V. Monochrome.
- Voice from the Viltrum README: plain, technical, understated; numbers come with their method and date,
  and weak results are stated as plainly as strong ones.

## Evidence on Hand

- Viltrum README feature table (HTTP/1.1, engine, routing, middleware, JSON, TLS, static files, forms,
  WebSocket, tests) and docs under `docs/` in the viltrum repo.
- HttpArena entry with a live badge (https://http-arena.com); README benchmark tables are dated and
  partly superseded, so the landing quotes no throughput figure unless the user supplies a current one.
- The running process itself (memory, uptime, workers) can be shown live.
- No customers, testimonials, logos, or adoption numbers exist; never invent them.

## Product Principles

1. Prove with the running thing, not adjectives.
2. Honest numbers or none.
3. Nothing the binary does not serve itself.
4. The template stays a teaching app: readable V, thin handlers, simple templates.
