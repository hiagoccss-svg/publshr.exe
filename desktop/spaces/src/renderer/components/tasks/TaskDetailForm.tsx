import { useState } from 'react'
import { getSpacesAPI } from '../../lib/api'
import { useSpacesStore } from '../../stores/spaces-store'
import { TaskStatusBadge } from '../layout/TopBar'
import type { Task, TaskStatus } from '../../../shared/types'

const STATUSES: TaskStatus[] = [
  'todo',
  'in_progress',
  'review',
  'blocked',
  'approved',
  'completed',
  'archived'
]

export function TaskDetailForm({
  task,
  onClose
}: {
  task: Task
  onClose: () => void
}): React.ReactElement {
  const refreshActiveSpace = useSpacesStore((s) => s.refreshActiveSpace)
  const [title, setTitle] = useState(task.title)
  const [description, setDescription] = useState(task.description)
  const [status, setStatus] = useState(task.status)

  const save = async (): Promise<void> => {
    await getSpacesAPI().updateTask({
      id: task.id,
      title,
      description,
      status
    })
    await refreshActiveSpace()
  }

  return (
    <div className="flex flex-1 flex-col overflow-y-auto p-3">
      <div className="mb-3 flex items-start justify-between gap-2">
        <TaskStatusBadge status={status} />
        <button type="button" onClick={onClose} className="text-xs text-ink-muted hover:text-ink">
          Clear
        </button>
      </div>
      <input
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        onBlur={() => void save()}
        className="mb-2 w-full rounded-lg border border-surface-border bg-surface px-2 py-1.5 text-sm font-medium text-ink focus:outline-none focus:ring-2 focus:ring-accent/15"
      />
      <textarea
        value={description}
        onChange={(e) => setDescription(e.target.value)}
        onBlur={() => void save()}
        rows={5}
        placeholder="Description, links, operational notes…"
        className="mb-3 w-full resize-none rounded-lg border border-surface-border bg-surface px-2 py-1.5 text-xs text-ink-secondary focus:outline-none focus:ring-2 focus:ring-accent/15"
      />
      <label className="mb-1 text-[10px] font-semibold uppercase text-ink-muted">Status</label>
      <select
        value={status}
        onChange={(e) => {
          setStatus(e.target.value as TaskStatus)
          void getSpacesAPI()
            .updateTask({ id: task.id, status: e.target.value as TaskStatus })
            .then(() => refreshActiveSpace())
        }}
        className="rounded-lg border border-surface-border bg-surface px-2 py-1.5 text-xs text-ink"
      >
        {STATUSES.map((s) => (
          <option key={s} value={s}>
            {s.replace('_', ' ')}
          </option>
        ))}
      </select>
      <p className="mt-4 text-[10px] text-ink-muted">
        Comments, dependencies, and linked docs — Phase 2.
      </p>
    </div>
  )
}
