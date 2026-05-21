import { useEffect, useState } from 'react'
import { HashRouter, Routes, Route } from 'react-router-dom'
import { TopBar } from '@/components/layout/TopBar'
import { Sidebar } from '@/components/layout/Sidebar'
import { ContextPanel } from '@/components/layout/ContextPanel'
import { SyncBanner } from '@/components/layout/SyncBanner'
import { MonitoringWorkspace } from '@/components/monitoring/MonitoringWorkspace'
import { ArticleDetailView } from '@/views/ArticleDetailView'
import { SignInModal } from '@/components/auth/SignInModal'
import { useMonitoringStore } from '@/store/monitoringStore'

function MainShell() {
  const [signInOpen, setSignInOpen] = useState(false)
  const { setAuthInfo, setSyncStatus } = useMonitoringStore()

  useEffect(() => {
    window.publshr.restoreSession().then((state: { email?: string; workspaceName?: string; session?: unknown }) => {
      setAuthInfo(state.email ?? null, state.workspaceName ?? null)
      setSyncStatus(state.session ? 'synced' : 'offline')
    })
    return window.publshr.onSyncStatus((payload: unknown) => {
      const p = payload as {
        status?: string
        auth?: { email?: string; workspaceName?: string; session?: unknown }
      }
      if (p.status) setSyncStatus(p.status as 'synced' | 'syncing' | 'offline' | 'error')
      if (p.auth) {
        setAuthInfo(p.auth.email ?? null, p.auth.workspaceName ?? null)
      }
    })
  }, [setAuthInfo, setSyncStatus])

  return (
    <div className="h-full flex flex-col">
      <TopBar onSignIn={() => setSignInOpen(true)} />
      <SyncBanner onSignIn={() => setSignInOpen(true)} />
      <div className="flex-1 flex min-h-0">
        <Sidebar />
        <MonitoringWorkspace />
        <ContextPanel />
      </div>
      <SignInModal open={signInOpen} onClose={() => setSignInOpen(false)} />
    </div>
  )
}

export default function App() {
  return (
    <HashRouter>
      <Routes>
        <Route path="/" element={<MainShell />} />
        <Route path="/article/:id" element={<ArticleDetailView />} />
      </Routes>
    </HashRouter>
  )
}
