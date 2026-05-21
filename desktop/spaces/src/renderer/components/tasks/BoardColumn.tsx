import { useDroppable } from '@dnd-kit/core'
import { SortableContext, useSortable, verticalListSortingStrategy } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import clsx from 'clsx'
import type { Task, TaskStatus } from '../../../shared/types'
import { BoardCard } from './TaskBoardView'

export function DroppableColumn({
  status,
  title,
  tasks,
  onSelectTask
}: {
  status: TaskStatus
  title: string
  tasks: Task[]
  onSelectTask: (id: string) => void
}): React.ReactElement {
  const { setNodeRef, isOver } = useDroppable({ id: status })

  return (
    <section
      ref={setNodeRef}
      className={clsx(
        'flex w-64 shrink-0 flex-col rounded-xl border bg-surface-muted/30',
        isOver ? 'border-accent/40 bg-accent-soft/20' : 'border-surface-border'
      )}
    >
      <header className="flex items-center justify-between px-3 py-2">
        <h3 className="text-xs font-semibold text-ink-secondary">{title}</h3>
        <span className="rounded bg-surface-raised px-1.5 text-[10px] text-ink-muted">{tasks.length}</span>
      </header>
      <SortableContext items={tasks.map((t) => t.id)} strategy={verticalListSortingStrategy}>
        <div className="flex flex-1 flex-col gap-2 overflow-y-auto px-2 pb-2">
          {tasks.map((task) => (
            <SortableBoardCard key={task.id} task={task} onSelect={() => onSelectTask(task.id)} />
          ))}
        </div>
      </SortableContext>
    </section>
  )
}

function SortableBoardCard({ task, onSelect }: { task: Task; onSelect: () => void }): React.ReactElement {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({
    id: task.id
  })
  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.4 : 1
  }

  return (
    <div ref={setNodeRef} style={style} {...attributes} {...listeners}>
      <BoardCard task={task} onClick={onSelect} />
    </div>
  )
}
