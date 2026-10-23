// Keeps the pages live with real readings from this server:
// - the line: a train every few seconds is a real GET /api/v1/health, timed;
// - the departure strip and the dashboard's status line poll /api/v1/stats,
//   and the uptime clock ticks between polls;
// - the clone command copies.
// Everything pauses while the tab is hidden. Without JS the pages are complete.
(function () {
  var TRAIN_MS = 7000;
  var POLL_MS = 5000;
  var reduced = matchMedia('(prefers-reduced-motion: reduce)');

  function plural(n, word) {
    return n === 1 ? '1 ' + word : n + ' ' + word + 's';
  }

  function clock(s) {
    var m = Math.floor(s / 60) % 60;
    var sec = s % 60;
    return Math.floor(s / 3600) + ':' + (m < 10 ? '0' : '') + m + ':' + (sec < 10 ? '0' : '') + sec;
  }

  // ---- The line -----------------------------------------------------------
  var send = document.getElementById('send');
  var out = document.getElementById('rtt');
  var said = document.getElementById('rtt-status');
  var line = document.querySelector('.line');
  var busy = false;

  function ride(manual) {
    if (busy || !line) return;
    busy = true;
    // Only a press shows the plate as busy; the timetable runs quietly.
    if (manual && send) send.disabled = true;
    line.classList.remove('go');
    void line.offsetWidth;
    line.classList.add('go');
    var t0 = performance.now();
    var arrive = new Promise(function (done) {
      setTimeout(done, reduced.matches ? 0 : 900);
    });
    var req = fetch('/api/v1/health', { cache: 'no-store' }).then(function (res) {
      return res.text().then(function () {
        return res.status + ' ' + (res.ok ? 'OK' : res.statusText) + ' in ' + (performance.now() - t0).toFixed(1) + ' ms';
      });
    }, function () {
      return 'No answer; the server may be restarting.';
    });
    Promise.all([req, arrive]).then(function (r) {
      out.textContent = r[0];
      if (manual && said) said.textContent = 'Round trip: ' + r[0];
      if (send) send.disabled = false;
      busy = false;
    });
  }

  if (send && out && line) {
    send.hidden = false;
    send.addEventListener('click', function () { ride(true); });
    setTimeout(function () { if (!document.hidden) ride(false); }, 1200);
    setInterval(function () { if (!document.hidden) ride(false); }, TRAIN_MS);
  }

  // ---- Live readings ------------------------------------------------------
  var fields = {};
  document.querySelectorAll('[data-live]').forEach(function (el) {
    (fields[el.getAttribute('data-live')] = fields[el.getAttribute('data-live')] || []).push(el);
  });
  var pulses = document.querySelectorAll('.pulse');
  var base = null; // { s: server uptime seconds, at: when we read it }

  function set(name, text) {
    (fields[name] || []).forEach(function (el) {
      if (el.textContent !== text) el.textContent = text;
    });
  }

  var up = fields.uptime && fields.uptime[0];
  if (up) {
    base = { s: parseInt(up.getAttribute('data-s'), 10) || 0, at: Date.now() };
    setInterval(function () {
      if (document.hidden || !base) return;
      set('uptime', clock(base.s + Math.floor((Date.now() - base.at) / 1000)));
    }, 1000);
  }
  if (fields.requests) set('requests', Number(fields.requests[0].textContent).toLocaleString('en-US'));

  function poll() {
    if (document.hidden) return;
    fetch('/api/v1/stats', { cache: 'no-store' }).then(function (res) {
      return res.ok ? res.json() : null;
    }).then(function (f) {
      if (!f) return;
      base = { s: f.uptime_s, at: Date.now() };
      set('uptime', clock(f.uptime_s));
      set('requests', f.requests.toLocaleString('en-US'));
      if (f.rss) set('rss', f.rss);
      set('store', plural(f.items, 'item') + ', ' + plural(f.users, 'user'));
      pulses.forEach(function (p) {
        p.classList.remove('beat');
        void p.offsetWidth;
        p.classList.add('beat');
      });
    }, function () {});
  }

  if (Object.keys(fields).length) {
    setInterval(poll, POLL_MS);
    document.addEventListener('visibilitychange', function () { if (!document.hidden) poll(); });
  }

  // ---- Copy -----------------------------------------------------------------
  document.querySelectorAll('[data-copy]').forEach(function (btn) {
    btn.hidden = false;
    btn.addEventListener('click', function () {
      var text = document.getElementById(btn.getAttribute('data-copy')).textContent;
      navigator.clipboard.writeText(text).then(function () {
        btn.textContent = 'Copied';
        setTimeout(function () { btn.textContent = 'Copy'; }, 1600);
      });
    });
  });
})();
