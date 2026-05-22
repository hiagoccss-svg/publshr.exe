import { useEffect } from 'react'
import { useSpacesStore } from './stores/spaces-store'
import { MainShell } from './components/layout/MainShell'
import { DocumentWindow } from './components/windows/DocumentWindow'

function useRoute(): 'main' | 'document' | 'space' {
  const hash = window.location.hash.replace(/^#\/?/, '')
  if (hash.startsWith('document/')) return 'document'
  if (hash.startsWith('space/')) return 'space'
  return 'main'
}

export default function App(): React.ReactElement {
  const route = useRoute()
  const loadBootstrap = useSpacesStore((s) => s.loadBootstrap)
  const refreshActiveSpace = useSpacesStore((s) => s.refreshActiveSpace)
  const ready = useSpacesStore((s) => s.ready)

  useEffect(() => {
    void loadBootstrap()
    const onRefresh = (): void => {
      void refreshActiveSpace()
    }
    window.addEventListener('spaces:refresh', onRefresh)
    return () => window.removeEventListener('spaces:refresh', onRefresh)
  }, [loadBootstrap, refreshActiveSpace])

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
      <div className="flex h-full items-center justify-center bg-surface">
        <p className="text-sm text-ink-muted">Loading Spaces…</p>
      </div>
    )
  }

  if (route === 'document') {
    const id = window.location.hash.replace(/^#\/?document\//, '')
    return <DocumentWindow documentId={id} />
  }

  return <MainShell />
}
