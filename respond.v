module main

// JSON response shapes and error helpers for the API. Pages answer with c.html and
// c.redirect from Viltrum itself.
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

// request_origin is the scheme and host the visitor used, for the examples a
// page prints. Behind a proxy the scheme comes from X-Forwarded-Proto.
fn request_origin(c &viltrum.Ctx) string {
	host := c.header('Host') or { 'localhost' }
	scheme := if p := c.header('X-Forwarded-Proto') { p } else { 'http' }
	return html_escape('${scheme}://${host}')
}
