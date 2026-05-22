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
import { shell } from '@/theme/shellTheme'

export function AppShell() {
  const { section, showCreatePanel } = useMonitoringStore()
  const { loadMonitors } = useMonitoringBootstrap()

  return (
    <div className="h-full flex flex-col" style={{ backgroundColor: shell.workspace }}>
      <TitleBar />
      <div className="flex-1 flex min-h-0">
        <ActivityBar />
        <WorkspaceSidebar />
        <div className="w-px shrink-0" style={{ backgroundColor: shell.border }} />
        <main className="flex-1 flex flex-col min-w-0 relative">
          {section === 'monitoring' && <FilterBar />}
          <MonitoringWorkspace />
          {showCreatePanel && <MonitorCreatePanel onCreated={() => void loadMonitors()} />}
        </main>
        <div className="w-px shrink-0" style={{ backgroundColor: shell.border }} />
        <ContextPanel />
      </div>
      <StatusBar />
    </div>
  )
}
