import { formatDistanceToNow } from 'date-fns'
import {
  Archive,
  LayoutGrid,
  LayoutList,
  Pin,
  Plus,
  Search,
  Star
} from 'lucide-react'
import clsx from 'clsx'
import { useMemo } from 'react'
import {
  SPACES_HIERARCHY_CHAIN,
  SPACES_HOME_TAGLINE,
  SPACE_TYPE_OPTIONS,
  spaceTypeLabel
} from '@spaces-enterprise/hierarchy'
import {
  buildSpacesHomeSections,
  spacesHomeCounts,
  type SpacesHomeLayout
} from '@spaces-enterprise/spaces-home'
import { useSpacesStore } from '../../stores/spaces-store'

/** ClickUp Spaces Home — enterprise browse, search, filter, and open every Space. */
export function SpacesEnterpriseHome(): React.ReactElement {
  const spaces = useSpacesStore((s) => s.spaces)
  const setActiveSpace = useSpacesStore((s) => s.setActiveSpace)
  const setNewSpaceModalOpen = useSpacesStore((s) => s.setNewSpaceModalOpen)
  const openSpaceSettings = useSpacesStore((s) => s.openSpaceSettings)
  const homeQuery = useSpacesStore((s) => s.spacesHomeQuery)
  const setSpacesHomeQuery = useSpacesStore((s) => s.setSpacesHomeQuery)
  const homeTypeFilter = useSpacesStore((s) => s.spacesHomeTypeFilter)
  const setSpacesHomeTypeFilter = useSpacesStore((s) => s.setSpacesHomeTypeFilter)
  const showArchived = useSpacesStore((s) => s.spacesHomeShowArchived)
  const setSpacesHomeShowArchived = useSpacesStore((s) => s.setSpacesHomeShowArchived)
  const layout = useSpacesStore((s) => s.spacesHomeLayout)
  const setSpacesHomeLayout = useSpacesStore((s) => s.setSpacesHomeLayout)

  const counts = useMemo(() => spacesHomeCounts(spaces), [spaces])
  const sections = useMemo(
    () =>
      buildSpacesHomeSections(spaces, {
        query: homeQuery,
        typeFilter: homeTypeFilter,
        showArchived
      }),
    [spaces, homeQuery, homeTypeFilter, showArchived]
  )

  return (
    <div className="animate-fade-in space-y-5 p-1">
      <header className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-ink-muted">
            <LayoutGrid className="h-4 w-4" />
            <span className="text-[10px] font-semibold uppercase tracking-wide">Spaces Home</span>
          </div>
          <h1 className="mt-1 text-xl font-semibold tracking-tight text-ink">All Spaces</h1>
          <p className="mt-1 max-w-2xl text-sm text-ink-secondary">{SPACES_HOME_TAGLINE}</p>
          <p className="mt-2 font-mono text-[10px] text-ink-muted">{SPACES_HIERARCHY_CHAIN}</p>
          <p className="mt-2 text-xs text-ink-muted">
            {counts.active} active
            {counts.archived > 0 ? ` · ${counts.archived} archived` : ''}
            {counts.pinned > 0 ? ` · ${counts.pinned} pinned` : ''}
          </p>
        </div>
        <button type="button" onClick={() => setNewSpaceModalOpen(true)} className="library-cta-pill">
          <Plus className="h-4 w-4" />
          New Space
        </button>
      </header>

      <div className="flex flex-wrap items-center gap-2">
        <div className="relative min-w-[200px] flex-1">
          <Search className="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-ink-muted" />
          <input
            value={homeQuery}
            onChange={(e) => setSpacesHomeQuery(e.target.value)}
            placeholder="Search spaces…"
            className="w-full rounded-lg border border-surface-border bg-surface py-1.5 pl-8 pr-3 text-sm text-ink focus:outline-none focus:ring-2 focus:ring-accent/20"
          />
        </div>
        <select
          value={homeTypeFilter}
          onChange={(e) =>
            setSpacesHomeTypeFilter(e.target.value as typeof homeTypeFilter)
          }
          className="rounded-lg border border-surface-border bg-surface px-2 py-1.5 text-sm text-ink"
          aria-label="Filter by space type"
        >
          <option value="all">All types</option>
          {SPACE_TYPE_OPTIONS.map((t) => (
            <option key={t.value} value={t.value}>
              {t.label}
            </option>
          ))}
        </select>
        <button
          type="button"
          onClick={() => setSpacesHomeShowArchived(!showArchived)}
          className={clsx(
            'flex items-center gap-1.5 rounded-lg border px-2.5 py-1.5 text-xs',
            showArchived
              ? 'border-accent/40 bg-accent-soft text-accent'
              : 'border-surface-border text-ink-secondary hover:bg-surface-muted'
          )}
        >
          <Archive className="h-3.5 w-3.5" />
          Archived
        </button>
        <LayoutToggle layout={layout} onChange={setSpacesHomeLayout} />
      </div>

      {sections.length === 0 ? (
        <p className="rounded-lg border border-dashed border-surface-border px-4 py-8 text-center text-sm text-ink-muted">
          No spaces match your filters.{' '}
          <button
            type="button"
            className="text-accent hover:underline"
            onClick={() => setNewSpaceModalOpen(true)}
          >
            Create a Space
          </button>
        </p>
      ) : (
        sections.map((section) => (
          <SpaceSection
            key={section.id}
            title={section.title}
            icon={section.id === 'pinned' ? Pin : section.id === 'favorites' ? Star : undefined}
            layout={layout}
            spaces={section.spaces}
            onOpen={setActiveSpace}
            onSettings={openSpaceSettings}
          />
        ))
      )}
    </div>
  )
}

