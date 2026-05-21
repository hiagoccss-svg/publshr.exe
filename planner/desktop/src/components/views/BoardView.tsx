import { DndContext, DragEndEvent, closestCorners, useDraggable, useDroppable } from '@dnd-kit/core'
import { useFilteredItems, usePlannerStore } from '@/stores/plannerStore'
import { BOARD_COLUMNS, type PlannerItemStatus } from '@/types/planner'
import PlannerCard from '../planner/PlannerCard'

export default function BoardView() {
  const items = useFilteredItems()
  const moveItemStatus = usePlannerStore((s) => s.moveItemStatus)
  const selectedId = usePlannerStore((s) => s.selectedId)
  const setSelectedId = usePlannerStore((s) => s.setSelectedId)

  const onDragEnd = (event: DragEndEvent) => {
    const { active, over } = event
    if (!over || active.id === over.id) return
    const status = String(over.id) as PlannerItemStatus
    if (BOARD_COLUMNS.some((c) => c.id === status)) {
      void moveItemStatus(String(active.id), status)
    }
  }

  return (
    <DndContext collisionDetection={closestCorners} onDragEnd={onDragEnd}>
      <div className="flex h-full gap-3 overflow-x-auto p-4">
        {BOARD_COLUMNS.map((col) => (
          <BoardColumn
            key={col.id}
            status={col.id}
            label={col.label}
            items={items.filter((i) => i.status === col.id)}
            selectedId={selectedId}
            onSelect={setSelectedId}
          />
        ))}
      </div>
    </DndContext>
  )
}

function BoardColumn({
  status,
  label,
  items,
  selectedId,
  onSelect
}: {
  status: PlannerItemStatus
  label: string
  items: ReturnType<typeof useFilteredItems>
  selectedId: string | null
  onSelect: (id: string) => void
}) {
  const { setNodeRef, isOver } = useDroppable({ id: status })

  return (
    <div
      ref={setNodeRef}
      className={`flex w-64 shrink-0 flex-col rounded-xl bg-surface-muted/50 ${isOver ? 'ring-1 ring-accent/30' : ''}`}
    >
      <div className="flex items-center justify-between px-3 py-2">
        <span className="text-xs font-medium text-ink-secondary">{label}</span>
        <span className="text-[10px] text-ink-muted">{items.length}</span>
      </div>
      <div className="flex-1 space-y-2 overflow-y-auto px-2 pb-2">
        {items.map((item) => (
          <DraggableCard
            key={item.id}
            item={item}
            selected={selectedId === item.id}
            onSelect={() => onSelect(item.id)}
          />
        ))}
      </div>
    </div>
  )
}

function DraggableCard({
  item,
  selected,
  onSelect
}: {
  item: ReturnType<typeof useFilteredItems>[0]
  selected: boolean
  onSelect: () => void
}) {
  const { attributes, listeners, setNodeRef, transform, isDragging } = useDraggable({ id: item.id })

  const style = transform
    ? { transform: `translate(${transform.x}px, ${transform.y}px)`, opacity: isDragging ? 0.6 : 1 }
    : undefined

  return (
    <div ref={setNodeRef} style={style} {...listeners} {...attributes}>
      <PlannerCard item={item} selected={selected} onSelect={onSelect} />
    </div>
  )
}
