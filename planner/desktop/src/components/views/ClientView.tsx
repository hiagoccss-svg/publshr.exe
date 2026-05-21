import { useFilteredItems } from '@/stores/plannerStore'
import { formatShortDate } from '@/lib/utils'

export default function ClientView() {
  const items = useFilteredItems().filter(
    (i) => i.status !== 'idea' && i.type !== 'internal_task'
  )

  return (
    <div className="h-full overflow-auto p-8">
      <div className="mx-auto max-w-3xl">
        <p className="text-xs font-medium uppercase tracking-widest text-ink-muted">Client-safe view</p>
        <h2 className="mt-2 font-display text-2xl font-semibold text-ink">Campaign timeline</h2>
        <p className="mt-2 text-sm text-ink-secondary">
          Internal notes, private comments, and sensitive files are hidden in this view.
        </p>
        <ul className="mt-8 divide-y divide-surface-border">
          {items.map((item) => (
            <li key={item.id} className="flex items-center justify-between py-4">
              <div>
                <p className="font-medium text-ink">{item.title}</p>
                <p className="text-xs capitalize text-ink-muted">{item.status.replace(/_/g, ' ')}</p>
              </div>
              <div className="text-right text-xs text-ink-secondary">
                <p>Publish {formatShortDate(item.publish_date)}</p>
                <p>Due {formatShortDate(item.due_date)}</p>
              </div>
            </li>
          ))}
          {items.length === 0 && (
            <li className="py-8 text-center text-sm text-ink-muted">No client-visible items yet.</li>
          )}
        </ul>
      </div>
    </div>
  )
}
