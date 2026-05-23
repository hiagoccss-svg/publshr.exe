import { FormEvent, useState } from 'react'
import { useAuthStore } from '@/stores/authStore'

export function LoginPanel() {
  const { signIn, continueOffline, error, loading, cloudConfigured } = useAuthStore()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    await signIn(email.trim(), password)
  }

  return (
    <div className="library-card mx-auto max-w-md">
      <h2 className="text-lg font-semibold text-[var(--lib-ink)]">Publshr Enterprise</h2>
      <p className="mt-1 text-sm text-[var(--lib-ink-muted)]">
        Sign in for cloud sync, or continue with the full local workspace (SQLite).
      </p>

      {cloudConfigured ? (
        <form className="mt-6 space-y-4" onSubmit={onSubmit}>
          <label className="block text-sm">
            <span className="text-[var(--lib-ink-muted)]">Email</span>
            <input
              type="email"
              autoComplete="username"
              className="mt-1 w-full rounded-lg border border-black/10 bg-white/80 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-black/10"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </label>
          <label className="block text-sm">
            <span className="text-[var(--lib-ink-muted)]">Password</span>
            <input
              type="password"
              autoComplete="current-password"
              className="mt-1 w-full rounded-lg border border-black/10 bg-white/80 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-black/10"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </label>
          {error ? <p className="text-sm text-red-600">{error}</p> : null}
          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-lg bg-[var(--lib-cta)] px-4 py-2 text-sm font-medium text-white disabled:opacity-50"
          >
            {loading ? 'Signing in…' : 'Sign in with cloud'}
          </button>
        </form>
      ) : (
        <p className="mt-4 text-sm text-[var(--lib-ink-muted)]">
          Supabase is optional. Add <code className="text-xs">.env</code> for cloud auth, or use the local
          workspace below.
        </p>
      )}

      <div className="mt-6 border-t border-black/10 pt-6">
        <button
          type="button"
          disabled={loading}
          onClick={continueOffline}
          className="w-full rounded-lg border border-black/10 bg-white/60 px-4 py-2 text-sm font-medium text-[var(--lib-ink)] hover:bg-white/90 disabled:opacity-50"
        >
          Continue with local workspace
        </button>
        <p className="mt-2 text-center text-xs text-[var(--lib-ink-muted)]">
          Dashboard, Spaces, Chat, Documents, Whiteboard, Files, and Reports run offline.
        </p>
      </div>
    </div>
  )
}
