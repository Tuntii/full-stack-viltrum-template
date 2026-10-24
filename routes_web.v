module main

// Browser pages: SSR with $tmpl + form POSTs + session cookie.
import viltrum

fn register_web(mut app viltrum.App, shared store Store, hits &Hits, shared reqlog ReqLog) {
	// The landing page introduces Viltrum; its numbers come from this process.
	app.get('/', fn [shared store, hits, shared reqlog] (mut c viltrum.Ctx) {
		signed_in := if _ := require_user(shared store, c) { true } else { false }
		c.html(200, view_landing(signed_in, request_origin(c), live_facts(shared store, hits, shared
			reqlog)))
	})

	app.get('/login', fn [shared store, hits, shared reqlog] (mut c viltrum.Ctx) {
		if _ := require_user(shared store, c) {
			c.redirect(303, '/items')
			return
		}
		flash := c.query_param('error') or { '' }
		c.html(200, view_login(flash, live_facts(shared store, hits, shared reqlog)))
	})

	app.post('/login', fn [shared store] (mut c viltrum.Ctx) {
		email := c.form_value('email') or { '' }
		password := c.form_value('password') or { '' }
		mut token := ''
		lock store {
			if u := store.user_by_email(email) {
				if store.check_password(password, u.hashed_password) {
					token = store.issue_token(u.id)
				}
			}
		}
		if token == '' {
			c.redirect(303, '/login?error=incorrect+email+or+password')
			return
		}
		c.set_cookie(name: session_cookie, value: token, max_age: session_max_age)
		c.redirect(303, '/items')
	})

	app.post('/logout', fn [shared store] (mut c viltrum.Ctx) {
		if token := session_token(c) {
			lock store {
				store.revoke_token(token)
			}
		}
		c.clear_cookie(name: session_cookie)
		c.redirect(303, '/login')
	})

	app.get('/items', fn [shared store, hits, shared reqlog] (mut c viltrum.Ctx) {
		u := require_user(shared store, c) or {
			c.redirect(303, '/login')
			return
		}
		flash := c.query_param('flash') or { '' }
		mut items := []Item{}
		rlock store {
			items = store.items_for(u)
		}
		c.html(200, view_items(page_for(u, 'Items', 'items', flash, live_facts(shared store, hits, shared
			reqlog)), items))
	})

	app.post('/items', fn [shared store] (mut c viltrum.Ctx) {
		u := require_user(shared store, c) or {
			c.redirect(303, '/login')
			return
		}
		title := c.form_value('title') or { '' }
		description := c.form_value('description') or { '' }
		mut ok := true
		lock store {
			_ := store.create_item(u.id, title, description) or {
				ok = false
				Item{}
			}
		}
		c.redirect(303, if ok {
			'/items?flash=item+created'
		} else {
			'/items?flash=could+not+create+item'
		})
	})

	app.post('/items/:id/delete', fn [shared store] (mut c viltrum.Ctx) {
		u := require_user(shared store, c) or {
			c.redirect(303, '/login')
			return
		}
		id := int(c.param_int('id') or { -1 })
		mut flash := 'item+deleted'
		lock store {
			if it := store.item_by_id(id) {
				if u.is_superuser || it.owner_id == u.id {
					store.delete_item(id)
				} else {
					flash = 'not+allowed'
				}
			} else {
				flash = 'no+such+item'
			}
		}
		c.redirect(303, '/items?flash=${flash}')
	})

	app.get('/users', fn [shared store, hits, shared reqlog] (mut c viltrum.Ctx) {
		u := require_user(shared store, c) or {
			c.redirect(303, '/login')
			return
		}
		if !u.is_superuser {
			c.redirect(303, '/items?flash=superuser+required')
			return
		}
		mut users := []User{}
		rlock store {
			users = store.all_users()
		}
		c.html(200, view_users(page_for(u, 'Users', 'users', '', live_facts(shared store, hits, shared
			reqlog)), users))
	})

	app.get('/account', fn [shared store, hits, shared reqlog] (mut c viltrum.Ctx) {
		u := require_user(shared store, c) or {
			c.redirect(303, '/login')
			return
		}
		role := if u.is_superuser { 'superuser' } else { 'user' }
		c.html(200, view_account(page_for(u, 'Account', 'account', '', live_facts(shared store,
			hits, shared reqlog)), u.id, html_escape(u.full_name), role))
	})
}
