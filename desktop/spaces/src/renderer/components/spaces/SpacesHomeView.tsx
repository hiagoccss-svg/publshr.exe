import { formatDistanceToNow } from 'date-fns'
import { LayoutGrid, Pin, Plus, Star } from 'lucide-react'
import clsx from 'clsx'
import { useSpacesStore } from '../../stores/spaces-store'

/** ClickUp Spaces Home — browse, pin, and open every Space in the workspace. */
export function SpacesHomeView(): React.ReactElement {
  const spaces = useSpacesStore((s) => s.spaces)
  const setActiveSpace = useSpacesStore((s) => s.setActiveSpace)
  const setNewSpaceModalOpen = useSpacesStore((s) => s.setNewSpaceModalOpen)
  const openSpaceSettings = useSpacesStore((s) => s.openSpaceSettings)

  const active = spaces.filter((s) => !s.isArchived)
  const pinned = active.filter((s) => s.isPinned)
  const favourites = active.filter((s) => s.isFavourite && !s.isPinned)
  const rest = active.filter((s) => !s.isPinned && !s.isFavourite)

  return (
    <div className="animate-fade-in space-y-6 p-1">
      <header className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-ink-muted">
            <LayoutGrid className="h-4 w-4" />
            <span className="text-[10px] font-semibold uppercase tracking-wide">Spaces Home</span>
          </div>
          <h1 className="mt-1 text-xl font-semibold tracking-tight text-ink">All Spaces</h1>
          <p className="mt-1 max-w-xl text-sm text-ink-secondary">
            Group departments, clients, and initiatives — same hierarchy as ClickUp: Space → Folder →
            List → Task.
          </p>
        </div>
        <button
          type="button"
          onClick={() => setNewSpaceModalOpen(true)}
          className="library-cta-pill"
        >
          <Plus className="h-4 w-4" />
          New Space
        </button>
      </header>

      {pinned.length > 0 && (
        <SpaceSection title="Pinned" icon={Pin} spaces={pinned} onOpen={setActiveSpace} onSettings={openSpaceSettings} />
      )}
      {favourites.length > 0 && (
        <SpaceSection title="Favorites" icon={Star} spaces={favourites} onOpen={setActiveSpace} onSettings={openSpaceSettings} />
      )}
      <SpaceSection
        title={pinned.length > 0 || favourites.length > 0 ? 'All Spaces' : undefined}
        spaces={rest.length > 0 ? rest : active}
        onOpen={setActiveSpace}
        onSettings={openSpaceSettings}
      />
    </div>
  )
}

function SpaceSection({
  title,
  icon: Icon,
  spaces,
  onOpen,
  onSettings
}: {
  title?: string
  icon?: React.ComponentType<{ className?: string }>
  spaces: { id: string; name: string; description: string; color: string; type: string; status: string; updatedAt: string; isPinned: boolean; isFavourite: boolean }[]
  onOpen: (id: string) => void
  onSettings: (id: string) => void
}): React.ReactElement {
  if (spaces.length === 0) return <></>

  return (
    <section>
      {title && (
        <h2 className="mb-3 flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-wide text-ink-muted">
          {Icon && <Icon className="h-3 w-3" />}
          {title}
        </h2>
      )}
      <div className="library-masonry library-masonry-responsive">
        {spaces.map((space) => (
          <div key={space.id} className="library-masonry-item">
            <article className="library-card group flex flex-col gap-3 transition hover:border-accent/25 hover:shadow-card">
              <button
                type="button"
                onClick={() => void onOpen(space.id)}
                className="flex flex-1 flex-col items-start text-left"
              >
                <div className="flex w-full items-center gap-2">
                  <span
                    className="h-3 w-3 shrink-0 rounded-full"
                    style={{ backgroundColor: space.color }}
                  />
                  <span className="truncate font-semibold text-ink">{space.name}</span>
                  {space.isPinned && <Pin className="h-3 w-3 shrink-0 text-ink-muted" />}
                  {space.isFavourite && <Star className="h-3 w-3 shrink-0 text-amber-500" />}
                </div>
                <p className="mt-2 line-clamp-2 text-xs text-ink-secondary">
                  {space.description || 'Operational workspace for tasks, docs, and deadlines.'}
                </p>
                <div className="mt-2 flex flex-wrap gap-1.5">
                  <span className="rounded bg-surface-muted px-1.5 py-0.5 text-[10px] capitalize text-ink-muted">
                    {space.type}
                  </span>
                  <span className="rounded bg-surface-muted px-1.5 py-0.5 text-[10px] capitalize text-ink-muted">
                    {space.status}
                  </span>
                </div>
              </button>
              <div className="flex items-center justify-between border-t border-surface-border/60 pt-2">
                <span className="text-[10px] text-ink-muted">
                  Updated {formatDistanceToNow(new Date(space.updatedAt), { addSuffix: true })}
                </span>
                <button
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation()
                    onSettings(space.id)
                  }}
                  className={clsx(
                    'rounded px-2 py-0.5 text-[10px] text-ink-muted opacity-0 transition',
                    'group-hover:opacity-100 hover:bg-surface-muted hover:text-ink'
                  )}
                >
                  Settings
                </button>
              </div>
            </article>
          </div>
        ))}
      </div>
    </section>
  )
}
