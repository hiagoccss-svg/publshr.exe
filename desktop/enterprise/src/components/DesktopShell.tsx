import { useEffect } from 'react'
import { useAuthStore } from '@/stores/authStore'
import { LoginPanel } from './LoginPanel'
import { TitleBar } from './TitleBar'
import { EnterpriseWorkspace } from './EnterpriseWorkspace'
export function DesktopShell() {
  const { snapshot, loading, initialize } = useAuthStore()
  const signedIn = Boolean(snapshot?.user)

  useEffect(() => {
    void initialize()
  }, [initialize])

  return (
    <div className="glass-shell flex h-full flex-col bg-[var(--lib-shell-bg)]">
      <TitleBar />
      <div className="flex min-h-0 flex-1">
        {loading ? (
          <main className="glass-workspace flex min-w-0 flex-1 items-center justify-center p-8">
            <p className="text-sm text-[var(--lib-ink-muted)]">Restoring session…</p>
          </main>
        ) : signedIn ? (
          <EnterpriseWorkspace />
        ) : (
          <main className="glass-workspace flex min-w-0 flex-1 flex-col p-8">
            <LoginPanel />
          </main>
        )}
      </div>
    </div>
  )
}
