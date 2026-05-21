import { useFilteredItems } from '@/stores/plannerStore'

const STAGES = [
  { id: 'internal', label: 'Internal approval' },
  { id: 'client', label: 'Client approval' },
  { id: 'legal', label: 'Legal approval' },
  { id: 'final', label: 'Final sign-off' }
]

export default function ApprovalsView() {
  const items = useFilteredItems().filter(
    (i) => i.status === 'internal_review' || i.status === 'client_approval'
  )

  return (
    <div className="h-full overflow-auto p-6">
      <h2 className="text-sm font-semibold text-ink">Pending approvals</h2>
      <p className="mt-1 text-xs text-ink-muted">
        Full approval workflow connects in Phase 4. Items in review stages appear below.
      </p>
      <div className="mt-6 grid gap-4 md:grid-cols-2">
        {STAGES.map((stage) => (
          <section key={stage.id} className="rounded-xl border border-surface-border bg-surface-raised p-4">
            <h3 className="text-xs font-semibold uppercase tracking-wider text-ink-muted">{stage.label}</h3>
            <ul className="mt-3 space-y-2">
              {items.length === 0 ? (
                <li className="text-xs text-ink-muted">Nothing waiting</li>
              ) : (
                items.map((item) => (
                  <li key={item.id} className="rounded-lg bg-surface-muted/60 px-3 py-2 text-sm">
                    {item.title}
                  </li>
                ))
              )}
            </ul>
          </section>
        ))}
      </div>
    </div>
  )
}
