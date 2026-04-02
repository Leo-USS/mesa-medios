# Spec: 7 Quick Wins — Mesa de Medios USS

**Fecha:** 2026-04-02  
**Estado:** Aprobado para implementación  
**Constraint clave:** Sin dependencias npm nuevas. Sin cambios a schema Supabase. Colores USS preservados.

---

## Decisiones de diseño (aprobadas vía visual companion)

| QW | Decisión aprobada |
|----|-------------------|
| Toast | bottom-right, borde izquierdo de color, auto-dismiss 4s (error 6s) |
| ConfirmDialog | modal centrado con overlay semitransparente |
| useMemo | wrap en App.jsx sobre filtrado + sort |
| useDebounce | hook propio 300ms, sin librería |
| Progress bar | mini barra dentro de columna "Contenido" |
| Empty state | emoji + texto contextual + CTA diferenciado por contexto |
| Keyboard shortcuts | Escape/Ctrl+K/N con hint sutil en footer |

---

## QW 1 — Toast Notifications

### Archivos nuevos
- `src/hooks/useToast.js`
- `src/components/Toaster.jsx`

### Comportamiento
- **Tipos:** `success`, `error`, `info`
- **Posición:** fixed bottom-right, z-index 9999
- **Auto-dismiss:** success/info = 4000ms, error = 6000ms
- **Máximo apilado:** 3 toasts simultáneos (el más antiguo se elimina al superar el límite)
- **Click para cerrar:** sí
- **Animación:** slide-in desde la derecha (translateX 100% → 0)
- **Colores:** error usa rojo estándar, success usa verde estándar, borde izquierdo 4px

### Reemplazos en App.jsx
| Código actual | Reemplazo |
|---|---|
| `alert('Error al guardar: ' + error.message)` | `addToast('Error al guardar. Los datos se recargarán.', 'error')` |
| `alert('Error al eliminar: ' + error.message)` | `addToast('Error al eliminar el contenido.', 'error')` |
| `alert('Error al agregar: ' + error.message)` | `addToast('Error al agregar el contenido.', 'error')` |

### Interfaz del hook
```js
const { toasts, addToast } = useToast()
// addToast(message: string, type?: 'success'|'error'|'info', duration?: number)
```

---

## QW 2 — ConfirmDialog antes de Eliminar

### Archivos nuevos
- `src/components/ConfirmDialog.jsx`

### Comportamiento
- Se activa al hacer click en "Eliminar" en cualquier fila
- Muestra overlay semitransparente (rgba 0,0,0,0.4)
- Dialog centrado con: nombre del contenido, botón Cancelar (ghost), botón Eliminar (rojo)
- Escape cancela el dialog
- Click en overlay cancela el dialog
- Foco inicial en botón "Cancelar" (previene borrado accidental con Enter)

### Estado en App.jsx
```js
const [confirmDelete, setConfirmDelete] = useState(null) // null | { id, nombre }
```

### Flujo
1. User hace click "Eliminar" → `setConfirmDelete({ id: row.id, nombre: row.nombre })`
2. Se renderiza `<ConfirmDialog />` con el nombre
3. User confirma → `handleDeleteRow(confirmDelete.id)` → `setConfirmDelete(null)`
4. User cancela → `setConfirmDelete(null)`

---

## QW 3 — useMemo para Filtrado/Ordenamiento

### Cambios en App.jsx
- Envolver la lógica actual de filtrado + sort en `useMemo`
- Dependencias: `[rows, filterText, sortDir]`
- Separar `filterInput` (estado del input) de `filterText` (valor debounced — ver QW4)
- El memo calcula sobre `filterText`, no sobre `filterInput`

```js
const filteredRows = useMemo(() => {
  let result = [...rows]
  if (filterText.trim()) {
    const q = filterText.toLowerCase()
    result = result.filter(r => r.nombre?.toLowerCase().includes(q))
  }
  result.sort((a, b) => {
    const da = a.semana || ''
    const db = b.semana || ''
    return sortDir === 'asc' ? da.localeCompare(db) : db.localeCompare(da)
  })
  return result
}, [rows, filterText, sortDir])
```

---

## QW 4 — useDebounce en Búsqueda

### Archivos nuevos
- `src/hooks/useDebounce.js`

### Comportamiento
- Delay: 300ms
- El input del header controla `filterInput` (estado inmediato para el value del input)
- `filterText = useDebounce(filterInput, 300)` se usa en el useMemo
- Sin cambios visibles en UX — el input responde instantáneo, el filtrado espera 300ms

### Interfaz
```js
// src/hooks/useDebounce.js
export function useDebounce(value, delay = 300) { ... }
```

---

## QW 5 — Indicador de Progreso por Fila

