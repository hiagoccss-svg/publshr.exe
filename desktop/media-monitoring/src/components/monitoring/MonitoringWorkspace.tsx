import { ArticleFeed } from './ArticleFeed'
import { MonitorCreatePanel } from './MonitorCreatePanel'
import { PublicationsView } from './PublicationsView'
import { DashboardView } from './DashboardView'
import { CoverageView } from './CoverageView'
import { SettingsPanel } from '@/components/settings/SettingsPanel'
import { useMonitoringStore } from '@/store/monitoringStore'
import { useMonitoringBootstrap } from '@/hooks/useMonitoring'

export function MonitoringWorkspace() {
  const { section, showCreatePanel } = useMonitoringStore()
  const { loadMonitors } = useMonitoringBootstrap()

  return (
    <main className="flex-1 flex flex-col min-w-0 relative bg-surface-editor">
      {section === 'dashboard' && <DashboardView />}
      {section === 'monitoring' && <ArticleFeed />}
      {section === 'coverage' && <CoverageView />}
      {section === 'publications' && <PublicationsView />}
      {section === 'settings' && <SettingsPanel />}
      {![
        'dashboard',
        'monitoring',
        'coverage',
        'publications'
      ].includes(section) && <ComingSoon name={section} />}
      {showCreatePanel && <MonitorCreatePanel onCreated={() => void loadMonitors()} />}
    </main>
  )
}

function ComingSoon({ name }: { name: string }) {
  return (
    <div className="flex flex-col items-center justify-center h-full text-content-dim text-sm px-8 text-center">
      <p className="text-content capitalize">{name.replace(/-/g, ' ')}</p>
      <p className="text-xs mt-2 max-w-sm">Coming in Phase 2 — reports, alerts, and competitor charts.</p>
    </div>
  )
}
