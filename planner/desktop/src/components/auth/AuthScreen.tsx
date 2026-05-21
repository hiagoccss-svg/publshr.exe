import { useState } from 'react'
import { useAuthStore } from '@/stores/authStore'

export default function AuthScreen() {
  const { signIn, signUp, error, loading } = useAuthStore()
  const [mode, setMode] = useState<'signin' | 'signup'>('signin')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [name, setName] = useState('')

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (mode === 'signin') await signIn(email, password)
    else await signUp(email, password, name)
  }

  return (
    <div className="flex h-screen bg-surface">
      <div className="drag-region hidden w-16 shrink-0 md:block" />
      <div className="flex flex-1 items-center justify-center px-6">
        <div className="w-full max-w-sm">
          <p className="text-xs font-medium uppercase tracking-widest text-ink-muted">Publshr</p>
          <h1 className="mt-2 font-display text-3xl font-semibold tracking-tight text-ink">
            Planner
          </h1>
          <p className="mt-2 text-sm text-ink-secondary">
            Communications planning for PR, media, and editorial teams.
          </p>

          <form onSubmit={submit} className="no-drag mt-8 space-y-4">
            {mode === 'signup' && (
              <div>
                <label className="text-xs font-medium text-ink-secondary">Name</label>
                <input
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="mt-1 w-full rounded-lg border border-surface-border bg-surface-raised px-3 py-2 text-sm outline-none ring-accent/20 focus:ring-2"
                  placeholder="Your name"
                />
              </div>
            )}
            <div>
              <label className="text-xs font-medium text-ink-secondary">Email</label>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="mt-1 w-full rounded-lg border border-surface-border bg-surface-raised px-3 py-2 text-sm outline-none ring-accent/20 focus:ring-2"
                placeholder="you@company.com"
              />
            </div>
            <div>
              <label className="text-xs font-medium text-ink-secondary">Password</label>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="mt-1 w-full rounded-lg border border-surface-border bg-surface-raised px-3 py-2 text-sm outline-none ring-accent/20 focus:ring-2"
                placeholder="••••••••"
              />
            </div>
            {error && <p className="text-xs text-status-overdue">{error}</p>}
            <button
              type="submit"
              disabled={loading}
              className="w-full rounded-lg bg-ink py-2.5 text-sm font-medium text-white transition hover:bg-ink/90 disabled:opacity-50"
            >
              {loading ? 'Please wait…' : mode === 'signin' ? 'Sign in' : 'Create account'}
            </button>
          </form>

          <button
            type="button"
            onClick={() => setMode(mode === 'signin' ? 'signup' : 'signin')}
            className="no-drag mt-4 w-full text-center text-xs text-ink-muted hover:text-ink"
          >
            {mode === 'signin' ? 'Need an account? Sign up' : 'Already have an account? Sign in'}
          </button>
        </div>
      </div>
    </div>
  )
}
