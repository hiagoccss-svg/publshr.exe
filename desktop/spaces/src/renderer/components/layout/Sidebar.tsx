import {
  Archive,
  BarChart3,
  Calendar,
  CheckCircle2,
  ChevronLeft,
  FileText,
  FolderKanban,
  LayoutDashboard,
  MessageSquare,
  Pin,
  Plus,
  Radio,
  Settings,
  Star,
  Users,
  Briefcase,
  Megaphone
} from 'lucide-react'
import clsx from 'clsx'
import { useSpacesStore } from '../../stores/spaces-store'
import { SpacesHierarchyTree } from '../spaces/SpacesHierarchyTree'
import type { SidebarSection } from '../../../shared/types'

const NAV: { id: SidebarSection; label: string; icon: React.ComponentType<{ className?: string }> }[] = [
  { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { id: 'spaces', label: 'Spaces', icon: FolderKanban },
  { id: 'planner', label: 'Planner', icon: Calendar },
  { id: 'chat', label: 'Chat', icon: MessageSquare },
  { id: 'documents', label: 'Documents', icon: FileText },
  { id: 'approvals', label: 'Approvals', icon: CheckCircle2 },
  { id: 'reports', label: 'Reports', icon: BarChart3 },
  { id: 'clients', label: 'Clients', icon: Briefcase },
  { id: 'campaigns', label: 'Campaigns', icon: Megaphone },
  { id: 'team', label: 'Team', icon: Users },
  { id: 'media', label: 'Media Monitoring', icon: Radio },
  { id: 'files', label: 'Files', icon: Archive }
]

interface SidebarProps {
  collapsed: boolean
}

export function Sidebar({ collapsed }: SidebarProps): React.ReactElement {
  const activeSection = useSpacesStore((s) => s.activeSection)
  const setActiveSection = useSpacesStore((s) => s.setActiveSection)
  const spaces = useSpacesStore((s) => s.spaces)
  const setActiveSpace = useSpacesStore((s) => s.setActiveSpace)
  const setSidebarCollapsed = useSpacesStore((s) => s.setSidebarCollapsed)
  const setNewSpaceModalOpen = useSpacesStore((s) => s.setNewSpaceModalOpen)
  const activeSpaceId = useSpacesStore((s) => s.activeSpaceId)

  const pinned = spaces.filter((s) => s.isPinned)
  const recent = spaces.filter((s) => !s.isPinned && !s.isArchived).slice(0, 8)

  return (
    <aside
      className={clsx(
        'glass-sidebar flex min-h-0 shrink-0 flex-col overflow-hidden transition-[width] duration-200',
        collapsed ? 'w-14 !bg-surface-raised/90' : activeSection === 'spaces' && activeSpaceId ? 'glass-sidebar-wide' : ''
      )}
    >
      {!collapsed && (
        <div className="px-3 pt-3 pb-2">
          <button type="button" onClick={() => setNewSpaceModalOpen(true)} className="library-cta-pill w-full justify-center">
            <Plus className="h-4 w-4" />
            New Space
          </button>
        </div>
      )}

      <div className="flex items-center justify-between px-3 py-2">
        {!collapsed && <span className="library-section-label !px-0">Operations</span>}
        <button
          type="button"
          onClick={() => setSidebarCollapsed(!collapsed)}
          className="rounded p-1 text-ink-muted hover:bg-surface-muted"
        >
          <ChevronLeft className={clsx('h-4 w-4 transition', collapsed && 'rotate-180')} />
        </button>
      </div>

      <nav className="flex-1 space-y-0.5 overflow-y-auto px-2 pb-2">
        {NAV.map((item) => {
          const Icon = item.icon
          const active = activeSection === item.id
          return (
            <button
              key={item.id}
              type="button"
              title={item.label}
              onClick={() => setActiveSection(item.id)}
              className={clsx(
                'library-nav-row text-sm',
                active && 'library-nav-row-active'
              )}
            >
              <Icon className="h-4 w-4 shrink-0" />
              {!collapsed && <span className="truncate">{item.label}</span>}
            </button>
          )
        })}

        {activeSection === 'spaces' && !collapsed && (
          <div className="mt-4 space-y-3 border-t border-surface-border pt-3">
            <SpaceGroup
              title="Pinned"
              icon={Pin}
              items={pinned}
              activeSpaceId={activeSpaceId}
              onSelect={(id) => void setActiveSpace(id)}
            />
            <SpaceGroup
              title="Recent"
              icon={Star}
              items={recent}
              activeSpaceId={activeSpaceId}
              onSelect={(id) => void setActiveSpace(id)}
            />
            <button
              type="button"
              onClick={() => setNewSpaceModalOpen(true)}
              className="w-full rounded-lg border border-dashed border-surface-border py-2 text-xs text-ink-muted hover:border-accent/30 hover:text-accent"
            >
              + New Space
            </button>
            {activeSpaceId && <SpacesHierarchyTree />}
          </div>
        )}
      </nav>

      <div className="border-t border-surface-border p-2">
        <button
          type="button"
          onClick={() => setActiveSection('settings')}
          className="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-sm text-ink-secondary hover:bg-surface-muted"
        >
          <Settings className="h-4 w-4" />
          {!collapsed && 'Settings'}
        </button>
      </div>
    </aside>
  )
}

function SpaceGroup({
  title,
  icon: Icon,
  items,
  activeSpaceId,
  onSelect
}: {
  title: string
  icon: React.ComponentType<{ className?: string }>
  items: { id: string; name: string; color: string }[]
  activeSpaceId: string | null
  onSelect: (id: string) => void
}): React.ReactElement | null {
  if (items.length === 0) return null
  return (
    <div>
      <p className="mb-1 flex items-center gap-1 px-2 text-[10px] font-semibold uppercase tracking-wide text-ink-muted">
        <Icon className="h-3 w-3" />
        {title}
      </p>
      {items.map((s) => (
        <button
          key={s.id}
          type="button"
          onClick={() => onSelect(s.id)}
          className={clsx(
            'flex w-full items-center gap-2 rounded-lg px-2 py-1 text-left text-xs',
            activeSpaceId === s.id ? 'bg-surface-muted font-medium text-ink' : 'text-ink-secondary hover:bg-surface-muted/60'
          )}
        >
          <span className="h-2 w-2 shrink-0 rounded-full" style={{ backgroundColor: s.color }} />
          <span className="truncate">{s.name}</span>
        </button>
      ))}
    </div>
  )
}