### Cambios en componentes
- `MediaTable.jsx`: agregar bloque de progreso bajo el nombre en la columna "Contenido"
- `MobileCardView.jsx`: agregar barra de progreso en la card header de cada contenido

### Función de cálculo (en App.jsx, exportada o en utils)
```js
export function getRowProgress(medios) {
  const filled = MEDIA_COLS.filter(col => {
    const { valor } = getCellData(medios, col.id)
    return valor && valor !== 'no'
  }).length
  return { filled, total: MEDIA_COLS.length, pct: Math.round((filled / MEDIA_COLS.length) * 100) }
}
```

### Visual
- Barra delgada (4px alto) debajo del texto del nombre, ancho 100% de la celda
- Color: verde (`#22c55e`) si pct ≥ 60%, amarillo (`#f59e0b`) si pct ≥ 30%, rojo (`#ef4444`) si < 30%
- Label: `"X/32 · Y%"` en texto muted 10px
- Sin tooltip (mantiene simplicidad)

---

## QW 6 — Empty States

### Cambios en componentes
- `MediaTable.jsx`: agregar fila de empty state en `<tbody>` cuando `filteredRows.length === 0`
- `MobileCardView.jsx`: agregar sección de empty state cuando no hay filas

### Dos contextos
| Contexto | Ícono | Título | Subtítulo | CTA |
|---|---|---|---|---|
| Sin contenidos (tabla vacía) | 📋 | "Sin contenidos aún" | "Agrega el primero para comenzar" | Botón dorado "+ Agregar contenido" → llama a `onAdd` |
| Filtro sin resultados | 🔍 | `Sin resultados para "X"` | "Prueba con otro término de búsqueda" | Botón ghost "Limpiar búsqueda" → llama a `onClearFilter` (= `() => setFilterInput('')` en App.jsx) |

### Detección
```js
// rows.length === 0 → sin contenidos
// rows.length > 0 && filteredRows.length === 0 → filtro sin match
```

---

## QW 7 — Keyboard Shortcuts

### Cambios en App.jsx
- Un `useEffect` con `document.addEventListener('keydown', handler)` que gestiona:

| Shortcut | Acción | Condición |
|---|---|---|
| `Escape` | Cierra modal activo (orden: confirmDelete → showModal → showLogs) | Algún modal abierto |
| `Ctrl+K` / `Cmd+K` | Focus en input de búsqueda | Siempre (previene default del browser) |
| `N` | Abre AddRowModal | Ningún input/textarea tiene foco, ningún modal abierto |

- Nota: `Ctrl+N` se descartó porque el OS lo intercepta para abrir nueva ventana del navegador.
- El handler verifica `document.activeElement.tagName` no sea INPUT/TEXTAREA/SELECT antes de actuar con `N`.
- El handler es estable con `useCallback` y las dependencias correctas.

### Hint visual (footer)
- Banda muy sutil al pie de la app (fuera del scroll de la tabla):
```
Esc cerrar  ·  Ctrl+K buscar  ·  N nuevo
```
- Fondo `#e8f0f8`, texto `#5a7a96`, font-size 11px
- Solo visible en desktop (oculto con `.mobile-only` / `@media`)

---

## Orden de implementación y commits

1. `useDebounce.js` + `useToast.js` (hooks base, sin dependencias)
2. `Toaster.jsx` + integración en App.jsx + reemplazar alert()
3. `ConfirmDialog.jsx` + estado `confirmDelete` en App.jsx
4. `useMemo` en App.jsx (filteredRows)
5. Progress bar en `MediaTable.jsx` + `MobileCardView.jsx`
6. Empty states en `MediaTable.jsx` + `MobileCardView.jsx`
7. Keyboard shortcuts useEffect en App.jsx + hint footer

Cada ítem = 1 commit atómico con mensaje descriptivo.

---

## Archivos que se modifican

| Archivo | Tipo de cambio |
|---|---|
| `src/App.jsx` | Agregar hooks, estado confirmDelete, useMemo, keyboard shortcuts |
| `src/components/MediaTable.jsx` | Progress bar + empty state |
| `src/components/MobileCardView.jsx` | Progress bar + empty state |
| `src/index.css` | Estilos: toast, confirm dialog, progress bar, empty state, footer hints |
| `src/hooks/useToast.js` | **NUEVO** |
| `src/hooks/useDebounce.js` | **NUEVO** |
| `src/components/Toaster.jsx` | **NUEVO** |
| `src/components/ConfirmDialog.jsx` | **NUEVO** |

## Archivos que NO se tocan

- `src/supabase.js`
- `src/config.js`
- `src/components/Header.jsx`
- `src/components/Login.jsx`
- `src/components/AuditLogPanel.jsx`
- `src/components/AddRowModal.jsx`
- `src/components/USSLoader.jsx`
- `vite.config.js`
- `package.json` (sin dependencias nuevas)
