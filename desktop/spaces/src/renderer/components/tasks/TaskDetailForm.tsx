import { useState } from 'react'
import { getSpacesAPI } from '../../lib/api'
import { useSpacesStore } from '../../stores/spaces-store'
import { TaskStatusBadge } from '../layout/TopBar'
import type { Task, TaskPriority, TaskStatus } from '../../../shared/types'

const PRIORITIES: TaskPriority[] = ['none', 'low', 'normal', 'high', 'urgent']

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
  const members = useSpacesStore((s) => s.members)
  const [title, setTitle] = useState(task.title)
  const [description, setDescription] = useState(task.description)
  const [status, setStatus] = useState(task.status)
  const [priority, setPriority] = useState(task.priority)
  const [assigneeId, setAssigneeId] = useState<string | null>(task.assigneeId)

  const save = async (): Promise<void> => {
    await getSpacesAPI().updateTask({
      id: task.id,
      title,
      description,
      status,
      priority,
      assigneeId
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
      <label className="mb-1 mt-3 text-[10px] font-semibold uppercase text-ink-muted">Priority</label>
      <select
        value={priority}
        onChange={(e) => {
          setPriority(e.target.value as TaskPriority)
          void getSpacesAPI()
            .updateTask({ id: task.id, priority: e.target.value as TaskPriority })
            .then(() => refreshActiveSpace())
        }}
        className="mb-3 w-full rounded-lg border border-surface-border bg-surface px-2 py-1.5 text-xs text-ink"
      >
        {PRIORITIES.map((p) => (
          <option key={p} value={p}>
            {p}
          </option>
        ))}
      </select>
      <label className="mb-1 text-[10px] font-semibold uppercase text-ink-muted">Assignee</label>
      <select
        value={assigneeId ?? ''}
        onChange={(e) => {
          const next = e.target.value || null
          setAssigneeId(next)
          void getSpacesAPI()
            .updateTask({ id: task.id, assigneeId: next })
            .then(() => refreshActiveSpace())
        }}
        className="w-full rounded-lg border border-surface-border bg-surface px-2 py-1.5 text-xs text-ink"
      >
        <option value="">Unassigned</option>
        {members.map((m) => (
          <option key={m.userId} value={m.userId}>
            {m.name}
          </option>
        ))}
      </select>
      <p className="mt-4 text-[10px] text-ink-muted">
        Comments and file attachments sync when Supabase is configured in .env.
      </p>
    </div>
  )
}
