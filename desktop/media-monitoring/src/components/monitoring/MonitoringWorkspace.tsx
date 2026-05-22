import { ArticleFeed } from './ArticleFeed'
import { PublicationsView } from './PublicationsView'
import { DashboardView } from './DashboardView'
import { CoverageView } from './CoverageView'
import { SettingsPanel } from '@/components/settings/SettingsPanel'
import { useMonitoringStore } from '@/store/monitoringStore'

export function MonitoringWorkspace() {
  const { section } = useMonitoringStore()

  return (
    <div className="flex-1 flex flex-col min-h-0 min-w-0">
      {section === 'dashboard' && <DashboardView />}
      {section === 'monitoring' && <ArticleFeed />}
      {section === 'coverage' && <CoverageView />}
      {section === 'publications' && <PublicationsView />}
      {section === 'settings' && <SettingsPanel />}
      {![
        'dashboard',
        'monitoring',
        'coverage',
        'publications',
        'settings'
      ].includes(section) && <ComingSoon name={section} />}
    </div>
  )
}

function ComingSoon({ name }: { name: string }) {
  return (
    <div className="flex flex-col items-center justify-center h-full text-content-dim text-[12px] px-8 text-center">
      <p className="text-content capitalize">{name.replace(/-/g, ' ')}</p>
      <p className="text-[11px] mt-2 max-w-sm">Coming in Phase 2 — reports, alerts, and competitor charts.</p>
    </div>
  )
}
