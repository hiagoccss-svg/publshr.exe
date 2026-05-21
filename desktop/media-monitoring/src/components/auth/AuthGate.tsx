import { useEffect, useState } from 'react'
import { Radio, Loader2 } from 'lucide-react'

interface AuthState {
  email: string | null
  workspaceName: string | null
}

export function AuthGate({ children }: { children: React.ReactNode }) {
  const [loading, setLoading] = useState(true)
  const [authed, setAuthed] = useState(false)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [authInfo, setAuthInfo] = useState<AuthState | null>(null)

  useEffect(() => {
    window.publshr
      .restoreSession()
      .then((state: { session?: unknown; email?: string; workspaceName?: string }) => {
        setAuthed(Boolean(state.session))
        setAuthInfo({ email: state.email ?? null, workspaceName: state.workspaceName ?? null })
      })
      .finally(() => setLoading(false))

    const unsub = window.publshr.onSyncStatus((payload: unknown) => {
      const p = payload as { auth?: AuthState & { session?: unknown } }
      if (p.auth) {
        setAuthed(Boolean(p.auth.session))
        setAuthInfo({
          email: p.auth.email ?? null,
          workspaceName: p.auth.workspaceName ?? null
        })
      }
    })
    return () => unsub()
  }, [])

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setError(null)
    try {
      const state = await window.publshr.signIn(email.trim(), password)
      setAuthed(Boolean(state.session))
      setAuthInfo({ email: state.email ?? null, workspaceName: state.workspaceName ?? null })
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Sign in failed')
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return (
      <div className="h-full flex items-center justify-center bg-surface-editor text-content-muted gap-2">
        <Loader2 size={18} className="animate-spin" />
        <span className="text-sm">Connecting…</span>
      </div>
    )
  }

  if (!authed) {
    return (
      <div className="h-full flex items-center justify-center bg-surface-editor px-6">
        <form
          onSubmit={handleSignIn}
          className="w-full max-w-sm bg-surface-sidebar border border-border rounded-lg p-6 space-y-4"
        >
          <div className="flex items-center gap-2 mb-2">
            <Radio size={20} className="text-accent" />
            <h1 className="text-base font-medium text-content">Media Monitoring</h1>
          </div>
          <p className="text-xs text-content-dim">
            Sign in with your Publshr account to sync coverage with Supabase.
          </p>
          <label className="block">
            <span className="text-xs text-content-muted">Email</span>
            <input
              type="email"
              className="input-field mt-1"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoComplete="email"
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
              autoComplete="current-password"
            />
          </label>
          {error && <p className="text-xs text-sentiment-negative">{error}</p>}
          <button type="submit" className="btn-primary w-full" disabled={submitting}>
            {submitting ? 'Signing in…' : 'Sign in'}
          </button>
        </form>
      </div>
    )
  }

  return (
    <>
      {authInfo?.workspaceName && (
        <span className="sr-only">Workspace: {authInfo.workspaceName}</span>
      )}
      {children}
    </>
  )
}
