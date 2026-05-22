import { Plus } from 'lucide-react'
import { useSpacesStore } from '../../stores/spaces-store'
import { SpaceOverview } from '../spaces/SpaceOverview'
import { SpacesHomeView } from '../spaces/SpacesHomeView'
import { TaskListView } from '../tasks/TaskListView'
import { TaskBoardView } from '../tasks/TaskBoardView'
import { CalendarView } from '../tasks/CalendarView'
import { TimelineView } from '../tasks/TimelineView'
import { WorkloadView } from '../tasks/WorkloadView'
import { PriorityMatrixView } from '../tasks/PriorityMatrixView'
import { EmptySpaceState } from '../spaces/EmptySpaceState'
import { PlaceholderSection } from '../spaces/PlaceholderSection'
import { SpacesBreadcrumb } from '../spaces/SpacesBreadcrumb'

const VIEW_TABS: { id: 'overview' | 'list' | 'board' | 'calendar' | 'timeline' | 'workload' | 'priority'; label: string }[] = [
  { id: 'overview', label: 'Overview' },
  { id: 'list', label: 'List' },
  { id: 'board', label: 'Board' },
  { id: 'calendar', label: 'Calendar' },
  { id: 'timeline', label: 'Timeline' },
  { id: 'workload', label: 'Workload' },
  { id: 'priority', label: 'Priority' }
]

export function WorkspaceArea(): React.ReactElement {
  const activeSection = useSpacesStore((s) => s.activeSection)
  const spaces = useSpacesStore((s) => s.spaces)
  const activeSpaceId = useSpacesStore((s) => s.activeSpaceId)
  const spacesHomeOpen = useSpacesStore((s) => s.spacesHomeOpen)
  const taskView = useSpacesStore((s) => s.taskView)
  const setTaskView = useSpacesStore((s) => s.setTaskView)
  const createTask = useSpacesStore((s) => s.createTask)

  if (activeSection !== 'spaces') {
    return <PlaceholderSection section={activeSection} />
  }

  if (!activeSpaceId) {
    if (spaces.length === 0) return <EmptySpaceState />
    if (spacesHomeOpen || !activeSpaceId) {
      return (
        <main className="glass-workspace flex min-w-0 flex-1 flex-col overflow-hidden">
          <div className="library-workspace-pad min-h-0 flex-1 overflow-auto">
            <SpacesHomeView />
          </div>
        </main>
      )
    }
    return <EmptySpaceState />
  }

  return (
    <main className="glass-workspace flex min-w-0 flex-1 flex-col overflow-hidden">
      <div className="dt-divider-h flex shrink-0 flex-wrap items-center gap-3 px-4 py-2">
        <SpacesBreadcrumb />
        <div className="ml-auto flex items-center gap-2">
          <TaskQuickAdd onCreate={(title) => void createTask(title)} />
        </div>
      </div>

      <div className="dt-divider-h flex shrink-0 items-center gap-1 px-4 py-2">
        {VIEW_TABS.map(({ id, label }) => (
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

      <div className="library-workspace-pad min-h-0 flex-1 overflow-auto">
        {taskView === 'overview' && <SpaceOverview />}
        {taskView === 'list' && <TaskListView />}
        {taskView === 'board' && <TaskBoardView />}
        {taskView === 'calendar' && <CalendarView />}
        {taskView === 'timeline' && <TimelineView />}
        {taskView === 'workload' && <WorkloadView />}
        {taskView === 'priority' && <PriorityMatrixView />}
      </div>
    </main>
  )
}

function TaskQuickAdd({ onCreate }: { onCreate: (title: string) => void }): React.ReactElement {
  return (
    <form
      className="flex items-center gap-1"
      onSubmit={(e) => {
        e.preventDefault()
        const fd = new FormData(e.currentTarget)
        const title = String(fd.get('title') ?? '').trim()
        if (title) {
          onCreate(title)
          e.currentTarget.reset()
        }
      }}
    >
      <input
        name="title"
        placeholder="New task…"
        className="w-40 rounded-lg border border-surface-border bg-surface px-2 py-1 text-xs text-ink focus:outline-none focus:ring-2 focus:ring-accent/15"
      />
      <button
        type="submit"
        className="flex items-center gap-1 rounded-lg bg-accent px-2 py-1 text-xs font-medium text-white hover:bg-accent-hover"
      >
        <Plus className="h-3 w-3" />
        Add
      </button>
    </form>
  )
}

