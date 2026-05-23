import { useEffect } from 'react'
import { useSpacesStore } from '@spaces/stores/spaces-store'
import { MainShell } from '@spaces/components/layout/MainShell'
import { initSpacesPlatform } from '@spaces/lib/api'
import { DocumentWindow } from '@spaces/components/windows/DocumentWindow'

function useRoute(): 'main' | 'document' {
  const hash = window.location.hash.replace(/^#\/?/, '')
  if (hash.startsWith('document/')) return 'document'
  return 'main'
}

/** Full enterprise workspace — 3-column shell with operational modules. */
export function EnterpriseWorkspace(): React.ReactElement {
  const route = useRoute()
  const loadBootstrap = useSpacesStore((s) => s.loadBootstrap)
  const refreshActiveSpace = useSpacesStore((s) => s.refreshActiveSpace)
  const loadWorkspaceData = useSpacesStore((s) => s.loadWorkspaceData)
  const ready = useSpacesStore((s) => s.ready)

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

  return <MainShell />
}
