module main

// JSON API under /api/v1 — auth, users, items.
// Shape inspired by full-stack-fastapi-template route groups, not a port.

import viltrum {
	Mount
	Request
	Response
	empty
	json
	not_found
}

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

fn unauthorized(msg string) Response {
	return json(401, '{"detail":"${json_escape(msg)}"}')
}

fn forbidden(msg string) Response {
	return json(403, '{"detail":"${json_escape(msg)}"}')
}

fn bad_request(msg string) Response {
	return json(400, '{"detail":"${json_escape(msg)}"}')
}

fn conflict(msg string) Response {
	return json(409, '{"detail":"${json_escape(msg)}"}')
}

fn require_user(shared store Store, req Request) ?User {
	token := bearer_token(req) or { return none }
	lock store {
		return store.user_from_token(token)
	}
	return none
}

fn register_api(mut m Mount, shared store Store) {
	// Health (no auth)
	m.get('/health', fn (_ Request) Response {
		return json(200, '{"status":"ok"}')
	})

	// POST /login/access-token  {"username":"email","password":"..."}
	// username field matches common OAuth2-password form naming from the FastAPI template.
	m.post('/login/access-token', fn [shared store] (req Request) Response {
		email := req.json_string('username') or {
			req.json_string('email') or { return bad_request('username (email) required') }
		}
		password := req.json_string('password') or { return bad_request('password required') }
		mut token := ''
		lock store {
			u := store.user_by_email(email) or {
				return unauthorized('incorrect email or password')
			}
			if !store.check_password(password, u.hashed_password) {
				return unauthorized('incorrect email or password')
			}
			token = store.issue_token(u.id)
		}
		return json(200, '{"access_token":"${token}","token_type":"bearer"}')
	})

	// POST /logout
	m.post('/logout', fn [shared store] (req Request) Response {
		token := bearer_token(req) or { return empty(204) }
		lock store {
			store.revoke_token(token)
		}
		return empty(204)
	})

	// GET /users/me
	m.get('/users/me', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return unauthorized('not authenticated') }
		return json(200, user_public_json(u))
	})

	// GET /users/  (superuser)
	m.get('/users/', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return unauthorized('not authenticated') }
		if !u.is_superuser {
			return forbidden('superuser required')
		}
		mut parts := []string{}
		rlock store {
			for _, usr in store.users {
				parts << user_public_json(usr)
			}
		}
		return json(200, '{"data":[${parts.join(',')}],"count":${parts.len}}')
	})

	// POST /users/  (superuser creates user)
	m.post('/users/', fn [shared store] (req Request) Response {
		actor := require_user(shared store, req) or { return unauthorized('not authenticated') }
		if !actor.is_superuser {
			return forbidden('superuser required')
		}
		email := req.json_string('email') or { return bad_request('email required') }
		password := req.json_string('password') or { return bad_request('password required') }
		full_name := req.json_string('full_name') or { '' }
		is_su := req.json_bool('is_superuser') or { false }
		mut created := User{}
		lock store {
			created = store.create_user(email, password, full_name, is_su) or {
				msg := err.msg()
				if msg.contains('already') {
					return conflict(msg)
				}
				return bad_request(msg)
			}
		}
		return json(201, user_public_json(created))
	})

	// GET /items/
	m.get('/items/', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return unauthorized('not authenticated') }
		mut parts := []string{}
		rlock store {
			for _, it in store.items {
				if u.is_superuser || it.owner_id == u.id {
					parts << item_json(it)
				}
			}
		}
		return json(200, '{"data":[${parts.join(',')}],"count":${parts.len}}')
	})

	// POST /items/
	m.post('/items/', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return unauthorized('not authenticated') }
		title := req.json_string('title') or { return bad_request('title required') }
		description := req.json_string('description') or { '' }
		mut created := Item{}
		lock store {
			created = store.create_item(u.id, title, description) or {
				return bad_request(err.msg())
			}
		}
		return json(201, item_json(created))
	})

	// GET /items/:id
	m.get('/items/:id', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return unauthorized('not authenticated') }
		id_str := req.param('id') or { return not_found() }
		id := id_str.int()
		rlock store {
			it := store.item_by_id(id) or { return not_found() }
			if !u.is_superuser && it.owner_id != u.id {
				return forbidden('not owner')
			}
			return json(200, item_json(it))
		}
	})

	// PUT /items/:id
	m.put('/items/:id', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return unauthorized('not authenticated') }
		id_str := req.param('id') or { return not_found() }
		id := id_str.int()
		title := req.json_string('title') or { '' }
		description := req.json_string('description') or { '' }
		lock store {
			it := store.item_by_id(id) or { return not_found() }
			if !u.is_superuser && it.owner_id != u.id {
				return forbidden('not owner')
			}
			updated := store.update_item(id, title, description) or {
				return bad_request(err.msg())
			}
			return json(200, item_json(updated))
		}
	})

	// DELETE /items/:id
	m.delete('/items/:id', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return unauthorized('not authenticated') }
		id_str := req.param('id') or { return not_found() }
		id := id_str.int()
		lock store {
			it := store.item_by_id(id) or { return not_found() }
			if !u.is_superuser && it.owner_id != u.id {
				return forbidden('not owner')
			}
			store.delete_item(id)
			return empty(204)
		}
	})
}
