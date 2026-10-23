module main

// Session extraction: Bearer token (API) or session cookie (browser).
import viltrum

// The session cookie: set and cleared with c.set_cookie / c.clear_cookie, whose
// defaults are what a session wants (Path=/, HttpOnly, SameSite=Lax).
const session_cookie = 'session'
const session_max_age = 7 * 24 * 3600

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

fn session_token(c &viltrum.Ctx) ?string {
	if t := bearer_token(c) {
		return t
	}
	return c.cookie(session_cookie)
}

fn require_user(shared store Store, c &viltrum.Ctx) ?User {
	token := session_token(c) or { return none }
	lock store {
		return store.user_from_token(token)
	}
	return none
}
