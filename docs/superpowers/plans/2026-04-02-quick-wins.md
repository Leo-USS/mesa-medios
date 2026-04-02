# Quick Wins Mesa de Medios USS — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar 7 quick wins de UX/performance en el dashboard Mesa de Medios USS sin agregar dependencias npm ni modificar el schema de Supabase.

**Architecture:** Hooks propios en `src/hooks/`, componentes nuevos en `src/components/`, estilos en `src/index.css`. El estado de confirmación de borrado se levanta a `App.jsx`. El debounce separa el estado visual del input del estado de filtrado real.

**Tech Stack:** React 18 con hooks, Vite 5, Supabase JS, vanilla CSS con variables CSS existentes.

---

## Pre-condición: verificar branch

```bash
cd "C:/Users/leopu/Desktop/Trabajo/USS/mesa-medios-main"
git branch
# debe mostrar * mejoras-quick-wins
```

---

## HALLAZGOS PREVIOS AL PLAN (leer antes de implementar)

- `App.jsx:145` — `displayRows` con `useMemo` **ya existe**. QW3 se reduce a añadir debounce.
- `MediaTable.jsx:28` — `deleteConfirm` local **ya existe** como estado inline Sí/No. Hay que **eliminarlo** y reemplazar con ConfirmDialog en App.jsx.
- `MobileCardView.jsx:183` — `deleteConfirm` local en `ContentCard` **también existe**. Ídem — eliminar.
- `MediaTable.jsx:95-107` — empty state básico **ya existe** con SVG. Hay que **reemplazarlo**.
- `MobileCardView.jsx:347-354` — empty state básico **ya existe**. Hay que **reemplazarlo**.
- `App.jsx:50` — `filterText` es hoy un único estado (input + filtro). Hay que separarlo en `filterInput` (inmediato) + `filterText` (debounced).

---

## File Map

| Archivo | Acción |
|---------|--------|
| `src/hooks/useToast.js` | CREAR |
| `src/hooks/useDebounce.js` | CREAR |
| `src/components/Toaster.jsx` | CREAR |
| `src/components/ConfirmDialog.jsx` | CREAR |
| `src/App.jsx` | MODIFICAR (toasts, confirmDelete, filterInput/debounce, getRowProgress export, keyboard shortcuts, footer hint, pasar props nuevos) |
| `src/components/MediaTable.jsx` | MODIFICAR (eliminar deleteConfirm local, reemplazar empty state, agregar progress bar, recibir props nuevos) |
| `src/components/MobileCardView.jsx` | MODIFICAR (eliminar deleteConfirm local en ContentCard, reemplazar empty state, agregar progress bar en card header) |
| `src/index.css` | MODIFICAR (agregar estilos: toast, confirm dialog, progress bar, empty state mejorado, shortcuts hint) |

---

## Task 1: Crear hooks base (useToast + useDebounce)

**Files:**
- Create: `src/hooks/useToast.js`
- Create: `src/hooks/useDebounce.js`

- [ ] **Step 1: Crear `src/hooks/useToast.js`**

```js
// src/hooks/useToast.js
import { useState, useCallback } from 'react'

export function useToast() {
  const [toasts, setToasts] = useState([])

  const addToast = useCallback((message, type = 'info', duration) => {
    const id = Date.now() + Math.random()
    const ms = duration ?? (type === 'error' ? 6000 : 4000)
    setToasts(prev => {
      const next = [...prev, { id, message, type }]
      return next.slice(-3) // máximo 3 apilados
    })
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id))
    }, ms)
  }, [])

  const removeToast = useCallback((id) => {
    setToasts(prev => prev.filter(t => t.id !== id))
  }, [])

  return { toasts, addToast, removeToast }
}
```

- [ ] **Step 2: Crear `src/hooks/useDebounce.js`**

```js
// src/hooks/useDebounce.js
import { useState, useEffect } from 'react'

export function useDebounce(value, delay = 300) {
  const [debounced, setDebounced] = useState(value)

  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delay)
    return () => clearTimeout(timer)
  }, [value, delay])

  return debounced
}
```

- [ ] **Step 3: Commit**

```bash
git add src/hooks/useToast.js src/hooks/useDebounce.js
git commit -m "feat: add useToast and useDebounce hooks"
```

---

## Task 2: Crear Toaster.jsx + agregar estilos CSS

**Files:**
- Create: `src/components/Toaster.jsx`
- Modify: `src/index.css` (agregar sección toast al final)

- [ ] **Step 1: Crear `src/components/Toaster.jsx`**

```jsx
// src/components/Toaster.jsx
export default function Toaster({ toasts, onRemove }) {
  if (toasts.length === 0) return null

  return (
    <div className="toast-container" role="region" aria-label="Notificaciones">
      {toasts.map(t => (
        <div
          key={t.id}
          className={`toast toast-${t.type}`}
          onClick={() => onRemove(t.id)}
          role="alert"
        >
          <span className="toast-icon">
            {t.type === 'success' && '✓'}
            {t.type === 'error'   && '✕'}
            {t.type === 'info'    && 'ℹ'}
          </span>
          <span className="toast-message">{t.message}</span>
          <button className="toast-close" onClick={() => onRemove(t.id)} aria-label="Cerrar">×</button>
        </div>
      ))}
    </div>
  )
}
```

