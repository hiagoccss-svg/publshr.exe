import clsx from 'clsx'
import { useMemo } from 'react'
import { useSpacesStore } from '../../stores/spaces-store'
import { TaskStatusBadge } from '../layout/TopBar'
import type { Task } from '../../../shared/types'

/** ClickUp Workload — open tasks grouped by assignee with capacity hints. */
export function WorkloadView(): React.ReactElement {
  const tasks = useSpacesStore((s) => s.tasks)
  const members = useSpacesStore((s) => s.members)
  const setSelectedTask = useSpacesStore((s) => s.setSelectedTask)

  const openTasks = tasks.filter((t) => t.status !== 'completed' && t.status !== 'archived')

  const columns = useMemo(() => {
    const byUser = new Map<string, Task[]>()
    const unassigned: Task[] = []

    for (const task of openTasks) {
      if (!task.assigneeId) {
        unassigned.push(task)
        continue
      }
      const list = byUser.get(task.assigneeId) ?? []
      list.push(task)
      byUser.set(task.assigneeId, list)
    }

    const memberCols = members.map((m) => ({
      id: m.userId,
      name: m.name,
      color: m.avatarColor,
      tasks: byUser.get(m.userId) ?? []
    }))

    if (unassigned.length > 0) {
      memberCols.push({ id: '_none', name: 'Unassigned', color: '#94a3b8', tasks: unassigned })
    }

    return memberCols
  }, [openTasks, members])

  return (
    <div className="flex h-full min-h-[320px] gap-3 overflow-x-auto pb-2">
      {columns.map((col) => (
        <div
          key={col.id}
          className="flex w-64 shrink-0 flex-col rounded-xl border border-surface-border bg-surface-raised shadow-card"
        >
          <header className="border-b border-surface-border px-3 py-2">
            <div className="flex items-center gap-2">
              <span className="h-6 w-6 rounded-full text-center text-[10px] font-bold leading-6 text-white" style={{ backgroundColor: col.color }}>
                {col.name.slice(0, 1).toUpperCase()}
              </span>
              <div>
                <p className="text-xs font-semibold text-ink">{col.name}</p>
                <p className="text-[10px] text-ink-muted">
                  {col.tasks.length} task{col.tasks.length === 1 ? '' : 's'}
                  {col.tasks.length > 8 && ' · heavy load'}
                </p>
              </div>
            </div>
          </header>
          <ul className="flex-1 space-y-1 overflow-y-auto p-2">
            {col.tasks.map((task) => (
              <li key={task.id}>
                <button
                  type="button"
                  onClick={() => void setSelectedTask(task.id)}
                  className={clsx(
                    'w-full rounded-lg border border-surface-border/60 px-2 py-1.5 text-left text-xs',
                    'hover:border-accent/30 hover:bg-surface-muted/50'
                  )}
                >
                  <p className="font-medium text-ink">{task.title}</p>
                  <div className="mt-1 flex items-center gap-1">
                    <TaskStatusBadge status={task.status} />
                    {task.priority !== 'none' && (
                      <span className="text-[10px] capitalize text-ink-muted">{task.priority}</span>
                    )}
                  </div>
                </button>
              </li>
            ))}
            {col.tasks.length === 0 && (
              <li className="px-2 py-4 text-center text-[10px] text-ink-muted">No tasks</li>
            )}
          </ul>
        </div>
      ))}
      {columns.length === 0 && (
        <p className="text-sm text-ink-muted">No open tasks in this location.</p>
      )}
    </div>
  )
}
