---
version: 1
slug: "templates-landing-html"
primary_target: "templates/landing.html"
related_targets: ["templates/login.html","templates/items.html","templates/users.html","templates/account.html","static/style.css"]
---

## Scope

Public demo at v.rustapi.cloud, served by this template. Two surfaces, one world:
- `/` landing (Persuade): introduces Viltrum to developers evaluating it; action = open the live
  dashboard (one-click demo sign-in) or clone it.
- `/login`, `/items`, `/users`, `/account` (Operate): an admin dashboard; the sign-in screen is that
  dashboard, locked.

Constraints: user pinned black and white to match the logo, no bloat, clean lines, speed and directness,
high contrast, functional (2026-10-23). No fonts, images, or scripts from anywhere but the binary; only a
few lines of inline JS on the landing. No throughput figures.

## Direction contract

THESIS: A request's trip through Viltrum, signed like a transit line, in the logo's black and white. Refuses
the dark-hero-plus-feature-cards developer landing and the soft SaaS admin.

OWN-WORLD: Signage black #000 bands and rail, pure white field, one hairline gray for rules. The logo's
disc-and-V is the bullet: filled white disc = here, outlined disc = elsewhere. System grotesk, heavy and
tight at sign scale; mono only for code and measured values. Square corners, 2px black rules, no shadows,
no gradients, no color.

STORY: The visitor reads what Viltrum is in one line, sees the route a request takes, fires a real
request and sees its measured time, then signs in to the demo with one click or copies the clone command.

FIRST VIEWPORT: Black sign band across the top (bullet, Viltrum, Docs, GitHub, white "Open the dashboard"
plate). White field: headline at sign scale, one sentence below, then the primary pair: the one-click
demo sign-in form and the clone command. Lower third: the line, five stations on a black rule, with a
"Send a request" control; a black departure strip at the bottom edge with live process facts.

FORM: Transit-authority signage standards (grounded list position 3), palette translated to the
user-pinned monochrome. seed:baceba22309f2a3c

Signature interaction: "Send a request" fetches /api/v1/health; a white bullet rides the line from Accept
to Write and the measured round trip prints at the terminus. Reduced motion: no ride, the value prints.

Raised lines: one horizon (the line is the page's spine, sections are its stops; city-pop); one shouting
word per section (futurist book); honest live counters as small chrome (minihompy); charged emptiness,
one focal move per view (ikebana).

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
