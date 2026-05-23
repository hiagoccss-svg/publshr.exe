import { LayoutGrid, Plus } from 'lucide-react'
import { useSpacesStore } from '../../stores/spaces-store'

export function EmptySpaceState(): React.ReactElement {
  const setNewSpaceModalOpen = useSpacesStore((s) => s.setNewSpaceModalOpen)

  return (
    <main className="glass-workspace-flat flex min-h-0 flex-1 flex-col overflow-hidden">
      <div className="flex flex-1 flex-col items-center justify-center px-8 py-12 text-center">
        <LayoutGrid className="h-8 w-8 text-ink-muted" strokeWidth={1.5} />
        <p className="mt-4 text-[15px] font-medium text-ink">No spaces yet</p>
        <p className="mt-2 max-w-[360px] text-xs text-ink-muted">
          Create a space for clients, campaigns, launches, and editorial work.
        </p>
        <button
          type="button"
          onClick={() => setNewSpaceModalOpen(true)}
          className="mt-6 inline-flex items-center gap-1.5 rounded-lg bg-accent px-4 py-2 text-sm font-medium text-white hover:bg-accent-hover"
        >
          <Plus className="h-4 w-4" />
          New Space
        </button>
      </div>
    </main>
  )
}
