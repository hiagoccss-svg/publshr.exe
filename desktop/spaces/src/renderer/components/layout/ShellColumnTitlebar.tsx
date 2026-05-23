import {
  ChevronLeft,
  ChevronRight,
  Cloud,
  CloudOff,
  PanelLeft,
  Plus,
  Search
} from 'lucide-react'
import clsx from 'clsx'
import { useSpacesStore } from '../../stores/spaces-store'
import { useChatStore } from '../../stores/chat-store'
import type { SidebarSection } from '../../../shared/types'
import { TitlebarChromeActionBar } from './TitlebarChromeActionBar'

const SECTION_SEARCH: Partial<Record<SidebarSection, string>> = {
  chat: 'Search channels and people',
  spaces: 'Search spaces and tasks',
  dashboard: 'Search workspace',
  documents: 'Search documents',
  planner: 'Search scheduled work',
  approvals: 'Search approvals',
  team: 'Search team',
  files: 'Search files',
  media: 'Search coverage',
  reports: 'Search reports'
}

const SECTION_LABELS: Partial<Record<SidebarSection, string>> = {
  dashboard: 'Dashboard',
  spaces: 'Spaces',
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

/** Unified titlebar row — column bands align with the shell below (traffic lights + col1/col2/col3). */
export function ShellColumnTitlebar({
  embedded = false,
  onSignOut
}: {
  embedded?: boolean
  onSignOut?: () => void
}): React.ReactElement {
  const activeSection = useSpacesStore((s) => s.activeSection)
  const sidebarCollapsed = useSpacesStore((s) => s.sidebarCollapsed)
  const setSidebarCollapsed = useSpacesStore((s) => s.setSidebarCollapsed)
  const searchQuery = useSpacesStore((s) => s.searchQuery)
  const setSearchQuery = useSpacesStore((s) => s.setSearchQuery)
  const setCommandOpen = useSpacesStore((s) => s.setCommandOpen)
  const setNotificationsOpen = useSpacesStore((s) => s.setNotificationsOpen)
  const setActiveSection = useSpacesStore((s) => s.setActiveSection)
  const createTask = useSpacesStore((s) => s.createTask)
  const workspace = useSpacesStore((s) => s.workspace)
  const syncStatus = useSpacesStore((s) => s.syncStatus)
  const members = useSpacesStore((s) => s.members)
  const notifications = useSpacesStore((s) => s.notifications)
  const spaces = useSpacesStore((s) => s.spaces)
  const activeSpaceId = useSpacesStore((s) => s.activeSpaceId)
  const chatSearch = useChatStore((s) => s.sidebarSearchQuery)
  const setChatSearch = useChatStore((s) => s.setSidebarSearchQuery)

  const submenuWidth = sidebarCollapsed
    ? 'var(--lib-sidebar-collapsed-width, 3rem)'
    : 'var(--lib-sidebar-width-wide, 272px)'

  const isChat = activeSection === 'chat'
  const col2Search = isChat ? chatSearch : searchQuery
  const setCol2Search = isChat ? setChatSearch : setSearchQuery
  const searchPlaceholder =
    SECTION_SEARCH[activeSection] ?? 'Search workspace'

  const activeSpace = spaces.find((s) => s.id === activeSpaceId)
  const editorTitle =
    activeSection === 'spaces'
      ? (activeSpace?.name ?? 'Spaces')
      : (SECTION_LABELS[activeSection] ?? workspace?.name ?? 'Workspace')

  const onlineCount = members.filter((m) => m.isOnline).length
  const unreadNotifications = notifications.filter((n) => !n.read).length

  return (
    <header
      data-tauri-drag-region={embedded ? true : undefined}
      className="glass-toolbar shell-unified-titlebar flex h-12 shrink-0 items-stretch border-b border-black/5"
    >
      {/* Column 1 — traffic reserve + shell navigation (matches macOS leadingBand) */}
      <div
        className="enterprise-nav-rail flex shrink-0 items-center gap-1 border-r border-black/5 px-2"
        style={{ width: 'var(--lib-bar-menu-width, 220px)' }}
      >
        {embedded ? (
          <div className="no-drag w-[var(--traffic-leading-inset,72px)] shrink-0" aria-hidden />
        ) : null}
        <div className="no-drag flex items-center gap-0.5">
          <button
            type="button"
            title={sidebarCollapsed ? 'Expand submenu' : 'Collapse submenu'}
            onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
            className="rounded-lg p-1.5 text-ink-secondary hover:bg-surface-muted"
          >
            <PanelLeft className="h-4 w-4" />
          </button>
          <button
            type="button"
            title="Back"
            className="rounded-lg p-1.5 text-ink-muted"
            disabled
          >
            <ChevronLeft className="h-4 w-4" />
          </button>
          <button
            type="button"
            title="Forward"
            className="rounded-lg p-1.5 text-ink-muted"
            disabled
          >
            <ChevronRight className="h-4 w-4" />
          </button>
        </div>
      </div>

      {/* Column 2 — module search */}
      <div
        className={clsx(
          'enterprise-context-sidebar no-drag flex shrink-0 items-center gap-2 border-r border-black/5 px-3',
          sidebarCollapsed && 'enterprise-context-sidebar-collapsed'
        )}
        style={{ width: submenuWidth }}
      >
        <Search className="h-3.5 w-3.5 shrink-0 text-ink-muted" />
        <input
          value={col2Search}
          onChange={(e) => setCol2Search(e.target.value)}
          placeholder={searchPlaceholder}
          className="min-w-0 flex-1 bg-transparent text-sm text-ink placeholder:text-ink-muted focus:outline-none"
        />
      </div>

      {/* Column 3 — editor titlebar band + chrome actions on the traffic row */}
      <div className="enterprise-editor-titlebar no-drag flex min-w-0 flex-1 items-center gap-3 border-r-0 px-3">
        <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-md bg-accent text-xs font-semibold text-white">
          {(workspace?.name ?? 'P')[0]}
        </div>
        <div className="min-w-0 flex-1">
          <p className="truncate text-xs font-medium text-ink">{workspace?.name ?? 'Publshr Enterprise'}</p>
          <p className="truncate text-[11px] text-ink-muted">{editorTitle}</p>
        </div>
        <button
          type="button"
          onClick={() => void createTask('New task')}
          className="library-cta-pill h-8 shrink-0 text-xs"
        >
          <Plus className="h-3.5 w-3.5" />
          Create
        </button>
        <div className="dt-content-surface-muted hidden shrink-0 items-center gap-1 rounded-lg px-2 py-1 text-[11px] text-ink-secondary sm:flex">
          {syncStatus === 'online' ? (
            <Cloud className="h-3.5 w-3.5 text-status-approved" />
          ) : (
            <CloudOff className="h-3.5 w-3.5 text-ink-muted" />
          )}
          <span className="capitalize">{syncStatus}</span>
        </div>
        <div className="hidden shrink-0 -space-x-1 md:flex">
          {members.slice(0, 4).map((m) => (
            <span
              key={m.id}
              title={m.name}
              className="inline-flex h-6 w-6 items-center justify-center rounded-full border-2 border-surface-raised text-[10px] font-medium text-white"
              style={{ backgroundColor: m.avatarColor }}
            >
              {m.name[0]}
            </span>
          ))}
          {onlineCount > 0 ? (
            <span className="ml-1 self-center text-[10px] text-ink-muted">{onlineCount} online</span>
          ) : null}
        </div>

        <TitlebarChromeActionBar
          unreadCount={unreadNotifications}
          onNotifications={() => setNotificationsOpen(true)}
          onCommand={() => setCommandOpen(true)}
          onSettings={() => setActiveSection('settings')}
        />

        {onSignOut ? (
          <button
            type="button"
            onClick={onSignOut}
            className="hidden rounded-lg px-2 py-1 text-xs text-ink-muted hover:bg-surface-muted hover:text-ink lg:inline"
          >
            Sign out
          </button>
        ) : null}
      </div>
    </header>
  )
}
