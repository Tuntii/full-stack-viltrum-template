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
}

fn process_facts(hits &Hits, items int, users int) ProcessFacts {
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
fn live_facts(shared store Store, hits &Hits) ProcessFacts {
	mut items := 0
	mut users := 0
	rlock store {
		items = store.items.len
		users = store.users.len
	}
	return process_facts(hits, items, users)
}
