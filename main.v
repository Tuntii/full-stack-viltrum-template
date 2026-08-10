module main

// Full-stack Viltrum starter.
// Inspired by https://github.com/fastapi/full-stack-fastapi-template — not a port.
//
// Layout:
//   models / store / auth / respond / views
//   routes_web  — browser (SSR + cookie)
//   routes_api  — JSON /api/v1 (bearer or cookie)
//   templates/  — V $tmpl HTML
//   static/     — CSS only

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
		store.seed_demo()
	}

	mut static_dir := os.join_path(os.dir(@FILE), 'static')
	if !os.is_dir(static_dir) {
		static_dir = os.abs_path('static')
	}

	mut app := new()
	app.use(recover)
	app.use(logger)
	app.use(static_files('/static', static_dir))

	register_web(mut app, shared store)
	app.mount('/api/v1', fn [shared store] (mut m Mount) {
		register_api(mut m, shared store)
	})

	addr := os.getenv_opt('VILTRUM_ADDR') or { '127.0.0.1:8090' }
	println('full-stack-viltrum-template -> http://${addr}')
	println('  UI   http://${addr}/login')
	println('  API  http://${addr}/api/v1/health')
	println('  demo admin@example.com / changethis')
	app.listen(addr) or { panic(err) }
}
