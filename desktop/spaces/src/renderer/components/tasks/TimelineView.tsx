import { useMemo, useState } from 'react'
import {
  addDays,
  addWeeks,
  differenceInCalendarDays,
  format,
  parseISO,
  startOfWeek,
  subWeeks
} from 'date-fns'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import clsx from 'clsx'
import { useSpacesStore } from '../../stores/spaces-store'
import type { Task } from '../../../shared/types'

const DAY_WIDTH = 28
const ROW_HEIGHT = 36

/** ClickUp Timeline / Gantt — tasks plotted from start to due date. */
export function TimelineView(): React.ReactElement {
  const tasks = useSpacesStore((s) => s.tasks)
  const setSelectedTask = useSpacesStore((s) => s.setSelectedTask)
  const [anchor, setAnchor] = useState(() => startOfWeek(new Date(), { weekStartsOn: 1 }))

  const rangeStart = anchor
  const rangeEnd = addWeeks(anchor, 6)
  const totalDays = differenceInCalendarDays(rangeEnd, rangeStart) + 1

  const dayHeaders = useMemo(() => {
    const days: Date[] = []
    for (let i = 0; i < totalDays; i++) days.push(addDays(rangeStart, i))
    return days
  }, [rangeStart, totalDays])

  const scheduled = useMemo(
    () =>
      tasks
        .filter((t) => t.status !== 'archived')
        .map((t) => ({ task: t, span: taskSpan(t, rangeStart, rangeEnd) }))
        .filter((x) => x.span !== null) as { task: Task; span: { left: number; width: number } }[],
    [tasks, rangeStart, rangeEnd]
  )

  const unscheduled = tasks.filter(
    (t) => t.status !== 'archived' && !taskSpan(t, rangeStart, rangeEnd)
  )

  return (
    <div className="flex h-full min-h-[360px] flex-col overflow-hidden rounded-xl border border-surface-border bg-surface-raised shadow-card">
      <div className="flex items-center gap-2 border-b border-surface-border px-3 py-2">
        <button
          type="button"
          onClick={() => setAnchor((a) => subWeeks(a, 2))}
          className="rounded p-1 text-ink-muted hover:bg-surface-muted"
        >
          <ChevronLeft className="h-4 w-4" />
        </button>
        <span className="text-xs font-medium text-ink">
          {format(rangeStart, 'MMM d')} – {format(rangeEnd, 'MMM d, yyyy')}
        </span>
        <button
          type="button"
          onClick={() => setAnchor((a) => addWeeks(a, 2))}
          className="rounded p-1 text-ink-muted hover:bg-surface-muted"
        >
          <ChevronRight className="h-4 w-4" />
        </button>
        <span className="ml-auto text-[10px] text-ink-muted">Drag dates in task details to schedule</span>
      </div>

      <div className="flex min-h-0 flex-1 overflow-auto">
        <div className="sticky left-0 z-10 w-48 shrink-0 border-r border-surface-border bg-surface-raised">
          <div className="h-8 border-b border-surface-border px-2 text-[10px] font-semibold uppercase text-ink-muted">
            Task
          </div>
          {scheduled.map(({ task }) => (
            <div
              key={task.id}
              className="truncate border-b border-surface-border/50 px-2 text-xs text-ink"
              style={{ height: ROW_HEIGHT, lineHeight: `${ROW_HEIGHT}px` }}
            >
              {task.title}
            </div>
          ))}
        </div>

        <div className="min-w-0 flex-1">
          <div className="flex h-8 border-b border-surface-border">
            {dayHeaders.map((d) => (
              <div
                key={d.toISOString()}
                className="shrink-0 border-r border-surface-border/40 text-center text-[9px] text-ink-muted"
                style={{ width: DAY_WIDTH }}
              >
                {format(d, 'd')}
              </div>
            ))}
          </div>
          <div className="relative" style={{ width: totalDays * DAY_WIDTH }}>
            {scheduled.map(({ task, span }) => (
              <div
                key={task.id}
                className="relative border-b border-surface-border/40"
                style={{ height: ROW_HEIGHT }}
              >
                <button
                  type="button"
                  onClick={() => void setSelectedTask(task.id)}
                  className={clsx(
                    'absolute top-2 h-5 rounded px-1.5 text-left text-[10px] font-medium text-white',
                    task.priority === 'urgent' ? 'bg-red-500' : task.priority === 'high' ? 'bg-amber-600' : 'bg-accent'
                  )}
                  style={{ left: span.left, width: Math.max(span.width, 48) }}
                  title={task.title}
                >
                  <span className="block truncate">{task.title}</span>
                </button>
              </div>
            ))}
          </div>
        </div>
      </div>

      {unscheduled.length > 0 && (
        <div className="border-t border-surface-border bg-surface-muted/30 px-3 py-2">
          <p className="text-[10px] font-semibold uppercase text-ink-muted">Unscheduled ({unscheduled.length})</p>
          <div className="mt-1 flex flex-wrap gap-1">
            {unscheduled.slice(0, 12).map((t) => (
              <button
                key={t.id}
                type="button"
                onClick={() => void setSelectedTask(t.id)}
                className="rounded bg-surface px-2 py-0.5 text-[10px] text-ink-secondary hover:bg-surface-muted"
              >
                {t.title}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

function taskSpan(
  task: Task,
  rangeStart: Date,
  rangeEnd: Date
): { left: number; width: number } | null {
  const start = task.startDate ? parseISO(task.startDate.slice(0, 10)) : task.dueDate ? parseISO(task.dueDate.slice(0, 10)) : null
  const end = task.dueDate ? parseISO(task.dueDate.slice(0, 10)) : start
  if (!start || !end) return null

  const barStart = start < rangeStart ? rangeStart : start
  const barEnd = end > rangeEnd ? rangeEnd : end
  if (barEnd < rangeStart || barStart > rangeEnd) return null

  const leftDays = differenceInCalendarDays(barStart, rangeStart)
  const widthDays = differenceInCalendarDays(barEnd, barStart) + 1
  return { left: leftDays * DAY_WIDTH, width: widthDays * DAY_WIDTH }
}
