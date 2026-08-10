/* Same-origin SPA against /api/v1. No build step. */

const API = '/api/v1'
const TOKEN_KEY = 'viltrum_full_stack_token'

const state = {
  token: localStorage.getItem(TOKEN_KEY) || '',
  me: null,
  view: 'items',
}

const $ = (sel) => document.querySelector(sel)

function setError(el, msg) {
  if (el) el.textContent = msg || ''
}

async function api(path, opts = {}) {
  const headers = Object.assign({ Accept: 'application/json' }, opts.headers || {})
  if (opts.body && !headers['Content-Type']) {
    headers['Content-Type'] = 'application/json'
  }
  if (state.token) {
    headers.Authorization = `Bearer ${state.token}`
  }
  const res = await fetch(API + path, { ...opts, headers })
  if (res.status === 204) return null
  const text = await res.text()
  let data = null
  try {
    data = text ? JSON.parse(text) : null
  } catch {
    data = { detail: text || res.statusText }
  }
  if (!res.ok) {
    const detail = (data && data.detail) || res.statusText || 'request failed'
    const err = new Error(detail)
    err.status = res.status
    throw err
  }
  return data
}

function show(view) {
  state.view = view
  ;['login', 'items', 'users', 'account'].forEach((name) => {
    const el = $(`#view-${name}`)
    if (el) el.hidden = name !== view
  })
  document.querySelectorAll('.nav-link').forEach((btn) => {
    btn.classList.toggle('is-active', btn.dataset.view === view)
  })
}

function setAuthed(me) {
  state.me = me
  const nav = $('#nav')
  const topEnd = $('#top-end')
  const navUsers = $('#nav-users')
  if (me) {
    nav.hidden = false
    topEnd.textContent = me.email
    navUsers.hidden = !me.is_superuser
  } else {
    nav.hidden = true
    topEnd.textContent = ''
    navUsers.hidden = true
  }
}

async function loadMe() {
  if (!state.token) {
    setAuthed(null)
    show('login')
    return
  }
  try {
    const me = await api('/users/me')
    setAuthed(me)
    show(state.view === 'login' ? 'items' : state.view)
    if (state.view === 'items') await loadItems()
    if (state.view === 'users' && me.is_superuser) await loadUsers()
    if (state.view === 'account') renderAccount()
  } catch {
    state.token = ''
    localStorage.removeItem(TOKEN_KEY)
    setAuthed(null)
    show('login')
  }
}

async function loadItems() {
  const list = $('#item-list')
  const empty = $('#items-empty')
  list.innerHTML = ''
  try {
    const res = await api('/items/')
    const items = (res && res.data) || []
    empty.hidden = items.length > 0
    items.forEach((it) => {
      const li = document.createElement('li')
      li.innerHTML = `
        <div>
          <div class="title"></div>
          <span class="tag">#${it.id}</span>
        </div>
        <div class="actions">
          <button type="button" class="btn btn-quiet" data-edit>Edit</button>
          <button type="button" class="btn btn-danger" data-del>Delete</button>
        </div>
        <p class="desc"></p>`
      li.querySelector('.title').textContent = it.title
      li.querySelector('.desc').textContent = it.description || ''
      li.querySelector('[data-edit]').addEventListener('click', () => openItemForm(it))
      li.querySelector('[data-del]').addEventListener('click', () => deleteItem(it.id))
      list.appendChild(li)
    })
  } catch (e) {
    empty.hidden = false
    empty.textContent = e.message
  }
}

function openItemForm(item) {
  const form = $('#item-form')
  form.hidden = false
  form.id.value = item ? item.id : ''
  form.title.value = item ? item.title : ''
  form.description.value = item ? item.description || '' : ''
  form.title.focus()
}

function closeItemForm() {
  const form = $('#item-form')
  form.hidden = true
  form.reset()
  form.id.value = ''
}

async function deleteItem(id) {
  if (!confirm('Delete this item?')) return
  try {
    await api(`/items/${id}`, { method: 'DELETE' })
    await loadItems()
  } catch (e) {
    alert(e.message)
  }
}

async function loadUsers() {
  const list = $('#user-list')
  list.innerHTML = ''
  try {
    const res = await api('/users/')
    const users = (res && res.data) || []
    users.forEach((u) => {
      const li = document.createElement('li')
      li.innerHTML = `
        <div>
          <div class="title"></div>
          <span class="tag"></span>
        </div>
        <p class="desc"></p>`
      li.querySelector('.title').textContent = u.email
      li.querySelector('.tag').textContent = u.is_superuser ? 'superuser' : `id ${u.id}`
      li.querySelector('.desc').textContent = u.full_name || ''
      list.appendChild(li)
    })
  } catch (e) {
    list.innerHTML = `<li><p class="desc">${e.message}</p></li>`
  }
}

function renderAccount() {
  const me = state.me
  const dl = $('#account-meta')
  if (!me) return
  dl.innerHTML = `
    <dt>Email</dt><dd></dd>
    <dt>Name</dt><dd></dd>
    <dt>Role</dt><dd></dd>
    <dt>Id</dt><dd></dd>`
  const dds = dl.querySelectorAll('dd')
  dds[0].textContent = me.email
  dds[1].textContent = me.full_name || '—'
  dds[2].textContent = me.is_superuser ? 'superuser' : 'user'
  dds[3].textContent = String(me.id)
}

function wire() {
  $('#login-form').addEventListener('submit', async (ev) => {
    ev.preventDefault()
    const fd = new FormData(ev.target)
    setError($('#login-error'), '')
    try {
      const body = JSON.stringify({
        username: fd.get('email'),
        password: fd.get('password'),
      })
      const res = await api('/login/access-token', { method: 'POST', body })
      state.token = res.access_token
      localStorage.setItem(TOKEN_KEY, state.token)
      state.view = 'items'
      await loadMe()
    } catch (e) {
      setError($('#login-error'), e.message)
    }
  })

  $('#logout-btn').addEventListener('click', async () => {
    try {
      await api('/logout', { method: 'POST' })
    } catch {
      /* ignore */
    }
    state.token = ''
    localStorage.removeItem(TOKEN_KEY)
    setAuthed(null)
    show('login')
  })

  document.querySelectorAll('.nav-link').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const view = btn.dataset.view
      show(view)
      if (view === 'items') await loadItems()
      if (view === 'users') await loadUsers()
      if (view === 'account') renderAccount()
    })
  })

  $('#item-new').addEventListener('click', () => openItemForm(null))
  $('#item-cancel').addEventListener('click', closeItemForm)

  $('#item-form').addEventListener('submit', async (ev) => {
    ev.preventDefault()
    const fd = new FormData(ev.target)
    const id = fd.get('id')
    const payload = {
      title: fd.get('title'),
      description: fd.get('description') || '',
    }
    try {
      if (id) {
        await api(`/items/${id}`, { method: 'PUT', body: JSON.stringify(payload) })
      } else {
        await api('/items/', { method: 'POST', body: JSON.stringify(payload) })
      }
      closeItemForm()
      await loadItems()
    } catch (e) {
      alert(e.message)
    }
  })
}

wire()
loadMe()
