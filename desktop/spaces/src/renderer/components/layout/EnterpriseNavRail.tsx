import {
  Archive,
  BarChart3,
  Briefcase,
  Calendar,
  CheckCircle2,
  FileText,
  FolderKanban,
  LayoutDashboard,
  Megaphone,
  MessageSquare,
  PenLine,
  Radio,
  Users
} from 'lucide-react'
import clsx from 'clsx'
import { useSpacesStore } from '../../stores/spaces-store'
import type { SidebarSection } from '../../../shared/types'

type NavId = SidebarSection | 'whiteboard'

const NAV: { id: NavId; label: string; icon: React.ComponentType<{ className?: string }> }[] = [
  { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { id: 'spaces', label: 'Spaces', icon: FolderKanban },
  { id: 'planner', label: 'Planner', icon: Calendar },
  { id: 'chat', label: 'Chat', icon: MessageSquare },
  { id: 'documents', label: 'Documents', icon: FileText },
  { id: 'whiteboard', label: 'Whiteboard', icon: PenLine },
  { id: 'approvals', label: 'Approvals', icon: CheckCircle2 },
  { id: 'reports', label: 'Reports', icon: BarChart3 },
  { id: 'clients', label: 'Clients', icon: Briefcase },
  { id: 'campaigns', label: 'Campaigns', icon: Megaphone },
  { id: 'team', label: 'Team', icon: Users },
  { id: 'media', label: 'Media Monitoring', icon: Radio },
  { id: 'files', label: 'Files', icon: Archive }
]

/** Column 1 — primary enterprise navigation (ClickUp-style bar menu). */
export function EnterpriseNavRail(): React.ReactElement {
  const activeSection = useSpacesStore((s) => s.activeSection)
  const taskView = useSpacesStore((s) => s.taskView)
  const selectNav = useSpacesStore((s) => s.selectEnterpriseNav)

  return (
    <aside className="glass-sidebar flex w-[var(--lib-bar-menu-width,200px)] min-h-0 shrink-0 flex-col border-r border-black/5">
      <div className="px-3 pt-4 pb-2">
        <p className="text-[10px] font-semibold uppercase tracking-wide text-ink-muted">Workspace</p>
      </div>
      <nav className="flex-1 space-y-0.5 overflow-y-auto px-2 pb-2">
        {NAV.map((item) => {
          const Icon = item.icon
          const active =
            item.id === 'whiteboard'
              ? activeSection === 'spaces' && taskView === 'whiteboard'
              : activeSection === item.id
          return (
            <button
              key={item.id}
              type="button"
              title={item.label}
              onClick={() => selectNav(item.id)}
              className={clsx('library-nav-row text-sm w-full', active && 'library-nav-row-active')}
            >
              <Icon className="h-4 w-4 shrink-0" />
              <span className="truncate">{item.label}</span>
            </button>
          )
        })}
      </nav>
    </aside>
  )
}
