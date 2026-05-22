import { format, formatDistanceToNow, isPast } from 'date-fns'
import { AlertCircle, CheckCircle2, Clock, FileText, Users } from 'lucide-react'
import { useSpacesStore } from '../../stores/spaces-store'
import { getSpacesAPI } from '../../lib/api'

export function SpaceOverview(): React.ReactElement {
  const spaces = useSpacesStore((s) => s.spaces)
  const activeSpaceId = useSpacesStore((s) => s.activeSpaceId)
  const tasks = useSpacesStore((s) => s.tasks)
  const members = useSpacesStore((s) => s.members)
  const activity = useSpacesStore((s) => s.activity)
  const approvals = useSpacesStore((s) => s.approvals)
  const documents = useSpacesStore((s) => s.documents)
  const files = useSpacesStore((s) => s.files)
  const setTaskView = useSpacesStore((s) => s.setTaskView)
  const setSelectedTask = useSpacesStore((s) => s.setSelectedTask)

  const space = spaces.find((s) => s.id === activeSpaceId)
  const openTasks = tasks.filter((t) => t.status !== 'completed' && t.status !== 'archived')
  const overdue = openTasks.filter((t) => t.dueDate && isPast(new Date(t.dueDate)))
  const pendingApprovals = approvals.filter((a) => a.status === 'requested' || a.status === 'in_review')
  const upcoming = [...openTasks]
    .filter((t) => t.dueDate)
    .sort((a, b) => new Date(a.dueDate!).getTime() - new Date(b.dueDate!).getTime())
    .slice(0, 5)

  if (!space) return <p className="text-sm text-ink-muted">Select a Space.</p>

  return (
    <div className="animate-fade-in space-y-4">
      <header className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-xl font-semibold tracking-tight text-ink">{space.name}</h1>
          <p className="mt-1 max-w-2xl text-sm text-ink-secondary">
            {space.description || 'Operational workspace — projects, campaigns, and deliverables.'}
          </p>
          <div className="mt-2 flex gap-2 text-xs text-ink-muted">
            <span className="rounded bg-surface-muted px-2 py-0.5 capitalize">{space.type}</span>
            <span className="rounded bg-surface-muted px-2 py-0.5 capitalize">{space.status}</span>
          </div>
        </div>
        <button
          type="button"
          onClick={() => getSpacesAPI().openSpaceWindow(space.id)}
          className="rounded-lg border border-surface-border px-3 py-1.5 text-xs text-ink-secondary hover:bg-surface-muted"
        >
          Open in new window
        </button>
      </header>

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <MetricCard label="Open tasks" value={openTasks.length} icon={CheckCircle2} />
        <MetricCard label="Overdue" value={overdue.length} icon={AlertCircle} warn={overdue.length > 0} />
        <MetricCard label="Approvals waiting" value={pendingApprovals.length} icon={Clock} />
        <MetricCard label="Team" value={members.length} icon={Users} />
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <Panel title="Key deadlines" className="lg:col-span-1">
          {upcoming.length === 0 ? (
            <p className="text-xs text-ink-muted">No upcoming deadlines.</p>
          ) : (
            <ul className="space-y-2">
              {upcoming.map((t) => (
                <li key={t.id}>
                  <button
                    type="button"
                    onClick={() => {
                      setSelectedTask(t.id)
                      setTaskView('list')
                    }}
                    className="flex w-full items-center justify-between rounded-lg px-2 py-1 text-left text-xs hover:bg-surface-muted"
                  >
                    <span className="truncate font-medium text-ink">{t.title}</span>
                    <span className="shrink-0 text-ink-muted">
                      {format(new Date(t.dueDate!), 'MMM d')}
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </Panel>

        <Panel title="Active tasks" className="lg:col-span-1">
          {openTasks.slice(0, 6).map((t) => (
            <button
              key={t.id}
              type="button"
              onClick={() => setSelectedTask(t.id)}
              className="mb-1 block w-full truncate rounded-lg px-2 py-1 text-left text-xs text-ink hover:bg-surface-muted"
            >
              {t.title}
            </button>
          ))}
          {openTasks.length === 0 && <p className="text-xs text-ink-muted">No active tasks.</p>}
        </Panel>

        <Panel title="Latest activity" className="lg:col-span-1">
          {activity.slice(0, 6).map((a) => (
            <p key={a.id} className="mb-1 text-xs text-ink-secondary">
              <span className="font-medium text-ink">{a.userName}</span> {a.action}
              <span className="block text-[10px] text-ink-muted">
                {formatDistanceToNow(new Date(a.createdAt), { addSuffix: true })}
              </span>
            </p>
          ))}
          {activity.length === 0 && <p className="text-xs text-ink-muted">No activity yet.</p>}
        </Panel>
      </div>

      <div className="grid gap-3 md:grid-cols-2">
        <Panel title="Documents" icon={FileText}>
          {documents.length === 0 ? (
            <p className="text-xs text-ink-muted">No documents yet.</p>
          ) : (
            documents.map((d) => (
              <button
                key={d.id}
                type="button"
                onClick={() => getSpacesAPI().openDocumentWindow(d.id, d.title)}
                className="block text-xs text-accent hover:underline"
              >
                {d.title}
              </button>
            ))
          )}
        </Panel>
        <Panel title="Recent files">
          {files.length === 0 ? (
            <p className="text-xs text-ink-muted">No files uploaded.</p>
          ) : (
            files.slice(0, 5).map((f) => (
              <p key={f.id} className="truncate text-xs text-ink-secondary">
                {f.fileName}
              </p>
            ))
          )}
        </Panel>
      </div>
    </div>
  )
}

function MetricCard({
  label,
  value,
  icon: Icon,
  warn
}: {
  label: string
  value: number
  icon: React.ComponentType<{ className?: string }>
  warn?: boolean
}): React.ReactElement {
  return (
    <div className="rounded-xl border border-surface-border bg-surface-raised p-3 shadow-card">
      <div className="flex items-center justify-between">
        <span className="text-[11px] font-medium uppercase tracking-wide text-ink-muted">{label}</span>
        <Icon className={`h-4 w-4 ${warn ? 'text-status-blocked' : 'text-ink-muted'}`} />
      </div>
      <p className={`mt-2 text-2xl font-semibold ${warn ? 'text-status-blocked' : 'text-ink'}`}>{value}</p>
    </div>
  )
}

function Panel({
  title,
  children,
  className,
  icon: Icon
}: {
  title: string
  children: React.ReactNode
  className?: string
  icon?: React.ComponentType<{ className?: string }>
}): React.ReactElement {
  return (
    <section className={`rounded-xl border border-surface-border bg-surface-raised p-4 shadow-card ${className ?? ''}`}>
      <h2 className="mb-3 flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide text-ink-muted">
        {Icon && <Icon className="h-3.5 w-3.5" />}
        {title}
      </h2>
      {children}
    </section>
  )
}
