import { useState } from 'react'
import {
  LayoutDashboard,
  CalendarRange,
  Megaphone,
  FileText,
  PenLine,
  CheckCircle2,
  Newspaper,
  BarChart3,
  Building2,
  Users,
  MessageSquare,
  Settings,
  ChevronLeft,
  ChevronRight,
  Pin
} from 'lucide-react'
import { useWorkspaceStore } from '@/stores/workspaceStore'
import { usePlannerStore } from '@/stores/plannerStore'
import { cn } from '@/lib/utils'

const navItems = [
  { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard, module: false },
  { id: 'planner', label: 'Planner', icon: CalendarRange, module: true, badge: 0 },
  { id: 'campaigns', label: 'Campaigns', icon: Megaphone, module: false },
  { id: 'press', label: 'Press Releases', icon: FileText, module: false },
  { id: 'editorial', label: 'Editorial', icon: PenLine, module: false },
  { id: 'approvals', label: 'Approvals', icon: CheckCircle2, module: false, badge: 3 },
  { id: 'coverage', label: 'Coverage', icon: Newspaper, module: false },
  { id: 'reports', label: 'Reports', icon: BarChart3, module: false },
  { id: 'clients', label: 'Clients', icon: Building2, module: false },
  { id: 'team', label: 'Team', icon: Users, module: false },
  { id: 'chat', label: 'Chat', icon: MessageSquare, module: false },
  { id: 'settings', label: 'Settings', icon: Settings, module: false }
] as const

export default function Sidebar() {
  const [collapsed, setCollapsed] = useState(false)
  const workspace = useWorkspaceStore((s) => s.currentWorkspace)
  const setView = usePlannerStore((s) => s.setView)

  return (
    <aside
      className={cn(
        'flex shrink-0 flex-col border-r border-surface-border bg-surface-raised/60 transition-all duration-200',
        collapsed ? 'w-[52px]' : 'w-[220px]'
      )}
    >
      <div className={cn('flex items-center gap-2 px-3 py-3', collapsed && 'justify-center')}>
        {!collapsed && (
          <div className="min-w-0 flex-1">
            <p className="truncate text-xs font-medium text-ink">{workspace?.name ?? 'Workspace'}</p>
            <p className="truncate text-[10px] text-ink-muted">Communications</p>
          </div>
        )}
        <button
          type="button"
          onClick={() => setCollapsed(!collapsed)}
          className="no-drag rounded-md p-1 text-ink-muted hover:bg-surface-muted hover:text-ink"
          aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
        >
          {collapsed ? <ChevronRight className="h-4 w-4" /> : <ChevronLeft className="h-4 w-4" />}
        </button>
      </div>

      <nav className="flex-1 space-y-0.5 overflow-y-auto px-2 pb-2">
        {navItems.map((item) => {
          const Icon = item.icon
          const active = item.id === 'planner'
          return (
            <button
              key={item.id}
              type="button"
              onClick={() => {
                if (item.id === 'planner') setView('timeline')
                if (item.id === 'approvals') setView('approvals')
              }}
              className={cn(
                'no-drag group flex w-full items-center gap-2.5 rounded-lg px-2.5 py-2 text-left text-sm transition',
                active
                  ? 'bg-accent-soft text-accent font-medium'
                  : 'text-ink-secondary hover:bg-surface-muted hover:text-ink',
                collapsed && 'justify-center px-2'
              )}
              title={collapsed ? item.label : undefined}
            >
              <Icon className="h-4 w-4 shrink-0" strokeWidth={1.75} />
              {!collapsed && (
                <>
                  <span className="flex-1 truncate">{item.label}</span>
                  {'badge' in item && item.badge ? (
                    <span className="rounded-full bg-status-overdue/10 px-1.5 text-[10px] font-medium text-status-overdue">
                      {item.badge}
                    </span>
                  ) : null}
                </>
              )}
            </button>
          )
        })}
      </nav>

      {!collapsed && (
        <div className="border-t border-surface-border px-3 py-3">
          <p className="mb-2 flex items-center gap-1 text-[10px] font-medium uppercase tracking-wider text-ink-muted">
            <Pin className="h-3 w-3" /> Pinned
          </p>
          <p className="text-xs text-ink-muted">Pin campaigns from the timeline.</p>
        </div>
      )}
    </aside>
  )
}
