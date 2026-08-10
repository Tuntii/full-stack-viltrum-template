module main

// In-memory persistence. Swap this file for Postgres/SQLite later;
// handlers should not care.

import crypto.sha256
import rand
import time

struct Store {
mut:
	next_user_id  int = 1
	next_item_id  int = 1
	users         map[int]User
	items         map[int]Item
	sessions      map[string]Session
	email_index   map[string]int
	password_salt string = 'viltrum-full-stack-demo-salt'
}

fn (s &Store) hash_password(password string) string {
	return sha256.hexhash('${s.password_salt}:${password}')
}

fn (s &Store) check_password(password string, hashed string) bool {
	return s.hash_password(password) == hashed
}

fn (mut s Store) seed_demo() {
	s.seed_superuser('admin@example.com', 'changethis', 'Admin')
	_ := s.create_item(1, 'Welcome item', 'Edit or delete from the dashboard.') or { Item{} }
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
	s.sessions[token] = Session{
		token:      token
		user_id:    user_id
		expires_at: time.now().unix() + 7 * 24 * 3600
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

fn (s &Store) items_for(u User) []Item {
	mut out := []Item{}
	for _, it in s.items {
		if u.is_superuser || it.owner_id == u.id {
			out << it
		}
	}
	return out
}

fn (s &Store) all_users() []User {
	mut out := []User{}
	for _, u in s.users {
		out << u
	}
	return out
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
