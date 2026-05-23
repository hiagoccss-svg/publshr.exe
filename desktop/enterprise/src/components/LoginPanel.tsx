import { FormEvent, useState } from 'react'
import { useAuthStore } from '@/stores/authStore'

export function LoginPanel() {
  const { signIn, error, loading, cloudConfigured } = useAuthStore()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    await signIn(email.trim(), password)
  }

  if (!cloudConfigured) {
    return (
      <div className="library-card max-w-md">
        <h2 className="text-lg font-semibold">Supabase not configured</h2>
        <p className="mt-2 text-sm text-[var(--lib-ink-muted)]">
          Copy <code className="text-xs">.env.example</code> to <code className="text-xs">.env</code>{' '}
          and set <code className="text-xs">VITE_SUPABASE_URL</code> and{' '}
          <code className="text-xs">VITE_SUPABASE_ANON_KEY</code>.
        </p>
      </div>
    )
  }

  return (
    <div className="library-card max-w-md">
      <h2 className="text-lg font-semibold text-[var(--lib-ink)]">Sign in</h2>
      <p className="mt-1 text-sm text-[var(--lib-ink-muted)]">
        Credentials are stored in the system keychain — not in browser storage.
      </p>
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
          {loading ? 'Signing in…' : 'Continue'}
        </button>
      </form>
    </div>
  )
}
