import { ActivityBar } from './ActivityBar'
import { WorkspaceSidebar } from './WorkspaceSidebar'
import { TitleBar } from './TitleBar'
import { StatusBar } from './StatusBar'
import { ContextPanel } from './ContextPanel'
import { MonitoringWorkspace } from '@/components/monitoring/MonitoringWorkspace'
import { MonitorCreatePanel } from '@/components/monitoring/MonitorCreatePanel'
import { FilterBar } from '@/components/monitoring/FilterBar'
import { useMonitoringStore } from '@/store/monitoringStore'
import { useMonitoringBootstrap } from '@/hooks/useMonitoring'
export function AppShell() {
  const { section, showCreatePanel } = useMonitoringStore()
  const { loadMonitors } = useMonitoringBootstrap()

  return (
    <div className="glass-shell h-full flex flex-col">
      <TitleBar />
      <div className="flex-1 flex min-h-0">
        <ActivityBar />
        <WorkspaceSidebar />
        <div className="dt-divider-v w-px shrink-0" />
        <main className="glass-workspace flex-1 flex flex-col min-w-0 relative">
          {section === 'monitoring' && <FilterBar />}
          <MonitoringWorkspace />
          {showCreatePanel && <MonitorCreatePanel onCreated={() => void loadMonitors()} />}
        </main>
        <div className="dt-divider-v w-px shrink-0" />
        <ContextPanel />
      </div>
      <StatusBar />
    </div>
  )
}
