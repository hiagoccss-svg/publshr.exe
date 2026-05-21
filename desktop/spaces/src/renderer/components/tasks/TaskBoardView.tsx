import {
  DndContext,
  DragOverlay,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
  type DragStartEvent
} from '@dnd-kit/core'
import { useState } from 'react'
import { MessageSquare, Paperclip } from 'lucide-react'
import { format } from 'date-fns'
import clsx from 'clsx'
import { useSpacesStore } from '../../stores/spaces-store'
import { BOARD_COLUMNS, TASK_STATUS_LABELS, type Task, type TaskStatus } from '../../../shared/types'
import { DroppableColumn } from './BoardColumn'

export function TaskBoardView(): React.ReactElement {
  const tasks = useSpacesStore((s) => s.tasks)
  const updateTaskStatus = useSpacesStore((s) => s.updateTaskStatus)
  const setSelectedTask = useSpacesStore((s) => s.setSelectedTask)
  const createTask = useSpacesStore((s) => s.createTask)
  const [activeId, setActiveId] = useState<string | null>(null)

  const sensors = useSensors(useSensor(PointerSensor, { activationConstraint: { distance: 6 } }))

  const activeTask = tasks.find((t) => t.id === activeId)

  const onDragStart = (e: DragStartEvent): void => setActiveId(String(e.active.id))
  const onDragEnd = (e: DragEndEvent): void => {
    setActiveId(null)
    const taskId = String(e.active.id)
    const newStatus = e.over?.id as TaskStatus | undefined
    if (!newStatus || !BOARD_COLUMNS.includes(newStatus)) return
    const task = tasks.find((t) => t.id === taskId)
    if (task && task.status !== newStatus) void updateTaskStatus(taskId, newStatus)
  }

  if (tasks.length === 0) {
    return (
      <div className="flex min-h-[360px] flex-col items-center justify-center rounded-xl border border-dashed border-surface-border">
        <p className="text-sm text-ink-muted">No tasks on the board.</p>
        <button
          type="button"
          onClick={() => void createTask('New task')}
          className="mt-3 text-xs font-medium text-accent hover:underline"
        >
          Create Task
        </button>
      </div>
    )
  }

  return (
    <DndContext sensors={sensors} onDragStart={onDragStart} onDragEnd={onDragEnd}>
      <div className="flex h-full min-h-[480px] gap-3 overflow-x-auto pb-2">
        {BOARD_COLUMNS.map((status) => (
          <DroppableColumn
            key={status}
            status={status}
            title={TASK_STATUS_LABELS[status]}
            tasks={tasks.filter((t) => t.status === status)}
            onSelectTask={setSelectedTask}
          />
        ))}
      </div>
      <DragOverlay>
        {activeTask ? <BoardCard task={activeTask} isDragging /> : null}
      </DragOverlay>
    </DndContext>
  )
}

export function BoardCard({
  task,
  isDragging,
  onClick
}: {
  task: Task
  isDragging?: boolean
  onClick?: () => void
}): React.ReactElement {
  return (
    <article
      onClick={onClick}
      className={clsx(
        'cursor-pointer rounded-lg border border-surface-border bg-surface-raised p-3 shadow-card transition',
        isDragging && 'rotate-1 opacity-90 shadow-panel',
        !isDragging && 'hover:border-accent/20'
      )}
    >
      <p className="text-sm font-medium leading-snug text-ink">{task.title}</p>
      <div className="mt-2 flex flex-wrap items-center gap-2 text-[10px] text-ink-muted">
        {task.dueDate && <span>{format(new Date(task.dueDate), 'MMM d')}</span>}
        {task.priority !== 'none' && (
          <span className="capitalize text-ink-secondary">{task.priority}</span>
        )}
        {task.commentCount > 0 && (
          <span className="inline-flex items-center gap-0.5">
            <MessageSquare className="h-3 w-3" />
            {task.commentCount}
          </span>
        )}
        {task.attachmentCount > 0 && (
          <span className="inline-flex items-center gap-0.5">
            <Paperclip className="h-3 w-3" />
            {task.attachmentCount}
          </span>
        )}
      </div>
    </article>
  )
}
