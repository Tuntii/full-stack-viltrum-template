module main

// Browser pages: SSR with $tmpl + form POSTs + session cookie.
import viltrum

fn register_web(mut app viltrum.App, shared store Store) {
	// The landing page introduces Viltrum; its numbers come from this process.
	app.get('/', fn [shared store] (mut c viltrum.Ctx) {
		signed_in := if _ := require_user(shared store, c) { true } else { false }
		mut items := 0
		mut users := 0
		rlock store {
			items = store.items.len
			users = store.users.len
		}
		html(mut c, 200, view_landing(signed_in, request_origin(c), process_facts(), items, users))
	})

	app.get('/login', fn [shared store] (mut c viltrum.Ctx) {
		if _ := require_user(shared store, c) {
			redirect(mut c, '/items')
			return
		}
		flash := c.query_param('error') or { '' }
		mut items := 0
		mut users := 0
		rlock store {
			items = store.items.len
			users = store.users.len
		}
		html(mut c, 200, view_login(flash, items, users))
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
			redirect(mut c, '/login?error=incorrect+email+or+password')
			return
		}
		c.set_header('Set-Cookie', set_session_cookie(token))
		redirect(mut c, '/items')
	})

	app.post('/logout', fn [shared store] (mut c viltrum.Ctx) {
		if token := session_token(c) {
			lock store {
				store.revoke_token(token)
			}
		}
		c.set_header('Set-Cookie', clear_session_cookie())
		redirect(mut c, '/login')
	})

	app.get('/items', fn [shared store] (mut c viltrum.Ctx) {
		u := require_user(shared store, c) or {
			redirect(mut c, '/login')
			return
		}
		flash := c.query_param('flash') or { '' }
		mut items := []Item{}
		rlock store {
			items = store.items_for(u)
		}
		html(mut c, 200, view_items(page_for(u, 'Items', 'items', flash), items))
	})

	app.post('/items', fn [shared store] (mut c viltrum.Ctx) {
		u := require_user(shared store, c) or {
			redirect(mut c, '/login')
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
		redirect(mut c, if ok {
			'/items?flash=item+created'
		} else {
			'/items?flash=could+not+create+item'
		})
	})

	app.post('/items/:id/delete', fn [shared store] (mut c viltrum.Ctx) {
		u := require_user(shared store, c) or {
			redirect(mut c, '/login')
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
		redirect(mut c, '/items?flash=${flash}')
	})

	app.get('/users', fn [shared store] (mut c viltrum.Ctx) {
		u := require_user(shared store, c) or {
			redirect(mut c, '/login')
			return
		}
		if !u.is_superuser {
			redirect(mut c, '/items?flash=superuser+required')
			return
		}
		mut users := []User{}
		rlock store {
			users = store.all_users()
		}
		html(mut c, 200, view_users(page_for(u, 'Users', 'users', ''), users))
	})

	app.get('/account', fn [shared store] (mut c viltrum.Ctx) {
		u := require_user(shared store, c) or {
			redirect(mut c, '/login')
			return
		}
		role := if u.is_superuser { 'superuser' } else { 'user' }
		html(mut c, 200, view_account(page_for(u, 'Account', 'account', ''), u.id,
			html_escape(u.full_name), role))
	})
}
