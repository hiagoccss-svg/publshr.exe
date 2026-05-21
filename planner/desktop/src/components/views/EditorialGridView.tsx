import { useFilteredItems, usePlannerStore } from '@/stores/plannerStore'
import { PLANNER_ITEM_TYPE_LABELS } from '@/types/planner'
import { formatShortDate } from '@/lib/utils'

export default function EditorialGridView() {
  const items = useFilteredItems()
  const setSelectedId = usePlannerStore((s) => s.setSelectedId)

  return (
    <div className="h-full overflow-auto">
      <table className="w-full min-w-[900px] border-collapse text-left text-sm">
        <thead className="sticky top-0 z-10 bg-surface/95 backdrop-blur-sm">
          <tr className="border-b border-surface-border text-[10px] font-semibold uppercase tracking-wider text-ink-muted">
            <th className="px-4 py-3 font-medium">Title</th>
            <th className="px-3 py-3">Type</th>
            <th className="px-3 py-3">Status</th>
            <th className="px-3 py-3">Priority</th>
            <th className="px-3 py-3">Deadline</th>
            <th className="px-3 py-3">Publish</th>
            <th className="px-3 py-3">Draft</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item) => (
            <tr
              key={item.id}
              onClick={() => setSelectedId(item.id)}
              className="cursor-pointer border-b border-surface-border/50 transition hover:bg-surface-muted/40"
            >
              <td className="px-4 py-2.5 font-medium text-ink">{item.title}</td>
              <td className="px-3 py-2.5 text-xs text-ink-secondary">
                {PLANNER_ITEM_TYPE_LABELS[item.type]}
              </td>
              <td className="px-3 py-2.5 text-xs capitalize text-ink-muted">
                {item.status.replace(/_/g, ' ')}
              </td>
              <td className="px-3 py-2.5 text-xs capitalize">{item.priority}</td>
              <td className="px-3 py-2.5 text-xs">{formatShortDate(item.due_date)}</td>
              <td className="px-3 py-2.5 text-xs">{formatShortDate(item.publish_date)}</td>
              <td className="px-3 py-2.5 text-xs text-accent">
                {item.editor_document_id ? 'Linked' : '—'}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
