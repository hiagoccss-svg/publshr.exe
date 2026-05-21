import { MonitorList } from './MonitorList'
import { ArticleFeed } from './ArticleFeed'
import { MonitorCreatePanel } from './MonitorCreatePanel'
import { PublicationsView } from './PublicationsView'
import { useMonitoringStore } from '@/store/monitoringStore'
import { useMonitoringBootstrap } from '@/hooks/useMonitoring'

export function MonitoringWorkspace() {
  const { section, showCreatePanel } = useMonitoringStore()
  const { loadMonitors } = useMonitoringBootstrap()

  return (
    <main className="flex-1 flex flex-col min-w-0 relative bg-surface-editor">
      {section === 'monitoring' && (
        <>
          <MonitorList />
          <ArticleFeed />
        </>
      )}
      {section === 'publications' && <PublicationsView />}
      {section !== 'monitoring' && section !== 'publications' && <PlaceholderSection name={section} />}
      {showCreatePanel && <MonitorCreatePanel onCreated={() => void loadMonitors()} />}
    </main>
  )
}

function PlaceholderSection({ name }: { name: string }) {
  const label = name.replace(/-/g, ' ')
  return (
    <div className="flex flex-col items-center justify-center h-full text-content-dim text-sm px-8 text-center">
      <p className="text-content capitalize">{label}</p>
      <p className="text-xs mt-2 max-w-sm">This section is scaffolded for Phase 2+ integration with reports, alerts, and competitor tracking.</p>
    </div>
  )
}
