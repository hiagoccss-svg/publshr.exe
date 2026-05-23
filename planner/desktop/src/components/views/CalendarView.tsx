import { useMemo } from 'react'
import {
  addDays,
  eachDayOfInterval,
  endOfMonth,
  endOfWeek,
  format,
  isSameMonth,
  isToday,
  startOfMonth,
  startOfWeek
} from 'date-fns'
import { useFilteredItems, usePlannerStore } from '@/stores/plannerStore'
import { TYPE_COLORS } from '@/types/planner'
import type { PlannerItem } from '@/types/planner'
import { cn } from '@/lib/utils'

const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

export default function CalendarView() {
  const items = useFilteredItems()
  const mode = usePlannerStore((s) => s.calendarMode)
  const setSelectedId = usePlannerStore((s) => s.setSelectedId)
  const today = new Date()

  const byDate = useMemo(() => {
    const map = new Map<string, PlannerItem[]>()
    for (const item of items) {
      const key = item.publish_date ?? item.due_date
      if (!key) continue
      const list = map.get(key) ?? []
      list.push(item)
      map.set(key, list)
    }
    return map
  }, [items])

  const renderItemChip = (item: PlannerItem) => (
    <button
      key={item.id}
      type="button"
      onClick={() => setSelectedId(item.id)}
      className="block w-full truncate rounded px-1 py-0.5 text-left text-[9px] text-white"
      style={{ backgroundColor: TYPE_COLORS[item.type] }}
    >
      {item.title}
    </button>
  )

  if (mode === 'day') {
    const key = format(today, 'yyyy-MM-dd')
    const dayItems = byDate.get(key) ?? []
    return (
      <div className="h-full overflow-auto p-4">
        <h2 className="mb-4 text-sm font-semibold text-ink">{format(today, 'EEEE, MMMM d, yyyy')}</h2>
        {dayItems.length === 0 ? (
          <p className="text-sm text-ink-muted">No items scheduled for today.</p>
        ) : (
          <ul className="space-y-2">
            {dayItems.map((item) => (
              <li
                key={item.id}
                className="flex items-center gap-3 rounded-lg border border-surface-border px-3 py-2"
              >
                <span
                  className="h-2 w-2 shrink-0 rounded-full"
                  style={{ backgroundColor: TYPE_COLORS[item.type] }}
                />
                <button type="button" className="text-left text-sm font-medium text-ink" onClick={() => setSelectedId(item.id)}>
                  {item.title}
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    )
  }

  if (mode === 'week') {
    const weekStart = startOfWeek(today, { weekStartsOn: 1 })
    const weekDays = eachDayOfInterval({ start: weekStart, end: addDays(weekStart, 6) })
    return (
      <div className="h-full overflow-auto p-4">
        <div className="mb-4 grid grid-cols-7 gap-2">
          {weekDays.map((day) => {
            const key = format(day, 'yyyy-MM-dd')
            const dayItems = byDate.get(key) ?? []
            return (
              <div
                key={key}
                className={cn(
                  'min-h-[120px] rounded-lg border border-surface-border/60 p-2',
                  isToday(day) && 'ring-1 ring-accent/30'
                )}
              >
                <p className={cn('text-[10px] font-medium', isToday(day) ? 'text-accent' : 'text-ink-muted')}>
                  {format(day, 'EEE d')}
                </p>
                <div className="mt-2 space-y-1">{dayItems.map(renderItemChip)}</div>
              </div>
            )
          })}
        </div>
      </div>
    )
  }

  if (mode === 'agenda') {
    const dated = items
      .filter((i) => i.publish_date ?? i.due_date)
      .sort((a, b) => {
        const da = a.publish_date ?? a.due_date ?? ''
        const db = b.publish_date ?? b.due_date ?? ''
        return da.localeCompare(db)
      })
    return (
      <div className="h-full overflow-auto p-4">
        {dated.length === 0 ? (
          <p className="text-sm text-ink-muted">No dated items in the planner.</p>
        ) : (
          <ul className="space-y-4">
            {dated.map((item) => {
              const dateKey = item.publish_date ?? item.due_date!
              return (
                <li key={item.id} className="flex gap-4 border-b border-surface-border/60 pb-3">
                  <time className="w-24 shrink-0 text-xs text-ink-muted">{format(new Date(dateKey), 'MMM d, yyyy')}</time>
                  <button
                    type="button"
                    className="text-left text-sm font-medium text-ink hover:text-accent"
                    onClick={() => setSelectedId(item.id)}
                  >
                    {item.title}
                  </button>
                </li>
              )
            })}
          </ul>
        )}
      </div>
    )
  }

  const monthStart = startOfMonth(today)
  const days = eachDayOfInterval({
    start: startOfWeek(monthStart, { weekStartsOn: 1 }),
    end: endOfWeek(endOfMonth(monthStart), { weekStartsOn: 1 })
  })

  return (
    <div className="h-full overflow-auto p-4">
      <div className="mb-4 grid grid-cols-7 gap-1 text-center text-[10px] font-medium uppercase text-ink-muted">
        {WEEKDAYS.map((d) => (
          <div key={d}>{d}</div>
        ))}
      </div>
      <div className="grid grid-cols-7 gap-1">
        {days.map((day) => {
          const key = format(day, 'yyyy-MM-dd')
          const dayItems = byDate.get(key) ?? []
          return (
            <div
              key={key}
              className={cn(
                'min-h-[88px] rounded-lg border border-surface-border/60 p-1.5',
                !isSameMonth(day, monthStart) && 'opacity-40',
                isToday(day) && 'ring-1 ring-accent/30'
              )}
            >
              <span className={cn('text-[10px]', isToday(day) && 'font-semibold text-accent')}>
                {format(day, 'd')}
              </span>
              <div className="mt-1 space-y-0.5">{dayItems.slice(0, 3).map(renderItemChip)}</div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
