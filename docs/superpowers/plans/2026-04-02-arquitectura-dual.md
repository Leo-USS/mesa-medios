# Arquitectura Dual USS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transformar el dashboard único de Mesa de Medios en un sistema dual que también aloja Mesa Editorial, con auth compartido, selector post-login, y componentes reutilizables.

**Architecture:** El nuevo `App.jsx` asume toda la lógica de auth y enruta a `DashboardSelector`, `MesaMediosApp` o `MesaEditorialApp`. Los componentes compartidos viven en `src/apps/shared/`. Mesa de Medios se mueve a `src/apps/mesa-medios/` sin cambios funcionales. Mesa Editorial es nueva en `src/apps/mesa-editorial/`.

**Tech Stack:** React 18, Vite, Supabase (auth + DB + realtime), CSS variables, Montserrat. Sin dependencias npm nuevas.

**Branch:** `arquitectura-dual` (desde `mejoras-quick-wins`)

---

## Archivos: mapa completo

### Archivos movidos (sin cambios de lógica)
- `src/supabase.js` → `src/apps/shared/utils/supabase.js`
- `src/hooks/useToast.js` → `src/apps/shared/hooks/useToast.js`
- `src/hooks/useDebounce.js` → `src/apps/shared/hooks/useDebounce.js`
- `src/components/Toaster.jsx` → `src/apps/shared/components/Toaster.jsx`
- `src/components/ConfirmDialog.jsx` → `src/apps/shared/components/ConfirmDialog.jsx`
- `src/components/USSLoader.jsx` → `src/apps/shared/components/USSLoader.jsx`
- `src/components/MediaTable.jsx` → `src/apps/mesa-medios/components/MediaTable.jsx`
- `src/components/MobileCardView.jsx` → `src/apps/mesa-medios/components/MobileCardView.jsx`
- `src/components/AddRowModal.jsx` → `src/apps/mesa-medios/components/AddRowModal.jsx`
- `src/components/AuditLogPanel.jsx` → `src/apps/mesa-medios/components/AuditLogPanel.jsx`
- `src/components/CellPopover.jsx` → `src/apps/mesa-medios/components/CellPopover.jsx`
- `src/config.js` → `src/apps/mesa-medios/config.js`

### Archivos modificados
- `src/App.jsx` — nuevo router con auth
- `src/components/Login.jsx` → `src/apps/shared/components/Login.jsx` — título genérico
- `src/components/Header.jsx` → `src/apps/mesa-medios/components/Header.jsx` — añade `onBackToSelector` prop

### Archivos nuevos (Mesa de Medios)
- `src/apps/mesa-medios/MesaMediosApp.jsx` — App.jsx original adaptado (sin auth)
- `src/apps/mesa-medios/utils.js` — getCellData, setCellData, getRowProgress (movidos desde App.jsx)

### Archivos nuevos (Shared)
- `src/apps/shared/DashboardSelector.jsx`

### Archivos nuevos (Mesa Editorial)
- `src/apps/mesa-editorial/config.js`
- `src/apps/mesa-editorial/MesaEditorialApp.jsx`
- `src/apps/mesa-editorial/components/Header.jsx`
- `src/apps/mesa-editorial/components/EditorialTable.jsx`
- `src/apps/mesa-editorial/components/EjeSection.jsx`
- `src/apps/mesa-editorial/components/AddActionModal.jsx`
- `src/apps/mesa-editorial/components/MobileCardView.jsx`

### Archivos de SQL
- `supabase-editorial-setup.sql` — CREATE TABLE + RLS + Realtime + 56 INSERTs

---

## Task 1: Crear branch y estructura de directorios

**Files:** Solo git + filesystem

- [ ] **Step 1: Crear branch desde mejoras-quick-wins**

```bash
cd "C:/Users/leopu/Desktop/Trabajo/USS/mesa-medios-main"
git checkout mejoras-quick-wins
git checkout -b arquitectura-dual
```

Expected: `Switched to a new branch 'arquitectura-dual'`

- [ ] **Step 2: Crear directorios**

```bash
mkdir -p src/apps/mesa-medios/components
mkdir -p src/apps/mesa-editorial/components
mkdir -p src/apps/shared/components
mkdir -p src/apps/shared/hooks
mkdir -p src/apps/shared/utils
```

- [ ] **Step 3: Verificar estructura**

```bash
ls src/apps/
```

Expected: `mesa-editorial/  mesa-medios/  shared/`

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "chore: create multi-app directory structure"
```

---

## Task 2: Mover utilidades compartidas

**Files:**
- Create: `src/apps/shared/utils/supabase.js`
- Create: `src/apps/shared/hooks/useToast.js`
- Create: `src/apps/shared/hooks/useDebounce.js`
- Create: `src/apps/shared/components/Toaster.jsx`
- Create: `src/apps/shared/components/ConfirmDialog.jsx`
- Create: `src/apps/shared/components/USSLoader.jsx`
- Create: `src/apps/shared/components/Login.jsx`

- [ ] **Step 1: Copiar supabase.js a shared/utils/**

Crear `src/apps/shared/utils/supabase.js` con el MISMO contenido que `src/supabase.js` (sin cambios):

```bash
cp src/supabase.js src/apps/shared/utils/supabase.js
```

- [ ] **Step 2: Copiar hooks a shared/hooks/**

```bash
cp src/hooks/useToast.js src/apps/shared/hooks/useToast.js
cp src/hooks/useDebounce.js src/apps/shared/hooks/useDebounce.js
```

- [ ] **Step 3: Copiar componentes compartidos a shared/components/**

```bash
cp src/components/Toaster.jsx src/apps/shared/components/Toaster.jsx
cp src/components/ConfirmDialog.jsx src/apps/shared/components/ConfirmDialog.jsx
cp src/components/USSLoader.jsx src/apps/shared/components/USSLoader.jsx
```

- [ ] **Step 4: Crear Login.jsx compartido**

Crear `src/apps/shared/components/Login.jsx`. Es una copia de `src/components/Login.jsx` con dos cambios:
1. Import de supabase: `from '../utils/supabase'`
2. LoginHeader con título genérico "Sistema USS"

```jsx
import { useState, useEffect, useCallback } from 'react'
import { supabase } from '../utils/supabase'

const COOLDOWN_SECONDS = 60

export default function Login() {
  const [email,     setEmail]     = useState('')
  const [sent,      setSent]      = useState(false)
  const [loading,   setLoading]   = useState(false)
  const [error,     setError]     = useState('')
  const [cooldown,  setCooldown]  = useState(0)
  const [mode,      setMode]      = useState('magic')
  const [pin,       setPin]       = useState('')

  useEffect(() => {
    if (cooldown <= 0) return
    const t = setTimeout(() => setCooldown(c => c - 1), 1000)
    return () => clearTimeout(t)
  }, [cooldown])

  useEffect(() => {
    const saved = sessionStorage.getItem('mm_cooldown_until')
    if (saved) {
      const remaining = Math.round((parseInt(saved) - Date.now()) / 1000)
      if (remaining > 0) setCooldown(remaining)
    }
  }, [])

  const startCooldown = useCallback(() => {
    setCooldown(COOLDOWN_SECONDS)
    sessionStorage.setItem('mm_cooldown_until', String(Date.now() + COOLDOWN_SECONDS * 1000))
  }, [])

  async function handleMagicLink(e) {
    e.preventDefault()
    setError('')
    if (!email.toLowerCase().endsWith('@uss.cl')) {
      setError('Solo se permiten correos institucionales @uss.cl')
      return
    }
    if (cooldown > 0) { setError(`Espera ${cooldown}s antes de solicitar otro link`); return }
    setLoading(true)
    const { error } = await supabase.auth.signInWithOtp({
      email: email.toLowerCase(),
      options: { emailRedirectTo: 'https://comunicaciones-uss.github.io/mesa-medios/', shouldCreateUser: true },
    })
    setLoading(false)
    if (error) {
      const msg = error.message.toLowerCase()
      if (msg.includes('rate') || msg.includes('limit') || msg.includes('exceeded') || msg.includes('too many')) {
        setError('Se alcanzó el límite de envíos. Usa el acceso con PIN o intenta más tarde.')
        startCooldown()
      } else { setError('Error al enviar el link: ' + error.message) }
    } else { setSent(true); startCooldown() }
  }

  async function handlePinLogin(e) {
    e.preventDefault()
    setError('')
    if (!email.toLowerCase().endsWith('@uss.cl')) { setError('Solo se permiten correos institucionales @uss.cl'); return }
    if (!pin.trim()) { setError('Ingresa el PIN de acceso'); return }
    setLoading(true)
    const { error } = await supabase.auth.signInWithPassword({ email: email.toLowerCase(), password: pin.trim() })
    setLoading(false)
    if (error) {
      const msg = error.message.toLowerCase()
      if (msg.includes('invalid') || msg.includes('credentials')) setError('PIN incorrecto o correo no registrado')
      else setError('Error de acceso: ' + error.message)
    }
  }

  if (sent) {
    return (
      <div className="login-page">
        <div className="login-card">
          <LoginHeader />
          <div className="login-body login-sent">
            <div className="sent-icon">
              <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
                <circle cx="24" cy="24" r="22" fill="#c6efce" stroke="#82c985" strokeWidth="1.5" />
                <path d="M14 24l7 7 13-13" stroke="#276221" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
            <h3>¡Revisa tu correo!</h3>
            <p>Enviamos un link de acceso a <strong>{email}</strong>. Haz clic en el link para ingresar.</p>
            <p className="sent-hint">El link expira en 1 hora. Si no llega, revisa la carpeta de spam.</p>
            {cooldown > 0 && <p className="cooldown-text">Puedes reenviar en {cooldown}s</p>}
            <div className="sent-actions">
              <button className="btn-secondary" onClick={() => setSent(false)} disabled={cooldown > 0}>
                {cooldown > 0 ? `Reenviar (${cooldown}s)` : 'Reenviar link'}
              </button>
              <button className="btn-text" onClick={() => { setSent(false); setMode('pin') }}>Usar PIN en su lugar</button>
            </div>
          </div>
        </div>
        <PageFooter />
      </div>
    )
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <LoginHeader />
        <div className="login-body">
          <p className="login-desc">
            {mode === 'magic'
              ? 'Ingresa tu correo institucional USS para recibir un link de acceso seguro.'
              : 'Ingresa tu correo institucional USS y el PIN de acceso.'}
          </p>
          <div className="login-mode-toggle">
            <button className={`mode-btn ${mode === 'magic' ? 'mode-active' : ''}`} onClick={() => { setMode('magic'); setError('') }} type="button">
              <svg width="14" height="14" viewBox="0 0 14 14" fill="none"><rect x="1" y="3" width="12" height="8" rx="1.5" stroke="currentColor" strokeWidth="1.2" /><path d="M1.5 4l5.5 3.5L12.5 4" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" /></svg>
              Magic Link
            </button>
            <button className={`mode-btn ${mode === 'pin' ? 'mode-active' : ''}`} onClick={() => { setMode('pin'); setError('') }} type="button">
              <svg width="14" height="14" viewBox="0 0 14 14" fill="none"><rect x="3" y="6" width="8" height="6" rx="1.5" stroke="currentColor" strokeWidth="1.2" /><path d="M5 6V4.5a2 2 0 014 0V6" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" /></svg>
              PIN de acceso
            </button>
          </div>
          <form onSubmit={mode === 'magic' ? handleMagicLink : handlePinLogin}>
            <div className="form-group">
              <label htmlFor="email">Correo institucional USS</label>
              <input id="email" type="email" placeholder="nombre@uss.cl" value={email} onChange={e => setEmail(e.target.value)} required autoFocus />
            </div>
            {mode === 'pin' && (
              <div className="form-group">
                <label htmlFor="pin">PIN de acceso</label>
                <input id="pin" type="password" placeholder="Ingresa el PIN" value={pin} onChange={e => setPin(e.target.value)} required autoComplete="current-password" />
              </div>
            )}
            {error && <p className="login-error">{error}</p>}
            <button type="submit" className="btn-primary login-btn" disabled={loading || !email || (mode === 'magic' && cooldown > 0)}>
              {loading ? 'Verificando...' : mode === 'magic' ? cooldown > 0 ? `Espera ${cooldown}s` : 'Enviar link de acceso' : 'Ingresar con PIN'}
            </button>
          </form>
        </div>
        <div className="login-footer">
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none"><circle cx="7" cy="7" r="6" stroke="#5a7a96" strokeWidth="1.2" /><path d="M7 6v4M7 4.5v.5" stroke="#5a7a96" strokeWidth="1.2" strokeLinecap="round" /></svg>
          Solo usuarios autorizados pueden acceder
        </div>
      </div>
      <PageFooter />
    </div>
  )
}

