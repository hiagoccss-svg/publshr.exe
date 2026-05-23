import { ChevronLeft, LayoutDashboard, Pin, Plus, Settings, Star } from 'lucide-react'
import clsx from 'clsx'
import { useSpacesStore } from '../../stores/spaces-store'
import { SpacesHierarchyTree } from '../spaces/SpacesHierarchyTree'
import { ChatContextSidebar } from '../chat/ChatContextSidebar'

/** Column 2 — contextual sidebar (spaces tree, chat channels placeholder, etc.). */
export function EnterpriseContextSidebar(): React.ReactElement {
  const collapsed = useSpacesStore((s) => s.sidebarCollapsed)
  const setSidebarCollapsed = useSpacesStore((s) => s.setSidebarCollapsed)
  const activeSection = useSpacesStore((s) => s.activeSection)
  const spaces = useSpacesStore((s) => s.spaces)
  const setActiveSpace = useSpacesStore((s) => s.setActiveSpace)
  const setNewSpaceModalOpen = useSpacesStore((s) => s.setNewSpaceModalOpen)
  const setSpacesHomeOpen = useSpacesStore((s) => s.setSpacesHomeOpen)
  const openSpaceSettings = useSpacesStore((s) => s.openSpaceSettings)
  const activeSpaceId = useSpacesStore((s) => s.activeSpaceId)
  const spacesHomeOpen = useSpacesStore((s) => s.spacesHomeOpen)
  const setActiveSection = useSpacesStore((s) => s.setActiveSection)

  const pinned = spaces.filter((s) => s.isPinned)
  const recent = spaces.filter((s) => !s.isPinned && !s.isArchived).slice(0, 8)
  const showSpacesTree = activeSection === 'spaces'
  const showChatNav = activeSection === 'chat'

  if (showChatNav) {
    return (
      <aside
        className={clsx(
          'glass-sidebar flex min-h-0 w-56 shrink-0 flex-col overflow-hidden border-r border-black/5',
          collapsed && 'w-12'
        )}
      >
        <ContextHeader collapsed={collapsed} onToggle={() => setSidebarCollapsed(!collapsed)} />
        {!collapsed && <ChatContextSidebar />}
        <SettingsFooter collapsed={collapsed} onSettings={() => setActiveSection('settings')} />
      </aside>
    )
  }

  if (!showSpacesTree) {
    return (
      <aside
        className={clsx(
          'glass-sidebar flex min-h-0 shrink-0 flex-col border-r border-black/5 transition-[width] duration-200',
          collapsed ? 'w-12' : 'w-56'
        )}
      >
        <ContextHeader collapsed={collapsed} onToggle={() => setSidebarCollapsed(!collapsed)} />
        {!collapsed && (
          <div className="flex-1 overflow-y-auto px-3 py-2 text-xs text-ink-muted">
            <p className="font-medium text-ink-secondary">{sectionContextLabel(activeSection)}</p>
            <p className="mt-2 leading-relaxed">
              Use the main workspace to browse and manage {sectionContextLabel(activeSection).toLowerCase()}.
            </p>
          </div>
        )}
        <SettingsFooter collapsed={collapsed} onSettings={() => setActiveSection('settings')} />
      </aside>
    )
  }

  return (
    <aside
      className={clsx(
        'glass-sidebar flex min-h-0 shrink-0 flex-col overflow-hidden border-r border-black/5 transition-[width] duration-200',
        collapsed ? 'w-12' : activeSpaceId ? 'glass-sidebar-wide w-64' : 'w-56'
      )}
    >
      {!collapsed && (
        <div className="px-3 pt-3 pb-2">
          <button
            type="button"
            onClick={() => setNewSpaceModalOpen(true)}
            className="library-cta-pill w-full justify-center"
          >
            <Plus className="h-4 w-4" />
            New Space
          </button>
        </div>
      )}

      <ContextHeader collapsed={collapsed} onToggle={() => setSidebarCollapsed(!collapsed)} />

      <div className="flex-1 space-y-0.5 overflow-y-auto px-2 pb-2">
        {!collapsed && (
          <>
            <button
              type="button"
              onClick={() => setSpacesHomeOpen(true)}
              className={clsx(
                'flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-left text-xs',
                spacesHomeOpen && !activeSpaceId
                  ? 'bg-accent-soft font-medium text-accent'
                  : 'text-ink-secondary hover:bg-surface-muted/60'
              )}
            >
              <LayoutDashboard className="h-3.5 w-3.5" />
              Spaces Home
            </button>
            <SpaceGroup
              title="Pinned"
              icon={Pin}
              items={pinned}
              activeSpaceId={activeSpaceId}
              onSelect={(id) => void setActiveSpace(id)}
              onSettings={openSpaceSettings}
            />
            <SpaceGroup
              title="Recent"
              icon={Star}
              items={recent}
              activeSpaceId={activeSpaceId}
              onSelect={(id) => void setActiveSpace(id)}
              onSettings={openSpaceSettings}
            />
            <button
              type="button"
              onClick={() => setNewSpaceModalOpen(true)}
              className="w-full rounded-lg border border-dashed border-surface-border py-2 text-xs text-ink-muted hover:border-accent/30 hover:text-accent"
            >
              + New Space
            </button>
            {activeSpaceId && <SpacesHierarchyTree />}
          </>
        )}
      </div>

      <SettingsFooter collapsed={collapsed} onSettings={() => setActiveSection('settings')} />
    </aside>
  )
}

