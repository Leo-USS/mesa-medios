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