function LoginHeader() {
  return (
    <div className="login-header">
      <svg width="40" height="40" viewBox="0 0 40 40" fill="none">
        <rect width="40" height="40" rx="8" fill="#ceb37c" />
        <rect x="8" y="11" width="24" height="3" rx="1.5" fill="#0f2b41" />
        <rect x="8" y="18.5" width="17" height="3" rx="1.5" fill="#0f2b41" />
        <rect x="8" y="26" width="20" height="3" rx="1.5" fill="#0f2b41" />
      </svg>
      <div>
        <h1>Sistema USS</h1>
        <p>Gestión de comunicaciones</p>
      </div>
    </div>
  )
}

function PageFooter() {
  return (
    <footer className="login-page-footer">
      <div className="footer-inner">
        <div className="footer-col footer-logo-col">
          <img src="/mesa-medios/escudo-uss-horizontal-blanco.svg" alt="Universidad San Sebastián" className="footer-uss-logo" />
        </div>
        <div className="footer-col footer-social-col">
          <span className="footer-label">Síguenos</span>
          <div className="footer-social-links">
            <a href="https://www.instagram.com/usansebastian/" target="_blank" rel="noopener noreferrer" title="Instagram">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="2" width="20" height="20" rx="5" /><circle cx="12" cy="12" r="5" /><circle cx="17.5" cy="6.5" r="1.5" fill="currentColor" stroke="none" /></svg>
            </a>
            <a href="https://www.facebook.com/ComunidadUSS/" target="_blank" rel="noopener noreferrer" title="Facebook">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M18 2h-3a5 5 0 00-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 011-1h3z" /></svg>
            </a>
          </div>
        </div>
        <div className="footer-col footer-links-col">
          <span className="footer-label">Sitios de interés</span>
          <a href="https://www.uss.cl" target="_blank" rel="noopener noreferrer">USS.CL</a>
        </div>
      </div>
      <div className="footer-copyright">
        © {new Date().getFullYear()} Universidad San Sebastián — Dirección General de Comunicaciones
      </div>
    </footer>
  )
}
```

- [ ] **Step 5: Commit**

```bash
git add src/apps/shared/
git commit -m "feat(architecture): move shared utilities to apps/shared/"
```

---

## Task 3: Mover y adaptar Mesa de Medios

**Files:**
- Create: `src/apps/mesa-medios/utils.js`
- Create: `src/apps/mesa-medios/config.js`
- Create: `src/apps/mesa-medios/components/Header.jsx`
- Create: `src/apps/mesa-medios/components/CellPopover.jsx`
- Create: `src/apps/mesa-medios/components/AuditLogPanel.jsx`
- Create: `src/apps/mesa-medios/components/AddRowModal.jsx`
- Create: `src/apps/mesa-medios/components/MediaTable.jsx`
- Create: `src/apps/mesa-medios/components/MobileCardView.jsx`
- Create: `src/apps/mesa-medios/MesaMediosApp.jsx`

- [ ] **Step 1: Crear utils.js con las funciones helper extraídas de App.jsx**

Crear `src/apps/mesa-medios/utils.js`:

```js
import { MEDIA_COLS } from './config'

// Lee valor de celda desde formato JSONB nuevo o legacy string
export function getCellData(medios, colId) {
  const raw = medios?.[colId]
  if (!raw) return { valor: '', notas: '' }
  if (typeof raw === 'string') return { valor: raw, notas: '' }
  return { valor: raw.valor || '', notas: raw.notas || '' }
}

export function setCellData(medios, colId, valor, notas) {
  const existing = getCellData(medios, colId)
  const newNotas = notas !== undefined ? notas : existing.notas
  if (!valor && !newNotas) return { ...medios, [colId]: null }
  return { ...medios, [colId]: { valor: valor || '', notas: newNotas || '' } }
}

export function getRowProgress(medios) {
  const filled = MEDIA_COLS.filter(col => {
    const { valor } = getCellData(medios, col.id)
    return valor && valor !== 'no'
  }).length
  const total = MEDIA_COLS.length
  return { filled, total, pct: Math.round((filled / total) * 100) }
}
```

- [ ] **Step 2: Copiar config.js**

```bash
cp src/config.js src/apps/mesa-medios/config.js
```

- [ ] **Step 3: Copiar componentes de Mesa de Medios y actualizar imports**

Copiar `src/components/Header.jsx` → `src/apps/mesa-medios/components/Header.jsx`, añadir prop `onBackToSelector`:

```jsx
export default function Header({ userName, userEmail, onAdd, onLogout, onShowLogs, onBackToSelector }) {
  const initials = userName
    ? userName.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()
    : '?'

  return (
    <header className="header">
      <div className="header-row-top">
        <div className="header-left">
          {onBackToSelector && (
            <button className="btn-back-selector" onClick={onBackToSelector} title="Volver al selector">
              <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                <path d="M10 3L5 8l5 5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </button>
          )}
          <div className="header-logo">
            <img src="/mesa-medios/escudo-uss-horizontal-blanco.svg" alt="USS" className="header-logo-img" />
          </div>
          <div className="header-divider" />
          <div>
            <h1 className="header-title">Mesa de Medios USS</h1>
            <p className="header-subtitle">Planificación de contenidos y medios</p>
          </div>
        </div>
        <div className="header-user">
          <div className="user-menu">
            <div className="user-avatar" title={`${userName} (${userEmail})`}>{initials}</div>
            <div className="user-info">
              <span className="user-name">{userName}</span>
              <span className="user-email">{userEmail}</span>
            </div>
            <button className="btn-logout" onClick={onLogout} title="Cerrar sesión">
              <svg width="15" height="15" viewBox="0 0 15 15" fill="none">
                <path d="M5.5 2H3a1 1 0 00-1 1v9a1 1 0 001 1h2.5M10 10l3-2.5L10 5M6 7.5h7" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </button>
          </div>
        </div>
      </div>
      <div className="header-row-actions">
        <div className="realtime-badge"><span className="realtime-dot" /><span>En vivo</span></div>
        <button className="btn-logs" onClick={onShowLogs} title="Ver registro de actividad">
          <svg width="15" height="15" viewBox="0 0 15 15" fill="none"><rect x="1.5" y="1.5" width="12" height="12" rx="2" stroke="currentColor" strokeWidth="1.3" /><path d="M4 5h7M4 7.5h7M4 10h4" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" /></svg>
          <span>Actividad</span>
        </button>
        <button className="btn-add" onClick={onAdd}>
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none"><path d="M8 2v12M2 8h12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" /></svg>
          <span>Agregar contenido</span>
        </button>
      </div>
    </header>
  )
}
```

- [ ] **Step 4: Copiar CellPopover.jsx con import actualizado**

```bash
cp src/components/CellPopover.jsx src/apps/mesa-medios/components/CellPopover.jsx
```

Luego editar `src/apps/mesa-medios/components/CellPopover.jsx`: la línea de import de getCellData (si existe) debe apuntar a `../utils`.

- [ ] **Step 5: Copiar AuditLogPanel.jsx con import actualizado**

```bash
cp src/components/AuditLogPanel.jsx src/apps/mesa-medios/components/AuditLogPanel.jsx
```

Editar `src/apps/mesa-medios/components/AuditLogPanel.jsx`: cambiar `import { supabase } from '../supabase'` → `import { supabase } from '../../../apps/shared/utils/supabase'`

- [ ] **Step 6: Copiar AddRowModal.jsx**

```bash
cp src/components/AddRowModal.jsx src/apps/mesa-medios/components/AddRowModal.jsx
```

Este componente no tiene imports externos de supabase o config, no necesita edición.

- [ ] **Step 7: Crear MediaTable.jsx con imports actualizados**

```bash
cp src/components/MediaTable.jsx src/apps/mesa-medios/components/MediaTable.jsx
```

Editar `src/apps/mesa-medios/components/MediaTable.jsx`: cambiar:
- `import { MEDIA_COLS, N_PROPIOS, N_PAGADOS } from '../config'` → `import { MEDIA_COLS, N_PROPIOS, N_PAGADOS } from '../config'` (igual, ya está correcto relativamente)
- `import { getCellData, getRowProgress } from '../App'` → `import { getCellData, getRowProgress } from '../utils'`
- `import CellPopover from './CellPopover'` → sin cambios

- [ ] **Step 8: Copiar MobileCardView.jsx con imports actualizados**

```bash
cp src/components/MobileCardView.jsx src/apps/mesa-medios/components/MobileCardView.jsx
```

Editar para cambiar:
- `import { getCellData, getRowProgress } from '../App'` → `import { getCellData, getRowProgress } from '../utils'`
- `import { MEDIA_COLS } from '../config'` → `import { MEDIA_COLS } from '../config'` (sin cambios)

- [ ] **Step 9: Crear MesaMediosApp.jsx**

Es el `src/App.jsx` actual adaptado: sin auth propio, recibe `session`, `userName`, `onLogout`, `onBackToSelector` como props.

Crear `src/apps/mesa-medios/MesaMediosApp.jsx`:

```jsx
import { useState, useEffect, useMemo } from 'react'
import { supabase } from '../../apps/shared/utils/supabase'
import { MEDIA_COLS } from './config'
import { getCellData, setCellData, getRowProgress } from './utils'
import Header from './components/Header'
import MediaTable from './components/MediaTable'
import MobileCardView from './components/MobileCardView'
import AddRowModal from './components/AddRowModal'
import AuditLogPanel from './components/AuditLogPanel'
import Toaster from '../../apps/shared/components/Toaster'
import { useToast } from '../../apps/shared/hooks/useToast'
import { useDebounce } from '../../apps/shared/hooks/useDebounce'
import ConfirmDialog from '../../apps/shared/components/ConfirmDialog'

function sortRows(rows, direction) {
  return [...rows].sort((a, b) => {
    const dateA = a.semana || ''
    const dateB = b.semana || ''
    const cmp = dateA.localeCompare(dateB)
    if (cmp !== 0) return direction === 'asc' ? cmp : -cmp
    return (a.nombre || '').localeCompare(b.nombre || '', 'es')
  })
}

