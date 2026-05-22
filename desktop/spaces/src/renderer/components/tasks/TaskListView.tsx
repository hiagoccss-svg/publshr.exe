import { format } from 'date-fns'
import { useSpacesStore } from '../../stores/spaces-store'
import { TaskStatusBadge } from '../layout/TopBar'
import type { Task, TaskPriority } from '../../../shared/types'
import clsx from 'clsx'

const PRIORITY_STYLES: Record<TaskPriority, string> = {
  none: 'text-ink-muted',
  low: 'text-ink-muted',
  normal: 'text-ink-secondary',
  high: 'text-amber-700',
  urgent: 'text-red-600 font-medium'
}

export function TaskListView(): React.ReactElement {
  const tasks = useSpacesStore((s) => s.tasks)
  const setSelectedTask = useSpacesStore((s) => s.setSelectedTask)
  const createTask = useSpacesStore((s) => s.createTask)

  if (tasks.length === 0) {
    return (
      <EmptyTasks onCreate={() => void createTask('New operational task')} />
    )
  }

  return (
    <div className="animate-fade-in overflow-hidden rounded-xl border border-surface-border bg-surface-raised shadow-card">
      <table className="w-full text-left text-sm">
        <thead>
          <tr className="border-b border-surface-border text-[11px] uppercase tracking-wide text-ink-muted">
            <th className="px-4 py-2 font-medium">Task</th>
            <th className="px-3 py-2 font-medium">Status</th>
            <th className="px-3 py-2 font-medium">Priority</th>
            <th className="px-3 py-2 font-medium">Due</th>
            <th className="px-3 py-2 font-medium">Progress</th>
          </tr>
        </thead>
        <tbody>
          {tasks.map((task) => (
            <TaskRow key={task.id} task={task} onSelect={() => setSelectedTask(task.id)} />
          ))}
        </tbody>
      </table>
    </div>
  )
}

function TaskRow({ task, onSelect }: { task: Task; onSelect: () => void }): React.ReactElement {
  const done = task.checklist.filter((c) => c.done).length
  const total = task.checklist.length
  const progress = total > 0 ? Math.round((done / total) * 100) : null

  return (
    <tr
      onClick={onSelect}
      className="cursor-pointer border-b border-surface-border/60 transition hover:bg-surface-muted/40 last:border-0"
    >
      <td className="px-4 py-2.5">
        <p className="font-medium text-ink">{task.title}</p>
        {task.description && (
          <p className="mt-0.5 line-clamp-1 text-xs text-ink-muted">{task.description}</p>
        )}
      </td>
      <td className="px-3 py-2.5">
        <TaskStatusBadge status={task.status} />
      </td>
      <td className={clsx('px-3 py-2.5 text-xs capitalize', PRIORITY_STYLES[task.priority])}>
        {task.priority === 'none' ? '—' : task.priority}
      </td>
      <td className="px-3 py-2.5 text-xs text-ink-secondary">
        {task.dueDate ? format(new Date(task.dueDate), 'MMM d') : '—'}
      </td>
      <td className="px-3 py-2.5 text-xs text-ink-muted">
        {progress !== null ? `${progress}%` : '—'}
      </td>
    </tr>
  )
}

function EmptyTasks({ onCreate }: { onCreate: () => void }): React.ReactElement {
  return (
    <div className="flex min-h-[360px] flex-col items-center justify-center rounded-xl border border-dashed border-surface-border bg-surface-raised/40 text-center">
      <p className="text-sm font-medium text-ink">No tasks yet.</p>
      <p className="mt-1 max-w-md text-xs text-ink-muted">
        Create your first operational task, document, or campaign activity.
      </p>
      <button
        type="button"
        onClick={onCreate}
        className="mt-4 rounded-lg bg-accent px-4 py-2 text-xs font-medium text-white hover:bg-accent-hover"
      >
        Create Task
      </button>
    </div>
  )
}