function ContextHeader({
  collapsed,
  onToggle
}: {
  collapsed: boolean
  onToggle: () => void
}): React.ReactElement {
  return (
    <div className="flex items-center justify-between px-3 py-2">
      {!collapsed && <span className="library-section-label !px-0">Spaces</span>}
      <button
        type="button"
        onClick={onToggle}
        className="rounded p-1 text-ink-muted hover:bg-surface-muted"
        title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
      >
        <ChevronLeft className={clsx('h-4 w-4 transition', collapsed && 'rotate-180')} />
      </button>
    </div>
  )
}

function SettingsFooter({
  collapsed,
  onSettings
}: {
  collapsed: boolean
  onSettings: () => void
}): React.ReactElement {
  return (
    <div className="border-t border-surface-border p-2">
      <button
        type="button"
        onClick={onSettings}
        className="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-sm text-ink-secondary hover:bg-surface-muted"
      >
        <Settings className="h-4 w-4" />
        {!collapsed && 'Settings'}
      </button>
    </div>
  )
}

function sectionContextLabel(section: string): string {
  const map: Record<string, string> = {
    dashboard: 'Dashboard',
    planner: 'Planner',
    chat: 'Chat',
    documents: 'Documents',
    approvals: 'Approvals',
    reports: 'Reports',
    clients: 'Clients',
    campaigns: 'Campaigns',
    team: 'Team',
    media: 'Media Monitoring',
    files: 'Files',
    settings: 'Settings'
  }
  return map[section] ?? 'Workspace'
}

function SpaceGroup({
  title,
  icon: Icon,
  items,
  activeSpaceId,
  onSelect,
  onSettings
}: {
  title: string
  icon: React.ComponentType<{ className?: string }>
  items: { id: string; name: string; color: string }[]
  activeSpaceId: string | null
  onSelect: (id: string) => void
  onSettings: (id: string) => void
}): React.ReactElement | null {
  if (items.length === 0) return null
  return (
    <div className="mt-3">
      <p className="mb-1 flex items-center gap-1 px-2 text-[10px] font-semibold uppercase tracking-wide text-ink-muted">
        <Icon className="h-3 w-3" />
        {title}
      </p>
      {items.map((s) => (
        <div key={s.id} className="group flex items-center gap-0.5">
          <button
            type="button"
            onClick={() => onSelect(s.id)}
            className={clsx(
              'flex min-w-0 flex-1 items-center gap-2 rounded-lg px-2 py-1 text-left text-xs',
              activeSpaceId === s.id
                ? 'bg-surface-muted font-medium text-ink'
                : 'text-ink-secondary hover:bg-surface-muted/60'
            )}
          >
            <span className="h-2 w-2 shrink-0 rounded-full" style={{ backgroundColor: s.color }} />
            <span className="truncate">{s.name}</span>
          </button>
          <button
            type="button"
            title="Space settings"
            onClick={() => onSettings(s.id)}
            className="rounded p-0.5 text-ink-muted opacity-0 hover:bg-surface-muted group-hover:opacity-100"
          >
            <Settings className="h-3 w-3" />
          </button>
        </div>
      ))}
    </div>
  )
}
