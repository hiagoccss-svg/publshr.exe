import {
  LayoutDashboard,
  Radio,
  FolderOpen,
  Newspaper,
  Bookmark,
  Settings
} from 'lucide-react'
import { useMonitoringStore } from '@/store/monitoringStore'
import type { SidebarSection } from '@/types'
import { shell } from '@/theme/shellTheme'

const ITEMS: { id: SidebarSection; icon: typeof Radio; label: string }[] = [
  { id: 'dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { id: 'monitoring', icon: Radio, label: 'Monitoring' },
  { id: 'coverage', icon: FolderOpen, label: 'Coverage' },
  { id: 'saved-searches', icon: Bookmark, label: 'Saved' },
  { id: 'publications', icon: Newspaper, label: 'Publications' }
]

export function ActivityBar() {
  const { section, setSection } = useMonitoringStore()

  return (
    <div
      className="dt-chrome flex flex-col items-center py-1 shrink-0 dt-divider-v relative"
      style={{ width: shell.activityBarWidth }}
    >
      {ITEMS.map(({ id, icon: Icon, label }) => (
        <button
          key={id}
          type="button"
          title={label}
          onClick={() => setSection(id)}
          className="flex items-center justify-center w-12 h-12 transition-colors"
          style={{
            color: section === id ? shell.foreground : shell.foregroundDim,
            backgroundColor: section === id ? `${shell.sideBar}80` : 'transparent'
          }}
        >
          <Icon size={20} strokeWidth={1.5} />
        </button>
      ))}
      <div className="flex-1" />
      <button
        type="button"
        title="Settings"
        onClick={() => setSection('settings')}
        className="w-12 h-12 flex items-center justify-center"
        style={{ color: section === 'settings' ? shell.foreground : shell.foregroundDim }}
      >
        <Settings size={18} />
      </button>
    </div>
  )
}
