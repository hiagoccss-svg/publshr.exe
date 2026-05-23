import { useEffect, useState } from 'react'
import { useAuthStore } from '@/stores/authStore'
import { LoginPanel } from './LoginPanel'
import { TitleBar } from './TitleBar'
import { getCacheStats } from '@/lib/local-db'
import { checkForAppUpdate, type UpdateCheckResult } from '@/lib/updater'
import { invoke } from '@tauri-apps/api/core'
import type { DesktopPlatformInfo } from '@shared/desktop/types'

export function DesktopShell() {
  const { snapshot, loading, initialize } = useAuthStore()
  const [platform, setPlatform] = useState<DesktopPlatformInfo | null>(null)
  const [cache, setCache] = useState({ syncQueuePending: 0, kvEntries: 0 })
  const [updateInfo, setUpdateInfo] = useState<UpdateCheckResult | null>(null)

  useEffect(() => {
    void initialize()
    void invoke<DesktopPlatformInfo>('platform_get_info').then(setPlatform)
    void getCacheStats().then(setCache)
    void checkForAppUpdate().then(setUpdateInfo)
  }, [initialize])

  const signedIn = Boolean(snapshot?.user)

  return (
    <div className="glass-shell flex h-full flex-col bg-[var(--lib-shell-bg)]">
      <TitleBar />
      <div className="flex min-h-0 flex-1">
        <aside className="glass-sidebar flex flex-col border-r border-black/5 p-4">
          <p className="text-xs font-semibold uppercase tracking-wide text-[var(--lib-ink-muted)]">
            Workspace
          </p>
          <p className="mt-2 text-sm font-medium text-[var(--lib-ink)]">
            {signedIn ? snapshot?.user?.email : 'Not signed in'}
          </p>
          <nav className="mt-8 space-y-1 text-sm text-[var(--lib-ink-muted)]">
            <div className="rounded-lg bg-black/5 px-3 py-2 font-medium text-[var(--lib-ink)]">
              Home
            </div>
            <div className="px-3 py-2 opacity-60">Chat (coming soon)</div>
            <div className="px-3 py-2 opacity-60">Spaces (coming soon)</div>
            <div className="px-3 py-2 opacity-60">Planner (coming soon)</div>
          </nav>
          <div className="mt-auto space-y-2 text-xs text-[var(--lib-ink-muted)]">
            <p>Sync queue: {cache.syncQueuePending}</p>
            <p>Local KV: {cache.kvEntries}</p>
            {updateInfo ? <p>{updateInfo.message}</p> : null}
            {platform ? (
              <p className="truncate" title={platform.dataDir}>
                v{platform.appVersion} · {platform.os}
              </p>
            ) : null}
          </div>
        </aside>
        <main className="glass-workspace flex min-w-0 flex-1 flex-col p-8">
          {loading ? (
            <p className="text-sm text-[var(--lib-ink-muted)]">Restoring session…</p>
          ) : signedIn ? (
            <SignedInHome email={snapshot!.user!.email} workspaceId={snapshot?.workspaceId} />
          ) : (
            <LoginPanel />
          )}
        </main>
      </div>
    </div>
  )
}

function SignedInHome({
  email,
  workspaceId
}: {
  email: string
  workspaceId: string | null | undefined
}) {
  return (
    <div className="library-card max-w-xl">
      <h1 className="text-2xl font-semibold text-[var(--lib-ink)]">Publshr Enterprise</h1>
      <p className="mt-2 text-sm text-[var(--lib-ink-muted)]">
        Native desktop shell — session stored in OS keychain, data cached in SQLite.
      </p>
      <dl className="mt-6 space-y-2 text-sm">
        <div className="flex gap-2">
          <dt className="text-[var(--lib-ink-muted)]">Signed in</dt>
          <dd className="font-medium">{email}</dd>
        </div>
        <div className="flex gap-2">
          <dt className="text-[var(--lib-ink-muted)]">Workspace</dt>
          <dd>{workspaceId ?? 'Not selected'}</dd>
        </div>
      </dl>
      <p className="mt-6 text-xs text-[var(--lib-ink-muted)]">
        Modules (Chat, Spaces, Planner) migrate here from Electron. Install once; updates via
        Tauri updater + GitHub Releases.
      </p>
    </div>
  )
}
