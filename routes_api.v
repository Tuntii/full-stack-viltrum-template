module main

// JSON API under /api/v1 — for curl, scripts, and optional JS.
import json
import viltrum

struct LoginIn {
	username string // the email, as in OAuth2's password flow
	email    string
	password string
}

struct UserIn {
	email        string
	password     string
	full_name    string
	is_superuser bool
}

struct ItemIn {
	title       string
	description string
}

// decode_body reads a JSON request body into T; none when it is not valid JSON.
fn decode_body[T](c &viltrum.Ctx) ?T {
	return json.decode(T, c.body().bytestr()) or { return none }
}

// login_input takes the credentials from a form body (OAuth2 password flow, what
// FastAPI's /login/access-token expects) or from JSON.
fn login_input(mut c viltrum.Ctx) LoginIn {
	if username := c.form_value('username') {
		return LoginIn{
			username: username.clone()
			password: (c.form_value('password') or { '' }).clone()
		}
	}
	return decode_body[LoginIn](c) or { LoginIn{} }
}

fn register_api(mut api viltrum.Group, shared store Store, hits &Hits, shared reqlog ReqLog) {
	api.get('/health', fn (mut c viltrum.Ctx) {
		c.json(200, Health{
			status: 'ok'
		})
	})

	// The live pages poll this for their departure strip and status line.
	api.get('/stats', fn [shared store, hits, shared reqlog] (mut c viltrum.Ctx) {
		c.set_header('Cache-Control', 'no-store')
		c.json(200, live_facts(shared store, hits, shared reqlog))
	})

	api.post('/login/access-token', fn [shared store] (mut c viltrum.Ctx) {
		input := login_input(mut c)
		email := if input.username != '' { input.username } else { input.email }
		if email == '' || input.password == '' {
			bad_request(mut c, 'username (email) and password required')
			return
		}
		mut token := ''
		lock store {
			if u := store.user_by_email(email) {
				if store.check_password(input.password, u.hashed_password) {
					token = store.issue_token(u.id)
				}
			}
		}
		if token == '' {
			api_error(mut c, 401, 'incorrect email or password')
			return
		}
		c.json(200, AccessToken{
			access_token: token
			token_type:   'bearer'
		})
	})

	api.post('/logout', fn [shared store] (mut c viltrum.Ctx) {
		if token := session_token(c) {
			lock store {
				store.revoke_token(token)
			}
		}
		c.no_content(204)
	})

	api.get('/users/me', fn [shared store] (mut c viltrum.Ctx) {
		u := require_user(shared store, c) or {
			unauthorized(mut c)
			return
		}
		c.json(200, public(u))
	})

	api.get('/users/', fn [shared store] (mut c viltrum.Ctx) {
		u := require_user(shared store, c) or {
			unauthorized(mut c)
			return
		}
		if !u.is_superuser {
			forbidden(mut c, 'superuser required')
			return
		}
		mut users := []UserPublic{}
		rlock store {
			for usr in store.all_users() {
				users << public(usr)
			}
		}
		c.json(200, UsersPage{
			data:  users
			count: users.len
		})
	})

	api.post('/users/', fn [shared store] (mut c viltrum.Ctx) {
		actor := require_user(shared store, c) or {
			unauthorized(mut c)
			return
		}
		if !actor.is_superuser {
			forbidden(mut c, 'superuser required')
			return
		}
		input := decode_body[UserIn](c) or {
			bad_request(mut c, 'a JSON body is required')
			return
		}
		mut created := User{}
		mut failure := ''
		lock store {
			created = store.create_user(input.email, input.password, input.full_name,
				input.is_superuser) or {
				failure = err.msg()
				User{}
			}
		}
		if failure != '' {
			status := if failure.contains('already') { 409 } else { 400 }
			api_error(mut c, status, failure)
			return
		}
		c.json(201, public(created))
	})

	api.get('/items/', fn [shared store] (mut c viltrum.Ctx) {
		u := require_user(shared store, c) or {
			unauthorized(mut c)
			return
		}
		mut items := []Item{}
		rlock store {
			items = store.items_for(u)
		}
		c.json(200, ItemsPage{
			data:  items
			count: items.len
		})
	})

	api.post('/items/', fn [shared store] (mut c viltrum.Ctx) {
		u := require_user(shared store, c) or {
			unauthorized(mut c)
			return
		}
		input := decode_body[ItemIn](c) or {
			bad_request(mut c, 'a JSON body is required')
			return
		}
		mut created := Item{}
		mut failure := ''
		lock store {
			created = store.create_item(u.id, input.title, input.description) or {
				failure = err.msg()
				Item{}
			}
		}
		if failure != '' {
			bad_request(mut c, failure)
			return
		}
		c.json(201, created)
	})

	api.get('/items/:id', fn [shared store] (mut c viltrum.Ctx) {
		u := require_user(shared store, c) or {
			unauthorized(mut c)
			return
		}
		id := int(c.param_int('id') or { -1 })
		mut found := Item{}
		mut ok := false
		rlock store {
			if it := store.item_by_id(id) {
				found = it
				ok = true
			}
		}
		if !ok {
			not_found(mut c)
			return
		}
		if !u.is_superuser && found.owner_id != u.id {
			forbidden(mut c, 'not owner')
			return
		}
		c.json(200, found)
	})

	api.put('/items/:id', fn [shared store] (mut c viltrum.Ctx) {
		u := require_user(shared store, c) or {
			unauthorized(mut c)
			return
		}
		id := int(c.param_int('id') or { -1 })
		input := decode_body[ItemIn](c) or {
			bad_request(mut c, 'a JSON body is required')
			return
		}
		mut status := 200
		mut updated := Item{}
		lock store {
			if it := store.item_by_id(id) {
				if u.is_superuser || it.owner_id == u.id {
					updated = store.update_item(id, input.title, input.description) or { Item{} }
				} else {
					status = 403
				}
			} else {
				status = 404
			}
		}
		match status {
			403 { forbidden(mut c, 'not owner') }
			404 { not_found(mut c) }
			else { c.json(200, updated) }
		}
	})

	api.delete('/items/:id', fn [shared store] (mut c viltrum.Ctx) {
		u := require_user(shared store, c) or {
			unauthorized(mut c)
			return
		}
		id := int(c.param_int('id') or { -1 })
		mut status := 204
		lock store {
			if it := store.item_by_id(id) {
				if u.is_superuser || it.owner_id == u.id {
					store.delete_item(id)
				} else {
					status = 403
				}
			} else {
				status = 404
			}
		}
		match status {
			403 { forbidden(mut c, 'not owner') }
			404 { not_found(mut c) }
			else { c.no_content(204) }
		}
	})
}
