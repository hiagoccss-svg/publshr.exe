import { useSpacesStore } from '../../stores/spaces-store'
import { SpaceOverview } from '../spaces/SpaceOverview'
import { TaskListView } from '../tasks/TaskListView'
import { TaskBoardView } from '../tasks/TaskBoardView'
import { EmptySpaceState } from '../spaces/EmptySpaceState'
import { PlaceholderSection } from '../spaces/PlaceholderSection'

export function WorkspaceArea(): React.ReactElement {
  const activeSection = useSpacesStore((s) => s.activeSection)
  const activeSpaceId = useSpacesStore((s) => s.activeSpaceId)
  const taskView = useSpacesStore((s) => s.taskView)
  const setTaskView = useSpacesStore((s) => s.setTaskView)

  if (activeSection !== 'spaces') {
    return <PlaceholderSection section={activeSection} />
  }

  if (!activeSpaceId) {
    return <EmptySpaceState />
  }

  return (
    <main className="flex min-w-0 flex-1 flex-col overflow-hidden">
      <div className="flex shrink-0 items-center gap-1 border-b border-surface-border px-4 py-2">
        {(
          [
            ['overview', 'Overview'],
            ['list', 'List'],
            ['board', 'Board'],
            ['timeline', 'Timeline'],
            ['calendar', 'Calendar'],
            ['workload', 'Workload'],
            ['priority', 'Priority']
          ] as const
        ).map(([id, label]) => (
          <button
            key={id}
            type="button"
            onClick={() => setTaskView(id)}
            className={
              taskView === id
                ? 'rounded-lg bg-accent-soft px-3 py-1 text-xs font-medium text-accent'
                : 'rounded-lg px-3 py-1 text-xs text-ink-muted hover:bg-surface-muted hover:text-ink-secondary'
            }
          >
            {label}
          </button>
        ))}
      </div>

      <div className="min-h-0 flex-1 overflow-auto p-4">
        {taskView === 'overview' && <SpaceOverview />}
        {taskView === 'list' && <TaskListView />}
        {taskView === 'board' && <TaskBoardView />}
        {(taskView === 'timeline' ||
          taskView === 'calendar' ||
          taskView === 'workload' ||
          taskView === 'priority' ||
          taskView === 'document') && (
          <PhasePlaceholder view={taskView} />
        )}
      </div>
    </main>
  )
}

function PhasePlaceholder({ view }: { view: string }): React.ReactElement {
  const labels: Record<string, string> = {
    timeline: 'Timeline / Gantt',
    calendar: 'Calendar',
    workload: 'Workload',
    priority: 'Priority',
    document: 'Document'
  }
  return (
    <div className="flex h-full min-h-[320px] flex-col items-center justify-center rounded-xl border border-dashed border-surface-border bg-surface-raised/50">
      <p className="text-sm font-medium text-ink">{labels[view] ?? view}</p>
      <p className="mt-1 max-w-sm text-center text-xs text-ink-muted">
        Scheduled for Phase 2–3. List and Board views are fully operational in Phase 1.
      </p>
    </div>
  )
}
