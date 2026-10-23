// Landing page: send a real request down the line, and copy the clone command.
(function () {
  var send = document.getElementById('send');
  var out = document.getElementById('rtt');
  var line = document.querySelector('.line');
  if (send && out && line) {
    send.hidden = false;
    send.addEventListener('click', function () {
      send.disabled = true;
      out.textContent = 'GET /api/v1/health';
      line.classList.remove('go');
      void line.offsetWidth;
      line.classList.add('go');
      var t0 = performance.now();
      var ride = new Promise(function (done) {
        setTimeout(done, matchMedia('(prefers-reduced-motion: reduce)').matches ? 0 : 900);
      });
      var req = fetch('/api/v1/health', { cache: 'no-store' }).then(function (res) {
        return res.text().then(function () {
          return res.status + ' ' + (res.ok ? 'OK' : res.statusText) + ' in ' + (performance.now() - t0).toFixed(1) + ' ms';
        });
      }, function () {
        return 'No answer; the server may be restarting. Try again.';
      });
      Promise.all([req, ride]).then(function (r) {
        out.textContent = r[0];
        send.disabled = false;
      });
    });
  }

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
