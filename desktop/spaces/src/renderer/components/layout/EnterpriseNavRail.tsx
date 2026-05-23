import {
  Archive,
  BarChart3,
  Briefcase,
  Calendar,
  CheckCircle2,
  ChevronRight,
  FileText,
  FolderKanban,
  Megaphone,
  MessageSquare,
  PenLine,
  Radio,
  Users
} from 'lucide-react'
import clsx from 'clsx'
import { ENTERPRISE_MAIN_NAV } from '../../../../../../shared/enterprise/nav-config'
import { useSpacesStore } from '../../stores/spaces-store'
import { useChatStore } from '../../stores/chat-store'
import type { SidebarSection } from '../../../shared/types'

type NavId = SidebarSection | 'whiteboard'

const ICONS: Record<string, React.ComponentType<{ className?: string }>> = {
  FolderKanban,
  Calendar,
  MessageSquare,
  FileText,
  PenLine,
  CheckCircle2,
  BarChart3,
  Briefcase,
  Megaphone,
  Users,
  Radio,
  Archive
}

const NAV: { id: NavId; label: string; icon: React.ComponentType<{ className?: string }> }[] =
  ENTERPRISE_MAIN_NAV.map((item) => ({
    id: item.id as NavId,
    label: item.label,
    icon: ICONS[item.icon] ?? FolderKanban
  }))

/** Column 1 — primary enterprise navigation (ClickUp-style bar menu). */
export function EnterpriseNavRail(): React.ReactElement {
  const activeSection = useSpacesStore((s) => s.activeSection)
  const taskView = useSpacesStore((s) => s.taskView)
  const selectNav = useSpacesStore((s) => s.selectEnterpriseNav)
  const currentUserName = useSpacesStore((s) => s.currentUserName)
  const myStatus = useChatStore((s) => s.channels.length > 0 ? 'online' : 'offline')

  return (
    <aside className="glass-sidebar enterprise-nav-rail flex min-h-0 shrink-0 flex-col border-r border-black/5">
      <nav className="flex-1 space-y-0.5 overflow-y-auto px-2 pb-2 pt-3">
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
      <div className="border-t border-surface-border px-2 py-2">
        <button
          type="button"
          className="flex w-full min-w-0 items-center gap-2.5 rounded-lg px-2 py-2 text-left hover:bg-surface-muted/60"
        >
          <span className="relative inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-emerald-100 text-sm font-semibold text-emerald-800">
            {(currentUserName || 'J').slice(0, 1).toUpperCase()}
            <span className="absolute -bottom-0.5 -right-0.5 h-2.5 w-2.5 rounded-full border-2 border-white bg-emerald-500" />
          </span>
          <span className="min-w-0 flex-1">
            <span className="block truncate text-sm font-semibold text-ink">{currentUserName || 'John'}</span>
            <span className="block truncate text-[11px] capitalize text-ink-muted">{myStatus}</span>
          </span>
          <ChevronRight className="h-3.5 w-3.5 shrink-0 text-ink-muted" />
        </button>
      </div>
    </aside>
  )
}