- [ ] **Step 2: Abrir `src/index.css` y agregar al final del archivo**

```css
/* ── Toast Notifications ─────────────────────────────────────── */
.toast-container {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 9999;
  display: flex;
  flex-direction: column;
  gap: 8px;
  pointer-events: none;
}

.toast {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 11px 14px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  box-shadow: 0 4px 16px rgba(0,0,0,.15);
  max-width: 360px;
  pointer-events: all;
  cursor: pointer;
  animation: toastSlideIn .22s ease;
  border-left: 4px solid transparent;
  font-family: 'Inter', system-ui, sans-serif;
}

.toast-success {
  background: #f0fdf4;
  color: #166534;
  border-left-color: #22c55e;
}

.toast-error {
  background: #fef2f2;
  color: #b91c1c;
  border-left-color: #dc2626;
}

.toast-info {
  background: #eff6ff;
  color: #1e40af;
  border-left-color: #3b82f6;
}

.toast-icon {
  font-size: 14px;
  font-weight: 700;
  flex-shrink: 0;
}

.toast-message {
  flex: 1;
  line-height: 1.4;
}

.toast-close {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 16px;
  color: currentColor;
  opacity: .5;
  padding: 0 2px;
  line-height: 1;
  flex-shrink: 0;
}
.toast-close:hover { opacity: 1; }

@keyframes toastSlideIn {
  from { transform: translateX(110%); opacity: 0; }
  to   { transform: translateX(0);    opacity: 1; }
}

@media (max-width: 768px) {
  .toast-container {
    bottom: 16px;
    right: 12px;
    left: 12px;
  }
  .toast { max-width: 100%; }
}
```

- [ ] **Step 3: Commit**

```bash
git add src/components/Toaster.jsx src/index.css
git commit -m "feat: add Toaster component and toast CSS styles"
```

---

## Task 3: Integrar toasts en App.jsx + reemplazar alert()

**Files:**
- Modify: `src/App.jsx`

- [ ] **Step 1: Agregar imports en App.jsx (línea 1, junto a los existentes)**

Cambiar la línea de imports de react de:
```js
import { useState, useEffect, useMemo } from 'react'
```
a:
```js
import { useState, useEffect, useMemo, useCallback } from 'react'
```

Agregar después de `import USSLoader from './components/USSLoader'`:
```js
import Toaster from './components/Toaster'
import { useToast } from './hooks/useToast'
```

- [ ] **Step 2: Agregar hook `useToast` dentro de la función `App()`, justo después de los `useState` existentes (después de línea 52, `const [sortDir...]`)**

```js
// ── Toast notifications ───────────────────────────────────────
const { toasts, addToast, removeToast } = useToast()
```

- [ ] **Step 3: Reemplazar los tres `alert()` en App.jsx**

Cambiar en `handleAddRow` (buscar `alert('Error al agregar`):
```js
// ANTES:
if (error) { alert('Error al agregar: ' + error.message); return }

// DESPUÉS:
if (error) { addToast('Error al agregar el contenido. Intenta nuevamente.', 'error'); return }
```

Cambiar en `handleCellChange` (buscar `alert('Error al guardar`):
```js
// ANTES:
if (error) { alert('Error al guardar: ' + error.message); fetchRows(); return }

// DESPUÉS:
if (error) { addToast('Error al guardar. Los datos se recargarán.', 'error'); fetchRows(); return }
```

Cambiar en `handleFieldChange` (buscar `alert('Error al guardar`):
```js
// ANTES:
if (error) { alert('Error al guardar: ' + error.message); fetchRows(); return }

// DESPUÉS:
if (error) { addToast('Error al guardar el campo. Los datos se recargarán.', 'error'); fetchRows(); return }
```

Cambiar en `handleDeleteRow` (buscar `alert('Error al eliminar`):
```js
// ANTES:
if (error) { alert('Error al eliminar: ' + error.message); fetchRows(); return }

// DESPUÉS:
if (error) { addToast('Error al eliminar el contenido.', 'error'); fetchRows(); return }
```

- [ ] **Step 4: Agregar `<Toaster>` al final del return de App, justo antes del cierre `</div>`**

El return de App termina con:
```jsx
      {showLogs && (
        <AuditLogPanel onClose={() => setShowLogs(false)} />
      )}
    </div>
  )
```

Cambiar a:
```jsx
      {showLogs && (
        <AuditLogPanel onClose={() => setShowLogs(false)} />
      )}

      <Toaster toasts={toasts} onRemove={removeToast} />
    </div>
  )
```

