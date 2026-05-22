import { Plus, Pin } from 'lucide-react'
import { useMonitoringStore } from '@/store/monitoringStore'
import { MonitorList } from '@/components/monitoring/MonitorList'
import { shell } from '@/theme/shellTheme'

const SECTION_TITLES: Record<string, string> = {
  dashboard: 'Dashboard',
  monitoring: 'Monitoring',
  coverage: 'Saved coverage',
  'saved-searches': 'Saved searches',
  publications: 'Publications',
  settings: 'Settings'
}

export function WorkspaceSidebar() {
  const { section, monitors, setShowCreatePanel } = useMonitoringStore()

  return (
    <aside
      className="flex flex-col shrink-0 border-r overflow-hidden"
      style={{
        width: shell.sideBarWidth,
        backgroundColor: shell.sideBar,
        borderColor: shell.border
      }}
    >
      <div
        className="px-3 py-2 text-[11px] font-semibold uppercase tracking-wide border-b"
        style={{ color: shell.header, borderColor: shell.border }}
      >
        {SECTION_TITLES[section] ?? 'Workspace'}
      </div>

      {section === 'monitoring' && (
        <>
          <div className="p-2 border-b" style={{ borderColor: shell.border }}>
            <button
              type="button"
              className="w-full flex items-center justify-center gap-1 text-[12px] py-1.5 rounded text-white"
              style={{ backgroundColor: shell.button }}
              onClick={() => setShowCreatePanel(true)}
            >
              <Plus size={13} /> New monitor
            </button>
          </div>
          <MonitorList />
          {monitors.length > 0 && (
            <div className="px-3 py-2 border-t" style={{ borderColor: shell.border }}>
              <p
                className="text-[10px] uppercase tracking-wide flex items-center gap-1"
                style={{ color: shell.header }}
              >
                <Pin size={9} /> Pinned
              </p>
            </div>
          )}
        </>
      )}

      {section === 'coverage' && (
        <p className="px-3 py-2 text-[12px] text-content-muted">
          Articles you saved for reports and clients.
        </p>
      )}
      {section === 'publications' && (
        <p className="px-3 py-2 text-[12px] text-content-muted">
          Approved publication sources for monitoring.
        </p>
      )}
      {section === 'dashboard' && (
        <p className="px-3 py-2 text-[12px] text-content-muted">
          Workspace overview and live monitor status.
        </p>
      )}
    </aside>
  )
}
