import { useSpacesStore } from '../../stores/spaces-store'

export function EmptySpaceState(): React.ReactElement {
  const createSpace = useSpacesStore((s) => s.createSpace)

  return (
    <div className="flex h-full flex-col items-center justify-center p-8 text-center">
      <h1 className="text-lg font-semibold text-ink">Spaces</h1>
      <p className="mt-2 max-w-md text-sm text-ink-secondary">
        This is where your company runs its work — projects, campaigns, clients, and operations in one
        connected hub.
      </p>
      <p className="mt-4 text-xs text-ink-muted">No Spaces yet.</p>
      <button
        type="button"
        onClick={() => {
          const name = window.prompt('Name your first Space')
          if (name?.trim()) void createSpace(name.trim())
        }}
        className="mt-4 rounded-lg bg-accent px-4 py-2 text-sm font-medium text-white hover:bg-accent-hover"
      >
        Create Space
      </button>
    </div>
  )
}
