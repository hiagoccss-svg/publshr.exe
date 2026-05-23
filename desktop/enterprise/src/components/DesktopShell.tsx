import { useEffect } from 'react'
import { useAuthStore } from '@/stores/authStore'
import { LoginPanel } from './LoginPanel'
import { EnterpriseWorkspace } from './EnterpriseWorkspace'

export function DesktopShell() {
  const { snapshot, loading, initialize } = useAuthStore()
  const workspaceUnlocked = Boolean(snapshot?.user)

  useEffect(() => {
    void initialize()
  }, [initialize])

  return (
    <div className="glass-shell flex h-full flex-col bg-[var(--lib-shell-bg)]">
      {loading ? (
        <main className="flex min-h-0 flex-1 items-center justify-center p-8">
          <p className="text-sm text-[var(--lib-ink-muted)]">Restoring session…</p>
        </main>
      ) : workspaceUnlocked ? (
        <EnterpriseWorkspace />
      ) : (
        <main className="flex min-h-0 flex-1 items-center p-8">
          <LoginPanel />
        </main>
      )}
    </div>
  )
}
