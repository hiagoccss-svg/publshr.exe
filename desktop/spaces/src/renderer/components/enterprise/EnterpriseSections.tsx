import { format, formatDistanceToNow, isPast } from 'date-fns'
import {
  Briefcase,
  Cloud,
  CloudOff,
  ExternalLink,
  FileText,
  Megaphone,
  MessageSquare,
  Plus,
  Radio
} from 'lucide-react'
import clsx from 'clsx'
import { useSpacesStore } from '../../stores/spaces-store'
import { getSpacesAPI } from '../../lib/api'
import type { Approval, SidebarSection, Space } from '../../../shared/types'

export function EnterpriseSectionView({ section }: { section: SidebarSection }): React.ReactElement {
  switch (section) {
    case 'dashboard':
      return <DashboardSection />
    case 'documents':
      return <DocumentsSection />
    case 'approvals':
      return <ApprovalsSection />
    case 'files':
      return <FilesSection />
    case 'clients':
      return <SpacesByTypeSection type="client" title="Clients" icon={Briefcase} />
    case 'campaigns':
      return <SpacesByTypeSection type="campaign" title="Campaigns" icon={Megaphone} />
    case 'team':
      return <TeamSection />
    case 'reports':
      return <ReportsSection />
    case 'chat':
      return <ChatSection />
    case 'planner':
      return <PlannerSection />
    case 'media':
      return <MediaSection />
    case 'settings':
      return <SettingsSection />
    default:
      return <DashboardSection />
  }
}

