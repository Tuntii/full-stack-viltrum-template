module main

// In-memory app state. Teaching stand-in for a database.
// Production apps pick their own store (Postgres, SQLite, files).
// Viltrum itself has no ORM — by design.

import crypto.sha256
import rand
import time

struct User {
	id       int
	email    string
	full_name string
	is_superuser bool
	hashed_password string
}

struct Item {
	id          int
	title       string
	description string
	owner_id    int
}

struct Session {
	token     string
	user_id   int
	expires_at i64
}

struct Store {
mut:
	next_user_id int = 1
	next_item_id int = 1
	users        map[int]User
	items        map[int]Item
	// token -> session
	sessions     map[string]Session
	// email lower -> user id
	email_index  map[string]int
	password_salt string = 'viltrum-full-stack-demo-salt'
}

fn (s &Store) hash_password(password string) string {
	return sha256.hexhash('${s.password_salt}:${password}')
}

fn (s &Store) check_password(password string, hashed string) bool {
	return s.hash_password(password) == hashed
}

fn (mut s Store) seed_superuser(email string, password string, full_name string) {
	if email.to_lower() in s.email_index {
		return
	}
	id := s.next_user_id
	s.next_user_id++
	u := User{
		id:              id
		email:           email
		full_name:       full_name
		is_superuser:    true
		hashed_password: s.hash_password(password)
	}
	s.users[id] = u
	s.email_index[email.to_lower()] = id
}

fn (mut s Store) create_user(email string, password string, full_name string, is_superuser bool) !User {
	key := email.to_lower()
	if key in s.email_index {
		return error('email already registered')
	}
	if email.len == 0 || !email.contains('@') {
		return error('invalid email')
	}
	if password.len < 8 {
		return error('password must be at least 8 characters')
	}
	id := s.next_user_id
	s.next_user_id++
	u := User{
		id:              id
		email:           email
		full_name:       full_name
		is_superuser:    is_superuser
		hashed_password: s.hash_password(password)
	}
	s.users[id] = u
	s.email_index[key] = id
	return u
}

fn (s &Store) user_by_email(email string) ?User {
	id := s.email_index[email.to_lower()] or { return none }
	return s.users[id] or { none }
}

fn (s &Store) user_by_id(id int) ?User {
	return s.users[id] or { none }
}

fn (mut s Store) issue_token(user_id int) string {
	token := 'vt_${rand.u64()}_${rand.u64()}_${time.sys_mono_now()}'
	// 7 days
	expires := time.now().unix() + 7 * 24 * 3600
	s.sessions[token] = Session{
		token:      token
		user_id:    user_id
		expires_at: expires
	}
	return token
}

fn (mut s Store) revoke_token(token string) {
	s.sessions.delete(token)
}

fn (mut s Store) user_from_token(token string) ?User {
	sess := s.sessions[token] or { return none }
	if sess.expires_at < time.now().unix() {
		s.sessions.delete(token)
		return none
	}
	return s.users[sess.user_id] or { none }
}

fn (mut s Store) create_item(owner_id int, title string, description string) !Item {
	if title.trim_space().len == 0 {
		return error('title required')
	}
	id := s.next_item_id
	s.next_item_id++
	it := Item{
		id:          id
		title:       title.trim_space()
		description: description
		owner_id:    owner_id
	}
	s.items[id] = it
	return it
}

fn (s &Store) item_by_id(id int) ?Item {
	return s.items[id] or { none }
}

fn (mut s Store) update_item(id int, title string, description string) !Item {
	old := s.items[id] or { return error('not found') }
	new_title := if title.trim_space().len > 0 { title.trim_space() } else { old.title }
	it := Item{
		id:          old.id
		title:       new_title
		description: description
		owner_id:    old.owner_id
	}
	s.items[id] = it
	return it
}

fn (mut s Store) delete_item(id int) bool {
	if id in s.items {
		s.items.delete(id)
		return true
	}
	return false
}

fn json_escape(s string) string {
	return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '\\r')
}

fn user_public_json(u User) string {
	su := if u.is_superuser { 'true' } else { 'false' }
	return '{"id":${u.id},"email":"${json_escape(u.email)}","full_name":"${json_escape(u.full_name)}","is_superuser":${su}}'
}

fn item_json(it Item) string {
	return '{"id":${it.id},"title":"${json_escape(it.title)}","description":"${json_escape(it.description)}","owner_id":${it.owner_id}}'
}
