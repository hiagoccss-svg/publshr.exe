import { useEffect } from 'react'
import { useSpacesStore } from '@spaces/stores/spaces-store'
import { MainShell } from '@spaces/components/layout/MainShell'
import { initSpacesPlatform } from '@spaces/lib/api'
import { DocumentWindow } from '@spaces/components/windows/DocumentWindow'
import { useAuthStore } from '@/stores/authStore'

function useRoute(): 'main' | 'document' {
  const hash = window.location.hash.replace(/^#\/?/, '')
  if (hash.startsWith('document/')) return 'document'
  return 'main'
}

/** Full enterprise workspace — 3-column shell with operational modules. */
export function EnterpriseWorkspace(): React.ReactElement {
  const route = useRoute()
  const signOut = useAuthStore((s) => s.signOut)
  const loadBootstrap = useSpacesStore((s) => s.loadBootstrap)
  const refreshActiveSpace = useSpacesStore((s) => s.refreshActiveSpace)
  const loadWorkspaceData = useSpacesStore((s) => s.loadWorkspaceData)
  const ready = useSpacesStore((s) => s.ready)
  const bootstrapError = useSpacesStore((s) => s.bootstrapError)

  useEffect(() => {
    initSpacesPlatform()
    void loadBootstrap()
    const onRefresh = (): void => {
      void refreshActiveSpace()
      void loadWorkspaceData()
    }
    window.addEventListener('spaces:refresh', onRefresh)
    return () => window.removeEventListener('spaces:refresh', onRefresh)
  }, [loadBootstrap, refreshActiveSpace, loadWorkspaceData])

  useEffect(() => {
    const onKey = (e: KeyboardEvent): void => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault()
        useSpacesStore.getState().setCommandOpen(true)
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  if (bootstrapError && route === 'main') {
    return (
      <div className="flex h-full flex-1 flex-col items-center justify-center gap-4 p-8">
        <p className="max-w-md text-center text-sm text-red-600">{bootstrapError}</p>
        <button
          type="button"
          className="rounded-lg bg-[var(--lib-cta)] px-4 py-2 text-sm font-medium text-white"
          onClick={() => void loadBootstrap()}
        >
          Retry
        </button>
      </div>
    )
  }

  if (!ready && route === 'main') {
    return (
      <div className="flex h-full flex-1 items-center justify-center">
        <p className="text-sm text-[var(--lib-ink-muted)]">Loading workspace…</p>
      </div>
    )
  }

  if (route === 'document') {
    const id = window.location.hash.replace(/^#\/?document\//, '')
    return <DocumentWindow documentId={id} />
  }

  return (
    <MainShell
      embedded
      onSignOut={() => {
        void signOut()
      }}
    />
  )
}
