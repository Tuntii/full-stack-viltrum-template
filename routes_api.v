module main

// JSON API under /api/v1 — for curl, scripts, and optional JS.

import viltrum {
	Mount
	Request
	Response
	empty
	json
	not_found
}

fn register_api(mut m Mount, shared store Store) {
	m.get('/health', fn (_ Request) Response {
		return json(200, '{"status":"ok"}')
	})

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

	m.post('/logout', fn [shared store] (req Request) Response {
		token := session_token(req) or { return empty(204) }
		lock store {
			store.revoke_token(token)
		}
		return empty(204)
	})

	m.get('/users/me', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return unauthorized('not authenticated') }
		return json(200, user_public_json(u))
	})

	m.get('/users/', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return unauthorized('not authenticated') }
		if !u.is_superuser {
			return forbidden('superuser required')
		}
		mut parts := []string{}
		rlock store {
			for usr in store.all_users() {
				parts << user_public_json(usr)
			}
		}
		return json(200, '{"data":[${parts.join(',')}],"count":${parts.len}}')
	})

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

	m.get('/items/', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return unauthorized('not authenticated') }
		mut parts := []string{}
		rlock store {
			for it in store.items_for(u) {
				parts << item_json(it)
			}
		}
		return json(200, '{"data":[${parts.join(',')}],"count":${parts.len}}')
	})

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

	m.get('/items/:id', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return unauthorized('not authenticated') }
		id := (req.param('id') or { return not_found() }).int()
		rlock store {
			it := store.item_by_id(id) or { return not_found() }
			if !u.is_superuser && it.owner_id != u.id {
				return forbidden('not owner')
			}
			return json(200, item_json(it))
		}
	})

	m.put('/items/:id', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return unauthorized('not authenticated') }
		id := (req.param('id') or { return not_found() }).int()
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

	m.delete('/items/:id', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return unauthorized('not authenticated') }
		id := (req.param('id') or { return not_found() }).int()
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
