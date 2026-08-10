module main

// Full-stack starter for Viltrum.
// Layout inspired by https://github.com/fastapi/full-stack-fastapi-template
// (API + same-origin SPA + auth + items). Not a port: no Postgres, no React
// build step, no Docker/Traefik. Own engine, in-memory store, static UI.

import os
import viltrum {
	Mount
	new
	recover
	logger
	static_files
}

fn main() {
	shared store := Store{}
	lock store {
		// Demo credentials — change before any real deploy.
		store.seed_superuser('admin@example.com', 'changethis', 'Admin')
		_ := store.create_item(1, 'Welcome item', 'Delete me or edit me from the dashboard.') or {
			Item{}
		}
	}

	mut frontend := os.join_path(os.dir(@FILE), 'frontend')
	if !os.is_dir(frontend) {
		frontend = os.abs_path('frontend')
	}

	mut app := new()
	app.use(recover)
	app.use(logger)
	// SPA assets: index.html, app.css, app.js at site root when present.
	app.use(static_files('/', frontend))

	app.mount('/api/v1', fn [shared store] (mut m Mount) {
		register_api(mut m, shared store)
	})

	addr := os.getenv_opt('VILTRUM_ADDR') or { '127.0.0.1:8090' }
	println('Viltrum full-stack -> http://${addr}')
	println('  UI     http://${addr}/')
	println('  API    http://${addr}/api/v1/health')
	println('  login  admin@example.com / changethis')
	println('Inspired by: https://github.com/fastapi/full-stack-fastapi-template')
	app.listen(addr) or { panic(err) }
}
