module main

// Server-rendered pages via V $tmpl.
// Repeated parts (the dashboard rail, table rows) are built in V, so the
// templates stay simple shells on every V version.

struct PageCtx {
	title        string
	email        string
	is_superuser bool
	flash        string
	active       string
	live         ProcessFacts
}

// html_escape is for every request- or user-supplied string a page shows: the
// templates print @{...} as it is.
fn html_escape(s string) string {
	return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')
}

const arrow_svg = '<svg viewBox="0 0 20 20" aria-hidden="true"><path d="M3 10h12M11 5l5 5-5 5" fill="none" stroke="currentColor" stroke-width="2.5"/></svg>'

// The dashboard rail: a filled disc marks the current page. On the sign-in
// page every stop is shown, locked.
fn rail_html(page PageCtx) string {
	pages := [['items', '/items', 'Items'], ['users', '/users', 'Users'],
		['account', '/account', 'Account']]
	mut b := ''
	for p in pages {
		if page.active == 'login' {
			b += '<span class="rail-link is-locked"><span class="disc"></span>${p[2]}</span>'
			continue
		}
		if p[0] == 'users' && !page.is_superuser {
			continue
		}
		current := if p[0] == page.active { ' aria-current="page"' } else { '' }
		b += '<a class="rail-link" href="${p[1]}"${current}><span class="disc"></span>${p[2]}</a>'
	}
	return b
}

fn rail_foot_html(page PageCtx) string {
	status := live_status(page.live)
	if page.active == 'login' {
		return '${status}<p class="who">Not signed in</p><a href="/">About Viltrum</a>'
	}
	return '${status}<p class="who">${page.email}</p><form method="post" action="/logout"><button type="submit" class="plate">Sign out</button></form>'
}

// live_status is the server's pulse: a disc that beats on each fresh reading,
// its clock and its request count. static/live.js keeps the values current.
fn live_status(f ProcessFacts) string {
	return '<p class="status"><span class="pulse" aria-hidden="true"></span>Live, up <b data-live="uptime" data-s="${f.uptime_s}">${f.uptime}</b>, <b data-live="requests">${f.requests}</b> requests</p>'
}

fn plural(n int, word string) string {
	return if n == 1 { '1 ${word}' } else { '${n} ${word}s' }
}

fn render_items_rows(items []Item) string {
	if items.len == 0 {
		return '<tr><td colspan="5" class="empty">No items yet. Add one above, or POST /api/v1/items/ with a Bearer token.</td></tr>'
	}
	mut b := ''
	for it in items {
		title := html_escape(it.title)
		desc := html_escape(it.description)
		b += '<tr><td class="num">${it.id}</td><td class="strong">${title}</td><td class="desc">${desc}</td>'
		b += '<td class="num opt" data-label="Owner">${it.owner_id}</td><td class="act">'
		b += '<form method="post" action="/items/${it.id}/delete"><button type="submit" class="row-btn" aria-label="Delete ${title}">Delete</button></form></td></tr>'
	}
	return b
}

fn render_users_rows(users []User) string {
	mut b := ''
	for u in users {
		email := html_escape(u.email)
		name := html_escape(u.full_name)
		role := if u.is_superuser {
			'<span class="tag is-solid">superuser</span>'
		} else {
			'<span class="tag">user</span>'
		}
		b += '<tr><td class="num">${u.id}</td><td class="strong">${email}</td><td class="opt">${name}</td><td>${role}</td></tr>'
	}
	return b
}

fn view_landing(signed_in bool, origin string, facts ProcessFacts) string {
	// One click signs in as the seeded demo admin: the action a visitor came for.
	band_action := demo_action(signed_in, 'Open the dashboard', 'Dashboard')
	hero_action := demo_action(signed_in, 'Open the live dashboard', 'Open the live dashboard')
	hero_note := if signed_in {
		'You are signed in. The dashboard and the API share your session cookie.'
	} else {
		'Signs you in as admin@example.com. Everything lives in memory.'
	}
	rss_fact := if facts.rss != '' {
		'<span>resident <b data-live="rss">${facts.rss}</b></span>'
	} else {
		''
	}
	store_fact := '${plural(facts.items, 'item')}, ${plural(facts.users, 'user')}'
	return $tmpl('templates/landing.html')
}

// demo_action is the sign-in plate; `short` replaces `label` on the narrowest screens.
fn demo_action(signed_in bool, label string, short string) string {
	text := if label == short {
		label
	} else {
		'<span class="label-long">${label}</span><span class="label-short">${short}</span>'
	}
	if signed_in {
		return '<a class="plate" href="/items">${text} ${arrow_svg}</a>'
	}
	return '<form method="post" action="/login"><input type="hidden" name="email" value="admin@example.com" /><input type="hidden" name="password" value="changethis" /><button type="submit" class="plate">${text} ${arrow_svg}</button></form>'
}

fn view_login(flash string, facts ProcessFacts) string {
	page := PageCtx{
		title:  'Sign in'
		flash:  html_escape(flash)
		active: 'login'
		live:   facts
	}
	rail := rail_html(page)
	rail_foot := rail_foot_html(page)
	behind := '${plural(facts.items, 'item')} and ${plural(facts.users, 'user')} in memory. Sign in to open them.'
	return $tmpl('templates/login.html')
}

fn view_items(page PageCtx, items []Item) string {
	rail := rail_html(page)
	rail_foot := rail_foot_html(page)
	count := plural(items.len, 'item')
	rows := render_items_rows(items)
	return $tmpl('templates/items.html')
}

fn view_users(page PageCtx, users []User) string {
	rail := rail_html(page)
	rail_foot := rail_foot_html(page)
	count := plural(users.len, 'user')
	rows := render_users_rows(users)
	return $tmpl('templates/users.html')
}

fn view_account(page PageCtx, user_id int, full_name string, role string) string {
	rail := rail_html(page)
	rail_foot := rail_foot_html(page)
	return $tmpl('templates/account.html')
}

fn page_for(u User, title string, active string, flash string, live ProcessFacts) PageCtx {
	return PageCtx{
		title:        title
		email:        html_escape(u.email)
		is_superuser: u.is_superuser
		flash:        html_escape(flash)
		active:       active
		live:         live
	}
}