function LayoutToggle({
  layout,
  onChange
}: {
  layout: SpacesHomeLayout
  onChange: (layout: SpacesHomeLayout) => void
}): React.ReactElement {
  return (
    <div className="flex rounded-lg border border-surface-border p-0.5">
      <button
        type="button"
        title="Grid"
        onClick={() => onChange('grid')}
        className={clsx(
          'rounded-md p-1.5',
          layout === 'grid' ? 'bg-accent-soft text-accent' : 'text-ink-muted hover:bg-surface-muted'
        )}
      >
        <LayoutGrid className="h-3.5 w-3.5" />
      </button>
      <button
        type="button"
        title="List"
        onClick={() => onChange('list')}
        className={clsx(
          'rounded-md p-1.5',
          layout === 'list' ? 'bg-accent-soft text-accent' : 'text-ink-muted hover:bg-surface-muted'
        )}
      >
        <LayoutList className="h-3.5 w-3.5" />
      </button>
    </div>
  )
}

function SpaceSection({
  title,
  icon: Icon,
  layout,
  spaces,
  onOpen,
  onSettings
}: {
  title: string
  icon?: React.ComponentType<{ className?: string }>
  layout: SpacesHomeLayout
  spaces: {
    id: string
    name: string
    description: string
    color: string
    type: string
    status: string
    updatedAt: string
    isPinned: boolean
    isFavourite: boolean
    isArchived: boolean
  }[]
  onOpen: (id: string) => void
  onSettings: (id: string) => void
}): React.ReactElement | null {
  if (spaces.length === 0) return null

  return (
    <section>
      <h2 className="mb-3 flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-wide text-ink-muted">
        {Icon && <Icon className="h-3 w-3" />}
        {title}
      </h2>
      <div
        className={clsx(
          layout === 'grid'
            ? 'library-masonry library-masonry-responsive'
            : 'flex flex-col gap-2'
        )}
      >
        {spaces.map((space) => (
          <div key={space.id} className={layout === 'grid' ? 'library-masonry-item' : ''}>
            <SpaceCard space={space} layout={layout} onOpen={onOpen} onSettings={onSettings} />
          </div>
        ))}
      </div>
    </section>
  )
}

function SpaceCard({
  space,
  layout,
  onOpen,
  onSettings
}: {
  space: {
    id: string
    name: string
    description: string
    color: string
    type: string
    status: string
    updatedAt: string
    isPinned: boolean
    isFavourite: boolean
    isArchived: boolean
  }
  layout: SpacesHomeLayout
  onOpen: (id: string) => void
  onSettings: (id: string) => void
}): React.ReactElement {
  const typeLabel = spaceTypeLabel(space.type)

  return (
    <article
      className={clsx(
        'library-card group transition hover:border-accent/25 hover:shadow-card',
        layout === 'list' && 'flex flex-row items-center gap-4 p-3'
      )}
    >
      <button
        type="button"
        onClick={() => void onOpen(space.id)}
        className={clsx(
          'flex flex-1 flex-col items-start text-left',
          layout === 'list' && 'min-w-0 flex-row items-center gap-3'
        )}
      >
        <div className="flex w-full items-center gap-2">
          <span className="h-3 w-3 shrink-0 rounded-full" style={{ backgroundColor: space.color }} />
          <span className="truncate font-semibold text-ink">{space.name}</span>
          {space.isPinned && <Pin className="h-3 w-3 shrink-0 text-ink-muted" />}
          {space.isFavourite && <Star className="h-3 w-3 shrink-0 text-amber-500" />}
          {space.isArchived && (
            <span className="rounded bg-surface-muted px-1 py-0.5 text-[9px] uppercase text-ink-muted">
              Archived
            </span>
          )}
        </div>
        {layout === 'grid' && (
          <>
            <p className="mt-2 line-clamp-2 text-xs text-ink-secondary">
              {space.description || 'Tasks, folders, lists, and docs for this Space.'}
            </p>
            <div className="mt-2 flex flex-wrap gap-1.5">
              <span className="rounded bg-surface-muted px-1.5 py-0.5 text-[10px] text-ink-muted">
                {typeLabel}
              </span>
              <span className="rounded bg-surface-muted px-1.5 py-0.5 text-[10px] capitalize text-ink-muted">
                {space.status}
              </span>
            </div>
          </>
        )}
        {layout === 'list' && (
          <span className="truncate text-xs text-ink-muted">
            {typeLabel} · {space.status}
          </span>
        )}
      </button>
      <div
        className={clsx(
          'flex items-center justify-between text-[10px] text-ink-muted',
          layout === 'grid' && 'border-t border-surface-border/60 pt-2'
        )}
      >
        <span>
          Updated {formatDistanceToNow(new Date(space.updatedAt), { addSuffix: true })}
        </span>
        <button
          type="button"
          onClick={(e) => {
            e.stopPropagation()
            onSettings(space.id)
          }}
          className={clsx(
            'rounded px-2 py-0.5 hover:bg-surface-muted hover:text-ink',
            layout === 'grid' && 'opacity-0 group-hover:opacity-100'
          )}
        >
          Settings
        </button>
      </div>
    </article>
  )
}