- [ ] **Step 5: Verificar que no quedan `alert(` en App.jsx**

```bash
grep -n "alert(" src/App.jsx
# debe retornar vacío
```

- [ ] **Step 6: Commit**

```bash
git add src/App.jsx
git commit -m "feat: replace alert() with toast notifications in App.jsx"
```

---

## Task 4: Crear ConfirmDialog + levantar delete a App.jsx

**Files:**
- Create: `src/components/ConfirmDialog.jsx`
- Modify: `src/App.jsx` (agregar confirmDelete state, requestDeleteRow)
- Modify: `src/components/MediaTable.jsx` (eliminar deleteConfirm local)
- Modify: `src/components/MobileCardView.jsx` (eliminar deleteConfirm local en ContentCard)
- Modify: `src/index.css` (agregar estilos ConfirmDialog)

- [ ] **Step 1: Crear `src/components/ConfirmDialog.jsx`**

```jsx
// src/components/ConfirmDialog.jsx
import { useEffect, useRef } from 'react'

export default function ConfirmDialog({ nombre, onConfirm, onCancel }) {
  const cancelRef = useRef(null)

  // Focus en "Cancelar" al abrir para evitar borrado accidental con Enter
  useEffect(() => {
    cancelRef.current?.focus()
  }, [])

  // Escape cancela
  useEffect(() => {
    function handleKey(e) {
      if (e.key === 'Escape') onCancel()
    }
    document.addEventListener('keydown', handleKey)
    return () => document.removeEventListener('keydown', handleKey)
  }, [onCancel])

  return (
    <div className="confirm-overlay" onClick={onCancel}>
      <div className="confirm-dialog" onClick={e => e.stopPropagation()} role="dialog" aria-modal="true">
        <div className="confirm-icon">
          <svg width="28" height="28" viewBox="0 0 28 28" fill="none">
            <circle cx="14" cy="14" r="12" stroke="#dc2626" strokeWidth="1.8" fill="#fef2f2" />
            <path d="M14 9v6M14 18v1.5" stroke="#dc2626" strokeWidth="2" strokeLinecap="round" />
          </svg>
        </div>
        <h3 className="confirm-title">¿Eliminar contenido?</h3>
        <p className="confirm-body">
          Se eliminará <strong>"{nombre}"</strong> y todos sus datos de medios asignados.
          <br />Esta acción no se puede deshacer.
        </p>
        <div className="confirm-actions">
          <button ref={cancelRef} className="btn-ghost-cancel" onClick={onCancel}>
            Cancelar
          </button>
          <button className="btn-danger-confirm" onClick={onConfirm}>
            Eliminar
          </button>
        </div>
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Agregar estilos en `src/index.css` (al final, después de los estilos de toast)**

```css
/* ── Confirm Dialog ──────────────────────────────────────────── */
.confirm-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, .45);
  z-index: 8000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
  animation: fadeIn .15s ease;
}

.confirm-dialog {
  background: white;
  border-radius: 12px;
  padding: 28px 28px 24px;
  max-width: 380px;
  width: 100%;
  box-shadow: 0 20px 60px rgba(0,0,0,.25);
  text-align: center;
  animation: dialogScaleIn .18s ease;
}

.confirm-icon {
  margin-bottom: 12px;
}

.confirm-title {
  font-size: 17px;
  font-weight: 700;
  color: var(--text-main);
  margin: 0 0 8px;
}

.confirm-body {
  font-size: 14px;
  color: var(--text-muted);
  margin: 0 0 24px;
  line-height: 1.55;
}

.confirm-body strong {
  color: var(--text-main);
}

.confirm-actions {
  display: flex;
  gap: 10px;
  justify-content: center;
}

.btn-ghost-cancel {
  padding: 9px 20px;
  border-radius: 7px;
  border: 1.5px solid var(--border);
  background: white;
  color: var(--text-main);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: border-color .15s, background .15s;
}
.btn-ghost-cancel:hover {
  border-color: var(--secondary);
  background: #f0f6fc;
}
.btn-ghost-cancel:focus-visible {
  outline: 2px solid var(--secondary);
  outline-offset: 2px;
}

