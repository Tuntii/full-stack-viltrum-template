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
import viltrum

fn main() {
	shared store := Store{}
	lock store {
		store.seed_demo()
	}
	app := new_app(shared store)
	addr := os.getenv_opt('VILTRUM_ADDR') or { '127.0.0.1:8090' }
	println('full-stack-viltrum-template -> http://${addr}')
	println('  UI   http://${addr}/login')
	println('  API  http://${addr}/api/v1/health')
	println('  demo admin@example.com / changethis')
	app.listen(addr) or { panic(err) }
}

// new_app wires middleware and routes; the tests serve requests through it with
// handle_raw, without a socket.
fn new_app(shared store Store) &viltrum.App {
	mut static_dir := os.join_path(os.dir(@FILE), 'static')
	if !os.is_dir(static_dir) {
		static_dir = os.abs_path('static')
	}
	mut app := viltrum.new()
	app.use(viltrum.recover)
	app.use(viltrum.logger)
	// Every request counts toward "requests served" on the live pages.
	mut hits := &Hits{}
	app.use(fn [mut hits] (mut c viltrum.Ctx) {
		hits.add()
		c.next()
	})
	app.static_files('/static', static_dir, max_age: 3600)
	register_web(mut app, shared store, hits)
	mut api := app.group('/api/v1')
	register_api(mut api, shared store, hits)
	return app
}
