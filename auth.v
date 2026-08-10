module main

// Session extraction: Bearer token (API) or session cookie (browser).

import viltrum { Request }

const session_cookie = 'session'

fn bearer_token(req Request) ?string {
	raw := req.headers.get('Authorization') or { return none }
	if raw.len >= 7 && raw[..7].to_lower() == 'bearer ' {
		tok := raw[7..].trim_space()
		if tok.len == 0 {
			return none
		}
		return tok
	}
	return none
}

fn cookie_value(req Request, name string) ?string {
	raw := req.headers.get('Cookie') or { return none }
	for part in raw.split(';') {
		p := part.trim_space()
		if p.len == 0 {
			continue
		}
		eq := p.index('=') or { continue }
		k := p[..eq].trim_space()
		if k == name {
			return p[eq + 1..].trim_space()
		}
	}
	return none
}

fn session_token(req Request) ?string {
	if t := bearer_token(req) {
		return t
	}
	return cookie_value(req, session_cookie)
}

fn require_user(shared store Store, req Request) ?User {
	token := session_token(req) or { return none }
	lock store {
		return store.user_from_token(token)
	}
	return none
}

fn set_session_cookie(token string) string {
	// HttpOnly so JS cannot read it; SameSite=Lax for form POSTs.
	return '${session_cookie}=${token}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${7 * 24 * 3600}'
}

fn clear_session_cookie() string {
	return '${session_cookie}=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0'
}
