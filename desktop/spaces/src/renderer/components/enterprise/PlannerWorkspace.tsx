import { format, isPast, isThisWeek, parseISO } from 'date-fns'
import { Calendar } from 'lucide-react'
import clsx from 'clsx'
import { useMemo } from 'react'
import { useSpacesStore } from '../../stores/spaces-store'

/** Planner hub — dated tasks from all Spaces (editorial calendar preview). */
export function PlannerWorkspace(): React.ReactElement {
  const tasks = useSpacesStore((s) => s.workspaceTasks)
  const setActiveSpace = useSpacesStore((s) => s.setActiveSpace)
  const setSelectedTask = useSpacesStore((s) => s.setSelectedTask)
  const setActiveSection = useSpacesStore((s) => s.setActiveSection)

  const dated = useMemo(
    () =>
      tasks
        .filter((t) => t.dueDate || t.startDate)
        .sort((a, b) => {
          const ad = a.dueDate ?? a.startDate ?? ''
          const bd = b.dueDate ?? b.startDate ?? ''
          return ad.localeCompare(bd)
        }),
    [tasks]
  )

  const thisWeek = dated.filter((t) => t.dueDate && isThisWeek(parseISO(t.dueDate)))
  const overdue = dated.filter(
    (t) => t.dueDate && isPast(parseISO(t.dueDate)) && t.status !== 'completed'
  )

  return (
    <div className="space-y-6 p-6">
      <header>
        <h1 className="flex items-center gap-2 text-xl font-semibold text-ink">
          <Calendar className="h-5 w-5 text-accent" />
          Planner
        </h1>
        <p className="mt-1 text-sm text-ink-secondary">
          Scheduled work pulled from Spaces tasks. Connect Supabase to sync editorial calendars across teams.
        </p>
      </header>

      <div className="library-masonry library-masonry-responsive">
        <Stat label="Dated tasks" value={dated.length} />
        <Stat label="Due this week" value={thisWeek.length} />
        <Stat label="Overdue" value={overdue.length} warn={overdue.length > 0} />
      </div>

      <section className="library-card overflow-hidden">
        <h2 className="border-b border-surface-border px-4 py-2 text-xs font-semibold uppercase tracking-wide text-ink-muted">
          Schedule
        </h2>
        {dated.length === 0 ? (
          <p className="p-4 text-sm text-ink-muted">Add due dates on tasks in Spaces to populate the planner.</p>
        ) : (
          <ul>
            {dated.map((t) => {
              const due = t.dueDate ? parseISO(t.dueDate) : null
              const late = due && isPast(due) && t.status !== 'completed'
              return (
                <li key={t.id} className="border-b border-surface-border last:border-0">
                  <button
                    type="button"
                    className="flex w-full items-center justify-between gap-3 px-4 py-3 text-left hover:bg-surface-muted"
                    onClick={() => {
                      setActiveSection('spaces')
                      void setActiveSpace(t.spaceId)
                      void setSelectedTask(t.id)
                    }}
                  >
                    <div className="min-w-0">
                      <p className="truncate text-sm font-medium text-ink">{t.title}</p>
                      <p className="truncate text-xs text-ink-muted">{t.spaceName}</p>
                    </div>
                    <span
                      className={clsx(
                        'shrink-0 text-xs',
                        late ? 'font-medium text-status-blocked' : 'text-ink-muted'
                      )}
                    >
                      {due ? format(due, 'MMM d, yyyy') : '—'}
                    </span>
                  </button>
                </li>
              )
            })}
          </ul>
        )}
      </section>
    </div>
  )
}

function Stat({
  label,
  value,
  warn
}: {
  label: string
  value: number
  warn?: boolean
}): React.ReactElement {
  return (
    <div className="library-card library-masonry-item">
      <span className="text-[11px] font-medium uppercase tracking-wide text-ink-muted">{label}</span>
      <p className={clsx('mt-2 text-2xl font-semibold', warn ? 'text-status-blocked' : 'text-ink')}>
        {value}
      </p>
    </div>
  )
}