export default function MesaMediosApp({ session, userName, onLogout, onBackToSelector }) {
  const [rows,          setRows]          = useState([])
  const [loading,       setLoading]       = useState(true)
  const [error,         setError]         = useState(null)
  const [showModal,     setShowModal]     = useState(false)
  const [showLogs,      setShowLogs]      = useState(false)
  const [confirmDelete, setConfirmDelete] = useState(null)
  const [filterInput,   setFilterInput]   = useState('')
  const filterText = useDebounce(filterInput, 300)
  const [sortDir,       setSortDir]       = useState('asc')
  const { toasts, addToast, removeToast } = useToast()

  // Realtime
  useEffect(() => {
    const channel = supabase
      .channel('contenidos-realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'contenidos' }, (payload) => {
        if (payload.eventType === 'INSERT')  setRows(prev => [...prev, payload.new])
        else if (payload.eventType === 'UPDATE') setRows(prev => prev.map(r => r.id === payload.new.id ? payload.new : r))
        else if (payload.eventType === 'DELETE') setRows(prev => prev.filter(r => r.id !== payload.old.id))
      })
      .subscribe()
    fetchRows()
    return () => supabase.removeChannel(channel)
  }, [])

  // Keyboard shortcuts
  useEffect(() => {
    function handleKeyDown(e) {
      const tag = document.activeElement?.tagName
      const inInput = tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT'
      if (e.key === 'Escape') {
        if (confirmDelete) { setConfirmDelete(null); return }
        if (showModal)     { setShowModal(false);    return }
        if (showLogs)      { setShowLogs(false);     return }
      }
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault()
        document.querySelector('.filter-input')?.focus()
        return
      }
      if (e.key.toLowerCase() === 'n' && !inInput && !showModal && !showLogs && !confirmDelete) {
        setShowModal(true)
      }
    }
    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [confirmDelete, showModal, showLogs])

  async function fetchRows() {
    setLoading(true)
    const { data, error } = await supabase
      .from('contenidos').select('*')
      .order('semana', { ascending: true })
      .order('nombre', { ascending: true })
    if (error) setError(error.message)
    else setRows(data || [])
    setLoading(false)
  }

  async function logAction(accion, contenidoId, contenidoNombre, detalle = '') {
    if (!session) return
    await supabase.from('logs').insert([{
      user_email:       session.user.email,
      user_nombre:      userName || session.user.email,
      accion,
      contenido_id:     contenidoId,
      contenido_nombre: contenidoNombre,
      detalle,
    }])
  }

  const displayRows = useMemo(() => {
    let result = rows
    if (filterText.trim()) {
      const q = filterText.toLowerCase()
      result = result.filter(r => r.nombre?.toLowerCase().includes(q))
    }
    return sortRows(result, sortDir)
  }, [rows, filterText, sortDir])

  async function handleAddRow({ nombre, semana }) {
    const { data, error } = await supabase
      .from('contenidos').insert([{ nombre, semana, medios: {} }]).select().single()
    if (error) { addToast('Error al agregar el contenido. Intenta nuevamente.', 'error'); return }
    await logAction('AGREGAR', data.id, nombre, `Agregó "${nombre}"`)
    setShowModal(false)
  }

  async function handleCellChange(rowId, colId, value, notas) {
    const row = rows.find(r => r.id === rowId)
    if (!row) return
    const { valor: oldValue, notas: oldNotas } = getCellData(row.medios, colId)
    if (oldValue === value && oldNotas === notas) return
    const newMedios = setCellData(row.medios, colId, value, notas)
    setRows(prev => prev.map(r => r.id === rowId ? { ...r, medios: newMedios } : r))
    const { error } = await supabase.from('contenidos').update({ medios: newMedios }).eq('id', rowId)
    if (error) { addToast('Error al guardar. Los datos se recargarán.', 'error'); fetchRows(); return }
    const detalle = value ? `"${colId}" → "${value}"${notas ? ' (con notas)' : ''}` : `Limpió "${colId}"`
    await logAction('MODIFICAR', rowId, row.nombre, detalle)
  }

  async function handleFieldChange(rowId, field, value) {
    const row = rows.find(r => r.id === rowId)
    setRows(prev => prev.map(r => r.id === rowId ? { ...r, [field]: value } : r))
    const { error } = await supabase.from('contenidos').update({ [field]: value }).eq('id', rowId)
    if (error) { addToast('Error al guardar el campo. Los datos se recargarán.', 'error'); fetchRows(); return }
    await logAction('MODIFICAR', rowId, row?.nombre, `Cambió "${field}" → "${value}"`)
  }

  function requestDeleteRow(rowId) {
    const row = rows.find(r => r.id === rowId)
    setConfirmDelete({ id: rowId, nombre: row?.nombre || 'este contenido' })
  }

  async function handleDeleteRow(rowId) {
    const row = rows.find(r => r.id === rowId)
    setRows(prev => prev.filter(r => r.id !== rowId))
    const { error } = await supabase.from('contenidos').delete().eq('id', rowId)
    if (error) { addToast('Error al eliminar el contenido.', 'error'); fetchRows(); return }
    await logAction('ELIMINAR', rowId, row?.nombre, `Eliminó "${row?.nombre}"`)
  }

  return (
    <div className="app">
      <Header
        userName={userName}
        userEmail={session.user.email}
        onAdd={() => setShowModal(true)}
        onLogout={onLogout}
        onShowLogs={() => setShowLogs(true)}
        onBackToSelector={onBackToSelector}
      />

      <div className="filter-bar">
        <div className="filter-search">
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <circle cx="6" cy="6" r="4.5" stroke="currentColor" strokeWidth="1.3" />
            <path d="M9.5 9.5L13 13" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" />
          </svg>
          <input type="text" placeholder="Filtrar contenidos..." value={filterInput}
            onChange={e => setFilterInput(e.target.value)} className="filter-input" />
          {filterInput && (
            <button className="filter-clear" onClick={() => setFilterInput('')}>
              <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
                <path d="M3 3l6 6M9 3l-6 6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
              </svg>
            </button>
          )}
        </div>
        <button className="sort-btn" onClick={() => setSortDir(d => d === 'asc' ? 'desc' : 'asc')}
          title={sortDir === 'asc' ? 'Más antigua primero' : 'Más reciente primero'}>
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <path d="M7 2v10M4 4l3-2.5L10 4" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round" style={{ opacity: sortDir === 'asc' ? 1 : 0.3 }} />
            <path d="M4 10l3 2.5L10 10" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round" style={{ opacity: sortDir === 'desc' ? 1 : 0.3 }} />
          </svg>
          <span>Fecha</span>
        </button>
        {filterInput && <span className="filter-count">{displayRows.length} de {rows.length}</span>}
      </div>

      {loading && <div className="loading-state"><div className="spinner" /><span>Cargando datos...</span></div>}
      {error && <div className="error-state"><strong>Error de conexión:</strong> {error}</div>}

      {!loading && !error && (
        <>
          <div className="desktop-only">
            <MediaTable rows={displayRows} onCellChange={handleCellChange} onFieldChange={handleFieldChange}
              onDeleteRow={requestDeleteRow} totalRows={rows.length} filterQuery={filterInput}
              onClearFilter={() => setFilterInput('')} onAdd={() => setShowModal(true)} />
          </div>
          <div className="mobile-only">
            <MobileCardView rows={displayRows} onCellChange={handleCellChange} onFieldChange={handleFieldChange}
              onDeleteRow={requestDeleteRow} totalRows={rows.length} filterQuery={filterInput}
              onClearFilter={() => setFilterInput('')} onAdd={() => setShowModal(true)} />
          </div>
          <div className="shortcuts-hint desktop-only">
            <span><kbd>Esc</kbd> cerrar</span><span>·</span>
            <span><kbd>Ctrl+K</kbd> buscar</span><span>·</span>
            <span><kbd>N</kbd> nuevo</span>
          </div>
        </>
      )}

      {showModal && <AddRowModal onConfirm={handleAddRow} onClose={() => setShowModal(false)} />}
      {showLogs && <AuditLogPanel onClose={() => setShowLogs(false)} />}
      {confirmDelete && (
        <ConfirmDialog nombre={confirmDelete.nombre}
          onConfirm={() => { handleDeleteRow(confirmDelete.id); setConfirmDelete(null) }}
          onCancel={() => setConfirmDelete(null)} />
      )}
      <Toaster toasts={toasts} onRemove={removeToast} />
    </div>
  )
}
```

- [ ] **Step 10: Commit**

```bash
git add src/apps/mesa-medios/
git commit -m "feat(architecture): move Mesa de Medios to apps/mesa-medios/"
```

---

## Task 4: Crear nuevo App.jsx router

**Files:**
- Modify: `src/App.jsx` — reemplazar completamente

- [ ] **Step 1: Reemplazar src/App.jsx con el router**

```jsx
import { useState, useEffect } from 'react'
import { supabase } from './apps/shared/utils/supabase'
import Login from './apps/shared/components/Login'
import USSLoader from './apps/shared/components/USSLoader'
import DashboardSelector from './apps/shared/DashboardSelector'
import MesaMediosApp from './apps/mesa-medios/MesaMediosApp'
import MesaEditorialApp from './apps/mesa-editorial/MesaEditorialApp'

export default function App() {
  const [session,           setSession]           = useState(null)
  const [loading,           setLoading]           = useState(true)
  const [authorized,        setAuthorized]        = useState(null)
  const [userName,          setUserName]          = useState('')
  const [selectedDashboard, setSelectedDashboard] = useState(null)

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      if (session) checkAuthorized(session.user.email)
      else setLoading(false)
    })
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
      if (session) checkAuthorized(session.user.email)
      else { setAuthorized(null); setLoading(false); setSelectedDashboard(null) }
    })
    return () => subscription.unsubscribe()
  }, [])

  async function checkAuthorized(email) {
    const [data] = await Promise.all([
      supabase
        .from('usuarios_autorizados').select('email, nombre')
        .eq('email', email.toLowerCase()).eq('activo', true).single()
        .then(res => res.data),
      new Promise(resolve => setTimeout(resolve, 400))
    ])
    if (data) {
      setAuthorized(true)
      setUserName(data.nombre || email)
      await supabase.from('logs').insert([{
        user_email: email.toLowerCase(),
        user_nombre: data.nombre || email,
        accion: 'LOGIN',
        detalle: 'Inició sesión',
      }])
      const last = localStorage.getItem('uss_last_dashboard')
      if (last) setSelectedDashboard(last)
    } else {
      setAuthorized(false)
    }
    setLoading(false)
  }

  async function handleLogout() {
    await supabase.auth.signOut()
    setAuthorized(null)
    setUserName('')
    setSelectedDashboard(null)
  }

  function handleSelectDashboard(dashboard) {
    setSelectedDashboard(dashboard)
    localStorage.setItem('uss_last_dashboard', dashboard)
  }

  function handleBackToSelector() {
    setSelectedDashboard(null)
  }

  if (loading) return (
    <div className="fullscreen-center">
      <USSLoader />
      <span>Cargando...</span>
    </div>
  )

  if (!session) return <Login />

  if (authorized === null) return (
    <div className="fullscreen-center">
      <USSLoader />
      <span>Verificando acceso...</span>
    </div>
  )

  if (authorized === false) return (
    <div className="fullscreen-center">
      <div className="not-authorized">
        <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
          <circle cx="24" cy="24" r="22" stroke="#9C0006" strokeWidth="2" fill="#FFC7CE" />
          <path d="M24 14v12M24 32v2" stroke="#9C0006" strokeWidth="2.5" strokeLinecap="round" />
        </svg>
        <h2>Acceso denegado</h2>
        <p>Tu correo <strong>{session.user.email}</strong> no está en la lista de usuarios autorizados.</p>
        <button className="btn-add" onClick={handleLogout}>Volver</button>
      </div>
    </div>
  )

  if (!selectedDashboard) return (
    <DashboardSelector
      userName={userName}
      userEmail={session.user.email}
      onSelect={handleSelectDashboard}
      onLogout={handleLogout}
    />
  )

  if (selectedDashboard === 'medios') return (
    <MesaMediosApp
      session={session}
      userName={userName}
      onLogout={handleLogout}
      onBackToSelector={handleBackToSelector}
    />
  )

  if (selectedDashboard === 'editorial') return (
    <MesaEditorialApp
      session={session}
      userName={userName}
      onLogout={handleLogout}
      onBackToSelector={handleBackToSelector}
    />
  )

  return null
}
```

- [ ] **Step 2: Actualizar main.jsx si referencia App correctamente**

Verificar que `src/main.jsx` hace `import App from './App'`. No debería necesitar cambios.

- [ ] **Step 3: Verificar que npm run dev arranca sin errores**

```bash
npm run dev
```

Expected: servidor en http://localhost:5173 sin errores en consola.
Verificar: flujo de login y Mesa de Medios funciona igual que antes (sin regresiones).

- [ ] **Step 4: Commit**

```bash
git add src/App.jsx
git commit -m "feat(architecture): replace App.jsx with multi-dashboard router"
```

---

## Task 5: Crear SQL para Mesa Editorial

**Files:**
- Create: `supabase-editorial-setup.sql`

- [ ] **Step 1: Crear archivo SQL completo**

Crear `supabase-editorial-setup.sql` en la raíz del proyecto:

```sql
-- ================================================================
-- Mesa Editorial USS — Schema + RLS + Realtime + Seed Data
-- Ejecutar en Supabase SQL Editor
-- ================================================================

