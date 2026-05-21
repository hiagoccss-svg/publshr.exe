import { TopBar } from '@/components/layout/TopBar'
import { Sidebar } from '@/components/layout/Sidebar'
import { ContextPanel } from '@/components/layout/ContextPanel'
import { MonitoringWorkspace } from '@/components/monitoring/MonitoringWorkspace'

export default function App() {
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
