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
        const ejeColor  = EJE_COLOR_MAP[row.eje]   || '#64748b'
        const tipoCfg   = TIPOS_CONFIG[row.tipo]    || {}
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
