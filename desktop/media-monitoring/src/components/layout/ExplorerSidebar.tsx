import { Plus, Pin } from 'lucide-react'
import { useMonitoringStore } from '@/store/monitoringStore'
import { MonitorList } from '@/components/monitoring/MonitorList'
import { cursor } from '@/theme/cursor'

const SECTION_TITLES: Record<string, string> = {
  dashboard: 'Dashboard',
  monitoring: 'Monitoring',
  coverage: 'Saved coverage',
  'saved-searches': 'Saved searches',
  publications: 'Publications',
  settings: 'Settings'
}

export function ExplorerSidebar() {
  const { section, monitors, setShowCreatePanel } = useMonitoringStore()

  return (
    <aside
      className="flex flex-col shrink-0 border-r overflow-hidden min-h-0"
      style={{
        width: cursor.sideBarWidth,
        backgroundColor: cursor.sideBar,
        borderColor: cursor.border
      }}
    >
      <div className="cursor-panel-header" style={{ color: cursor.header, borderColor: cursor.border }}>
        {SECTION_TITLES[section] ?? 'Explorer'}
      </div>

      {section === 'monitoring' && (
        <>
          <div className="p-2 border-b shrink-0" style={{ borderColor: cursor.border }}>
            <button
              type="button"
              className="w-full flex items-center justify-center gap-1 text-[12px] py-1.5 rounded-sm text-white"
              style={{ backgroundColor: cursor.button }}
              onClick={() => setShowCreatePanel(true)}
            >
              <Plus size={13} /> New monitor
            </button>
          </div>
          <MonitorList />
          {monitors.length > 0 && (
            <div className="px-3 py-2 border-t shrink-0" style={{ borderColor: cursor.border }}>
              <p className="cursor-section-header flex items-center gap-1">
                <Pin size={9} /> Pinned
              </p>
            </div>
          )}
        </>
      )}

      {section === 'coverage' && (
        <p className="px-3 py-2 text-[11px] text-content-muted leading-relaxed">Articles you saved for reports and clients.</p>
      )}
      {section === 'publications' && (
        <p className="px-3 py-2 text-[11px] text-content-muted leading-relaxed">Approved publication sources for monitoring.</p>
      )}
      {section === 'dashboard' && (
        <p className="px-3 py-2 text-[11px] text-content-muted leading-relaxed">Workspace overview and live monitor status.</p>
      )}
    </aside>
  )
}
