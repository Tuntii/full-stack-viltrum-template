module main

// Small response helpers (JSON API + HTML pages).

import viltrum {
	Response
	empty
	json
	text
}

fn json_escape(s string) string {
	return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '\\r')
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

// form_field reads application/x-www-form-urlencoded (or simple JSON string fields).
fn form_field(req_body string, key string) ?string {
	// Prefer JSON helpers path when body looks like JSON — handled by callers via json_string.
	for part in req_body.split('&') {
		if part.len == 0 {
			continue
		}
		eq := part.index('=') or {
			if url_decode_form(part) == key {
				return ''
			}
			continue
		}
		k := url_decode_form(part[..eq])
		if k == key {
			return url_decode_form(part[eq + 1..])
		}
	}
	return none
}

fn url_decode_form(s string) string {
	mut out := []u8{cap: s.len}
	mut i := 0
	bytes := s.bytes()
	for i < bytes.len {
		c := bytes[i]
		if c == `+` {
			out << ` `
			i++
		} else if c == `%` && i + 2 < bytes.len {
			h := s[i + 1..i + 3]
			out << u8(h.parse_int(16, 8) or { 0 })
			i += 3
		} else {
			out << c
			i++
		}
	}
	return out.bytestr()
}
