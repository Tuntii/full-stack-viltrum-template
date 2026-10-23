module main

// Live facts about this process for the landing page: what it shows is read
// from the running binary, not written into the copy.
import os
import time
import viltrum
import viltrum.engine

const started_at = time.sys_mono_now()

struct ProcessFacts {
	version string
	workers int
	rss     string // '' off Linux
	uptime  string
}

fn process_facts() ProcessFacts {
	return ProcessFacts{
		version: viltrum.version
		workers: engine.worker_count(0)
		rss:     rss_text()
		uptime:  uptime_text((time.sys_mono_now() - started_at) / i64(time.second))
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

fn uptime_text(secs i64) string {
	if secs < 60 {
		return '${secs} s'
	}
	if secs < 3600 {
		return '${secs / 60} min'
	}
	return '${secs / 3600} h ${secs % 3600 / 60} min'
}
