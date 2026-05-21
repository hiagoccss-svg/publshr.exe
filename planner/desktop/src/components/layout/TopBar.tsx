import { useState } from 'react'
import {
  Search,
  Plus,
  Bell,
  Sparkles,
  Cloud,
  CloudOff,
  Loader2,
  ChevronDown,
  ZoomIn,
  ZoomOut,
  Filter,
  Users
} from 'lucide-react'
import { useWorkspaceStore } from '@/stores/workspaceStore'
import { usePlannerStore } from '@/stores/plannerStore'
import { useAuthStore } from '@/stores/authStore'
import { cn, formatShortDate } from '@/lib/utils'
import type { PlannerView } from '@/types/planner'

const VIEW_LABELS: Record<PlannerView, string> = {
  timeline: 'Timeline',
  calendar: 'Calendar',
  board: 'Board',
  editorial_grid: 'Editorial Grid',
  approvals: 'Approvals',
  workload: 'Team Workload',
  client: 'Client View'
}

const VIEWS: PlannerView[] = [
  'timeline',
  'calendar',
  'board',
  'editorial_grid',
  'approvals',
  'workload',
  'client'
]

export default function TopBar() {
  const workspace = useWorkspaceStore((s) => s.currentWorkspace)
  const view = usePlannerStore((s) => s.view)
  const setView = usePlannerStore((s) => s.setView)
  const syncStatus = usePlannerStore((s) => s.syncStatus)
  const timelineZoom = usePlannerStore((s) => s.timelineZoom)
  const setTimelineZoom = usePlannerStore((s) => s.setTimelineZoom)
  const calendarMode = usePlannerStore((s) => s.calendarMode)
  const setCalendarMode = usePlannerStore((s) => s.setCalendarMode)
  const setCreatePanelOpen = usePlannerStore((s) => s.setCreatePanelOpen)
  const user = useAuthStore((s) => s.user)
  const [search, setSearch] = useState('')
  const [viewMenuOpen, setViewMenuOpen] = useState(false)

  const SyncIcon =
    syncStatus === 'syncing' ? Loader2 : syncStatus === 'offline' ? CloudOff : Cloud

  return (
    <header className="drag-region flex h-12 shrink-0 items-center gap-3 border-b border-surface-border bg-surface-raised/80 px-4 backdrop-blur-sm">
      {window.planner?.platform === 'darwin' && <div className="w-14 shrink-0" />}

      <div className="no-drag flex min-w-0 items-center gap-2">
        <div className="flex h-7 w-7 items-center justify-center rounded-md bg-ink text-[10px] font-semibold text-white">
          {workspace?.name?.[0]?.toUpperCase() ?? 'P'}
        </div>
        <div className="hidden min-w-0 sm:block">
          <p className="truncate text-xs font-medium text-ink">{workspace?.name ?? 'Workspace'}</p>
          <p className="truncate text-[10px] text-ink-muted">
            Planner · {VIEW_LABELS[view]}
          </p>
        </div>
      </div>

      <div className="no-drag mx-auto flex max-w-xl flex-1 items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-ink-muted" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onFocus={() => window.dispatchEvent(new CustomEvent('planner:command-palette'))}
            placeholder="Search items, campaigns, files…"
            className="w-full rounded-lg border border-transparent bg-surface-muted/80 py-1.5 pl-8 pr-3 text-xs outline-none transition placeholder:text-ink-muted focus:border-surface-border focus:bg-surface-raised"
          />
          <kbd className="absolute right-2 top-1/2 hidden -translate-y-1/2 rounded border border-surface-border bg-surface-raised px-1 text-[10px] text-ink-muted sm:inline">
            {window.planner?.platform === 'darwin' ? '⌘K' : 'Ctrl+K'}
          </kbd>
        </div>

        <button
          type="button"
          onClick={() => setCreatePanelOpen(true)}
          className="inline-flex items-center gap-1.5 rounded-lg bg-ink px-3 py-1.5 text-xs font-medium text-white transition hover:bg-ink/90"
        >
          <Plus className="h-3.5 w-3.5" />
          New
        </button>

        {view === 'timeline' && (
          <>
            <button
              type="button"
              className="rounded-lg border border-surface-border px-2 py-1 text-xs text-ink-secondary hover:bg-surface-muted"
            >
              Today
            </button>
            <div className="flex items-center rounded-lg border border-surface-border">
              {(['week', 'month', 'quarter'] as const).map((z) => (
                <button
                  key={z}
                  type="button"
                  onClick={() => setTimelineZoom(z)}
                  className={cn(
                    'px-2 py-1 text-[10px] capitalize',
                    timelineZoom === z ? 'bg-surface-muted font-medium text-ink' : 'text-ink-muted'
                  )}
                >
                  {z}
                </button>
              ))}
            </div>
            <button type="button" className="rounded-lg p-1.5 text-ink-muted hover:bg-surface-muted">
              <ZoomOut className="h-3.5 w-3.5" />
            </button>
            <button type="button" className="rounded-lg p-1.5 text-ink-muted hover:bg-surface-muted">
              <ZoomIn className="h-3.5 w-3.5" />
            </button>
          </>
        )}

        {view === 'calendar' && (
          <div className="flex items-center rounded-lg border border-surface-border">
            {(['day', 'week', 'month', 'agenda'] as const).map((m) => (
              <button
                key={m}
                type="button"
                onClick={() => setCalendarMode(m)}
                className={cn(
                  'px-2 py-1 text-[10px] capitalize',
                  calendarMode === m ? 'bg-surface-muted font-medium text-ink' : 'text-ink-muted'
                )}
              >
                {m}
              </button>
            ))}
          </div>
        )}

        <div className="relative">
          <button
            type="button"
            onClick={() => setViewMenuOpen(!viewMenuOpen)}
            className="inline-flex items-center gap-1 rounded-lg border border-surface-border px-2 py-1 text-xs text-ink-secondary hover:bg-surface-muted"
          >
            {VIEW_LABELS[view]}
            <ChevronDown className="h-3 w-3" />
          </button>
          {viewMenuOpen && (
            <>
              <div className="fixed inset-0 z-40" onClick={() => setViewMenuOpen(false)} />
              <div className="absolute right-0 top-full z-50 mt-1 w-44 rounded-lg border border-surface-border bg-surface-raised py-1 shadow-soft">
                {VIEWS.map((v) => (
                  <button
                    key={v}
                    type="button"
                    onClick={() => {
                      setView(v)
                      setViewMenuOpen(false)
                    }}
                    className={cn(
                      'block w-full px-3 py-1.5 text-left text-xs hover:bg-surface-muted',
                      view === v && 'font-medium text-accent'
                    )}
                  >
                    {VIEW_LABELS[v]}
                  </button>
                ))}
              </div>
            </>
          )}
        </div>

        <button type="button" className="rounded-lg p-1.5 text-ink-muted hover:bg-surface-muted" title="Filters">
          <Filter className="h-3.5 w-3.5" />
        </button>
      </div>

      <div className="no-drag flex items-center gap-2">
        <span className="hidden text-[10px] text-ink-muted lg:inline">
          {formatShortDate(new Date().toISOString())}
        </span>
        <div
          className={cn(
            'flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px]',
            syncStatus === 'error' && 'text-status-overdue',
            syncStatus === 'offline' && 'text-ink-muted',
            syncStatus === 'syncing' && 'text-accent'
          )}
          title={`Sync: ${syncStatus}`}
        >
          <SyncIcon className={cn('h-3 w-3', syncStatus === 'syncing' && 'animate-spin')} />
          <span className="capitalize">{syncStatus}</span>
        </div>
        <button type="button" className="relative rounded-lg p-1.5 text-ink-muted hover:bg-surface-muted">
          <Bell className="h-4 w-4" />
          <span className="absolute right-1 top-1 h-1.5 w-1.5 rounded-full bg-status-overdue" />
        </button>
        <div className="hidden items-center -space-x-1 sm:flex" title="Team online">
          <span className="flex h-6 w-6 items-center justify-center rounded-full border-2 border-surface-raised bg-accent-soft text-[9px] font-medium text-accent">
            <Users className="h-3 w-3" />
          </span>
        </div>
        <button
          type="button"
          className="rounded-lg p-1.5 text-ink-muted hover:bg-accent-soft hover:text-accent"
          title="AI Assistant"
        >
          <Sparkles className="h-4 w-4" />
        </button>
        <button
          type="button"
          className="flex h-7 w-7 items-center justify-center rounded-full bg-surface-muted text-[10px] font-medium text-ink"
          title={user?.email ?? 'Profile'}
        >
          {user?.email?.[0]?.toUpperCase() ?? '?'}
        </button>
        {window.planner?.platform !== 'darwin' && <div className="w-2" />}
      </div>
    </header>
  )
}
