module main

// Browser pages: SSR with $tmpl + form POSTs + session cookie.

import viltrum {
	App
	Request
	Response
}

fn register_web(mut app App, shared store Store) {
	app.get('/', fn [shared store] (req Request) Response {
		if _ := require_user(shared store, req) {
			return redirect('/items')
		}
		return redirect('/login')
	})

	app.get('/login', fn [shared store] (req Request) Response {
		if _ := require_user(shared store, req) {
			return redirect('/items')
		}
		flash := req.query_param('error') or { '' }
		return html(200, view_login(flash))
	})

	app.post('/login', fn [shared store] (req Request) Response {
		body := req.text()
		email := form_field(body, 'email') or { '' }
		password := form_field(body, 'password') or { '' }
		mut token := ''
		lock store {
			u := store.user_by_email(email) or {
				return redirect('/login?error=incorrect+email+or+password')
			}
			if !store.check_password(password, u.hashed_password) {
				return redirect('/login?error=incorrect+email+or+password')
			}
			token = store.issue_token(u.id)
		}
		mut r := redirect('/items')
		return with_cookie(mut r, set_session_cookie(token))
	})

	app.post('/logout', fn [shared store] (req Request) Response {
		if token := session_token(req) {
			lock store {
				store.revoke_token(token)
			}
		}
		mut r := redirect('/login')
		return with_cookie(mut r, clear_session_cookie())
	})

	app.get('/items', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return redirect('/login') }
		flash := req.query_param('flash') or { '' }
		mut items := []Item{}
		rlock store {
			items = store.items_for(u)
		}
		page := page_for(u, 'Items', 'items', flash)
		return html(200, view_items(page, items))
	})

	app.post('/items', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return redirect('/login') }
		body := req.text()
		title := form_field(body, 'title') or { '' }
		description := form_field(body, 'description') or { '' }
		mut ok := true
		lock store {
			_ := store.create_item(u.id, title, description) or {
				ok = false
				Item{}
			}
		}
		if !ok {
			return redirect('/items?flash=could+not+create+item')
		}
		return redirect('/items?flash=item+created')
	})

	app.post('/items/:id/delete', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return redirect('/login') }
		id := (req.param('id') or { return redirect('/items') }).int()
		lock store {
			it := store.item_by_id(id) or { return redirect('/items') }
			if !u.is_superuser && it.owner_id != u.id {
				return redirect('/items?flash=not+allowed')
			}
			store.delete_item(id)
		}
		return redirect('/items?flash=item+deleted')
	})

	app.get('/users', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return redirect('/login') }
		if !u.is_superuser {
			return redirect('/items?flash=superuser+required')
		}
		mut users := []User{}
		rlock store {
			users = store.all_users()
		}
		page := page_for(u, 'Users', 'users', '')
		return html(200, view_users(page, users))
	})

	app.get('/account', fn [shared store] (req Request) Response {
		u := require_user(shared store, req) or { return redirect('/login') }
		role := if u.is_superuser { 'superuser' } else { 'user' }
		page := page_for(u, 'Account', 'account', '')
		return html(200, view_account(page, u.id, u.full_name, role))
	})
}
