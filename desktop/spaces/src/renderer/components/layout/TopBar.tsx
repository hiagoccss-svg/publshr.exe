import {
  Bell,
  Cloud,
  CloudOff,
  Filter,
  LayoutGrid,
  Plus,
  Search,
  Sparkles
} from 'lucide-react'
import { useSpacesStore } from '../../stores/spaces-store'
import { TASK_STATUS_LABELS, type TaskViewMode } from '../../../shared/types'
import clsx from 'clsx'

const VIEW_LABELS: Record<TaskViewMode, string> = {
  overview: 'Overview',
  list: 'List',
  board: 'Board',
  whiteboard: 'Whiteboard',
  timeline: 'Timeline',
  calendar: 'Calendar',
  workload: 'Workload',
  priority: 'Priority',
  document: 'Document'
}

const SECTION_LABELS: Record<string, string> = {
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

export function TopBar({
  embedded = false,
  onSignOut
}: {
  embedded?: boolean
  onSignOut?: () => void
}): React.ReactElement {
  const workspace = useSpacesStore((s) => s.workspace)
  const spaces = useSpacesStore((s) => s.spaces)
  const activeSection = useSpacesStore((s) => s.activeSection)
  const activeSpaceId = useSpacesStore((s) => s.activeSpaceId)
  const taskView = useSpacesStore((s) => s.taskView)
  const currentUserName = useSpacesStore((s) => s.currentUserName)
  const syncStatus = useSpacesStore((s) => s.syncStatus)
  const members = useSpacesStore((s) => s.members)
  const searchQuery = useSpacesStore((s) => s.searchQuery)
  const setSearchQuery = useSpacesStore((s) => s.setSearchQuery)
  const setCommandOpen = useSpacesStore((s) => s.setCommandOpen)
  const createTask = useSpacesStore((s) => s.createTask)

  const activeSpace = spaces.find((s) => s.id === activeSpaceId)
  const onlineCount = members.filter((m) => m.isOnline).length

  const subtitle =
    activeSection === 'spaces'
      ? (activeSpace?.name ?? 'Select a Space')
      : (SECTION_LABELS[activeSection] ?? 'Workspace')

  return (
    <header
      data-tauri-drag-region={embedded ? true : undefined}
      className="glass-toolbar flex h-12 shrink-0 items-center gap-3 border-b border-black/5 px-4"
    >
      <div className={embedded ? 'w-16 shrink-0' : 'no-drag w-14 shrink-0'} aria-hidden />
      <div className="no-drag flex min-w-0 items-center gap-3">
        <div className="flex h-7 w-7 items-center justify-center rounded-md bg-accent text-xs font-semibold text-white">
          {(workspace?.name ?? 'P')[0]}
        </div>
        <div className="min-w-0 leading-tight">
          <p className="truncate text-xs font-medium text-ink">{workspace?.name ?? 'Publshr Enterprise'}</p>
          <p className="truncate text-[11px] text-ink-muted">{subtitle}</p>
        </div>
      </div>

      <div className="no-drag mx-auto flex max-w-xl flex-1 items-center gap-2">
        <div className="relative flex-1">
          <Search className="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-ink-muted" />
          <input
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            onFocus={() => setCommandOpen(true)}
            placeholder="Search tasks, docs, files…"
            className="dt-content-input h-8 w-full rounded-lg pl-8 pr-16 text-sm text-ink placeholder:text-ink-muted focus:border-accent/40 focus:outline-none focus:ring-2 focus:ring-accent/10"
          />
          <kbd className="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 rounded border border-surface-border bg-surface-raised px-1.5 text-[10px] text-ink-muted">
            ⌘K
          </kbd>
        </div>
        <button
          type="button"
          onClick={() => void createTask('New task')}
          className="library-cta-pill h-8 text-xs"
        >
          <Plus className="h-3.5 w-3.5" />
          Create
        </button>
      </div>

      <div className="no-drag flex items-center gap-2">
        <ViewContextControls view={taskView} />
        <div className="dt-content-surface-muted flex items-center gap-1 rounded-lg px-2 py-1 text-[11px] text-ink-secondary">
          {syncStatus === 'online' ? (
            <Cloud className="h-3.5 w-3.5 text-status-approved" />
          ) : (
            <CloudOff className="h-3.5 w-3.5 text-ink-muted" />
          )}
          <span className="capitalize">{syncStatus}</span>
        </div>
        <div className="flex -space-x-1">
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
          {onlineCount > 0 && (
            <span className="ml-1 self-center text-[10px] text-ink-muted">{onlineCount} online</span>
          )}
        </div>
        <button type="button" className="rounded-lg p-1.5 text-ink-secondary hover:bg-surface-muted">
          <Bell className="h-4 w-4" />
        </button>
        <button type="button" className="rounded-lg p-1.5 text-ink-secondary hover:bg-surface-muted">
          <Sparkles className="h-4 w-4" />
        </button>
        <span
          className="inline-flex h-7 w-7 items-center justify-center rounded-full bg-accent-soft text-xs font-semibold text-accent"
          title={currentUserName}
        >
          {(currentUserName || 'Y').slice(0, 1).toUpperCase()}
        </span>
        {onSignOut ? (
          <button
            type="button"
            onClick={onSignOut}
            className="rounded-lg px-2 py-1 text-xs text-ink-muted hover:bg-surface-muted hover:text-ink"
          >
            Sign out
          </button>
        ) : null}
      </div>
    </header>
  )
}

function ViewContextControls({ view }: { view: TaskViewMode }): React.ReactElement | null {
  if (view === 'board' || view === 'list' || view === 'priority') {
    return (
      <>
        <button
          type="button"
          className="inline-flex h-8 items-center gap-1 rounded-lg border border-surface-border px-2 text-xs text-ink-secondary hover:bg-surface-muted"
        >
          <Filter className="h-3.5 w-3.5" />
          Filters
        </button>
        <button
          type="button"
          className="inline-flex h-8 items-center gap-1 rounded-lg border border-surface-border px-2 text-xs text-ink-secondary hover:bg-surface-muted"
        >
          <LayoutGrid className="h-3.5 w-3.5" />
          Group
        </button>
      </>
    )
  }
  if (view === 'timeline') {
    return (
      <span className="text-xs text-ink-muted">Week · Milestones · Dependencies</span>
    )
  }
  if (view === 'overview') {
    return (
      <span className="rounded-lg bg-surface-muted px-2 py-1 text-xs text-ink-secondary">
        {VIEW_LABELS[view]}
      </span>
    )
  }
  return (
    <span className="rounded-lg bg-surface-muted px-2 py-1 text-xs text-ink-secondary">
      {VIEW_LABELS[view]}
    </span>
  )
}

export function TaskStatusBadge({ status }: { status: keyof typeof TASK_STATUS_LABELS }): React.ReactElement {
  return (
    <span
      className={clsx(
        'inline-flex rounded px-1.5 py-0.5 text-[10px] font-medium capitalize',
        status === 'completed' && 'bg-status-done/10 text-status-done',
        status === 'in_progress' && 'bg-accent-soft text-accent',
        status === 'review' && 'bg-amber-50 text-amber-800',
        status === 'blocked' && 'bg-red-50 text-status-blocked',
        status === 'todo' && 'bg-surface-muted text-ink-muted'
      )}
    >
      {TASK_STATUS_LABELS[status]}
    </span>
  )
}
