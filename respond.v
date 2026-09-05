module main

// Small response helpers (JSON API + HTML pages).

import viltrum {
	Response
	empty
	json
	json_escape
	text
}

fn user_public_json(u User) string {
	su := if u.is_superuser { 'true' } else { 'false' }
	return '{"id":${u.id},"email":"${json_escape(u.email)}","full_name":"${json_escape(u.full_name)}","is_superuser":${su}}'
}

fn item_json(it Item) string {
	return '{"id":${it.id},"title":"${json_escape(it.title)}","description":"${json_escape(it.description)}","owner_id":${it.owner_id}}'
}

fn api_error(status int, msg string) Response {
	return json(status, '{"detail":"${json_escape(msg)}"}')
}

fn unauthorized(msg string) Response {
	return api_error(401, msg)
}

fn forbidden(msg string) Response {
	return api_error(403, msg)
}

fn bad_request(msg string) Response {
	return api_error(400, msg)
}

fn conflict(msg string) Response {
	return api_error(409, msg)
}

fn html(status int, body string) Response {
	mut r := text(status, body)
	r.headers.set('Content-Type', 'text/html; charset=utf-8')
	return r
}

fn redirect(location string) Response {
	mut r := empty(303)
	r.headers.set('Location', location)
	return r
}

fn with_cookie(mut r Response, cookie string) Response {
	r.headers.set('Set-Cookie', cookie)
	return r
}
