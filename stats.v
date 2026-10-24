module main

// Live facts about this process for the landing page and the dashboard: what
// they show is read from the running binary, not written into the copy.
import os
import sync.stdatomic
import time
import viltrum
import viltrum.engine

const started_at = time.sys_mono_now()

// Hits counts the requests served since start, across every worker.
@[heap]
struct Hits {
mut:
	n u64
}

fn (mut h Hits) add() {
	stdatomic.add_u64(&h.n, 1)
}

fn (h &Hits) count() u64 {
	return stdatomic.load_u64(&h.n)
}

// Served is one line of the live request log on the landing page.
struct Served {
	seq    u64
	method string
	route  string
	status int
	us     i64
}

// ReqLog keeps the last few requests this server answered, newest last.
struct ReqLog {
mut:
	seq  u64
	rows []Served
}

const log_rows = 9

fn (mut l ReqLog) add(method string, path string, status int, us i64) {
	l.seq++
	l.rows << Served{
		seq:    l.seq
		method: method.clone()
		route:  route_of(path, status)
		status: status
		us:     us
	}
	if l.rows.len > log_rows {
		l.rows.delete(0)
	}
}

// route_of keeps ids and whatever a scanner probes out of a public log: numeric
// segments become :id, and paths with no route are not shown.
fn route_of(path string, status int) string {
	if status == 404 {
		return '(no route)'
	}
	mut parts := path.split('/')
	for i, p in parts {
		if p.len > 0 && p.bytes().all(it.is_digit()) {
			parts[i] = ':id'
		}
	}
	r := parts.join('/')
	return if r.len > 40 { r[..40] + '...' } else { r }
}

// ProcessFacts is also the JSON of GET /api/v1/stats, which the pages poll.
struct ProcessFacts {
	version  string
	workers  int
	rss      string // '' off Linux
	uptime   string
	uptime_s i64
	requests u64
	items    int
	users    int
	recent   []Served
}

fn process_facts(hits &Hits, items int, users int, recent []Served) ProcessFacts {
	secs := (time.sys_mono_now() - started_at) / i64(time.second)
	return ProcessFacts{
		version:  viltrum.version
		workers:  engine.worker_count(0)
		rss:      rss_text()
		uptime:   uptime_text(secs)
		uptime_s: secs
		requests: hits.count()
		items:    items
		users:    users
		recent:   recent
	}
}

// rss_text reads VmRSS from /proc/self/status.
fn rss_text() string {
	status := os.read_file('/proc/self/status') or { return '' }
	for line in status.split_into_lines() {
		if line.starts_with('VmRSS:') {
			kb := line.all_after(':').trim_space().all_before(' ').int()
			return '${f64(kb) / 1024:.1f} MB'
		}
	}
	return ''
}

// uptime_text reads like a departure board clock: H:MM:SS.
fn uptime_text(secs i64) string {
	return '${secs / 3600}:${secs % 3600 / 60:02}:${secs % 60:02}'
}

// live_facts reads the store's counts and this process's facts in one call.
fn live_facts(shared store Store, hits &Hits, shared reqlog ReqLog) ProcessFacts {
	mut items := 0
	mut users := 0
	rlock store {
		items = store.items.len
		users = store.users.len
	}
	mut recent := []Served{}
	rlock reqlog {
		recent = reqlog.rows.clone()
	}
	return process_facts(hits, items, users, recent)
}
