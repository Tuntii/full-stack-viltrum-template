module main

// Domain types only — no I/O, no HTTP.

struct User {
	id              int
	email           string
	full_name       string
	is_superuser    bool
	hashed_password string
}

struct Item {
	id          int
	title       string
	description string
	owner_id    int
}

struct Session {
	token      string
	user_id    int
	expires_at i64
}
