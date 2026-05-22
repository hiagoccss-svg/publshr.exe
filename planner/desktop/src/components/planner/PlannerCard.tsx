import { FilePen, MessageCircle, Paperclip, AlertCircle } from 'lucide-react'
import type { PlannerItem } from '@/types/planner'
import { PLANNER_ITEM_TYPE_LABELS, TYPE_COLORS } from '@/types/planner'
import { cn, formatShortDate, isOverdue, initials } from '@/lib/utils'

type Props = {
  item: PlannerItem
  selected?: boolean
  compact?: boolean
  onSelect: () => void
  onOpenEditor?: () => void
  onDoubleClick?: () => void
}

export default function PlannerCard({
  item,
  selected,
  compact,
  onSelect,
  onOpenEditor,
  onDoubleClick
}: Props) {
  const overdue = isOverdue(item)
  const typeColor = TYPE_COLORS[item.type]

  return (
    <article
      role="button"
      tabIndex={0}
      onClick={onSelect}
      onDoubleClick={(e) => {
        e.stopPropagation()
        onDoubleClick?.()
      }}
      onKeyDown={(e) => e.key === 'Enter' && onSelect()}
      className={cn(
        'library-card group cursor-pointer transition hover:shadow-card',
        selected && 'ring-1 ring-accent/25',
        overdue && 'border-status-overdue/30'
      )}
      style={{ borderLeftWidth: 3, borderLeftColor: typeColor }}
    >
      <div className="flex items-start justify-between gap-2">
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-medium text-ink">{item.title}</p>
          {!compact && (
            <p className="mt-0.5 text-[10px] text-ink-muted">
              {PLANNER_ITEM_TYPE_LABELS[item.type]}
            </p>
          )}
        </div>
        {overdue && <AlertCircle className="h-3.5 w-3.5 shrink-0 text-status-overdue" />}
      </div>

      {!compact && (
        <div className="mt-2 flex flex-wrap items-center gap-2 text-[10px] text-ink-muted">
          <span
            className="rounded-full px-1.5 py-0.5 capitalize"
            style={{ backgroundColor: `${typeColor}18`, color: typeColor }}
          >
            {item.status.replace(/_/g, ' ')}
          </span>
          {item.due_date && (
            <span className={overdue ? 'font-medium text-status-overdue' : ''}>
              Due {formatShortDate(item.due_date)}
            </span>
          )}
        </div>
      )}

      <div className="mt-2 flex items-center justify-between">
        <div className="flex h-5 w-5 items-center justify-center rounded-full bg-surface-muted text-[9px] font-medium text-ink-secondary">
          {item.owner_id ? initials(item.owner_id.slice(0, 8)) : '—'}
        </div>
        <div className="flex items-center gap-2 opacity-0 transition group-hover:opacity-100">
          {item.editor_document_id && (
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation()
                onOpenEditor?.()
              }}
              className="text-ink-muted hover:text-accent"
              title="Open editor"
            >
              <FilePen className="h-3 w-3" />
            </button>
          )}
          <MessageCircle className="h-3 w-3 text-ink-muted" />
          <Paperclip className="h-3 w-3 text-ink-muted" />
        </div>
      </div>
    </article>
  )
}
