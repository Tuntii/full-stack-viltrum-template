module main

// Server-rendered pages via V $tmpl.
// List bodies are built in V (simpler than heavy @for in templates on all V versions).

struct PageCtx {
	title        string
	email        string
	is_superuser bool
	flash        string
	active       string
}

fn html_escape(s string) string {
	return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')
}

fn nav_users_html(is_superuser bool) string {
	if is_superuser {
		return '<a class="nav-link" href="/users">Users</a>'
	}
	return ''
}

fn render_items_list(items []Item) string {
	mut b := ''
	for it in items {
		title := html_escape(it.title)
		desc := html_escape(it.description)
		b += '<li><div><div class="title">${title}</div><span class="tag">#${it.id}</span></div>'
		b += '<form method="post" action="/items/${it.id}/delete" class="inline">'
		b += '<button type="submit" class="btn btn-danger">Delete</button></form>'
		b += '<p class="desc">${desc}</p></li>'
	}
	return b
}

fn render_users_list(users []User) string {
	mut b := ''
	for u in users {
		email := html_escape(u.email)
		name := html_escape(u.full_name)
		tag := if u.is_superuser { 'superuser' } else { 'id ${u.id}' }
		b += '<li><div><div class="title">${email}</div><span class="tag">${tag}</span></div>'
		b += '<p class="desc">${name}</p></li>'
	}
	return b
}

fn view_login(flash string) string {
	page := PageCtx{
		title:        'Sign in'
		email:        ''
		is_superuser: false
		flash:        flash
		active:       'login'
	}
	return $tmpl('templates/login.html')
}

fn view_items(page PageCtx, items []Item) string {
	nav_users := nav_users_html(page.is_superuser)
	items_html := render_items_list(items)
	return $tmpl('templates/items.html')
}

fn view_users(page PageCtx, users []User) string {
	users_html := render_users_list(users)
	return $tmpl('templates/users.html')
}

fn view_account(page PageCtx, user_id int, full_name string, role string) string {
	nav_users := nav_users_html(page.is_superuser)
	return $tmpl('templates/account.html')
}

fn page_for(u User, title string, active string, flash string) PageCtx {
	return PageCtx{
		title:        title
		email:        u.email
		is_superuser: u.is_superuser
		flash:        flash
		active:       active
	}
}