-- Crear tabla
CREATE TABLE IF NOT EXISTS mesa_editorial_acciones (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  eje         TEXT        NOT NULL,
  tipo        TEXT,
  tema        TEXT,
  accion      TEXT,
  tipo_accion TEXT,
  fecha       DATE,
  responsable TEXT,
  status      TEXT        NOT NULL DEFAULT 'Pendiente',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE mesa_editorial_acciones ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuarios autorizados pueden hacer todo" ON mesa_editorial_acciones;

CREATE POLICY "Usuarios autorizados pueden hacer todo"
  ON mesa_editorial_acciones
  FOR ALL
  USING (
    auth.jwt() ->> 'email' IN (
      SELECT email FROM usuarios_autorizados WHERE activo = true
    )
  );

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE mesa_editorial_acciones;

-- Trigger para updated_at automático
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_mesa_editorial_updated_at ON mesa_editorial_acciones;
CREATE TRIGGER update_mesa_editorial_updated_at
  BEFORE UPDATE ON mesa_editorial_acciones
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ================================================================
-- SEED DATA: 56 registros desde Dashboard USS Semana 30 abril
-- ================================================================

INSERT INTO mesa_editorial_acciones (eje, tipo, tema, accion, tipo_accion, fecha, responsable, status) VALUES

-- DISCUSIÓN PAÍS (13 registros)
('Discusión País', 'AO', 'Encuesta Chile Nos Habla-Seguridad', 'Medios de comunicación', 'Externo', '2026-03-30', 'Viviana', 'En desarrollo'),
('Discusión País', 'AO', 'Encuesta Chile Nos Habla-Seguridad', 'Canales USS', NULL, NULL, 'Viviana', 'En desarrollo'),
('Discusión País', 'AO', 'Encuesta Chile Nos Habla-Seguridad', 'Difusión en medios propios', 'Interna-Externa', '2026-03-30', 'TBC', 'Pendiente'),
('Discusión País', 'Ancla', 'Informe Cescro Persecución Crimen Organizado', 'Diseño informes y minuta', 'Interna', '2026-04-01', 'Yaritza', 'En desarrollo'),
('Discusión País', 'Ancla', 'Informe Cescro Persecución Crimen Organizado', 'Landing page, entrega maqueta', 'Interna', '2026-03-30', 'Yaritza', 'Completado'),
('Discusión País', 'Ancla', 'Informe Cescro Persecución Crimen Organizado', 'Desarrollo de comunicado de prensa y bases de datos', 'Interna', '2026-04-02', 'Viviana', 'En desarrollo'),
('Discusión País', 'Ancla', 'Informe Cescro Persecución Crimen Organizado', 'Datos Cescro para presentación (PPT)', 'Interna', '2026-03-31', 'Yaritza', 'En desarrollo'),
('Discusión País', 'Soporte', 'Informe Cescro Persecución Crimen Organizado', 'Seguimiento solicitud reunión ministra Steinert', 'Interna', '2026-03-31', 'Yaritza', 'En desarrollo'),
('Discusión País', 'AO', 'Caso inspectora asesinada en Calama', 'Gestión columna de opinión e Índice de Bienestar Docente', 'Externo', '2026-03-30', 'Viviana', 'En desarrollo'),
('Discusión País', 'AO', 'Presentación Informe Tasa Máxima Convencional', 'Definición de espacio en Campus Los Leones', 'Externo', '2026-03-30', 'María Ignacia', 'Pendiente'),
('Discusión País', 'AO', 'Día Mundial del Autismo', 'Gestión vocerías prensa sobre Ley Tea y PIE', 'Externo', '2026-03-30', 'Viviana', 'Pendiente'),
('Discusión País', 'AO', 'Educación financiera', 'Participación Alejandro Weber en CAB Equifax', NULL, '2026-04-16', 'Yaritza', 'En desarrollo'),
('Discusión País', 'AO', 'Educación financiera', 'Presentación a prensa Informe Deuda Morosa USS-Equifax', 'Externa-Interno', '2026-04-20', 'Yaritza-Viviana', 'Pendiente'),

-- ORGULLO USS (8 registros)
('Orgullo USS', 'Ancla', 'Nuevo rector', 'Video saludo', 'Interna', '2026-04-01', 'Claudia', 'Pendiente'),
('Orgullo USS', 'Ancla', 'Nuevo rector', 'Entrevista para web', 'Interna', '2026-03-31', 'Natalie', 'Pendiente'),
('Orgullo USS', 'Ancla', 'Nuevo rector', 'Entrevista El Mercurio', 'Interna', NULL, 'Extend', 'Pendiente'),
('Orgullo USS', 'Ancla', 'Nuevo rector', 'Teaser', 'Interno', '2026-03-30', 'Felipe', 'Pendiente'),
('Orgullo USS', 'Ancla', 'AQAS', 'Publireportaje 12 de abril', 'Externo', '2026-04-12', 'Natalie', 'Pendiente'),
('Orgullo USS', 'AO', 'Nombramiento Seremi Valdivia', 'Redes sociales y web', 'Interno', '2026-03-31', 'Natalie', 'Pendiente'),
('Orgullo USS', 'AO', 'Nombramiento Seremi Concepción', 'Redes sociales y web', 'Interno', '2026-03-31', 'Natalie', 'Pendiente'),
('Orgullo USS', 'AO', 'Club Deportivo vs Estados Unidos', 'Redes sociales, web, alianza', 'Interno y Externo', '2026-04-01', 'Natalie', 'Pendiente'),

-- SALUD (7 registros)
('Salud', 'AO', 'Año Académico Clínica BUPA', 'Cobertura en terreno', 'Interno', '2026-03-31', 'Esteban', 'Pendiente'),
('Salud', 'AO', 'Año Académico Clínica BUPA', 'Redes sociales y web', 'Interno', '2026-03-31', 'Esteban', 'Pendiente'),
('Salud', 'Ancla', 'Congreso Fronteras en Innovación', 'RRSS, web e inicio oficial del Congreso (Teletón)', 'Interno', '2026-03-26', 'Esteban', 'Pendiente'),
('Salud', 'AO', 'Concurso de Políticas Públicas IPSUSS', 'Redes sociales y web', 'Interno', '2026-04-01', 'Esteban', 'Pendiente'),
('Salud', 'AO', 'Virus respiratorios y estrategias MINSAL', 'Gestión de Prensa', 'Externo', '2026-03-30', 'Cristóbal', 'Pendiente'),
('Salud', 'AO', 'Análisis cáncer IPSUSS', 'Gestión de Prensa', 'Externo', '2026-03-30', 'Esteban - Cristóbal', 'Pendiente'),
('Salud', 'AO', 'Baja natalidad en Chile', 'Gestión de Prensa', 'Externo', '2026-03-30', 'Esteban - Cristóbal', 'Pendiente'),

-- INVESTIGACIÓN (7 registros)
('Investigación', 'Soporte', 'Decretadas', 'Comunicado Actividad', 'Interno', '2026-04-01', 'Sebastián / Marconi', 'Completado'),
('Investigación', 'Soporte', 'Decretadas', 'RRSS Actividad Lanzamiento', 'Interno', '2026-04-01', 'Sebastián / Marconi', 'En desarrollo'),
('Investigación', 'Soporte', 'Decretadas', 'LinkedIn Lanzamiento', 'Interno', '2026-04-01', 'Sebastián / Marconi', 'Pendiente'),
('Investigación', 'Soporte', 'Decretadas', 'Comunicado Conjunto USS/UAI/UNAB', 'Externo', '2026-04-06', 'Sebastián', 'Pendiente'),
('Investigación', 'Soporte', 'Decretadas', 'Columna de opinión', 'Externo', '2026-04-06', 'Sebastián', 'Pendiente'),
('Investigación', 'Soporte', 'Decretadas', 'RRSS Actividades Nacional', 'Externo', '2026-04-08', 'Sebastián', 'Pendiente'),
('Investigación', 'Soporte', 'Aquasur y Pérez-Acle', 'Nota en LinkedIn', 'Interno', '2026-03-30', 'Felipe', 'En desarrollo'),

-- VINCULACIÓN CON EL MEDIO (21 registros)
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Landing de la Feria', 'Interna', '2026-03-27', 'Sebastián', 'Completado'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Mailing invitación inauguración', 'Interna', '2026-03-30', 'Sebastián', 'Completado'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Intranet', 'Interna', '2026-03-30', 'Sebastián', 'En desarrollo'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Pantalla en los campus', 'Interna', '2026-03-27', 'Sebastián', 'Completado'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Landing USS Banner', 'Interna', '2026-03-27', 'Sebastián', 'Completado'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Reel de Instagram', 'Interna', '2026-03-30', 'Sebastián', 'En desarrollo'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'TikTok', 'Interna', '2026-03-30', 'Sebastián', 'En desarrollo'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Nota web Inauguración', 'Interna', '2026-04-09', 'Sebastián', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Instagram inauguración', 'Interna', '2026-04-09', 'Sebastián', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Gestión de Prensa', 'Externo', '2026-04-06', 'Sebastián', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Paid Media / La Tercera', 'Externo', '2026-04-06', 'Sebastián', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Nota web Balance', 'Interno', '2026-04-13', 'Sebastián', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'Columna de opinión', 'Externo', '2026-03-30', 'Jeran', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'Entrevistas en Radio', 'Externo', '2026-03-30', 'Jeran', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'Comunicados de Prensa Local', 'Externo', '2026-04-13', 'Jeran', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'Comunicados de Prensa Nacional', 'Externo', '2026-04-13', 'Sebastián', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'Sociales Congreso', 'Externo', '2026-04-13', 'Jeran', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'RRSS Lanzamiento Campaña', 'Interno', '2026-03-29', 'Jeran', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'RRSS Dinámicas de Interacción', 'Interno', '2026-04-06', 'Jeran', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'RRSS Presentación Takeovers', 'Interno', '2026-04-13', 'Jeran', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'RRSS Minuto a minuto', 'Interno', '2026-04-23', 'Jeran', 'Pendiente');

-- Verificar inserción
SELECT eje, COUNT(*) as total FROM mesa_editorial_acciones GROUP BY eje ORDER BY eje;
```

- [ ] **Step 2: Commit**

```bash
git add supabase-editorial-setup.sql
git commit -m "feat(supabase): add mesa_editorial_acciones table with 56 seed records"
```

- [ ] **Step 3: INSTRUCCIÓN PARA USUARIO**

El SQL debe ejecutarse manualmente en el Supabase SQL Editor:
1. Abrir Supabase Dashboard → SQL Editor
2. Pegar y ejecutar `supabase-editorial-setup.sql`
3. Verificar que la query final muestra los 56 registros agrupados por eje

---

## Task 6: Crear Dashboard Selector

**Files:**
- Create: `src/apps/shared/DashboardSelector.jsx`

- [ ] **Step 1: Crear DashboardSelector.jsx**

```jsx
import { useEffect, useState } from 'react'

export default function DashboardSelector({ userName, userEmail, onSelect, onLogout }) {
  const [lastUsed, setLastUsed] = useState(null)
  const [visible,  setVisible]  = useState(false)

  useEffect(() => {
    const last = localStorage.getItem('uss_last_dashboard')
    setLastUsed(last)
    // Trigger fade+slide animation
    const t = setTimeout(() => setVisible(true), 50)
    return () => clearTimeout(t)
  }, [])

  return (
    <div className={`selector-page ${visible ? 'selector-visible' : ''}`}>
      <div className="selector-container">

        {/* Header */}
        <div className="selector-header">
          <img
            src="/mesa-medios/escudo-uss-horizontal-blanco.svg"
            alt="Universidad San Sebastián"
            className="selector-logo"
          />
          <h1 className="selector-title">Sistema de Gestión USS</h1>
          <p className="selector-subtitle">Selecciona tu mesa de trabajo</p>
        </div>

        {/* Cards */}
        <div className="selector-cards">
          <button
            className="selector-card"
            onClick={() => onSelect('medios')}
          >
            <span className="selector-card-icon" aria-hidden="true">📊</span>
            <h2 className="selector-card-title">Mesa de Medios</h2>
            <p className="selector-card-desc">Gestión de campañas y contenidos</p>
            {lastUsed === 'medios' && (
              <span className="selector-last-badge">Último usado</span>
            )}
          </button>

          <button
            className="selector-card"
            onClick={() => onSelect('editorial')}
          >
            <span className="selector-card-icon" aria-hidden="true">📝</span>
            <h2 className="selector-card-title">Mesa Editorial</h2>
            <p className="selector-card-desc">Plan comunicacional y acciones por eje</p>
            {lastUsed === 'editorial' && (
              <span className="selector-last-badge">Último usado</span>
            )}
          </button>
        </div>

        {/* Footer */}
        <div className="selector-footer">
          <span className="selector-user">
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
              <circle cx="7" cy="5" r="2.5" stroke="currentColor" strokeWidth="1.2" />
              <path d="M2 12c0-2.761 2.239-5 5-5s5 2.239 5 5" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" />
            </svg>
            {userName}
          </span>
          <span className="selector-separator">·</span>
          <button className="selector-logout" onClick={onLogout}>
            <svg width="13" height="13" viewBox="0 0 13 13" fill="none">
              <path d="M4.5 2H2.5a1 1 0 00-1 1v7a1 1 0 001 1h2M8.5 9l2.5-2.5L8.5 4M5 6.5h6" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
            Cerrar sesión
          </button>
        </div>
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Agregar estilos del selector en src/index.css**

Añadir al final de `src/index.css`:

```css
/* ── Dashboard Selector ─────────────────────────────────────────── */
.selector-page {
  min-height: 100vh;
  background: #f0f4f8;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem 1rem;
  opacity: 0;
  transform: translateY(12px);
  transition: opacity 0.3s ease, transform 0.3s ease;
}

.selector-page.selector-visible {
  opacity: 1;
  transform: translateY(0);
}

.selector-container {
  background: white;
  border-radius: 16px;
  padding: 2.5rem 2rem;
  width: 100%;
  max-width: 560px;
  box-shadow: 0 4px 24px rgba(15,43,65,0.12);
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.selector-header {
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
}

.selector-logo {
  height: 40px;
  filter: brightness(0) saturate(100%) invert(15%) sepia(40%) saturate(600%) hue-rotate(180deg);
}

.selector-title {
  font-size: 1.4rem;
  font-weight: 700;
  color: #0f2b41;
  margin: 0;
}

.selector-subtitle {
  font-size: 0.9rem;
  color: #64748b;
  margin: 0;
}

.selector-cards {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.selector-card {
  position: relative;
  background: white;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  padding: 1.5rem 1rem;
  cursor: pointer;
  text-align: center;
  transition: border-color 0.2s, box-shadow 0.2s, transform 0.15s;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  font-family: 'Montserrat', sans-serif;
}

.selector-card:hover {
  border-color: #ceb37c;
  box-shadow: 0 4px 16px rgba(206,179,124,0.25);
  transform: translateY(-2px);
}

.selector-card:focus-visible {
  outline: 2px solid #ceb37c;
  outline-offset: 2px;
}

.selector-card-icon {
  font-size: 2rem;
  display: block;
}

.selector-card-title {
  font-size: 1rem;
  font-weight: 700;
  color: #0f2b41;
  margin: 0;
}

.selector-card-desc {
  font-size: 0.78rem;
  color: #64748b;
  margin: 0;
  line-height: 1.4;
}

.selector-last-badge {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  background: #ceb37c;
  color: #0f2b41;
  font-size: 0.65rem;
  font-weight: 600;
  padding: 0.15rem 0.5rem;
  border-radius: 20px;
}

.selector-footer {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  font-size: 0.82rem;
  color: #64748b;
  border-top: 1px solid #f1f5f9;
  padding-top: 1rem;
}

.selector-user {
  display: flex;
  align-items: center;
  gap: 0.3rem;
}

.selector-separator { color: #cbd5e1; }

.selector-logout {
  background: none;
  border: none;
  color: #0f2b41;
  font-size: 0.82rem;
  font-family: 'Montserrat', sans-serif;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.3rem;
  padding: 0.2rem 0.4rem;
  border-radius: 4px;
  transition: background 0.15s;
}

.selector-logout:hover { background: #f1f5f9; }

/* Botón volver al selector en headers */
.btn-back-selector {
  background: rgba(255,255,255,0.15);
  border: 1px solid rgba(255,255,255,0.3);
  border-radius: 6px;
  color: white;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background 0.15s;
  margin-right: 0.5rem;
}

.btn-back-selector:hover { background: rgba(255,255,255,0.25); }

/* Responsive Selector */
@media (max-width: 480px) {
  .selector-cards { grid-template-columns: 1fr; }
  .selector-container { padding: 1.5rem 1rem; }
}
```

- [ ] **Step 3: Commit**

```bash
git add src/apps/shared/DashboardSelector.jsx src/index.css
git commit -m "feat(selector): add dashboard selector with localStorage and animations"
```

---

## Task 7: Crear config y componentes base de Mesa Editorial

**Files:**
- Create: `src/apps/mesa-editorial/config.js`
- Create: `src/apps/mesa-editorial/components/Header.jsx`
- Create: `src/apps/mesa-editorial/components/AddActionModal.jsx`

- [ ] **Step 1: Crear config.js**

```js
// src/apps/mesa-editorial/config.js

export const EJES = [
  { id: 'discusion',   label: 'Discusión País',           color: '#2A5BA8' },
  { id: 'orgullo',     label: 'Orgullo USS',               color: '#C8102E' },
  { id: 'salud',       label: 'Salud',                     color: '#1D7A4F' },
  { id: 'investigacion', label: 'Investigación',           color: '#7A2AB8' },
  { id: 'vinculacion', label: 'Vinculación con el Medio',  color: '#B06A00' },
]

export const EJE_LABELS = EJES.map(e => e.label)

export const EJE_COLOR_MAP = Object.fromEntries(EJES.map(e => [e.label, e.color]))

export const TIPOS_CONFIG = {
  'Ancla':   { color: '#C8102E', bg: '#FEE2E2', label: 'Ancla' },
  'AO':      { color: '#2A5BA8', bg: '#DBEAFE', label: 'AO' },
  'Soporte': { color: '#7A2AB8', bg: '#EDE9FE', label: 'Soporte' },
}

export const STATUS_CONFIG = {
  'Completado':   { dot: '#16A34A', text: '#166534', bg: '#DCFCE7' },
  'En desarrollo':{ dot: '#D97706', text: '#92400E', bg: '#FEF3C7' },
  'Pendiente':    { dot: '#DC2626', text: '#991B1B', bg: '#FEE2E2' },
}

export const STATUS_OPTIONS = ['Pendiente', 'En desarrollo', 'Completado']

export const TIPO_ACCION_OPTIONS = [
  'Interna', 'Externo', 'Interno y Externo', 'Interna-Externa', 'Externa-Interno',
]
```

- [ ] **Step 2: Crear Header.jsx para Mesa Editorial**

```jsx
// src/apps/mesa-editorial/components/Header.jsx
export default function HeaderEditorial({ userName, userEmail, onLogout, onBackToSelector }) {
  const initials = userName
    ? userName.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()
    : '?'

  return (
    <header className="header header-editorial">
      <div className="header-row-top">
        <div className="header-left">
          {onBackToSelector && (
            <button className="btn-back-selector" onClick={onBackToSelector} title="Volver al selector">
              <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                <path d="M10 3L5 8l5 5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </button>
          )}
          <div className="header-logo">
            <img src="/mesa-medios/escudo-uss-horizontal-blanco.svg" alt="USS" className="header-logo-img" />
          </div>
          <div className="header-divider" />
          <div>
            <h1 className="header-title">Mesa Editorial USS</h1>
            <p className="header-subtitle">Plan comunicacional y acciones por eje</p>
          </div>
        </div>
        <div className="header-user">
          <div className="user-menu">
            <div className="user-avatar" title={`${userName} (${userEmail})`}>{initials}</div>
            <div className="user-info">
              <span className="user-name">{userName}</span>
              <span className="user-email">{userEmail}</span>
            </div>
            <button className="btn-logout" onClick={onLogout} title="Cerrar sesión">
              <svg width="15" height="15" viewBox="0 0 15 15" fill="none">
                <path d="M5.5 2H3a1 1 0 00-1 1v9a1 1 0 001 1h2.5M10 10l3-2.5L10 5M6 7.5h7" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    </header>
  )
}
```

- [ ] **Step 3: Crear AddActionModal.jsx**

```jsx
// src/apps/mesa-editorial/components/AddActionModal.jsx
import { useState, useEffect, useRef } from 'react'
import { EJES, TIPOS_CONFIG, TIPO_ACCION_OPTIONS } from '../config'

export default function AddActionModal({ onConfirm, onClose }) {
  const [eje,        setEje]        = useState(EJES[0].label)
  const [tipo,       setTipo]       = useState('Ancla')
  const [tema,       setTema]       = useState('')
  const [accion,     setAccion]     = useState('')
  const [tipoAccion, setTipoAccion] = useState('Interna')
  const [fecha,      setFecha]      = useState('')
  const [responsable,setResponsable]= useState('')
  const firstRef = useRef(null)

  useEffect(() => { firstRef.current?.focus() }, [])

  useEffect(() => {
    function handleKey(e) { if (e.key === 'Escape') onClose() }
    document.addEventListener('keydown', handleKey)
    return () => document.removeEventListener('keydown', handleKey)
  }, [onClose])

  function handleSubmit(e) {
    e.preventDefault()
    if (!accion.trim()) return
    onConfirm({ eje, tipo, tema, accion: accion.trim(), tipo_accion: tipoAccion, fecha: fecha || null, responsable, status: 'Pendiente' })
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-card" onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <h2>Nueva acción editorial</h2>
          <button className="modal-close" onClick={onClose} aria-label="Cerrar">
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
              <path d="M4 4l8 8M12 4l-8 8" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
            </svg>
          </button>
        </div>
        <form onSubmit={handleSubmit} className="modal-form">
          <div className="form-row-2">
            <div className="form-group">
              <label>Eje</label>
              <select value={eje} onChange={e => setEje(e.target.value)} ref={firstRef}>
                {EJES.map(e => <option key={e.id} value={e.label}>{e.label}</option>)}
              </select>
            </div>
            <div className="form-group">
              <label>Tipo</label>
              <select value={tipo} onChange={e => setTipo(e.target.value)}>
                {Object.keys(TIPOS_CONFIG).map(t => <option key={t} value={t}>{t}</option>)}
              </select>
            </div>
          </div>
          <div className="form-group">
            <label>Tema</label>
            <input type="text" value={tema} onChange={e => setTema(e.target.value)} placeholder="Tema general de la acción" />
          </div>
          <div className="form-group">
            <label>Acción <span className="required">*</span></label>
            <input type="text" value={accion} onChange={e => setAccion(e.target.value)} placeholder="Descripción específica de la acción" required />
          </div>
          <div className="form-row-2">
            <div className="form-group">
              <label>Canal</label>
              <select value={tipoAccion} onChange={e => setTipoAccion(e.target.value)}>
                {TIPO_ACCION_OPTIONS.map(t => <option key={t} value={t}>{t}</option>)}
              </select>
            </div>
            <div className="form-group">
              <label>Fecha</label>
              <input type="date" value={fecha} onChange={e => setFecha(e.target.value)} />
            </div>
          </div>
          <div className="form-group">
            <label>Responsable</label>
            <input type="text" value={responsable} onChange={e => setResponsable(e.target.value)} placeholder="Nombre del responsable" />
          </div>
          <div className="modal-actions">
            <button type="button" className="btn-ghost-cancel" onClick={onClose}>Cancelar</button>
            <button type="submit" className="btn-add" disabled={!accion.trim()}>Agregar acción</button>
          </div>
        </form>
      </div>
    </div>
  )
}
```

- [ ] **Step 4: Commit**

```bash
git add src/apps/mesa-editorial/config.js src/apps/mesa-editorial/components/
git commit -m "feat(editorial): add config, header and add-action modal"
```

---

## Task 8: Crear EjeSection y EditorialTable

**Files:**
- Create: `src/apps/mesa-editorial/components/EjeSection.jsx`
- Create: `src/apps/mesa-editorial/components/EditorialTable.jsx`

- [ ] **Step 1: Crear EjeSection.jsx**

```jsx
// src/apps/mesa-editorial/components/EjeSection.jsx
import { useState } from 'react'
import { TIPOS_CONFIG, STATUS_CONFIG, STATUS_OPTIONS } from '../config'

function formatDate(dateStr) {
  if (!dateStr) return '—'
  const d = new Date(dateStr + 'T00:00:00')
  return d.toLocaleDateString('es-CL', { day: 'numeric', month: 'short', year: '2-digit' })
}

export default function EjeSection({ eje, rows, onCellChange, onDeleteRow, collapsed, onToggle }) {
  const completadas   = rows.filter(r => r.status === 'Completado').length
  const enDesarrollo  = rows.filter(r => r.status === 'En desarrollo').length
  const pendientes    = rows.filter(r => r.status === 'Pendiente').length
  const pct = rows.length > 0 ? Math.round((completadas / rows.length) * 100) : 0

  return (
    <div className="eje-section">
      {/* ── Header del eje ── */}
      <div className="eje-header" onClick={onToggle} style={{ '--eje-color': eje.color }}>
        <div className="eje-stripe" style={{ background: eje.color }} />
        <h2 className="eje-title">{eje.label}</h2>
        <span className="eje-count">{rows.length} {rows.length === 1 ? 'acción' : 'acciones'}</span>
        <div className="eje-progress-track">
          <div className="eje-progress-fill" style={{ width: `${pct}%`, background: eje.color }} />
        </div>
        <span className="eje-pct">{pct}%</span>
        <svg
          className={`eje-chevron ${collapsed ? '' : 'eje-chevron-open'}`}
          width="14" height="14" viewBox="0 0 14 14" fill="none"
        >
          <path d="M3 5l4 4 4-4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </div>

      {/* ── Tabla de acciones del eje ── */}
      {!collapsed && (
        <div className="eje-table-wrap">
          {rows.length === 0 ? (
            <div className="eje-empty">Sin acciones en este eje.</div>
          ) : (
            <table className="editorial-table">
              <thead>
                <tr>
                  <th className="col-tipo">Tipo</th>
                  <th className="col-tema">Tema</th>
                  <th className="col-accion">Acción</th>
                  <th className="col-canal">Canal</th>
                  <th className="col-fecha">Fecha</th>
                  <th className="col-resp">Responsable</th>
                  <th className="col-status">Status</th>
                  <th className="col-del"></th>
                </tr>
              </thead>
              <tbody>
                {rows.map(row => (
                  <EjeRow
                    key={row.id}
                    row={row}
                    onCellChange={onCellChange}
                    onDeleteRow={onDeleteRow}
                  />
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  )
}

function EjeRow({ row, onCellChange, onDeleteRow }) {
  const tipoCfg = TIPOS_CONFIG[row.tipo] || {}
  const statusCfg = STATUS_CONFIG[row.status] || STATUS_CONFIG['Pendiente']

  function handleInlineEdit(field, value) {
    if (value !== row[field]) onCellChange(row.id, field, value)
  }

  return (
    <tr className="editorial-row">
      {/* Tipo — badge, no editable */}
      <td className="col-tipo">
        <span className="tipo-badge" style={{ color: tipoCfg.color, background: tipoCfg.bg }}>
          {row.tipo || '—'}
        </span>
      </td>

      {/* Tema — contenteditable */}
      <td className="col-tema">
        <span
          contentEditable
          suppressContentEditableWarning
          onBlur={e => handleInlineEdit('tema', e.currentTarget.textContent.trim())}
          onKeyDown={e => { if (e.key === 'Enter') { e.preventDefault(); e.currentTarget.blur() } }}
          className="editorial-editable"
        >
          {row.tema || ''}
        </span>
      </td>

      {/* Acción — contenteditable */}
      <td className="col-accion">
        <span
          contentEditable
          suppressContentEditableWarning
          onBlur={e => handleInlineEdit('accion', e.currentTarget.textContent.trim())}
          onKeyDown={e => { if (e.key === 'Enter') { e.preventDefault(); e.currentTarget.blur() } }}
          className="editorial-editable"
        >
          {row.accion || ''}
        </span>
      </td>

      {/* Canal — no editable */}
      <td className="col-canal">
        <span className="canal-text">{row.tipo_accion || '—'}</span>
      </td>

      {/* Fecha — editable con input */}
      <td className="col-fecha">
        <input
          type="date"
          defaultValue={row.fecha || ''}
          onBlur={e => handleInlineEdit('fecha', e.target.value || null)}
          className="editorial-date-input"
          title={formatDate(row.fecha)}
        />
        <span className="fecha-display">{formatDate(row.fecha)}</span>
      </td>

      {/* Responsable — contenteditable */}
      <td className="col-resp">
        <span
          contentEditable
          suppressContentEditableWarning
          onBlur={e => handleInlineEdit('responsable', e.currentTarget.textContent.trim())}
          onKeyDown={e => { if (e.key === 'Enter') { e.preventDefault(); e.currentTarget.blur() } }}
          className="editorial-editable"
        >
          {row.responsable || ''}
        </span>
      </td>

      {/* Status — select dropdown */}
      <td className="col-status">
        <select
          value={row.status || 'Pendiente'}
          onChange={e => handleInlineEdit('status', e.target.value)}
          className="status-select"
          style={{ color: statusCfg.text, background: statusCfg.bg }}
        >
          {STATUS_OPTIONS.map(s => (
            <option key={s} value={s}>{s}</option>
          ))}
        </select>
      </td>

      {/* Eliminar */}
      <td className="col-del">
        <button className="btn-delete-row" onClick={() => onDeleteRow(row.id)} title="Eliminar acción">
          <svg width="13" height="13" viewBox="0 0 13 13" fill="none">
            <path d="M2 3.5h9M5 3.5V2.5a.5.5 0 01.5-.5h2a.5.5 0 01.5.5v1M5.5 5.5v4M7.5 5.5v4M3.5 3.5l.5 7h5l.5-7" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </button>
      </td>
    </tr>
  )
}
```

- [ ] **Step 2: Crear EditorialTable.jsx**

```jsx
// src/apps/mesa-editorial/components/EditorialTable.jsx
import { useState } from 'react'
import { EJES } from '../config'
import EjeSection from './EjeSection'

export default function EditorialTable({ rows, onCellChange, onDeleteRow, filterQuery, totalRows, onClearFilter, onAdd }) {
  const [collapsedEjes, setCollapsedEjes] = useState({})

  function toggleEje(ejeLabel) {
    setCollapsedEjes(prev => ({ ...prev, [ejeLabel]: !prev[ejeLabel] }))
  }

  // Agrupar rows por eje, manteniendo el orden de EJES
  const rowsByEje = EJES.reduce((acc, eje) => {
    acc[eje.label] = rows.filter(r => r.eje === eje.label)
    return acc
  }, {})

  // Empty state: sin datos cargados
  if (totalRows === 0) {
    return (
      <div className="empty-state">
        <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
          <rect x="8" y="8" width="32" height="32" rx="6" stroke="#ceb37c" strokeWidth="2" fill="none"/>
          <path d="M16 20h16M16 26h10" stroke="#ceb37c" strokeWidth="2" strokeLinecap="round"/>
        </svg>
        <h3>Sin acciones registradas</h3>
        <p>Comienza agregando la primera acción editorial.</p>
        <button className="btn-add" onClick={onAdd}>+ Agregar acción</button>
      </div>
    )
  }

  // Empty state: filtro sin resultados
  if (rows.length === 0 && filterQuery) {
    return (
      <div className="empty-state">
        <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
          <circle cx="22" cy="22" r="14" stroke="#ceb37c" strokeWidth="2" fill="none"/>
          <path d="M32 32l8 8" stroke="#ceb37c" strokeWidth="2" strokeLinecap="round"/>
          <path d="M17 22h10M22 17v10" stroke="#ceb37c" strokeWidth="2" strokeLinecap="round"/>
        </svg>
        <h3>Sin resultados para "{filterQuery}"</h3>
        <p>Intenta con otro término de búsqueda.</p>
        <button className="btn-secondary" onClick={onClearFilter}>Limpiar filtro</button>
      </div>
    )
  }

  return (
    <div className="editorial-table-container">
      {EJES.map(eje => {
        const ejeRows = rowsByEje[eje.label] || []
        // No renderizar ejes vacíos cuando hay filtro activo
        if (ejeRows.length === 0 && filterQuery) return null
        return (
          <EjeSection
            key={eje.id}
            eje={eje}
            rows={ejeRows}
            onCellChange={onCellChange}
            onDeleteRow={onDeleteRow}
            collapsed={!!collapsedEjes[eje.label]}
            onToggle={() => toggleEje(eje.label)}
          />
        )
      })}
    </div>
  )
}
```

- [ ] **Step 3: Commit**

```bash
git add src/apps/mesa-editorial/components/EjeSection.jsx src/apps/mesa-editorial/components/EditorialTable.jsx
git commit -m "feat(editorial): add EjeSection and EditorialTable with collapsible groups"
```

---

## Task 9: Crear MobileCardView y MesaEditorialApp

**Files:**
- Create: `src/apps/mesa-editorial/components/MobileCardView.jsx`
- Create: `src/apps/mesa-editorial/MesaEditorialApp.jsx`

- [ ] **Step 1: Crear MobileCardView.jsx para Editorial**

```jsx
// src/apps/mesa-editorial/components/MobileCardView.jsx
import { EJES, TIPOS_CONFIG, STATUS_CONFIG, STATUS_OPTIONS, EJE_COLOR_MAP } from '../config'

function formatDate(dateStr) {
  if (!dateStr) return '—'
  const d = new Date(dateStr + 'T00:00:00')
  return d.toLocaleDateString('es-CL', { day: 'numeric', month: 'short', year: '2-digit' })
}

export default function MobileCardViewEditorial({ rows, onCellChange, onDeleteRow, totalRows, filterQuery, onClearFilter, onAdd }) {
  if (totalRows === 0) {
    return (
      <div className="empty-state">
        <h3>Sin acciones registradas</h3>
        <button className="btn-add" onClick={onAdd}>+ Agregar acción</button>
      </div>
    )
  }
  if (rows.length === 0 && filterQuery) {
    return (
      <div className="empty-state">
        <h3>Sin resultados para "{filterQuery}"</h3>
        <button className="btn-secondary" onClick={onClearFilter}>Limpiar filtro</button>
      </div>
    )
  }

  return (
    <div className="mobile-cards">
      {rows.map(row => {
        const ejeColor = EJE_COLOR_MAP[row.eje] || '#64748b'
        const tipoCfg  = TIPOS_CONFIG[row.tipo] || {}
        const statusCfg = STATUS_CONFIG[row.status] || STATUS_CONFIG['Pendiente']
        return (
          <div key={row.id} className="mobile-card" style={{ borderLeftColor: ejeColor }}>
            <div className="mobile-card-header">
              <span className="mobile-eje-label" style={{ color: ejeColor }}>{row.eje}</span>
              <span className="tipo-badge" style={{ color: tipoCfg.color, background: tipoCfg.bg }}>{row.tipo}</span>
            </div>
            {row.tema && <p className="mobile-tema">{row.tema}</p>}
            <p className="mobile-accion">{row.accion}</p>
            <div className="mobile-card-meta">
              <span>{row.tipo_accion || '—'}</span>
              <span>·</span>
              <span>{formatDate(row.fecha)}</span>
              <span>·</span>
              <span>{row.responsable || '—'}</span>
            </div>
            <div className="mobile-card-footer">
              <select
                value={row.status || 'Pendiente'}
                onChange={e => onCellChange(row.id, 'status', e.target.value)}
                className="status-select"
                style={{ color: statusCfg.text, background: statusCfg.bg }}
              >
                {STATUS_OPTIONS.map(s => <option key={s} value={s}>{s}</option>)}
              </select>
              <button className="btn-delete-row" onClick={() => onDeleteRow(row.id)}>
                <svg width="13" height="13" viewBox="0 0 13 13" fill="none">
                  <path d="M2 3.5h9M5 3.5V2.5a.5.5 0 01.5-.5h2a.5.5 0 01.5.5v1M5.5 5.5v4M7.5 5.5v4M3.5 3.5l.5 7h5l.5-7" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </button>
            </div>
          </div>
        )
      })}
    </div>
  )
}
```

- [ ] **Step 2: Crear MesaEditorialApp.jsx**

```jsx
// src/apps/mesa-editorial/MesaEditorialApp.jsx
import { useState, useEffect, useMemo } from 'react'
import { supabase } from '../../apps/shared/utils/supabase'
import { EJES, EJE_LABELS } from './config'
import { useToast } from '../../apps/shared/hooks/useToast'
import { useDebounce } from '../../apps/shared/hooks/useDebounce'
import HeaderEditorial from './components/Header'
import EditorialTable from './components/EditorialTable'
import MobileCardViewEditorial from './components/MobileCardView'
import AddActionModal from './components/AddActionModal'
import Toaster from '../../apps/shared/components/Toaster'
import ConfirmDialog from '../../apps/shared/components/ConfirmDialog'
import { STATUS_CONFIG } from './config'

const TABLE = 'mesa_editorial_acciones'

export default function MesaEditorialApp({ session, userName, onLogout, onBackToSelector }) {
  const [rows,          setRows]          = useState([])
  const [loading,       setLoading]       = useState(true)
  const [error,         setError]         = useState(null)
  const [showModal,     setShowModal]     = useState(false)
  const [confirmDelete, setConfirmDelete] = useState(null)

  // Filtros
  const [filterInput,   setFilterInput]   = useState('')
  const filterText = useDebounce(filterInput, 300)
  const [filterEje,     setFilterEje]     = useState('all')
  const [filterStatus,  setFilterStatus]  = useState('all')

  const { toasts, addToast, removeToast } = useToast()

  // Realtime
  useEffect(() => {
    const channel = supabase
      .channel('editorial-acciones-realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: TABLE }, (payload) => {
        if (payload.eventType === 'INSERT')  setRows(prev => [...prev, payload.new])
        else if (payload.eventType === 'UPDATE') setRows(prev => prev.map(r => r.id === payload.new.id ? payload.new : r))
        else if (payload.eventType === 'DELETE') setRows(prev => prev.filter(r => r.id !== payload.old.id))
      })
      .subscribe()
    fetchRows()
    return () => supabase.removeChannel(channel)
  }, [])

  // Keyboard shortcuts
  useEffect(() => {
    function handleKeyDown(e) {
      const tag = document.activeElement?.tagName
      const inInput = tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT'
      if (e.key === 'Escape') {
        if (confirmDelete) { setConfirmDelete(null); return }
        if (showModal)     { setShowModal(false);    return }
      }
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault()
        document.querySelector('.editorial-filter-input')?.focus()
        return
      }
      if (e.key.toLowerCase() === 'n' && !inInput && !showModal && !confirmDelete) {
        setShowModal(true)
      }
    }
    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [confirmDelete, showModal])

  async function fetchRows() {
    setLoading(true)
    const { data, error } = await supabase
      .from(TABLE).select('*').order('eje').order('created_at')
    if (error) setError(error.message)
    else setRows(data || [])
    setLoading(false)
  }

  async function logAction(accion, itemId, itemNombre, detalle = '') {
    if (!session) return
    await supabase.from('logs').insert([{
      user_email:       session.user.email,
      user_nombre:      userName || session.user.email,
      accion,
      contenido_id:     itemId,
      contenido_nombre: itemNombre,
      detalle,
    }])
  }

  // Filtrado con useMemo
  const displayRows = useMemo(() => {
    let result = rows
    if (filterEje !== 'all')    result = result.filter(r => r.eje === filterEje)
    if (filterStatus !== 'all') result = result.filter(r => r.status === filterStatus)
    if (filterText.trim()) {
      const q = filterText.toLowerCase()
      result = result.filter(r =>
        r.tema?.toLowerCase().includes(q) ||
        r.accion?.toLowerCase().includes(q) ||
        r.responsable?.toLowerCase().includes(q)
      )
    }
    return result
  }, [rows, filterEje, filterStatus, filterText])

  // KPI
  const kpi = useMemo(() => {
    const completadas  = rows.filter(r => r.status === 'Completado').length
    const enDesarrollo = rows.filter(r => r.status === 'En desarrollo').length
    const pendientes   = rows.filter(r => r.status === 'Pendiente').length
    const pct = rows.length > 0 ? Math.round((completadas / rows.length) * 100) : 0
    return { total: rows.length, completadas, enDesarrollo, pendientes, pct }
  }, [rows])

  async function handleAddRow(data) {
    const { data: inserted, error } = await supabase.from(TABLE).insert([data]).select().single()
    if (error) { addToast('Error al agregar la acción. Intenta nuevamente.', 'error'); return }
    await logAction('AGREGAR', inserted.id, data.accion, `Agregó "${data.accion}"`)
    setShowModal(false)
  }

  async function handleCellChange(rowId, field, value) {
    const row = rows.find(r => r.id === rowId)
    if (!row || row[field] === value) return
    setRows(prev => prev.map(r => r.id === rowId ? { ...r, [field]: value } : r))
    const { error } = await supabase.from(TABLE).update({ [field]: value }).eq('id', rowId)
    if (error) { addToast('Error al guardar. Los datos se recargarán.', 'error'); fetchRows(); return }
    await logAction('MODIFICAR', rowId, row.accion, `"${field}" → "${value}"`)
  }

  function requestDeleteRow(rowId) {
    const row = rows.find(r => r.id === rowId)
    setConfirmDelete({ id: rowId, nombre: row?.accion || 'esta acción' })
  }

  async function handleDeleteRow(rowId) {
    const row = rows.find(r => r.id === rowId)
    setRows(prev => prev.filter(r => r.id !== rowId))
    const { error } = await supabase.from(TABLE).delete().eq('id', rowId)
    if (error) { addToast('Error al eliminar la acción.', 'error'); fetchRows(); return }
    await logAction('ELIMINAR', rowId, row?.accion, `Eliminó "${row?.accion}"`)
  }

  return (
    <div className="app app-editorial">
      <HeaderEditorial
        userName={userName}
        userEmail={session.user.email}
        onLogout={onLogout}
        onBackToSelector={onBackToSelector}
      />

      {/* ── KPI Bar ── */}
      <div className="editorial-kpi-bar">
        <span className="kpi-item">
          <strong>{kpi.total}</strong> acciones
        </span>
        <span className="kpi-dot" style={{ background: '#16A34A' }} />
        <span className="kpi-item"><strong>{kpi.completadas}</strong> completadas</span>
        <span className="kpi-dot" style={{ background: '#D97706' }} />
        <span className="kpi-item"><strong>{kpi.enDesarrollo}</strong> en desarrollo</span>
        <span className="kpi-dot" style={{ background: '#DC2626' }} />
        <span className="kpi-item"><strong>{kpi.pendientes}</strong> pendientes</span>
        <span className="kpi-sep" />
        <span className="kpi-pct"><strong>{kpi.pct}%</strong> avance</span>
        <div className="kpi-actions">
          <button className="btn-add btn-add-sm" onClick={() => setShowModal(true)}>
            <svg width="13" height="13" viewBox="0 0 13 13" fill="none">
              <path d="M6.5 1v11M1 6.5h11" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"/>
            </svg>
            Nueva acción
          </button>
        </div>
      </div>

      {/* ── Filter bar ── */}
      <div className="editorial-filter-bar">
        <div className="filter-search">
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <circle cx="6" cy="6" r="4.5" stroke="currentColor" strokeWidth="1.3" />
            <path d="M9.5 9.5L13 13" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" />
          </svg>
          <input
            type="text"
            placeholder="Buscar tema, acción, responsable..."
            value={filterInput}
            onChange={e => setFilterInput(e.target.value)}
            className="editorial-filter-input filter-input"
          />
          {filterInput && (
            <button className="filter-clear" onClick={() => setFilterInput('')}>
              <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
                <path d="M3 3l6 6M9 3l-6 6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
              </svg>
            </button>
          )}
        </div>

        {/* Filtro por eje */}
        <div className="filter-pills">
          <button className={`pill ${filterEje === 'all' ? 'pill-active' : ''}`} onClick={() => setFilterEje('all')}>
            Todos los ejes
          </button>
          {EJES.map(eje => (
            <button
              key={eje.id}
              className={`pill ${filterEje === eje.label ? 'pill-active' : ''}`}
              style={filterEje === eje.label ? { background: eje.color, color: 'white', borderColor: eje.color } : {}}
              onClick={() => setFilterEje(filterEje === eje.label ? 'all' : eje.label)}
            >
              {eje.label}
            </button>
          ))}
        </div>

        {/* Filtro por status */}
        <div className="filter-pills">
          {['all', 'Pendiente', 'En desarrollo', 'Completado'].map(s => (
            <button
              key={s}
              className={`pill ${filterStatus === s ? 'pill-active' : ''}`}
              onClick={() => setFilterStatus(s)}
            >
              {s === 'all' ? 'Todos los status' : s}
            </button>
          ))}
        </div>
      </div>

      {loading && <div className="loading-state"><div className="spinner" /><span>Cargando acciones...</span></div>}
      {error && <div className="error-state"><strong>Error de conexión:</strong> {error}</div>}

      {!loading && !error && (
        <>
          <div className="desktop-only">
            <EditorialTable
              rows={displayRows}
              onCellChange={handleCellChange}
              onDeleteRow={requestDeleteRow}
              totalRows={rows.length}
              filterQuery={filterInput}
              onClearFilter={() => setFilterInput('')}
              onAdd={() => setShowModal(true)}
            />
          </div>
          <div className="mobile-only">
            <MobileCardViewEditorial
              rows={displayRows}
              onCellChange={handleCellChange}
              onDeleteRow={requestDeleteRow}
              totalRows={rows.length}
              filterQuery={filterInput}
              onClearFilter={() => setFilterInput('')}
              onAdd={() => setShowModal(true)}
            />
          </div>
          <div className="shortcuts-hint desktop-only">
            <span><kbd>Esc</kbd> cerrar</span><span>·</span>
            <span><kbd>Ctrl+K</kbd> buscar</span><span>·</span>
            <span><kbd>N</kbd> nueva acción</span>
          </div>
        </>
      )}

      {showModal && <AddActionModal onConfirm={handleAddRow} onClose={() => setShowModal(false)} />}
      {confirmDelete && (
        <ConfirmDialog
          nombre={confirmDelete.nombre}
          onConfirm={() => { handleDeleteRow(confirmDelete.id); setConfirmDelete(null) }}
          onCancel={() => setConfirmDelete(null)}
        />
      )}
      <Toaster toasts={toasts} onRemove={removeToast} />
    </div>
  )
}
```

- [ ] **Step 3: Commit**

```bash
git add src/apps/mesa-editorial/
git commit -m "feat(editorial): add MesaEditorialApp with realtime, filters and CRUD"
```

---

## Task 10: Estilos CSS para Mesa Editorial

**Files:**
- Modify: `src/index.css` — añadir estilos de editorial al final

- [ ] **Step 1: Añadir estilos de Mesa Editorial a index.css**

Añadir al final de `src/index.css`:

```css
/* ══════════════════════════════════════════════════════════════════
   MESA EDITORIAL — Tema invertido (navy primary, gold accent)
   ══════════════════════════════════════════════════════════════════ */

/* Variables del tema Editorial */
.app-editorial {
  --ed-primary: #0f2b41;
  --ed-accent:  #ceb37c;
  --ed-bg:      #f8f9fb;
}

/* Header editorial */
.header-editorial {
  background: #0f2b41;
}

/* KPI Bar */
.editorial-kpi-bar {
  position: sticky;
  top: 0;
  z-index: 10;
  background: #0f2b41;
  color: #ffffff;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.6rem 1.5rem;
  font-size: 0.82rem;
  flex-wrap: wrap;
}

.kpi-item { display: flex; align-items: center; gap: 0.3rem; }
.kpi-item strong { font-weight: 700; }
.kpi-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.kpi-sep { flex: 1; }
.kpi-pct { font-weight: 600; color: #ceb37c; }

.btn-add-sm {
  font-size: 0.78rem;
  padding: 0.35rem 0.75rem;
}

/* Filter bar editorial */
.editorial-filter-bar {
  background: white;
  border-bottom: 1px solid #e2e8f0;
  padding: 0.75rem 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.filter-pills {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
}

.pill {
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  border: 1.5px solid #e2e8f0;
  background: white;
  color: #475569;
  font-size: 0.75rem;
  font-family: 'Montserrat', sans-serif;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s;
}

.pill:hover { border-color: #0f2b41; color: #0f2b41; }
.pill-active { background: #0f2b41; color: white; border-color: #0f2b41; }

/* Container principal de editorial */
.editorial-table-container {
  display: flex;
  flex-direction: column;
  gap: 0;
}

/* ── EJE SECTION ── */
.eje-section {
  border-bottom: 1px solid #e2e8f0;
}

.eje-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.85rem 1.5rem;
  cursor: pointer;
  user-select: none;
  background: #f8fafc;
  transition: background 0.15s;
  position: relative;
}

.eje-header:hover { background: #f1f5f9; }

.eje-stripe {
  width: 6px;
  height: 28px;
  border-radius: 3px;
  flex-shrink: 0;
}

.eje-title {
  font-size: 0.95rem;
  font-weight: 700;
  color: #0f2b41;
  margin: 0;
  min-width: 180px;
}

.eje-count {
  font-size: 0.75rem;
  color: #64748b;
  white-space: nowrap;
}

.eje-progress-track {
  flex: 1;
  height: 6px;
  background: #e2e8f0;
  border-radius: 3px;
  overflow: hidden;
  max-width: 160px;
}

.eje-progress-fill {
  height: 100%;
  border-radius: 3px;
  transition: width 0.4s ease;
}

.eje-pct {
  font-size: 0.75rem;
  font-weight: 600;
  color: #475569;
  min-width: 32px;
  text-align: right;
}

.eje-chevron {
  color: #94a3b8;
  transition: transform 0.2s;
  flex-shrink: 0;
}

.eje-chevron-open { transform: rotate(180deg); }

/* ── TABLA EDITORIAL ── */
.eje-table-wrap {
  overflow-x: auto;
}

.editorial-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.8rem;
}

.editorial-table th {
  background: #f1f5f9;
  color: #475569;
  font-weight: 600;
  font-size: 0.72rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  padding: 0.5rem 0.75rem;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
}

.editorial-table td {
  padding: 0.5rem 0.75rem;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
  color: #1e293b;
}

.editorial-row:hover td { background: #f8fafc; }

/* Anchos de columna */
.col-tipo   { width: 70px; }
.col-tema   { min-width: 140px; max-width: 180px; }
.col-accion { min-width: 200px; max-width: 280px; }
.col-canal  { width: 110px; }
.col-fecha  { width: 110px; }
.col-resp   { min-width: 100px; max-width: 140px; }
.col-status { width: 130px; }
.col-del    { width: 36px; }

/* Tipo badge */
.tipo-badge {
  display: inline-block;
  padding: 0.15rem 0.5rem;
  border-radius: 4px;
  font-size: 0.72rem;
  font-weight: 600;
}

/* Canal text */
.canal-text {
  font-size: 0.76rem;
  color: #64748b;
}

/* Editable inline */
.editorial-editable {
  display: block;
  outline: none;
  border-radius: 4px;
  padding: 0.15rem 0.3rem;
  min-height: 1.2em;
  line-height: 1.4;
  transition: background 0.15s;
}

.editorial-editable:focus {
  background: #eff6ff;
  box-shadow: 0 0 0 2px rgba(42,91,168,0.25);
}

/* Fecha: ocultamos el input, mostramos display */
.editorial-date-input {
  position: absolute;
  opacity: 0;
  width: 0;
  height: 0;
}

.fecha-display {
  font-size: 0.78rem;
  color: #475569;
  cursor: pointer;
}

.col-fecha:hover .editorial-date-input {
  position: static;
  opacity: 1;
  width: 100%;
  height: auto;
  font-size: 0.78rem;
  border: 1px solid #ceb37c;
  border-radius: 4px;
  padding: 0.15rem 0.3rem;
}

.col-fecha:hover .fecha-display { display: none; }

/* Status select */
.status-select {
  border: none;
  border-radius: 4px;
  padding: 0.2rem 0.4rem;
  font-size: 0.75rem;
  font-family: 'Montserrat', sans-serif;
  font-weight: 600;
  cursor: pointer;
  width: 100%;
}

/* Delete button */
.btn-delete-row {
  background: none;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 0.25rem;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: color 0.15s, background 0.15s;
}

.btn-delete-row:hover { color: #dc2626; background: #fef2f2; }

/* Empty state en eje */
.eje-empty {
  padding: 1rem 1.5rem;
  color: #94a3b8;
  font-size: 0.82rem;
  font-style: italic;
}

/* ── MOBILE CARDS EDITORIAL ── */
.mobile-card {
  background: white;
  border-radius: 10px;
  border: 1px solid #e2e8f0;
  border-left: 4px solid;
  margin: 0.5rem 1rem;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}

.mobile-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
}

.mobile-eje-label {
  font-size: 0.72rem;
  font-weight: 700;
}

.mobile-tema {
  font-size: 0.78rem;
  color: #64748b;
  margin: 0;
}

.mobile-accion {
  font-size: 0.85rem;
  font-weight: 600;
  color: #1e293b;
  margin: 0;
}

.mobile-card-meta {
  display: flex;
  gap: 0.4rem;
  font-size: 0.72rem;
  color: #94a3b8;
  flex-wrap: wrap;
}

.mobile-card-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 0.25rem;
}

/* ── MODAL MULTI-COLUMNA ── */
.form-row-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

@media (max-width: 480px) {
  .form-row-2 { grid-template-columns: 1fr; }
}

/* required marker */
.required { color: #dc2626; }
```

- [ ] **Step 2: Commit**

```bash
git add src/index.css
git commit -m "feat(editorial): add editorial theme CSS with inverted colors and eje styles"
```

---

## Task 11: Verificación final y build de producción

**Files:**
- Ninguno — solo verificación

- [ ] **Step 1: Verificar que npm run dev arranca sin errores**

```bash
npm run dev
```

Expected: sin errores en consola, servidor en http://localhost:5173

- [ ] **Step 2: Verificar flujo completo manualmente**

Lista de verificación:
1. Login page carga ✓
2. Post-login → DashboardSelector aparece ✓
3. Click Mesa de Medios → MesaMediosApp carga con datos ✓
4. Botón ← Inicio regresa al selector ✓
5. Click Mesa Editorial → MesaEditorialApp carga (requiere SQL ejecutado en Supabase) ✓
6. Ejes colapsables funcionan ✓
7. Edición inline funciona ✓
8. Toasts se muestran al editar/agregar/eliminar ✓
9. ConfirmDialog antes de eliminar ✓
10. Filtros (búsqueda, eje, status) funcionan ✓
11. Keyboard shortcuts Esc/Ctrl+K/N funcionan ✓
12. Responsive en mobile ✓
13. localStorage recuerda última dashboard ✓

- [ ] **Step 3: Build de producción**

```bash
npm run build
```

Expected: sin errores, carpeta `dist/` generada.

- [ ] **Step 4: Commit final**

```bash
git add -A
git commit -m "$(cat <<'EOF'
feat: complete dual dashboard system USS

Sistema dual completo con:
- DashboardSelector post-login con localStorage
- Mesa de Medios refactorizada sin regresiones
- Mesa Editorial nueva con 5 ejes colapsables
- Tema visual invertido (navy/dorado)
- Quick Wins compartidos (toasts, confirmDialog, useMemo, debounce)
- Realtime sync en ambas apps
- Responsive mobile
- Build de producción OK

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review del Plan

**Spec coverage:**
- ✅ Arquitectura `apps/` → Tasks 1-3
- ✅ Router principal → Task 4
- ✅ SQL + 56 registros → Task 5
- ✅ DashboardSelector + localStorage → Task 6
- ✅ Mesa Editorial config + header + modal → Task 7
- ✅ EjeSection colapsable + EditorialTable → Task 8
- ✅ MesaEditorialApp + MobileCardView → Task 9
- ✅ Estilos invertidos + contraste → Task 10
- ✅ Quick Wins (toasts, confirm, useMemo, debounce, keyboard shortcuts, empty states) → en Tasks 3 y 9
- ✅ QA + build → Task 11
- ✅ Progreso por eje → en EjeSection (header con pct)
- ✅ KPI bar → en MesaEditorialApp
- ✅ Filtros (búsqueda debounced, por eje, por status) → en MesaEditorialApp

**Constraints validados:**
- ✅ Tablas Supabase sin renombrar (contenidos, logs, usuarios_autorizados)
- ✅ NUNCA #fff sobre #ceb37c — kpi-bar usa #0f2b41 con texto white
- ✅ Montserrat en ambas apps (font-family heredado de index.css)
- ✅ Canal realtime distinto: `editorial-acciones-realtime`
- ✅ RLS apunta a `usuarios_autorizados` (nombre real en DB)
- ✅ Sin nuevas dependencias npm

**Nota importante para ejecutor:** La tabla `mesa_editorial_acciones` debe crearse en Supabase **antes** de probar Mesa Editorial. El archivo `supabase-editorial-setup.sql` se genera en Task 5.
