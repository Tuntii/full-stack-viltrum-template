module main

// End-to-end tests through the real routes and middleware, without a socket:
// App.handle_raw serves one raw request in-process, on any platform.
import viltrum

fn demo_app() &viltrum.App {
	shared store := Store{}
	lock store {
		store.seed_demo()
	}
	return new_app(shared store)
}

fn status_of(res string) int {
	return res[9..12].int()
}

fn body_of(res string) string {
	return res.all_after('\r\n\r\n')
}

fn header_of(res string, name string) string {
	return res.all_before('\r\n\r\n').all_after('\r\n${name}: ').all_before('\r\n')
}

fn get(app &viltrum.App, path string, extra string) string {
	return app.handle_raw('GET ${path} HTTP/1.1\r\nHost: x\r\n${extra}\r\n') or { panic(err) }
}

fn send(app &viltrum.App, method string, path string, extra string, ctype string, body string) string {
	return app.handle_raw('${method} ${path} HTTP/1.1\r\nHost: x\r\n${extra}Content-Type: ${ctype}\r\nContent-Length: ${body.len}\r\n\r\n${body}') or {
		panic(err)
	}
}

fn api_token(app &viltrum.App) string {
	res := send(app, 'POST', '/api/v1/login/access-token', '', 'application/json',
		'{"username":"admin@example.com","password":"changethis"}')
	assert status_of(res) == 200, res
	return body_of(res).all_after('"access_token":"').all_before('"')
}

fn test_health() {
	res := get(demo_app(), '/api/v1/health', '')
	assert status_of(res) == 200 && body_of(res) == '{"status":"ok"}'
}

fn test_api_login_items_crud() {
	app := demo_app()
	auth := 'Authorization: Bearer ${api_token(app)}\r\n'
	me := get(app, '/api/v1/users/me', auth)
	assert body_of(me) == '{"id":1,"email":"admin@example.com","full_name":"Admin","is_superuser":true}'
	created := send(app, 'POST', '/api/v1/items/', auth, 'application/json',
		'{"title":"  Buy milk ","description":"2 l, \\"fresh\\""}')
	assert status_of(created) == 201
	assert body_of(created) == '{"id":2,"title":"Buy milk","description":"2 l, \\"fresh\\"","owner_id":1}'
	list := get(app, '/api/v1/items/', auth)
	assert body_of(list).ends_with(',"count":2}')
	put := send(app, 'PUT', '/api/v1/items/2', auth, 'application/json', '{"title":"Oat milk"}')
	assert body_of(put).contains('"title":"Oat milk"')
	del := app.handle_raw('DELETE /api/v1/items/2 HTTP/1.1\r\nHost: x\r\n${auth}\r\n')!
	assert status_of(del) == 204
	assert status_of(get(app, '/api/v1/items/2', auth)) == 404
}

fn test_api_rejects_bad_requests() {
	app := demo_app()
	assert status_of(get(app, '/api/v1/items/', '')) == 401
	assert status_of(get(app, '/api/v1/items/', 'Authorization: Bearer nope\r\n')) == 401
	bad := send(app, 'POST', '/api/v1/login/access-token', '', 'application/json',
		'{"username":"admin@example.com","password":"wrong"}')
	assert status_of(bad) == 401 && body_of(bad) == '{"detail":"incorrect email or password"}'
	auth := 'Authorization: Bearer ${api_token(app)}\r\n'
	assert status_of(send(app, 'POST', '/api/v1/items/', auth, 'application/json', 'not json')) == 400
	assert status_of(send(app, 'POST', '/api/v1/items/', auth, 'application/json', '{"title":" "}')) == 400
	dup := send(app, 'POST', '/api/v1/users/', auth, 'application/json',
		'{"email":"ADMIN@example.com","password":"longenough"}')
	assert status_of(dup) == 409
}

fn test_api_login_accepts_a_form_body() {
	app := demo_app()
	res := send(app, 'POST', '/api/v1/login/access-token', '', 'application/x-www-form-urlencoded',
		'username=admin%40example.com&password=changethis')
	assert status_of(res) == 200 && body_of(res).contains('"token_type":"bearer"')
}

fn test_users_only_for_superusers() {
	app := demo_app()
	admin := 'Authorization: Bearer ${api_token(app)}\r\n'
	made := send(app, 'POST', '/api/v1/users/', admin, 'application/json',
		'{"email":"ada@example.com","password":"analytical","full_name":"Ada"}')
	assert status_of(made) == 201 && !body_of(made).contains('password')
	login := send(app, 'POST', '/api/v1/login/access-token', '', 'application/json',
		'{"username":"ada@example.com","password":"analytical"}')
	ada := 'Authorization: Bearer ${body_of(login).all_after('"access_token":"').all_before('"')}\r\n'
	assert status_of(get(app, '/api/v1/users/', ada)) == 403
	assert status_of(get(app, '/api/v1/items/1', ada)) == 403 // the admin's item
	assert body_of(get(app, '/api/v1/users/', admin)).ends_with(',"count":2}')
}

fn test_browser_flow() {
	app := demo_app()
	assert header_of(get(app, '/', ''), 'Location') == '/login'
	login := send(app, 'POST', '/login', '', 'application/x-www-form-urlencoded',
		'email=admin%40example.com&password=changethis')
	assert status_of(login) == 303 && header_of(login, 'Location') == '/items'
	cookie := header_of(login, 'Set-Cookie').all_before(';')
	assert cookie.starts_with('session=vt_')
	jar := 'Cookie: theme=dark; ${cookie}\r\n'
	made := send(app, 'POST', '/items', jar, 'application/x-www-form-urlencoded',
		'title=%3Cb%3EBold%3C%2Fb%3E&description=kept+after+the+request')
	assert header_of(made, 'Location') == '/items?flash=item+created'
	page := get(app, '/items', jar)
	assert status_of(page) == 200
	assert page.contains('&lt;b&gt;Bold&lt;/b&gt;') && !page.contains('<b>Bold')
	// the form values were copied into the store, not kept as views into the request
	_ = get(app, '/api/v1/health', '')
	assert get(app, '/items', jar).contains('kept after the request')
	// the cookie works for the JSON API too
	assert status_of(get(app, '/api/v1/items/', jar)) == 200
	out := send(app, 'POST', '/logout', jar, 'application/x-www-form-urlencoded', '')
	assert header_of(out, 'Set-Cookie').contains('Max-Age=0')
	assert header_of(get(app, '/items', jar), 'Location') == '/login'
}

fn test_flash_is_escaped() {
	page := get(demo_app(), '/login?error=%3Cscript%3Ealert(1)%3C%2Fscript%3E', '')
	assert page.contains('&lt;script&gt;') && !page.contains('<script>alert')
}

fn test_static_css() {
	res := get(demo_app(), '/static/style.css', '')
	assert status_of(res) == 200 && header_of(res, 'Content-Type').starts_with('text/css')
	assert header_of(res, 'Cache-Control') == 'max-age=3600'
}