.btn-danger-confirm {
  padding: 9px 20px;
  border-radius: 7px;
  border: none;
  background: #dc2626;
  color: white;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  transition: background .15s;
}
.btn-danger-confirm:hover  { background: #b91c1c; }
.btn-danger-confirm:focus-visible {
  outline: 2px solid #dc2626;
  outline-offset: 2px;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to   { opacity: 1; }
}

@keyframes dialogScaleIn {
  from { transform: scale(.94); opacity: 0; }
  to   { transform: scale(1);   opacity: 1; }
}
```

- [ ] **Step 3: Modificar `App.jsx` — agregar import, estado y lógica**

Agregar import después de `import Toaster ...`:
```js
import ConfirmDialog from './components/ConfirmDialog'
```

Agregar estado después de `const [showLogs, setShowLogs] = useState(false)`:
```js
const [confirmDelete, setConfirmDelete] = useState(null) // null | { id, nombre }
```

Agregar función `requestDeleteRow` justo antes de `async function handleDeleteRow`:
```js
function requestDeleteRow(rowId) {
  const row = rows.find(r => r.id === rowId)
  setConfirmDelete({ id: rowId, nombre: row?.nombre || 'este contenido' })
}
```

- [ ] **Step 4: Cambiar `onDeleteRow` en el return de App.jsx para pasar `requestDeleteRow` en lugar de `handleDeleteRow`**

Buscar las dos ocurrencias de `onDeleteRow={handleDeleteRow}` (una en `<MediaTable>` y otra en `<MobileCardView>`) y cambiar ambas a:
```jsx
onDeleteRow={requestDeleteRow}
```

- [ ] **Step 5: Agregar `<ConfirmDialog>` en el return de App.jsx, junto a los otros modales**

Justo antes de `<Toaster ...>`:
```jsx
      {confirmDelete && (
        <ConfirmDialog
          nombre={confirmDelete.nombre}
          onConfirm={() => { handleDeleteRow(confirmDelete.id); setConfirmDelete(null) }}
          onCancel={() => setConfirmDelete(null)}
        />
      )}
```

- [ ] **Step 6: Limpiar `MediaTable.jsx` — eliminar deleteConfirm local**

En `MediaTable.jsx`, eliminar la línea:
```js
const [deleteConfirm, setDeleteConfirm] = useState(null)
```

Buscar el bloque de acciones en la columna actions (líneas ~194-211). Reemplazar todo el bloque `{deleteConfirm === row.id ? (...) : (...)}` por:
```jsx
<td className="col-actions td-actions">
  <button
    className="btn-delete"
    onClick={() => onDeleteRow(row.id)}
    title="Eliminar fila"
  >
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
      <path d="M2 3.5h10M5.5 3.5V2h3v1.5M5.833 6v4M8.167 6v4M3 3.5l.5 8a1 1 0 001 .917h5a1 1 0 001-.917l.5-8" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  </button>
</td>
```

- [ ] **Step 7: Limpiar `MobileCardView.jsx` — eliminar deleteConfirm local en ContentCard**

En `ContentCard`, eliminar:
```js
const [deleteConfirm, setDeleteConfirm] = useState(false)
```

Buscar el bloque de acciones (líneas ~309-323) y reemplazar `{deleteConfirm ? (...) : (...)}` por:
```jsx
<div className="mobile-card-actions">
  <button className="mobile-btn-delete" onClick={() => onDeleteRow(row.id)}>
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
      <path d="M2 3.5h10M5.5 3.5V2h3v1.5M5.833 6v4M8.167 6v4M3 3.5l.5 8a1 1 0 001 .917h5a1 1 0 001-.917l.5-8" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
    Eliminar contenido
  </button>
</div>
```

- [ ] **Step 8: Verificar que no queda `deleteConfirm` en MediaTable ni MobileCardView**

```bash
grep -n "deleteConfirm" src/components/MediaTable.jsx src/components/MobileCardView.jsx
# debe retornar vacío
```

- [ ] **Step 9: Commit**

```bash
git add src/components/ConfirmDialog.jsx src/App.jsx src/components/MediaTable.jsx src/components/MobileCardView.jsx src/index.css
git commit -m "feat: add ConfirmDialog and lift delete confirmation to App.jsx"
```

---

## Task 5: useDebounce en búsqueda (QW3+QW4 combinados)

**Files:**
- Modify: `src/App.jsx`

Nota: `useMemo` ya está implementado en App.jsx (línea 145, variable `displayRows`). Esta tarea solo añade debounce separando `filterInput` de `filterText`.

- [ ] **Step 1: Agregar import de `useDebounce` en App.jsx**

Agregar junto a los otros imports de hooks propios (después de `import { useToast } from './hooks/useToast'`):
```js
import { useDebounce } from './hooks/useDebounce'
```

- [ ] **Step 2: Modificar el estado `filterText` en App.jsx**

Buscar la línea:
```js
const [filterText,   setFilterText]   = useState('')
```

Reemplazar por:
```js
const [filterInput,  setFilterInput]  = useState('')
const filterText = useDebounce(filterInput, 300)
```

- [ ] **Step 3: Actualizar referencias a `filterText` / `setFilterText` en el JSX del filter-bar**

En el JSX del `filter-bar` (líneas ~244-281 en App.jsx), aplicar estos 4 cambios:

a) El input: cambiar `value={filterText}` → `value={filterInput}` y `onChange={e => setFilterText(e.target.value)}` → `onChange={e => setFilterInput(e.target.value)}`

b) El botón clear: cambiar `{filterText && (` → `{filterInput && (` y `onClick={() => setFilterText('')}` → `onClick={() => setFilterInput('')}`

c) El contador: cambiar `{filterText && (` → `{filterInput && (`

El bloque del filter-bar modificado queda así:
```jsx
<div className="filter-bar">
  <div className="filter-search">
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
      <circle cx="6" cy="6" r="4.5" stroke="currentColor" strokeWidth="1.3" />
      <path d="M9.5 9.5L13 13" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" />
    </svg>
    <input
      type="text"
      placeholder="Filtrar contenidos..."
      value={filterInput}
      onChange={e => setFilterInput(e.target.value)}
      className="filter-input"
    />
    {filterInput && (
      <button className="filter-clear" onClick={() => setFilterInput('')}>
        <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
          <path d="M3 3l6 6M9 3l-6 6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
        </svg>
      </button>
    )}
  </div>
  <button
    className="sort-btn"
    onClick={() => setSortDir(d => d === 'asc' ? 'desc' : 'asc')}
    title={sortDir === 'asc' ? 'Más antigua primero' : 'Más reciente primero'}
  >
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
      <path d="M7 2v10M4 4l3-2.5L10 4" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round"
        style={{ opacity: sortDir === 'asc' ? 1 : 0.3 }} />
      <path d="M4 10l3 2.5L10 10" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round"
        style={{ opacity: sortDir === 'desc' ? 1 : 0.3 }} />
    </svg>
    <span>Fecha</span>
  </button>
  {filterInput && (
    <span className="filter-count">{displayRows.length} de {rows.length}</span>
  )}
</div>
```

- [ ] **Step 4: Verificar que no quedan referencias a `setFilterText` en App.jsx**

```bash
grep -n "setFilterText\|filterText" src/App.jsx
# debe mostrar solo: filterText (la const debounced) y filterInput
```

- [ ] **Step 5: Commit**

```bash
git add src/App.jsx
git commit -m "feat: add useDebounce to search filter (300ms delay)"
```

---

## Task 6: Progress bar por fila

**Files:**
- Modify: `src/App.jsx` (exportar `getRowProgress`)
- Modify: `src/components/MediaTable.jsx` (importar y renderizar)
- Modify: `src/components/MobileCardView.jsx` (importar y renderizar en card header)
- Modify: `src/index.css` (estilos progress bar)

- [ ] **Step 1: Exportar `getRowProgress` desde `App.jsx`**

Agregar justo después de `export function setCellData(...)` (antes de `function sortRows`):

```js
export function getRowProgress(medios) {
  const filled = MEDIA_COLS.filter(col => {
    const { valor } = getCellData(medios, col.id)
    return valor && valor !== 'no'
  }).length
  const total = MEDIA_COLS.length
  return { filled, total, pct: Math.round((filled / total) * 100) }
}
```

También agregar el import de `MEDIA_COLS` al inicio de App.jsx (después del import de supabase):
```js
import { MEDIA_COLS } from './config'
```

- [ ] **Step 2: Importar `getRowProgress` en `MediaTable.jsx`**

Cambiar la línea de import de App en MediaTable.jsx de:
```js
import { getCellData } from '../App'
```
a:
```js
import { getCellData, getRowProgress } from '../App'
```

- [ ] **Step 3: Agregar bloque de progress bar en la celda `td-contenidos` de MediaTable.jsx**

Dentro del `<td className="sticky-col col-contenidos td-contenidos">`, después del bloque `isEditing ? <input...> : <span...>`, agregar el bloque de progreso.

El bloque completo de la celda queda así (reemplazar el td.col-contenidos existente):
```jsx
<td className="sticky-col col-contenidos td-contenidos">
  {isEditing && editingField.field === 'nombre' ? (
    <input
      className="inline-edit"
      value={editValue}
      onChange={e => setEditValue(e.target.value)}
      onBlur={commitEditField}
      onKeyDown={handleFieldKeyDown}
      autoFocus
    />
  ) : (
    <>
      <span
        className="contenido-text"
        onClick={() => startEditField(row.id, 'nombre', row.nombre)}
        title="Clic para editar"
      >
        {row.nombre || <em className="placeholder">Sin nombre</em>}
      </span>
      {(() => {
        const { filled, total, pct } = getRowProgress(row.medios)
        const color = pct >= 60 ? '#22c55e' : pct >= 30 ? '#f59e0b' : '#ef4444'
        return (
          <div className="row-progress">
            <div className="progress-bar-track">
              <div className="progress-bar-fill" style={{ width: `${pct}%`, background: color }} />
            </div>
            <span className="progress-label">{filled}/{total} · {pct}%</span>
          </div>
        )
      })()}
    </>
  )}
</td>
```

- [ ] **Step 4: Importar `getRowProgress` en `MobileCardView.jsx`**

Cambiar:
```js
import { getCellData } from '../App'
```
a:
```js
import { getCellData, getRowProgress } from '../App'
```

- [ ] **Step 5: Agregar progress bar en el header de ContentCard en `MobileCardView.jsx`**

Dentro de `ContentCard`, buscar el `<div className="mobile-card-title-area">`. Después del `{editingName ? <input...> : <span...>}`, reemplazar el `<span className="mobile-card-counter">` existente por:

```jsx
<div className="mobile-card-meta">
  {(() => {
    const { filled, total, pct } = getRowProgress(row.medios)
    const color = pct >= 60 ? '#22c55e' : pct >= 30 ? '#f59e0b' : '#ef4444'
    return (
      <>
        <div className="mobile-progress-track">
          <div className="mobile-progress-fill" style={{ width: `${pct}%`, background: color }} />
        </div>
        <span className="mobile-card-counter">{filled}/{total} medios</span>
      </>
    )
  })()}
</div>
```

- [ ] **Step 6: Agregar estilos en `src/index.css` (al final)**

```css
/* ── Row Progress Bar ────────────────────────────────────────── */
.row-progress {
  margin-top: 4px;
  display: flex;
  align-items: center;
  gap: 6px;
}

.progress-bar-track {
  flex: 1;
  height: 4px;
  background: var(--border);
  border-radius: 2px;
  overflow: hidden;
  min-width: 60px;
}

.progress-bar-fill {
  height: 100%;
  border-radius: 2px;
  transition: width .3s ease;
}

.progress-label {
  font-size: 10px;
  color: var(--text-muted);
  white-space: nowrap;
  flex-shrink: 0;
}

/* Mobile progress */
.mobile-card-meta {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 3px;
}

.mobile-progress-track {
  width: 60px;
  height: 4px;
  background: var(--border);
  border-radius: 2px;
  overflow: hidden;
  flex-shrink: 0;
}

.mobile-progress-fill {
  height: 100%;
  border-radius: 2px;
  transition: width .3s ease;
}
```

- [ ] **Step 7: Commit**

```bash
git add src/App.jsx src/components/MediaTable.jsx src/components/MobileCardView.jsx src/index.css
git commit -m "feat: add per-row progress bar in table and mobile cards"
```

---

## Task 7: Empty states mejorados

**Files:**
- Modify: `src/App.jsx` (pasar props nuevos a MediaTable y MobileCardView)
- Modify: `src/components/MediaTable.jsx` (reemplazar empty state, agregar prop totalRows/filterQuery/onClearFilter)
- Modify: `src/components/MobileCardView.jsx` (reemplazar empty state, agregar props)
- Modify: `src/index.css` (estilos empty state mejorados)

- [ ] **Step 1: Modificar el llamado a `<MediaTable>` en App.jsx para pasar nuevas props**

Buscar `<MediaTable` en el return de App.jsx y agregar tres props:
```jsx
<MediaTable
  rows={displayRows}
  onCellChange={handleCellChange}
  onFieldChange={handleFieldChange}
  onDeleteRow={requestDeleteRow}
  totalRows={rows.length}
  filterQuery={filterInput}
  onClearFilter={() => setFilterInput('')}
  onAdd={() => setShowModal(true)}
/>
```

- [ ] **Step 2: Modificar el llamado a `<MobileCardView>` en App.jsx**

```jsx
<MobileCardView
  rows={displayRows}
  onCellChange={handleCellChange}
  onFieldChange={handleFieldChange}
  onDeleteRow={requestDeleteRow}
  totalRows={rows.length}
  filterQuery={filterInput}
  onClearFilter={() => setFilterInput('')}
  onAdd={() => setShowModal(true)}
/>
```

- [ ] **Step 3: Actualizar la firma de `MediaTable` para recibir las nuevas props y reemplazar el empty state**

Cambiar la primera línea del componente MediaTable:
```jsx
// ANTES:
export default function MediaTable({ rows, onCellChange, onFieldChange, onDeleteRow }) {

// DESPUÉS:
export default function MediaTable({ rows, onCellChange, onFieldChange, onDeleteRow, totalRows, filterQuery, onClearFilter, onAdd }) {
```

Reemplazar el bloque de empty state existente en `<tbody>` (el `rows.length === 0 ? (...)`) por:
```jsx
{rows.length === 0 ? (
  <tr>
    <td colSpan={MEDIA_COLS.length + 3} className="empty-state-cell">
      {totalRows === 0 ? (
        <div className="empty-state">
          <span className="empty-state-icon">📋</span>
          <p className="empty-state-title">Sin contenidos aún</p>
          <span className="empty-state-sub">Agrega el primero para comenzar la planificación</span>
          <button className="empty-state-cta" onClick={onAdd}>+ Agregar contenido</button>
        </div>
      ) : (
        <div className="empty-state">
          <span className="empty-state-icon">🔍</span>
          <p className="empty-state-title">Sin resultados para "{filterQuery}"</p>
          <span className="empty-state-sub">Prueba con otro término de búsqueda</span>
          <button className="empty-state-ghost" onClick={onClearFilter}>✕ Limpiar búsqueda</button>
        </div>
      )}
    </td>
  </tr>
) : (
  rows.map((row, idx) => {
    // ⚠️ Este bloque (líneas 109-215 del MediaTable.jsx original) NO se modifica.
    // Solo se reemplaza el bloque de empty state de arriba. El resto de rows.map queda igual.
    const isEditing = editingField?.rowId === row.id
    return ( /* ... JSX de fila existente sin cambios ... */ )
  })
)}
```

- [ ] **Step 4: Actualizar `MobileCardView` — firma y empty state**

Cambiar la firma:
```jsx
// ANTES:
export default function MobileCardView({ rows, onCellChange, onFieldChange, onDeleteRow }) {

// DESPUÉS:
export default function MobileCardView({ rows, onCellChange, onFieldChange, onDeleteRow, totalRows, filterQuery, onClearFilter, onAdd }) {
```

Reemplazar el bloque de empty state (el `rows.length === 0 ? (...)`) en MobileCardView:
```jsx
{rows.length === 0 ? (
  <div className="mobile-empty">
    {totalRows === 0 ? (
      <>
        <span className="empty-state-icon">📋</span>
        <p className="empty-state-title">Sin contenidos aún</p>
        <span className="empty-state-sub">Agrega el primero para comenzar</span>
        <button className="empty-state-cta" onClick={onAdd}>+ Agregar contenido</button>
      </>
    ) : (
      <>
        <span className="empty-state-icon">🔍</span>
        <p className="empty-state-title">Sin resultados para "{filterQuery}"</p>
        <span className="empty-state-sub">Prueba con otro término</span>
        <button className="empty-state-ghost" onClick={onClearFilter}>✕ Limpiar búsqueda</button>
      </>
    )}
  </div>
) : (
  rows.map(row => (
    <ContentCard ... /> // igual que antes
  ))
)}
```

- [ ] **Step 5: Agregar estilos del empty state mejorado en `src/index.css`**

Buscar el selector `.empty-state` existente en index.css y **reemplazarlo** con:
```css
/* ── Empty States ────────────────────────────────────────────── */
.empty-state-cell {
  padding: 0 !important;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 40px 20px;
  text-align: center;
}

.empty-state-icon {
  font-size: 36px;
  line-height: 1;
  margin-bottom: 4px;
}

.empty-state-title {
  font-size: 15px;
  font-weight: 700;
  color: var(--text-main);
  margin: 0;
}

.empty-state-sub {
  font-size: 13px;
  color: var(--text-muted);
  max-width: 280px;
  line-height: 1.5;
}

.empty-state-cta {
  margin-top: 8px;
  padding: 9px 20px;
  background: var(--accent);
  color: var(--primary);
  border: none;
  border-radius: 7px;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  transition: background .15s;
}
.empty-state-cta:hover { background: var(--accent-light); }

.empty-state-ghost {
  margin-top: 8px;
  padding: 9px 20px;
  background: transparent;
  color: var(--secondary);
  border: 1.5px solid var(--secondary);
  border-radius: 7px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: background .15s, color .15s;
}
.empty-state-ghost:hover {
  background: var(--secondary);
  color: white;
}

/* Mobile empty state */
.mobile-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 48px 24px;
  text-align: center;
}
```

- [ ] **Step 6: Commit**

```bash
git add src/App.jsx src/components/MediaTable.jsx src/components/MobileCardView.jsx src/index.css
git commit -m "feat: improve empty states with contextual messages and CTAs"
```

---

## Task 8: Keyboard shortcuts + footer hint

**Files:**
- Modify: `src/App.jsx`
- Modify: `src/index.css`

- [ ] **Step 1: Agregar `useCallback` al import de react en App.jsx (si no está ya)**

Verificar que la primera línea de App.jsx tiene `useCallback`:
```js
import { useState, useEffect, useMemo, useCallback } from 'react'
```
(Ya fue agregado en Task 3, Step 1)

- [ ] **Step 2: Agregar el `useEffect` de keyboard shortcuts en App.jsx**

Agregar después del `useEffect` de realtime (después del bloque que suscribe al canal `contenidos-realtime`):

```js
// ── Keyboard shortcuts ────────────────────────────────────────
useEffect(() => {
  function handleKeyDown(e) {
    const tag = document.activeElement?.tagName
    const inInput = tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT'

    // Escape — cierra modales en orden de prioridad
    if (e.key === 'Escape') {
      if (confirmDelete) { setConfirmDelete(null); return }
      if (showModal)     { setShowModal(false);    return }
      if (showLogs)      { setShowLogs(false);     return }
    }

    // Ctrl/Cmd + K — focus en búsqueda
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
      e.preventDefault()
      document.querySelector('.filter-input')?.focus()
      return
    }

    // N — nuevo contenido (solo si no hay input enfocado y no hay modal abierto)
    if (e.key === 'n' && !inInput && !showModal && !showLogs && !confirmDelete) {
      setShowModal(true)
    }
  }

  document.addEventListener('keydown', handleKeyDown)
  return () => document.removeEventListener('keydown', handleKeyDown)
}, [confirmDelete, showModal, showLogs])
```

- [ ] **Step 3: Agregar el footer hint en el return de App.jsx**

Dentro del bloque `{!loading && !error && (...)}`, justo después del cierre del bloque `<div className="mobile-only">...</div>`, agregar el footer antes del cierre del fragment:

```jsx
{!loading && !error && (
  <>
    <div className="desktop-only">
      {/* Usar exactamente los props definidos en Task 7 Steps 1 y 2 */}
      <MediaTable
        rows={displayRows}
        onCellChange={handleCellChange}
        onFieldChange={handleFieldChange}
        onDeleteRow={requestDeleteRow}
        totalRows={rows.length}
        filterQuery={filterInput}
        onClearFilter={() => setFilterInput('')}
        onAdd={() => setShowModal(true)}
      />
    </div>
    <div className="mobile-only">
      <MobileCardView
        rows={displayRows}
        onCellChange={handleCellChange}
        onFieldChange={handleFieldChange}
        onDeleteRow={requestDeleteRow}
        totalRows={rows.length}
        filterQuery={filterInput}
        onClearFilter={() => setFilterInput('')}
        onAdd={() => setShowModal(true)}
      />
    </div>
    <div className="shortcuts-hint desktop-only">
      <span><kbd>Esc</kbd> cerrar</span>
      <span>·</span>
      <span><kbd>Ctrl+K</kbd> buscar</span>
      <span>·</span>
      <span><kbd>N</kbd> nuevo</span>
    </div>
  </>
)}
```

- [ ] **Step 4: Agregar estilos en `src/index.css`**

```css
/* ── Keyboard Shortcuts Hint ─────────────────────────────────── */
.shortcuts-hint {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 6px 16px;
  background: #e8f0f8;
  color: var(--text-muted);
  font-size: 11px;
  border-top: 1px solid var(--border);
  flex-shrink: 0;
}

.shortcuts-hint kbd {
  display: inline-block;
  padding: 1px 5px;
  background: white;
  border: 1px solid var(--border);
  border-radius: 3px;
  font-family: inherit;
  font-size: 10px;
  font-weight: 600;
  color: var(--text-main);
  box-shadow: 0 1px 0 var(--border);
}
```

- [ ] **Step 5: Commit**

```bash
git add src/App.jsx src/index.css
git commit -m "feat: add keyboard shortcuts (Esc, Ctrl+K, N) with footer hint"
```

---

## Task 9: Verificación final

- [ ] **Step 1: Verificar que no quedan `alert(` en ningún archivo src**

```bash
grep -rn "alert(" src/
# debe retornar vacío
```

- [ ] **Step 2: Verificar que no quedan `deleteConfirm` locales en MediaTable ni MobileCardView**

```bash
grep -n "deleteConfirm" src/components/MediaTable.jsx src/components/MobileCardView.jsx
# debe retornar vacío
```

- [ ] **Step 3: Verificar que se crearon todos los archivos nuevos**

```bash
ls src/hooks/
# useDebounce.js  useToast.js

ls src/components/
# AddRowModal.jsx  AuditLogPanel.jsx  CellPopover.jsx  ConfirmDialog.jsx
# Header.jsx  Login.jsx  MediaTable.jsx  MobileCardView.jsx
# Toaster.jsx  USSLoader.jsx
```

- [ ] **Step 4: Verificar git log**

```bash
git log --oneline
# debe mostrar 8 commits: init + 7 feat commits
```

- [ ] **Step 5: Levantar dev server y probar manualmente**

```bash
npm run dev
```

Checklist manual:
- [ ] Login funciona
- [ ] Al editar una celda con error, aparece toast rojo (bottom-right)
- [ ] Al hacer click en eliminar, aparece ConfirmDialog centrado
- [ ] Escape cierra el ConfirmDialog
- [ ] Escape cierra el modal de agregar
- [ ] La barra de búsqueda tiene debounce (typing rápido no flicker)
- [ ] Cada fila muestra barra de progreso bajo el nombre
- [ ] Tabla vacía muestra empty state con botón "+ Agregar contenido"
- [ ] Búsqueda sin resultados muestra "Sin resultados para X" con botón limpiar
- [ ] `N` abre modal de nuevo contenido
- [ ] `Ctrl+K` hace focus en el input de búsqueda
- [ ] Footer muestra hints de keyboard shortcuts

---

## Resumen de commits esperados

```
feat: add keyboard shortcuts (Esc, Ctrl+K, N) with footer hint
feat: improve empty states with contextual messages and CTAs
feat: add per-row progress bar in table and mobile cards
feat: add useDebounce to search filter (300ms delay)
feat: add ConfirmDialog and lift delete confirmation to App.jsx
feat: replace alert() with toast notifications in App.jsx
feat: add Toaster component and toast CSS styles
feat: add useToast and useDebounce hooks
```
