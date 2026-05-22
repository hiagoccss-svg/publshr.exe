import { Plus, Upload } from 'lucide-react'
import { usePlannerStore } from '@/stores/plannerStore'

export default function EmptyState() {
  const setCreatePanelOpen = usePlannerStore((s) => s.setCreatePanelOpen)

  return (
    <div className="flex h-full flex-col items-center justify-center px-8 text-center">
      <h2 className="font-display text-xl font-semibold tracking-tight text-ink">
        No planner items yet
      </h2>
      <p className="mt-2 max-w-md text-sm leading-relaxed text-ink-secondary">
        Create your first campaign communication, press release deadline, or editorial
        schedule. Everything connects to approvals, files, and the editor.
      </p>
      <div className="mt-8 flex flex-wrap justify-center gap-3">
        <button
          type="button"
          onClick={() => setCreatePanelOpen(true)}
          className="inline-flex items-center gap-2 rounded-lg bg-ink px-4 py-2 text-sm font-medium text-white hover:bg-ink/90"
        >
          <Plus className="h-4 w-4" />
          Create Planner Item
        </button>
        <button
          type="button"
          className="inline-flex items-center gap-2 rounded-lg border border-surface-border px-4 py-2 text-sm text-ink-secondary hover:bg-surface-muted"
        >
          <Upload className="h-4 w-4" />
          Import From Brief
        </button>
      </div>
    </div>
  )
}