function DashboardSection(): React.ReactElement {
  const summary = useSpacesStore((s) => s.workspaceSummary)
  const activity = useSpacesStore((s) => s.workspaceActivity)
  const tasks = useSpacesStore((s) => s.workspaceTasks)
  const setActiveSection = useSpacesStore((s) => s.setActiveSection)
  const setActiveSpace = useSpacesStore((s) => s.setActiveSpace)
  const setSelectedTask = useSpacesStore((s) => s.setSelectedTask)

  const overdue = tasks.filter((t) => t.dueDate && isPast(new Date(t.dueDate)) && t.status !== 'completed')

  return (
    <div className="animate-fade-in space-y-6 p-6">
      <header>
        <h1 className="text-xl font-semibold text-ink">Operations dashboard</h1>
        <p className="mt-1 text-sm text-ink-secondary">Cross-space summary for your workspace.</p>
      </header>

      {summary && (
        <div className="library-masonry library-masonry-responsive">
          <Metric label="Active spaces" value={summary.spaceCount} onClick={() => setActiveSection('spaces')} />
          <Metric
            label="Open tasks"
            value={summary.openTasks}
            warn={summary.overdueTasks > 0}
            onClick={() => setActiveSection('spaces')}
          />
          <Metric
            label="Overdue"
            value={summary.overdueTasks}
            warn={summary.overdueTasks > 0}
            onClick={() => setActiveSection('spaces')}
          />
          <Metric
            label="Pending approvals"
            value={summary.pendingApprovals}
            onClick={() => setActiveSection('approvals')}
          />
          <Metric label="Documents" value={summary.documentCount} onClick={() => setActiveSection('documents')} />
          <Metric label="Files" value={summary.fileCount} onClick={() => setActiveSection('files')} />
          <Metric label="Team online" value={summary.onlineMembers} onClick={() => setActiveSection('team')} />
        </div>
      )}

      <div className="grid gap-4 lg:grid-cols-2">
        <Panel title="Overdue tasks">
          {overdue.length === 0 ? (
            <p className="text-xs text-ink-muted">No overdue tasks.</p>
          ) : (
            <ul className="space-y-1">
              {overdue.slice(0, 8).map((t) => (
                <li key={t.id}>
                  <button
                    type="button"
                    className="flex w-full items-center justify-between rounded-lg px-2 py-1 text-left text-xs hover:bg-surface-muted"
                    onClick={() => {
                      void setActiveSpace(t.spaceId)
                      void setSelectedTask(t.id)
                    }}
                  >
                    <span className="truncate font-medium text-ink">{t.title}</span>
                    <span className="shrink-0 text-ink-muted">{t.spaceName}</span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </Panel>
        <Panel title="Latest activity">
          {activity.length === 0 ? (
            <p className="text-xs text-ink-muted">No activity yet.</p>
          ) : (
            activity.slice(0, 10).map((a) => (
              <p key={a.id} className="mb-2 text-xs text-ink-secondary">
                <span className="font-medium text-ink">{a.userName}</span> {a.action}
                <span className="block text-[10px] text-ink-muted">
                  {a.spaceName} · {formatDistanceToNow(new Date(a.createdAt), { addSuffix: true })}
                </span>
              </p>
            ))
          )}
        </Panel>
      </div>
    </div>
  )
}

function DocumentsSection(): React.ReactElement {
  const documents = useSpacesStore((s) => s.workspaceDocuments)
  const spaces = useSpacesStore((s) => s.spaces)
  const createDocument = useSpacesStore((s) => s.createDocument)

  return (
    <div className="space-y-4 p-6">
      <SectionHeader
        title="Documents"
        description="Briefs and drafts across all Spaces. Opens in a dedicated editor window."
        action={
          <button
            type="button"
            className="library-cta-pill text-xs"
            onClick={() => {
              const title = window.prompt('Document title')
              if (title) void createDocument(title)
            }}
            disabled={spaces.length === 0}
          >
            <Plus className="h-3.5 w-3.5" />
            New document
          </button>
        }
      />
      <EntityList
        empty="No documents yet. Create one to start writing."
        items={documents}
        render={(d) => (
          <button
            type="button"
            className="flex w-full items-center justify-between rounded-lg border border-surface-border px-3 py-2 text-left text-sm hover:bg-surface-muted"
            onClick={() => getSpacesAPI().openDocumentWindow(d.id, d.title)}
          >
            <span className="flex items-center gap-2 font-medium text-ink">
              <FileText className="h-4 w-4 text-ink-muted" />
              {d.title}
            </span>
            <span className="text-xs text-ink-muted">
              {d.spaceName} · {format(new Date(d.updatedAt), 'MMM d')}
            </span>
          </button>
        )}
      />
    </div>
  )
}

function ApprovalsSection(): React.ReactElement {
  const approvals = useSpacesStore((s) => s.workspaceApprovals)
  const spaces = useSpacesStore((s) => s.spaces)
  const setActiveSpace = useSpacesStore((s) => s.setActiveSpace)

  const spaceName = (spaceId: string): string => spaces.find((s) => s.id === spaceId)?.name ?? 'Space'

  return (
    <div className="space-y-4 p-6">
      <SectionHeader title="Approvals" description="Document, task, and campaign approval requests." />
      <EntityList
        empty="No approval requests."
        items={approvals}
        render={(a) => (
          <button
            type="button"
            className="flex w-full items-center justify-between rounded-lg border border-surface-border px-3 py-2 text-left text-sm hover:bg-surface-muted"
            onClick={() => void setActiveSpace(a.spaceId)}
          >
            <span className="font-medium text-ink">{a.title}</span>
            <ApprovalBadge status={a.status} spaceName={spaceName(a.spaceId)} />
          </button>
        )}
      />
    </div>
  )
}

function FilesSection(): React.ReactElement {
  const files = useSpacesStore((s) => s.workspaceFiles)
  const spaces = useSpacesStore((s) => s.spaces)
  const createFileLink = useSpacesStore((s) => s.createFileLink)

  return (
    <div className="space-y-4 p-6">
      <SectionHeader
        title="Files"
        description="Workspace file links and assets."
        action={
          <button
            type="button"
            className="library-cta-pill text-xs"
            disabled={spaces.length === 0}
            onClick={() => {
              const fileName = window.prompt('File name')
              const fileUrl = window.prompt('File URL')
              if (fileName && fileUrl) void createFileLink(fileName, fileUrl)
            }}
          >
            <Plus className="h-3.5 w-3.5" />
            Add link
          </button>
        }
      />
      <EntityList
        empty="No files yet. Add a link to an asset or upload URL."
        items={files}
        render={(f) => (
          <a
            href={f.fileUrl}
            target="_blank"
            rel="noreferrer"
            className="flex items-center justify-between rounded-lg border border-surface-border px-3 py-2 text-sm hover:bg-surface-muted"
          >
            <span className="font-medium text-ink">{f.fileName}</span>
            <ExternalLink className="h-3.5 w-3.5 text-accent" />
          </a>
        )}
      />
    </div>
  )
}

function SpacesByTypeSection({
  type,
  title,
  icon: Icon
}: {
  type: Space['type']
  title: string
  icon: React.ComponentType<{ className?: string }>
}): React.ReactElement {
  const spaces = useSpacesStore((s) => s.spaces.filter((sp) => sp.type === type && !sp.isArchived))
  const setActiveSpace = useSpacesStore((s) => s.setActiveSpace)
  const setActiveSection = useSpacesStore((s) => s.setActiveSection)

  return (
    <div className="space-y-4 p-6">
      <SectionHeader title={title} description={`${title} Spaces in this workspace.`} />
      {spaces.length === 0 ? (
        <p className="text-sm text-ink-muted">No {title.toLowerCase()} spaces yet.</p>
      ) : (
        <ul className="space-y-2">
          {spaces.map((s) => (
            <li key={s.id}>
              <button
                type="button"
                className="flex w-full items-center gap-3 rounded-lg border border-surface-border px-3 py-2 text-left hover:bg-surface-muted"
                onClick={() => {
                  setActiveSection('spaces')
                  void setActiveSpace(s.id)
                }}
              >
                <Icon className="h-4 w-4 text-accent" />
                <div>
                  <p className="text-sm font-medium text-ink">{s.name}</p>
                  <p className="text-xs text-ink-muted capitalize">{s.status}</p>
                </div>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

function TeamSection(): React.ReactElement {
  const members = useSpacesStore((s) => s.workspaceMembers)

  return (
    <div className="space-y-4 p-6">
      <SectionHeader title="Team" description="Members across all Spaces." />
      {members.length === 0 ? (
        <p className="text-sm text-ink-muted">No team members yet.</p>
      ) : (
        <ul className="grid gap-2 sm:grid-cols-2">
          {members.map((m) => (
            <li
              key={m.userId}
              className="flex items-center gap-3 rounded-lg border border-surface-border px-3 py-2"
            >
              <span
                className="flex h-8 w-8 items-center justify-center rounded-full text-xs font-semibold text-white"
                style={{ backgroundColor: m.avatarColor }}
              >
                {m.name[0]?.toUpperCase()}
              </span>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium text-ink">
                  {m.name}
                  {m.isOnline && (
                    <span className="ml-2 inline-block h-1.5 w-1.5 rounded-full bg-status-approved" />
                  )}
                </p>
                <p className="truncate text-xs text-ink-muted">
                  {m.role} · {m.spaceCount} space{m.spaceCount === 1 ? '' : 's'}
                </p>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

function ReportsSection(): React.ReactElement {
  const summary = useSpacesStore((s) => s.workspaceSummary)
  const tasks = useSpacesStore((s) => s.workspaceTasks)
  const byStatus = tasks.reduce<Record<string, number>>((acc, t) => {
    acc[t.status] = (acc[t.status] ?? 0) + 1
    return acc
  }, {})

  return (
    <div className="space-y-4 p-6">
      <SectionHeader title="Reports" description="Operational metrics from local workspace data." />
      {summary && (
        <div className="library-card space-y-3 p-4 text-sm">
          <Row label="Spaces" value={String(summary.spaceCount)} />
          <Row label="Open tasks" value={String(summary.openTasks)} />
          <Row label="Documents" value={String(summary.documentCount)} />
          <Row label="Pending approvals" value={String(summary.pendingApprovals)} />
        </div>
      )}
      <Panel title="Tasks by status">
        {Object.keys(byStatus).length === 0 ? (
          <p className="text-xs text-ink-muted">No task data.</p>
        ) : (
          <ul className="space-y-1">
            {Object.entries(byStatus).map(([status, count]) => (
              <li key={status} className="flex justify-between text-xs">
                <span className="capitalize text-ink-secondary">{status.replace(/_/g, ' ')}</span>
                <span className="font-medium text-ink">{count}</span>
              </li>
            ))}
          </ul>
        )}
      </Panel>
    </div>
  )
}

function ChatSection(): React.ReactElement {
  const notifications = useSpacesStore((s) => s.notifications)
  const activity = useSpacesStore((s) => s.workspaceActivity)
  const chatNotes = notifications.filter((n) => n.kind.includes('chat') || n.kind.includes('message'))
  const chatActivity = activity.filter(
    (a) => a.entityType === 'message' || a.action.toLowerCase().includes('message')
  )
  const hasItems = chatNotes.length > 0 || chatActivity.length > 0

  return (
    <div className="space-y-4 p-6">
      <SectionHeader
        title="Chat"
        description="Recent messaging activity in this workspace. Full chat runs in the Publshr macOS IDE."
        icon={MessageSquare}
      />
      {!hasItems ? (
        <p className="text-sm text-ink-muted">
          No chat notifications in Spaces cache. Open Publshr on macOS for live channels and threads.
        </p>
      ) : (
        <ul className="space-y-2">
          {chatNotes.map((n) => (
            <li key={n.id} className="rounded-lg border border-surface-border px-3 py-2 text-sm">
              <p className="font-medium text-ink">{n.title}</p>
              <p className="text-xs text-ink-muted">{n.body}</p>
            </li>
          ))}
          {chatActivity.map((a) => (
            <li key={a.id} className="rounded-lg border border-surface-border px-3 py-2 text-sm">
              <p className="text-ink">
                <span className="font-medium">{a.userName}</span> {a.action}
              </p>
              <p className="text-xs text-ink-muted">{a.spaceName}</p>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

function PlannerSection(): React.ReactElement {
  const tasks = useSpacesStore((s) => s.workspaceTasks)
  const withDates = tasks.filter((t) => t.dueDate || t.startDate)

  return (
    <div className="space-y-4 p-6">
      <SectionHeader
        title="Planner"
        description="Scheduled work from Spaces tasks. Use the Planner desktop app for editorial calendars."
      />
      {withDates.length === 0 ? (
        <p className="text-sm text-ink-muted">No dated tasks. Add due dates on tasks to see them here.</p>
      ) : (
        <ul className="space-y-2">
          {withDates.slice(0, 30).map((t) => (
            <li
              key={t.id}
              className="flex items-center justify-between rounded-lg border border-surface-border px-3 py-2 text-sm"
            >
              <span className="font-medium text-ink">{t.title}</span>
              <span className="text-xs text-ink-muted">
                {t.dueDate ? format(new Date(t.dueDate), 'MMM d, yyyy') : '—'} · {t.spaceName}
              </span>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

function MediaSection(): React.ReactElement {
  const spaces = useSpacesStore((s) => s.spaces)
  const mediaSpaces = spaces.filter((s) => s.type === 'publication' || s.name.toLowerCase().includes('media'))

  return (
    <div className="space-y-4 p-6">
      <SectionHeader
        title="Media Monitoring"
        description="Coverage operations linked to Spaces. Use the Media Monitoring desktop app for live feeds."
        icon={Radio}
      />
      {mediaSpaces.length === 0 ? (
        <p className="text-sm text-ink-muted">
          No publication Spaces yet. Create a publication-type Space or open Media Monitoring.
        </p>
      ) : (
        <ul className="space-y-2">
          {mediaSpaces.map((s) => (
            <li key={s.id} className="rounded-lg border border-surface-border px-3 py-2 text-sm">
              <p className="font-medium text-ink">{s.name}</p>
              <p className="text-xs capitalize text-ink-muted">{s.type}</p>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

function SettingsSection(): React.ReactElement {
  const workspace = useSpacesStore((s) => s.workspace)
  const syncStatus = useSpacesStore((s) => s.syncStatus)
  const loadWorkspaceData = useSpacesStore((s) => s.loadWorkspaceData)

  const SyncIcon = syncStatus === 'online' || syncStatus === 'syncing' ? Cloud : CloudOff

  return (
    <div className="max-w-lg space-y-6 p-6">
      <SectionHeader title="Settings" description="Workspace preferences and sync." />
      <div className="library-card space-y-4 p-4">
        <div>
          <p className="text-xs font-medium uppercase text-ink-muted">Workspace</p>
          <p className="mt-1 text-sm font-medium text-ink">{workspace?.name ?? '—'}</p>
          <p className="text-xs text-ink-muted">{workspace?.id}</p>
        </div>
        <div className="flex items-center gap-2">
          <SyncIcon className="h-4 w-4 text-ink-muted" />
          <span className="text-sm capitalize text-ink">Sync: {syncStatus}</span>
        </div>
        <button
          type="button"
          className="rounded-lg border border-surface-border px-3 py-1.5 text-xs text-ink-secondary hover:bg-surface-muted"
          onClick={() => void loadWorkspaceData()}
        >
          Refresh workspace data
        </button>
      </div>
    </div>
  )
}

function SectionHeader({
  title,
  description,
  action,
  icon: Icon
}: {
  title: string
  description: string
  action?: React.ReactNode
  icon?: React.ComponentType<{ className?: string }>
}): React.ReactElement {
  return (
    <header className="flex flex-wrap items-start justify-between gap-3">
      <div>
        <h1 className="flex items-center gap-2 text-xl font-semibold text-ink">
          {Icon && <Icon className="h-5 w-5 text-accent" />}
          {title}
        </h1>
        <p className="mt-1 max-w-2xl text-sm text-ink-secondary">{description}</p>
      </div>
      {action}
    </header>
  )
}

function EntityList<T>({
  items,
  empty,
  render
}: {
  items: T[]
  empty: string
  render: (item: T) => React.ReactNode
}): React.ReactElement {
  if (items.length === 0) return <p className="text-sm text-ink-muted">{empty}</p>
  return <ul className="space-y-2">{items.map((item, i) => <li key={i}>{render(item)}</li>)}</ul>
}

function Metric({
  label,
  value,
  warn,
  onClick
}: {
  label: string
  value: number
  warn?: boolean
  onClick?: () => void
}): React.ReactElement {
  const inner = (
    <>
      <span className="text-[11px] font-medium uppercase tracking-wide text-ink-muted">{label}</span>
      <p className={clsx('mt-2 text-2xl font-semibold', warn ? 'text-status-blocked' : 'text-ink')}>{value}</p>
    </>
  )
  if (onClick) {
    return (
      <button type="button" onClick={onClick} className="library-card library-masonry-item text-left hover:ring-2 hover:ring-accent/10">
        {inner}
      </button>
    )
  }
  return <div className="library-card library-masonry-item">{inner}</div>
}

function Panel({ title, children }: { title: string; children: React.ReactNode }): React.ReactElement {
  return (
    <section className="library-card p-4">
      <h2 className="mb-3 text-xs font-semibold uppercase tracking-wide text-ink-muted">{title}</h2>
      {children}
    </section>
  )
}

function Row({ label, value }: { label: string; value: string }): React.ReactElement {
  return (
    <div className="flex justify-between">
      <span className="text-ink-muted">{label}</span>
      <span className="font-medium text-ink">{value}</span>
    </div>
  )
}

function ApprovalBadge({
  status,
  spaceName
}: {
  status: Approval['status']
  spaceName: string
}): React.ReactElement {
  return (
    <span className="flex items-center gap-2 text-xs">
      <span
        className={clsx(
          'rounded px-1.5 py-0.5 capitalize',
          status === 'approved' && 'bg-status-approved/15 text-status-approved',
          status === 'rejected' && 'bg-status-blocked/15 text-status-blocked',
          (status === 'requested' || status === 'in_review') && 'bg-accent-soft text-accent'
        )}
      >
        {status.replace(/_/g, ' ')}
      </span>
      <span className="text-ink-muted">{spaceName}</span>
    </span>
  )
}
