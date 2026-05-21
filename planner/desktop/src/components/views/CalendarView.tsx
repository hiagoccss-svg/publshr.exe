import { useMemo } from 'react'
import {
  format,
  startOfMonth,
  endOfMonth,
  eachDayOfInterval,
  isSameMonth,
  isToday,
} from 'date-fns'
import { useFilteredItems, usePlannerStore } from '@/stores/plannerStore'
import { TYPE_COLORS } from '@/types/planner'
import { cn } from '@/lib/utils'

export default function CalendarView() {
  const items = useFilteredItems()
  const mode = usePlannerStore((s) => s.calendarMode)
  const setSelectedId = usePlannerStore((s) => s.setSelectedId)

  const monthStart = startOfMonth(new Date())
  const days = eachDayOfInterval({ start: monthStart, end: endOfMonth(monthStart) })

  const byDate = useMemo(() => {
    const map = new Map<string, typeof items>()
    for (const item of items) {
      const key = item.publish_date ?? item.due_date
      if (!key) continue
      const list = map.get(key) ?? []
      list.push(item)
      map.set(key, list)
    }
    return map
  }, [items])

  if (mode !== 'month') {
    return (
      <div className="flex h-full items-center justify-center text-sm text-ink-muted">
        {mode.charAt(0).toUpperCase() + mode.slice(1)} view — switch to Month in the top bar (full layout in Phase 2).
      </div>
    )
  }

  return (
    <div className="h-full overflow-auto p-4">
      <div className="mb-4 grid grid-cols-7 gap-1 text-center text-[10px] font-medium uppercase text-ink-muted">
        {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => (
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
              <div className="mt-1 space-y-0.5">
                {dayItems.slice(0, 3).map((item) => (
                  <button
                    key={item.id}
                    type="button"
                    onClick={() => setSelectedId(item.id)}
                    className="block w-full truncate rounded px-1 py-0.5 text-left text-[9px] text-white"
                    style={{ backgroundColor: TYPE_COLORS[item.type] }}
                  >
                    {item.title}
                  </button>
                ))}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
