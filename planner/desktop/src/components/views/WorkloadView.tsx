import { useMemo } from 'react'
import { useFilteredItems } from '@/stores/plannerStore'
import { formatShortDate, isOverdue } from '@/lib/utils'

export default function WorkloadView() {
  const items = useFilteredItems()

  const byOwner = useMemo(() => {
    const map = new Map<string, typeof items>()
    for (const item of items) {
      const key = item.owner_id ?? 'unassigned'
      const list = map.get(key) ?? []
      list.push(item)
      map.set(key, list)
    }
    return map
  }, [items])

  return (
    <div className="h-full overflow-auto p-6">
      <h2 className="text-sm font-semibold text-ink">Team workload</h2>
      <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {[...byOwner.entries()].map(([owner, ownerItems]) => {
          const overdue = ownerItems.filter(isOverdue).length
          const level = ownerItems.length > 8 ? 'high' : ownerItems.length > 4 ? 'medium' : 'light'
          return (
            <article key={owner} className="rounded-xl border border-surface-border bg-surface-raised p-4">
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium text-ink">{owner === 'unassigned' ? 'Unassigned' : owner.slice(0, 8)}</span>
                <span
                  className={`rounded-full px-2 py-0.5 text-[10px] capitalize ${
                    level === 'high'
                      ? 'bg-status-overdue/10 text-status-overdue'
                      : level === 'medium'
                        ? 'bg-status-approval/10 text-status-approval'
                        : 'bg-accent-soft text-accent'
                  }`}
                >
                  {level} load
                </span>
              </div>
              <p className="mt-2 text-[10px] text-ink-muted">
                {ownerItems.length} items · {overdue} overdue
              </p>
              <ul className="mt-3 max-h-40 space-y-1 overflow-y-auto">
                {ownerItems.map((item) => (
                  <li key={item.id} className="truncate text-xs text-ink-secondary">
                    {item.title}
                    <span className="text-ink-muted"> · {formatShortDate(item.due_date)}</span>
                  </li>
                ))}
              </ul>
            </article>
          )
        })}
      </div>
    </div>
  )
}
