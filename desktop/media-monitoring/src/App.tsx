import { HashRouter, Routes, Route } from 'react-router-dom'
import { AuthGate } from '@/components/auth/AuthGate'
import { TopBar } from '@/components/layout/TopBar'
import { Sidebar } from '@/components/layout/Sidebar'
import { ContextPanel } from '@/components/layout/ContextPanel'
import { MonitoringWorkspace } from '@/components/monitoring/MonitoringWorkspace'
import { ArticleDetailView } from '@/views/ArticleDetailView'

function MainShell() {
  return (
    <div className="h-full flex flex-col">
      <TopBar />
      <div className="flex-1 flex min-h-0">
        <Sidebar />
        <MonitoringWorkspace />
        <ContextPanel />
      </div>
    </div>
  )
}

export default function App() {
  return (
    <AuthGate>
      <HashRouter>
        <Routes>
          <Route path="/" element={<MainShell />} />
          <Route path="/article/:id" element={<ArticleDetailView />} />
        </Routes>
      </HashRouter>
    </AuthGate>
  )
}
