import { useMemo, useState } from 'react'
import { addMonths, eachDayOfInterval, endOfMonth, endOfWeek, format, isSameMonth, startOfMonth, startOfWeek, subMonths } from 'date-fns'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import clsx from 'clsx'
import { useSpacesStore } from '../../stores/spaces-store'

export function CalendarView(): React.ReactElement {
  const tasks = useSpacesStore((s) => s.tasks)
  const setSelectedTask = useSpacesStore((s) => s.setSelectedTask)
  const [month, setMonth] = useState(() => startOfMonth(new Date()))

  const days = useMemo(() => {
    const start = startOfWeek(startOfMonth(month), { weekStartsOn: 1 })
    const end = endOfWeek(endOfMonth(month), { weekStartsOn: 1 })
    return eachDayOfInterval({ start, end })
  }, [month])

  const tasksByDay = useMemo(() => {
    const map = new Map<string, typeof tasks>()
    for (const task of tasks) {
      if (!task.dueDate) continue
      const key = task.dueDate.slice(0, 10)
      const list = map.get(key) ?? []
      list.push(task)
      map.set(key, list)
    }
    return map
  }, [tasks])

  return (
    <div className="flex h-full flex-col">
      <div className="mb-4 flex items-center gap-2">
        <button
          type="button"
          onClick={() => setMonth((m) => subMonths(m, 1))}
          className="rounded p-1 text-ink-muted hover:bg-surface-muted"
        >
          <ChevronLeft className="h-4 w-4" />
        </button>
        <h2 className="min-w-[140px] text-center text-sm font-semibold text-ink">{format(month, 'MMMM yyyy')}</h2>
        <button
          type="button"
          onClick={() => setMonth((m) => addMonths(m, 1))}
          className="rounded p-1 text-ink-muted hover:bg-surface-muted"
        >
          <ChevronRight className="h-4 w-4" />
        </button>
      </div>

      <div className="grid grid-cols-7 gap-1 text-center text-[10px] font-semibold uppercase text-ink-muted">
        {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => (
          <div key={d}>{d}</div>
        ))}
      </div>

      <div className="mt-1 grid flex-1 auto-rows-fr grid-cols-7 gap-1">
        {days.map((day) => {
          const key = format(day, 'yyyy-MM-dd')
          const dayTasks = tasksByDay.get(key) ?? []
          const inMonth = isSameMonth(day, month)
          return (
            <div
              key={key}
              className={clsx(
                'min-h-[72px] rounded-lg border border-surface-border p-1.5 text-left',
                inMonth ? 'bg-surface-raised' : 'bg-surface-raised/40 opacity-60'
              )}
            >
              <span className="text-[11px] font-medium text-ink-secondary">{format(day, 'd')}</span>
              <div className="mt-1 space-y-0.5">
                {dayTasks.slice(0, 3).map((t) => (
                  <button
                    key={t.id}
                    type="button"
                    onClick={() => void setSelectedTask(t.id)}
                    className="block w-full truncate rounded bg-accent-soft px-1 py-0.5 text-left text-[9px] text-accent hover:bg-accent/20"
                  >
                    {t.title}
                  </button>
                ))}
                {dayTasks.length > 3 && (
                  <span className="text-[9px] text-ink-muted">+{dayTasks.length - 3} more</span>
                )}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
