import { useEffect, useState } from 'react'
import { getSpacesAPI } from '../../lib/api'
import { useSpacesStore } from '../../stores/spaces-store'
import { TaskStatusBadge } from '../layout/TopBar'
import type { ChecklistItem, Task, TaskPriority, TaskStatus } from '../../../shared/types'

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
  const taskComments = useSpacesStore((s) => s.taskComments)
  const postComment = useSpacesStore((s) => s.postComment)
  const [title, setTitle] = useState(task.title)
  const [description, setDescription] = useState(task.description)
  const [status, setStatus] = useState(task.status)
  const [priority, setPriority] = useState(task.priority)
  const [assigneeId, setAssigneeId] = useState<string | null>(task.assigneeId)
  const [startDate, setStartDate] = useState(task.startDate?.slice(0, 10) ?? '')
  const [dueDate, setDueDate] = useState(task.dueDate?.slice(0, 10) ?? '')
  const [tagsText, setTagsText] = useState(task.tags.join(', '))
  const [checklist, setChecklist] = useState<ChecklistItem[]>(task.checklist)
  const [newComment, setNewComment] = useState('')

  useEffect(() => {
    setTitle(task.title)
    setDescription(task.description)
    setStatus(task.status)
    setPriority(task.priority)
    setAssigneeId(task.assigneeId)
    setStartDate(task.startDate?.slice(0, 10) ?? '')
    setDueDate(task.dueDate?.slice(0, 10) ?? '')
    setTagsText(task.tags.join(', '))
    setChecklist(task.checklist)
  }, [task.id])

  const save = async (patch: Omit<import('../../../shared/types').UpdateTaskInput, 'id'>): Promise<void> => {
    await getSpacesAPI().updateTask({ id: task.id, ...patch })
    await refreshActiveSpace()
  }

  const toggleChecklistItem = (itemId: string): void => {
    const next = checklist.map((c) => (c.id === itemId ? { ...c, done: !c.done } : c))
    setChecklist(next)
    void save({ checklist: next })
  }

  const addChecklistItem = (): void => {
    const next = [...checklist, { id: crypto.randomUUID(), title: 'New item', done: false }]
    setChecklist(next)
    void save({ checklist: next })
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
        onBlur={() => void save({ title })}
        className="mb-2 w-full rounded-lg border border-surface-border bg-surface px-2 py-1.5 text-sm font-medium text-ink focus:outline-none focus:ring-2 focus:ring-accent/15"
      />
      <textarea
        value={description}
        onChange={(e) => setDescription(e.target.value)}
        onBlur={() => void save({ description })}
        rows={4}
        placeholder="Description, links, operational notes…"
        className="mb-3 w-full resize-none rounded-lg border border-surface-border bg-surface px-2 py-1.5 text-xs text-ink-secondary focus:outline-none focus:ring-2 focus:ring-accent/15"
      />

      <label className="mb-1 text-[10px] font-semibold uppercase text-ink-muted">Status</label>
      <select
        value={status}
        onChange={(e) => {
          const next = e.target.value as TaskStatus
          setStatus(next)
          void save({ status: next })
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
          const next = e.target.value as TaskPriority
          setPriority(next)
          void save({ priority: next })
        }}
        className="mb-3 w-full rounded-lg border border-surface-border bg-surface px-2 py-1.5 text-xs text-ink"
      >
        {PRIORITIES.map((p) => (
          <option key={p} value={p}>
            {p}
          </option>
        ))}
      </select>

      <label className="mb-1 text-[10px] font-semibold uppercase text-ink-muted">Start date</label>
      <input
        type="date"
        value={startDate}
        onChange={(e) => {
          const next = e.target.value || null
          setStartDate(e.target.value)
          void save({ startDate: next })
        }}
        className="mb-2 w-full rounded-lg border border-surface-border bg-surface px-2 py-1.5 text-xs text-ink"
      />

      <label className="mb-1 text-[10px] font-semibold uppercase text-ink-muted">Due date</label>
      <input
        type="date"
        value={dueDate}
        onChange={(e) => {
          const next = e.target.value || null
          setDueDate(e.target.value)
          void save({ dueDate: next })
        }}
        className="mb-3 w-full rounded-lg border border-surface-border bg-surface px-2 py-1.5 text-xs text-ink"
      />

      <label className="mb-1 text-[10px] font-semibold uppercase text-ink-muted">Assignee</label>
      <select
        value={assigneeId ?? ''}
        onChange={(e) => {
          const next = e.target.value || null
          setAssigneeId(next)
          void save({ assigneeId: next })
        }}
        className="mb-3 w-full rounded-lg border border-surface-border bg-surface px-2 py-1.5 text-xs text-ink"
      >
        <option value="">Unassigned</option>
        {members.map((m) => (
          <option key={m.userId} value={m.userId}>
            {m.name}
          </option>
        ))}
      </select>

      <label className="mb-1 text-[10px] font-semibold uppercase text-ink-muted">Tags</label>
      <input
        value={tagsText}
        onChange={(e) => setTagsText(e.target.value)}
        onBlur={() => {
          const tags = tagsText
            .split(',')
            .map((t) => t.trim())
            .filter(Boolean)
          void save({ tags })
        }}
        placeholder="comma, separated"
        className="mb-3 w-full rounded-lg border border-surface-border bg-surface px-2 py-1.5 text-xs text-ink"
      />

      <div className="mb-3">
        <div className="mb-1 flex items-center justify-between">
          <span className="text-[10px] font-semibold uppercase text-ink-muted">Checklist</span>
          <button type="button" onClick={addChecklistItem} className="text-[10px] text-accent hover:underline">
            + Add
          </button>
        </div>
        <ul className="space-y-1">
          {checklist.map((item) => (
            <li key={item.id} className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={item.done}
                onChange={() => toggleChecklistItem(item.id)}
                className="rounded border-surface-border"
              />
              <span className={item.done ? 'text-xs text-ink-muted line-through' : 'text-xs text-ink'}>
                {item.title}
              </span>
            </li>
          ))}
        </ul>
      </div>

      <div className="border-t border-surface-border pt-3">
        <label className="mb-2 block text-[10px] font-semibold uppercase text-ink-muted">Comments</label>
        <ul className="mb-2 max-h-32 space-y-2 overflow-y-auto">
          {taskComments.map((c) => (
            <li key={c.id} className="rounded-lg bg-surface px-2 py-1.5">
              <p className="text-[10px] font-medium text-ink-secondary">{c.userName}</p>
              <p className="text-xs text-ink">{c.body}</p>
            </li>
          ))}
        </ul>
        <div className="flex gap-1">
          <input
            value={newComment}
            onChange={(e) => setNewComment(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && newComment.trim()) {
                void postComment(newComment).then(() => setNewComment(''))
              }
            }}
            placeholder="Add a comment…"
            className="flex-1 rounded-lg border border-surface-border bg-surface px-2 py-1 text-xs"
          />
          <button
            type="button"
            disabled={!newComment.trim()}
            onClick={() => void postComment(newComment).then(() => setNewComment(''))}
            className="rounded-lg bg-accent px-2 py-1 text-xs text-white disabled:opacity-40"
          >
            Post
          </button>
        </div>
      </div>
    </div>
  )
}
