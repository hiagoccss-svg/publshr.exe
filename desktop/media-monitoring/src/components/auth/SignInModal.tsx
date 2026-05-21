import { useState } from 'react'
import { X, Cloud, Loader2 } from 'lucide-react'
import { useMonitoringStore } from '@/store/monitoringStore'

interface Props {
  open: boolean
  onClose: () => void
}

export function SignInModal({ open, onClose }: Props) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const { setAuthInfo, setSyncStatus } = useMonitoringStore()

  if (!open) return null

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setError(null)
    try {
      const state = await window.publshr.signIn(email.trim(), password)
      setAuthInfo(state.email ?? null, state.workspaceName ?? null)
      setSyncStatus('synced')
      onClose()
      window.location.reload()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Sign in failed')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <form
        onSubmit={handleSubmit}
        className="w-full max-w-sm bg-surface-sidebar border border-border rounded-lg p-6 space-y-4 shadow-xl"
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Cloud size={18} className="text-accent" />
            <h2 className="text-sm font-medium text-content">Connect cloud sync</h2>
          </div>
          <button type="button" className="btn-ghost p-1" onClick={onClose} aria-label="Close">
            <X size={16} />
          </button>
        </div>
        <p className="text-xs text-content-dim">
          Sign in to sync monitors and coverage with your team via Supabase. Local monitoring works without signing in.
        </p>
        <label className="block">
          <span className="text-xs text-content-muted">Email</span>
          <input
            type="email"
            className="input-field mt-1"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
        </label>
        <label className="block">
          <span className="text-xs text-content-muted">Password</span>
          <input
            type="password"
            className="input-field mt-1"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
        </label>
        {error && <p className="text-xs text-sentiment-negative">{error}</p>}
        <button type="submit" className="btn-primary w-full flex items-center justify-center gap-2" disabled={submitting}>
          {submitting && <Loader2 size={14} className="animate-spin" />}
          {submitting ? 'Connecting…' : 'Sign in & sync'}
        </button>
      </form>
    </div>
  )
}
