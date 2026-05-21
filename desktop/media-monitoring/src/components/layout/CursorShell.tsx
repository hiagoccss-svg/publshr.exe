import { ActivityBar } from './ActivityBar'
import { ExplorerSidebar } from './ExplorerSidebar'
import { TitleBar } from './TitleBar'
import { StatusBar } from './StatusBar'
import { ContextPanel } from './ContextPanel'
import { MonitoringWorkspace } from '@/components/monitoring/MonitoringWorkspace'
import { MonitorCreatePanel } from '@/components/monitoring/MonitorCreatePanel'
import { FilterBar } from '@/components/monitoring/FilterBar'
import { useMonitoringStore } from '@/store/monitoringStore'
import { useMonitoringBootstrap } from '@/hooks/useMonitoring'
import { cursor } from '@/theme/cursor'

export function CursorShell() {
  const { section, showCreatePanel } = useMonitoringStore()
  const { loadMonitors } = useMonitoringBootstrap()

  return (
    <div className="h-full flex flex-col" style={{ backgroundColor: cursor.editor }}>
      <TitleBar />
      <div className="flex-1 flex min-h-0">
        <ActivityBar />
        <ExplorerSidebar />
        <div className="w-px shrink-0" style={{ backgroundColor: cursor.border }} />
        <main className="flex-1 flex flex-col min-w-0 relative">
          {section === 'monitoring' && <FilterBar />}
          <MonitoringWorkspace />
          {showCreatePanel && <MonitorCreatePanel onCreated={() => void loadMonitors()} />}
        </main>
        <div className="w-px shrink-0" style={{ backgroundColor: cursor.border }} />
        <ContextPanel />
      </div>
      <StatusBar />
    </div>
  )
}
