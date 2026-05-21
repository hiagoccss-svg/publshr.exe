import {
  LayoutDashboard,
  Radio,
  Bookmark,
  Building2,
  Swords,
  FolderOpen,
  FileBarChart,
  Bell,
  Newspaper,
  UserRound,
  Briefcase,
  Download,
  Settings,
  ChevronLeft,
  ChevronRight,
  Pin
} from 'lucide-react'
import clsx from 'clsx'
import { useMonitoringStore } from '@/store/monitoringStore'
import { useActiveMonitor } from '@/hooks/useMonitoring'
import type { SidebarSection } from '@/types'

const NAV: { id: SidebarSection; label: string; icon: typeof Radio }[] = [
  { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { id: 'monitoring', label: 'Media Monitoring', icon: Radio },
  { id: 'saved-searches', label: 'Saved Searches', icon: Bookmark },
  { id: 'brands', label: 'Brands', icon: Building2 },
  { id: 'competitors', label: 'Competitors', icon: Swords },
  { id: 'coverage', label: 'Coverage', icon: FolderOpen },
  { id: 'reports', label: 'Reports', icon: FileBarChart },
  { id: 'alerts', label: 'Alerts', icon: Bell },
  { id: 'publications', label: 'Publications', icon: Newspaper },
  { id: 'journalists', label: 'Journalists', icon: UserRound },
  { id: 'clients', label: 'Clients', icon: Briefcase },
  { id: 'exports', label: 'Exports', icon: Download },
  { id: 'settings', label: 'Settings', icon: Settings }
]

export function Sidebar() {
  const { section, sidebarCollapsed, monitors, activeMonitorId, toggleSidebar, setSection, setShowCreatePanel } =
    useMonitoringStore()
  const { selectMonitor } = useActiveMonitor()
  const pinned = monitors.slice(0, 3)

  return (
    <aside
      className={clsx(
        'flex flex-col bg-surface-sidebar border-r border-border shrink-0 transition-all duration-200',
        sidebarCollapsed ? 'w-sidebar-collapsed' : 'w-sidebar'
      )}
    >
      <div className="flex items-center justify-between px-3 py-2 border-b border-border min-h-topbar">
        {!sidebarCollapsed && (
          <span className="text-xs font-semibold text-content-header tracking-wide uppercase">Workspace</span>
        )}
        <button type="button" onClick={toggleSidebar} className="btn-ghost p-1 ml-auto" aria-label="Toggle sidebar">
          {sidebarCollapsed ? <ChevronRight size={14} /> : <ChevronLeft size={14} />}
        </button>
      </div>

      <nav className="flex-1 overflow-y-auto py-2">
        {NAV.map(({ id, label, icon: Icon }) => (
          <button
            key={id}
            type="button"
            onClick={() => setSection(id)}
            className={clsx(
              'w-full flex items-center gap-2.5 px-3 py-1.5 text-sm transition-colors',
              section === id
                ? 'bg-surface-highlight text-content border-l-2 border-accent'
                : 'text-content-muted hover:text-content hover:bg-surface-highlight/50 border-l-2 border-transparent'
            )}
            title={sidebarCollapsed ? label : undefined}
          >
            <Icon size={15} className="shrink-0" />
            {!sidebarCollapsed && <span className="truncate">{label}</span>}
            {id === 'monitoring' && !sidebarCollapsed && monitors.some((m) => m.is_active) && (
              <span className="ml-auto w-1.5 h-1.5 rounded-full bg-sentiment-positive animate-pulse-soft" />
            )}
          </button>
        ))}

        {!sidebarCollapsed && pinned.length > 0 && (
          <div className="mt-4 px-3">
            <p className="text-2xs font-semibold text-content-header uppercase tracking-wide mb-2 flex items-center gap-1">
              <Pin size={10} /> Pinned monitors
            </p>
            {pinned.map((m) => (
              <button
                key={m.id}
                type="button"
                onClick={() => {
                  setSection('monitoring')
                  void selectMonitor?.(m.id)
                }}
                className={clsx(
                  'w-full text-left text-sm py-1 truncate rounded px-1',
                  activeMonitorId === m.id ? 'text-accent' : 'text-content-muted hover:text-content'
                )}
              >
                {m.name}
              </button>
            ))}
          </div>
        )}
      </nav>

      {!sidebarCollapsed && (
        <div className="p-3 border-t border-border">
          <button type="button" className="btn-primary w-full" onClick={() => setShowCreatePanel(true)}>
            Create monitor
          </button>
        </div>
      )}
    </aside>
  )
}
