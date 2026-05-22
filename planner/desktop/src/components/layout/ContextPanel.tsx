import { useState } from 'react'
import { X, FilePen, Send } from 'lucide-react'
import { usePlannerStore, useSelectedItem } from '@/stores/plannerStore'
import { PLANNER_ITEM_TYPE_LABELS } from '@/types/planner'
import { formatShortDate } from '@/lib/utils'

export default function ContextPanel() {
  const item = useSelectedItem()
  const setSelectedId = usePlannerStore((s) => s.setSelectedId)
  const setContextPanelOpen = usePlannerStore((s) => s.setContextPanelOpen)
  const updateItem = usePlannerStore((s) => s.updateItem)
  const [comment, setComment] = useState('')

  if (!item) return null

  const openEditor = () => {
    if (item.editor_document_id && window.planner) {
      void window.planner.openEditorWindow(item.editor_document_id, item.id)
    }
  }

  return (
    <aside className="dt-glass-panel flex min-h-0 w-[320px] shrink-0 flex-col overflow-hidden">
      <div className="dt-divider-h flex items-start justify-between gap-2 p-4">
        <div className="min-w-0">
          <input
            value={item.title}
            onChange={(e) => void updateItem(item.id, { title: e.target.value })}
            className="w-full bg-transparent text-sm font-semibold text-ink outline-none"
          />
          <p className="mt-1 text-[10px] text-ink-muted">{PLANNER_ITEM_TYPE_LABELS[item.type]}</p>
        </div>
        <button
          type="button"
          onClick={() => {
            setSelectedId(null)
            setContextPanelOpen(false)
          }}
          className="rounded-lg p-1 text-ink-muted hover:bg-surface-muted"
        >
          <X className="h-4 w-4" />
        </button>
      </div>

      <div className="flex-1 space-y-4 overflow-y-auto p-4 text-sm">
        <Section title="Status">
          <select
            value={item.status}
            onChange={(e) => void updateItem(item.id, { status: e.target.value as typeof item.status })}
            className="w-full rounded-lg border border-surface-border bg-surface px-2 py-1.5 text-xs"
          >
            {[
              'idea',
              'drafting',
              'internal_review',
              'client_approval',
              'scheduled',
              'published',
              'coverage_tracking',
              'reporting',
              'completed'
            ].map((s) => (
              <option key={s} value={s}>
                {s.replace(/_/g, ' ')}
              </option>
            ))}
          </select>
        </Section>

        <Section title="Dates">
          <dl className="space-y-1 text-xs">
            <Row label="Due" value={formatShortDate(item.due_date)} />
            <Row label="Publish" value={formatShortDate(item.publish_date)} />
          </dl>
        </Section>

        <Section title="Description">
          <textarea
            value={item.description ?? ''}
            onChange={(e) => void updateItem(item.id, { description: e.target.value })}
            rows={3}
            className="w-full resize-none rounded-lg border border-surface-border bg-surface px-2 py-1.5 text-xs outline-none focus:ring-1 focus:ring-accent/30"
            placeholder="Add context…"
          />
        </Section>

        {item.editor_document_id && (
          <Section title="Editor draft">
            <button
              type="button"
              onClick={openEditor}
              className="flex w-full items-center gap-2 rounded-lg border border-surface-border px-3 py-2 text-xs hover:bg-surface-muted"
            >
              <FilePen className="h-3.5 w-3.5 text-accent" />
              Open in new window
            </button>
          </Section>
        )}

        <Section title="Approvals">
          <p className="text-xs text-ink-muted">No approvals requested yet.</p>
          <button
            type="button"
            className="mt-2 text-xs font-medium text-accent hover:underline"
          >
            Request approval
          </button>
        </Section>

        <Section title="Comments">
          <div className="space-y-2">
            <p className="text-xs text-ink-muted">No comments yet.</p>
            <div className="flex gap-2">
              <input
                value={comment}
                onChange={(e) => setComment(e.target.value)}
                placeholder="Add a comment…"
                className="flex-1 rounded-lg border border-surface-border bg-surface px-2 py-1.5 text-xs"
              />
              <button type="button" className="rounded-lg p-1.5 text-accent hover:bg-accent-soft">
                <Send className="h-3.5 w-3.5" />
              </button>
            </div>
          </div>
        </Section>

        <Section title="Activity">
          <p className="text-xs text-ink-muted">Activity log syncs with Supabase Realtime (Phase 4).</p>
        </Section>
      </div>
    </aside>
  )
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <h3 className="mb-2 text-[10px] font-semibold uppercase tracking-wider text-ink-muted">{title}</h3>
      {children}
    </div>
  )
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between">
      <dt className="text-ink-muted">{label}</dt>
      <dd className="text-ink">{value}</dd>
    </div>
  )
}
