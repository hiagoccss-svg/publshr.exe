import { useMemo } from 'react'
import { addDays, addWeeks, startOfWeek, format, parseISO, differenceInDays } from 'date-fns'
import { usePlannerStore, useFilteredItems } from '@/stores/plannerStore'
import PlannerCard from '../planner/PlannerCard'

const ZOOM_DAYS = { week: 14, month: 42, quarter: 120 } as const

export default function TimelineView() {
  const items = useFilteredItems()
  const selectedId = usePlannerStore((s) => s.selectedId)
  const setSelectedId = usePlannerStore((s) => s.setSelectedId)
  const zoom = usePlannerStore((s) => s.timelineZoom)
  const rangeStart = useMemo(() => startOfWeek(new Date(), { weekStartsOn: 1 }), [])
  const dayCount = ZOOM_DAYS[zoom]
  const days = useMemo(
    () => Array.from({ length: dayCount }, (_, i) => addDays(rangeStart, i)),
    [rangeStart, dayCount]
  )

  const openEditor = (item: (typeof items)[0]) => {
    if (item.editor_document_id && window.planner) {
      void window.planner.openEditorWindow(item.editor_document_id, item.id)
    }
  }

  return (
    <div className="flex h-full flex-col">
      <div className="flex-1 overflow-auto">
        <div className="min-w-max">
          <div className="sticky top-0 z-10 flex border-b border-surface-border bg-surface/95 backdrop-blur-sm">
            <div className="w-48 shrink-0 border-r border-surface-border px-3 py-2 text-[10px] font-medium uppercase tracking-wider text-ink-muted">
              Item
            </div>
            <div className="flex">
              {days.map((day) => (
                <div
                  key={day.toISOString()}
                  className="w-12 shrink-0 border-r border-surface-border/60 px-1 py-2 text-center text-[9px] text-ink-muted"
                >
                  <div>{format(day, 'EEE')}</div>
                  <div className="font-medium text-ink-secondary">{format(day, 'd')}</div>
                </div>
              ))}
            </div>
          </div>

          {items.map((item) => {
            const start = item.start_date ? parseISO(item.start_date) : item.due_date ? parseISO(item.due_date) : rangeStart
            const end = item.due_date ? parseISO(item.due_date) : addWeeks(start, 1)
            const offset = Math.max(0, differenceInDays(start, rangeStart))
            const span = Math.max(1, differenceInDays(end, start) + 1)
            const colStart = offset + 2
            const colSpan = Math.min(span, dayCount - offset)

            return (
              <div
                key={item.id}
                className="flex border-b border-surface-border/40 hover:bg-surface-muted/30"
              >
                <div className="w-48 shrink-0 border-r border-surface-border px-3 py-2">
                  <p className="truncate text-xs font-medium text-ink">{item.title}</p>
                  <p className="truncate text-[10px] capitalize text-ink-muted">{item.type.replace(/_/g, ' ')}</p>
                </div>
                <div
                  className="relative grid flex-1"
                  style={{ gridTemplateColumns: `repeat(${dayCount}, 3rem)` }}
                >
                  <div
                    className="absolute top-2 bottom-2 rounded-lg bg-accent/10 ring-1 ring-accent/20"
                    style={{
                      left: `${(colStart - 1) * 3}rem`,
                      width: `${colSpan * 3 - 0.25}rem`
                    }}
                  >
                    <div className="p-1">
                      <PlannerCard
                        item={item}
                        compact
                        selected={selectedId === item.id}
                        onSelect={() => setSelectedId(item.id)}
                        onOpenEditor={() => openEditor(item)}
                        onDoubleClick={() => openEditor(item)}
                      />
                    </div>
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      </div>
    </div>
  )
}
