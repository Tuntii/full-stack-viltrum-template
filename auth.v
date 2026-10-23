module main

// Session extraction: Bearer token (API) or session cookie (browser).
import viltrum

const session_cookie = 'session'

fn bearer_token(c &viltrum.Ctx) ?string {
	raw := c.header('Authorization') or { return none }
	if raw.len >= 7 && raw[..7].to_lower() == 'bearer ' {
		tok := raw[7..].trim_space()
		if tok.len == 0 {
			return none
		}
		return tok
	}
	return none
}

fn cookie_value(c &viltrum.Ctx, name string) ?string {
	mut it := c.header_values('Cookie')
	for {
		raw := it.next() or { break }
		for part in raw.split(';') {
			p := part.trim_space()
			eq := p.index('=') or { continue }
			if p[..eq].trim_space() == name {
				return p[eq + 1..].trim_space()
			}
		}
	}
	return none
}

fn session_token(c &viltrum.Ctx) ?string {
	if t := bearer_token(c) {
		return t
	}
	return cookie_value(c, session_cookie)
}

fn require_user(shared store Store, c &viltrum.Ctx) ?User {
	token := session_token(c) or { return none }
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
