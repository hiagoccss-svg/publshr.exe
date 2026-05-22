import { useEffect, useState } from 'react'
import { X } from 'lucide-react'
import { useSpacesStore } from '../../stores/spaces-store'
import type { TaskViewMode } from '../../../shared/types'

const DEFAULT_VIEWS: { id: TaskViewMode; label: string }[] = [
  { id: 'overview', label: 'Overview' },
  { id: 'list', label: 'List' },
  { id: 'board', label: 'Board' },
  { id: 'calendar', label: 'Calendar' },
  { id: 'timeline', label: 'Timeline' }
]

const STATUS_OPTIONS = [
  'To Do',
  'In Progress',
  'Review',
  'Blocked',
  'Approved',
  'Complete'
] as const

/** ClickUp Space settings — name, pin, favorite, default view, status workflow summary. */
export function SpaceSettingsModal(): React.ReactElement | null {
  const spaceId = useSpacesStore((s) => s.spaceSettingsId)
  const setSpaceSettingsId = useSpacesStore((s) => s.setSpaceSettingsId)
  const spaces = useSpacesStore((s) => s.spaces)
  const updateSpace = useSpacesStore((s) => s.updateSpace)
  const getDefaultView = useSpacesStore((s) => s.getDefaultViewForSpace)
  const setDefaultViewForSpace = useSpacesStore((s) => s.setDefaultViewForSpace)

  const space = spaces.find((s) => s.id === spaceId)
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [defaultView, setDefaultView] = useState<TaskViewMode>('overview')
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    if (!space) return
    setName(space.name)
    setDescription(space.description)
    setDefaultView(getDefaultView(space.id))
  }, [space, getDefaultView])

  if (!spaceId || !space) return null

  const close = (): void => setSpaceSettingsId(null)

  const save = async (): Promise<void> => {
    setBusy(true)
    try {
      await updateSpace(space.id, {
        name: name.trim() || space.name,
        description: description.trim()
      })
      setDefaultViewForSpace(space.id, defaultView)
      close()
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div
        role="dialog"
        aria-labelledby="space-settings-title"
        className="w-full max-w-lg rounded-xl border border-surface-border bg-surface-raised shadow-panel"
      >
        <div className="flex items-center justify-between border-b border-surface-border px-4 py-3">
          <h2 id="space-settings-title" className="text-sm font-semibold text-ink">
            Space settings
          </h2>
          <button type="button" onClick={close} className="rounded p-1 text-ink-muted hover:bg-surface-muted">
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="max-h-[70vh] space-y-4 overflow-y-auto p-4">
          <div>
            <label className="mb-1 block text-[10px] font-semibold uppercase text-ink-muted">Name</label>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full rounded-lg border border-surface-border bg-surface px-3 py-2 text-sm text-ink"
            />
          </div>
          <div>
            <label className="mb-1 block text-[10px] font-semibold uppercase text-ink-muted">Description</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={2}
              className="w-full resize-none rounded-lg border border-surface-border bg-surface px-3 py-2 text-sm text-ink-secondary"
            />
          </div>

          <div className="flex flex-wrap gap-2">
            <ToggleButton
              label={space.isPinned ? 'Unpin' : 'Pin to sidebar'}
              active={space.isPinned}
              onClick={() => void updateSpace(space.id, { isPinned: !space.isPinned })}
            />
            <ToggleButton
              label={space.isFavourite ? 'Remove favorite' : 'Add to favorites'}
              active={space.isFavourite}
              onClick={() => void updateSpace(space.id, { isFavourite: !space.isFavourite })}
            />
          </div>

          <div>
            <label className="mb-1 block text-[10px] font-semibold uppercase text-ink-muted">
              Default view (ClickUp)
            </label>
            <select
              value={defaultView}
              onChange={(e) => setDefaultView(e.target.value as TaskViewMode)}
              className="w-full rounded-lg border border-surface-border bg-surface px-3 py-2 text-sm text-ink"
            >
              {DEFAULT_VIEWS.map((v) => (
                <option key={v.id} value={v.id}>
                  {v.label}
                </option>
              ))}
            </select>
            <p className="mt-1 text-[10px] text-ink-muted">
              Opens when you enter this Space (stored locally per device).
            </p>
          </div>

          <div>
            <p className="mb-2 text-[10px] font-semibold uppercase text-ink-muted">Task statuses (inherited)</p>
            <div className="flex flex-wrap gap-1">
              {STATUS_OPTIONS.map((s) => (
                <span key={s} className="rounded bg-surface-muted px-2 py-0.5 text-[10px] text-ink-secondary">
                  {s}
                </span>
              ))}
            </div>
            <p className="mt-2 text-[10px] text-ink-muted">
              Folders and lists inherit these statuses, like ClickUp. Custom per-folder overrides ship in a later
              release.
            </p>
          </div>
        </div>

        <div className="flex justify-between gap-2 border-t border-surface-border px-4 py-3">
          <button
            type="button"
            onClick={() => void updateSpace(space.id, { isArchived: true })}
            className="rounded-lg px-3 py-1.5 text-xs text-red-600 hover:bg-red-50"
          >
            Archive space
          </button>
          <div className="flex gap-2">
            <button type="button" onClick={close} className="rounded-lg px-3 py-1.5 text-sm text-ink-secondary hover:bg-surface-muted">
              Cancel
            </button>
            <button
              type="button"
              disabled={busy}
              onClick={() => void save()}
              className="rounded-lg bg-accent px-4 py-1.5 text-sm font-medium text-white hover:bg-accent-hover disabled:opacity-50"
            >
              Save
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

function ToggleButton({
  label,
  active,
  onClick
}: {
  label: string
  active: boolean
  onClick: () => void
}): React.ReactElement {
  return (
    <button
      type="button"
      onClick={onClick}
      className={
        active
          ? 'rounded-lg border border-accent/40 bg-accent-soft px-3 py-1.5 text-xs font-medium text-accent'
          : 'rounded-lg border border-surface-border px-3 py-1.5 text-xs text-ink-secondary hover:bg-surface-muted'
      }
    >
      {label}
    </button>
  )
}
