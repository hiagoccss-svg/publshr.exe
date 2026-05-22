import clsx from 'clsx'
import { isPast, isWithinInterval, addDays } from 'date-fns'
import { useSpacesStore } from '../../stores/spaces-store'
import type { Task } from '../../../shared/types'

const QUADRANTS = [
  { id: 'do', title: 'Do first', subtitle: 'Urgent · due soon', className: 'border-red-200/80 bg-red-50/50' },
  { id: 'schedule', title: 'Schedule', subtitle: 'Important · not urgent', className: 'border-amber-200/80 bg-amber-50/50' },
  { id: 'delegate', title: 'Delegate', subtitle: 'Urgent · lower priority', className: 'border-sky-200/80 bg-sky-50/50' },
  { id: 'later', title: 'Later', subtitle: 'Low urgency', className: 'border-surface-border bg-surface-muted/30' }
] as const

/** ClickUp-style priority matrix (Eisenhower quadrants by priority + due date). */
export function PriorityMatrixView(): React.ReactElement {
  const tasks = useSpacesStore((s) => s.tasks)
  const setSelectedTask = useSpacesStore((s) => s.setSelectedTask)

  const open = tasks.filter((t) => t.status !== 'completed' && t.status !== 'archived')
  const buckets: Record<(typeof QUADRANTS)[number]['id'], Task[]> = {
    do: [],
    schedule: [],
    delegate: [],
    later: []
  }

  const now = new Date()
  const soonEnd = addDays(now, 7)

  for (const task of open) {
    buckets[classify(task, now, soonEnd)].push(task)
  }

  return (
    <div className="grid h-full min-h-[360px] grid-cols-2 grid-rows-2 gap-3">
      {QUADRANTS.map((q) => (
        <section
          key={q.id}
          className={clsx('flex flex-col overflow-hidden rounded-xl border', q.className)}
        >
          <header className="border-b border-surface-border/50 px-3 py-2">
            <h3 className="text-xs font-semibold text-ink">{q.title}</h3>
            <p className="text-[10px] text-ink-muted">{q.subtitle}</p>
          </header>
          <ul className="flex-1 space-y-1 overflow-y-auto p-2">
            {buckets[q.id].map((t) => (
              <li key={t.id}>
                <button
                  type="button"
                  onClick={() => void setSelectedTask(t.id)}
                  className="w-full rounded-lg bg-surface/80 px-2 py-1.5 text-left text-xs hover:bg-surface"
                >
                  <span className="font-medium text-ink">{t.title}</span>
                  {t.dueDate && (
                    <span className="mt-0.5 block text-[10px] text-ink-muted">
                      Due {t.dueDate.slice(0, 10)}
                    </span>
                  )}
                </button>
              </li>
            ))}
            {buckets[q.id].length === 0 && (
              <li className="py-6 text-center text-[10px] text-ink-muted">Empty</li>
            )}
          </ul>
        </section>
      ))}
    </div>
  )
}

function classify(task: Task, now: Date, soonEnd: Date): (typeof QUADRANTS)[number]['id'] {
  const urgent = task.priority === 'urgent' || task.priority === 'high'
  const due = task.dueDate ? new Date(task.dueDate) : null
  const dueSoon = due && (isPast(due) || isWithinInterval(due, { start: now, end: soonEnd }))

  if (urgent && dueSoon) return 'do'
  if (urgent) return 'delegate'
  if (dueSoon || task.priority === 'normal') return 'schedule'
  return 'later'
}
