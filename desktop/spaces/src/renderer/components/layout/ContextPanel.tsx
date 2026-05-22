import { X } from 'lucide-react'
import { formatDistanceToNow } from 'date-fns'
import { useSpacesStore } from '../../stores/spaces-store'
import { TaskDetailForm } from '../tasks/TaskDetailForm'

export function ContextPanel(): React.ReactElement {
  const selectedTaskId = useSpacesStore((s) => s.selectedTaskId)
  const tasks = useSpacesStore((s) => s.tasks)
  const activity = useSpacesStore((s) => s.activity)
  const setContextPanelOpen = useSpacesStore((s) => s.setContextPanelOpen)
  const setSelectedTask = useSpacesStore((s) => s.setSelectedTask)

  const task = tasks.find((t) => t.id === selectedTaskId)

  return (
    <aside className="dt-glass-panel flex w-[340px] shrink-0 flex-col">
      <div className="dt-divider-h flex items-center justify-between px-3 py-2">
        <span className="text-xs font-semibold uppercase tracking-wide text-ink-muted">Context</span>
        <button
          type="button"
          onClick={() => setContextPanelOpen(false)}
          className="rounded p-1 text-ink-muted hover:bg-surface-muted"
        >
          <X className="h-4 w-4" />
        </button>
      </div>

      {task ? (
        <TaskDetailForm task={task} onClose={() => void setSelectedTask(null)} />
      ) : (
        <div className="flex-1 overflow-y-auto p-3">
          <p className="mb-3 text-xs text-ink-muted">Select a task to inspect details, checklist, and links.</p>
          <h3 className="mb-2 text-xs font-semibold text-ink-secondary">Recent activity</h3>
          <ul className="space-y-2">
            {activity.slice(0, 12).map((a) => (
              <li key={a.id} className="dt-content-surface-muted rounded-lg px-2 py-1.5">
                <p className="text-xs text-ink">
                  <span className="font-medium">{a.userName}</span> {a.action}
                </p>
                <p className="text-[10px] text-ink-muted">
                  {formatDistanceToNow(new Date(a.createdAt), { addSuffix: true })}
                </p>
              </li>
            ))}
            {activity.length === 0 && (
              <li className="text-xs text-ink-muted">No activity yet.</li>
            )}
          </ul>
        </div>
      )}
    </aside>
  )
}
