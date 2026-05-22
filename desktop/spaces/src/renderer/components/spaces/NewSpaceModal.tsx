import { useState } from 'react'
import { X } from 'lucide-react'
import { useSpacesStore } from '../../stores/spaces-store'
import type { SpaceType } from '../../../shared/types'

const SPACE_TYPES: { value: SpaceType; label: string }[] = [
  { value: 'general', label: 'General' },
  { value: 'campaign', label: 'Campaign' },
  { value: 'client', label: 'Client' },
  { value: 'editorial', label: 'Editorial' },
  { value: 'operation', label: 'Operation' }
]

export function NewSpaceModal(): React.ReactElement | null {
  const open = useSpacesStore((s) => s.newSpaceModalOpen)
  const setOpen = useSpacesStore((s) => s.setNewSpaceModalOpen)
  const createSpace = useSpacesStore((s) => s.createSpace)
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [type, setType] = useState<SpaceType>('general')
  const [busy, setBusy] = useState(false)

  if (!open) return null

  const submit = async (): Promise<void> => {
    const trimmed = name.trim()
    if (!trimmed) return
    setBusy(true)
    try {
      await createSpace({ name: trimmed, description: description.trim(), type })
      setName('')
      setDescription('')
      setType('general')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div
        role="dialog"
        aria-labelledby="new-space-title"
        className="w-full max-w-md rounded-xl border border-surface-border bg-surface-raised shadow-panel"
      >
        <div className="flex items-center justify-between border-b border-surface-border px-4 py-3">
          <h2 id="new-space-title" className="text-sm font-semibold text-ink">
            New Space
          </h2>
          <button
            type="button"
            onClick={() => setOpen(false)}
            className="rounded p-1 text-ink-muted hover:bg-surface-muted"
          >
            <X className="h-4 w-4" />
          </button>
        </div>
        <div className="space-y-3 p-4">
          <div>
            <label className="mb-1 block text-[10px] font-semibold uppercase text-ink-muted">Name</label>
            <input
              autoFocus
              value={name}
              onChange={(e) => setName(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && void submit()}
              placeholder="e.g. Q2 Campaign"
              className="w-full rounded-lg border border-surface-border bg-surface px-3 py-2 text-sm text-ink focus:outline-none focus:ring-2 focus:ring-accent/20"
            />
          </div>
          <div>
            <label className="mb-1 block text-[10px] font-semibold uppercase text-ink-muted">Type</label>
            <select
              value={type}
              onChange={(e) => setType(e.target.value as SpaceType)}
              className="w-full rounded-lg border border-surface-border bg-surface px-3 py-2 text-sm text-ink"
            >
              {SPACE_TYPES.map((t) => (
                <option key={t.value} value={t.value}>
                  {t.label}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="mb-1 block text-[10px] font-semibold uppercase text-ink-muted">
              Description (optional)
            </label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={3}
              className="w-full resize-none rounded-lg border border-surface-border bg-surface px-3 py-2 text-sm text-ink-secondary focus:outline-none focus:ring-2 focus:ring-accent/20"
            />
          </div>
        </div>
        <div className="flex justify-end gap-2 border-t border-surface-border px-4 py-3">
          <button
            type="button"
            onClick={() => setOpen(false)}
            className="rounded-lg px-3 py-1.5 text-sm text-ink-secondary hover:bg-surface-muted"
          >
            Cancel
          </button>
          <button
            type="button"
            disabled={!name.trim() || busy}
            onClick={() => void submit()}
            className="rounded-lg bg-accent px-4 py-1.5 text-sm font-medium text-white hover:bg-accent-hover disabled:opacity-50"
          >
            Create Space
          </button>
        </div>
      </div>
    </div>
  )
}
