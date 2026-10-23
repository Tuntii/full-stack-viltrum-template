module main

// Small response helpers (JSON API + HTML pages). Handlers write one response
// through the Ctx and return.
import viltrum

// UserPublic is what the API shows of a User: never the password hash.
struct UserPublic {
	id           int
	email        string
	full_name    string
	is_superuser bool
}

fn public(u User) UserPublic {
	return UserPublic{
		id:           u.id
		email:        u.email
		full_name:    u.full_name
		is_superuser: u.is_superuser
	}
}

struct UsersPage {
	data  []UserPublic
	count int
}

struct ItemsPage {
	data  []Item
	count int
}

struct Detail {
	detail string
}

struct AccessToken {
	access_token string
	token_type   string
}

struct Health {
	status string
}

fn api_error(mut c viltrum.Ctx, status int, msg string) {
	c.json(status, Detail{
		detail: msg
	})
}

fn unauthorized(mut c viltrum.Ctx) {
	api_error(mut c, 401, 'not authenticated')
}

fn forbidden(mut c viltrum.Ctx, msg string) {
	api_error(mut c, 403, msg)
}

fn bad_request(mut c viltrum.Ctx, msg string) {
	api_error(mut c, 400, msg)
}

fn not_found(mut c viltrum.Ctx) {
	api_error(mut c, 404, 'not found')
}

fn html(mut c viltrum.Ctx, status int, body string) {
	c.bytes(status, 'text/html; charset=utf-8', body.bytes())
}

// redirect answers 303 See Other, so a form POST is followed by a GET.
fn redirect(mut c viltrum.Ctx, location string) {
	c.set_header('Location', location)
	c.no_content(303)
}
