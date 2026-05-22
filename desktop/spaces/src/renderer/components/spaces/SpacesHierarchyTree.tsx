import { ChevronDown, ChevronRight, Folder, Inbox, List, Plus } from 'lucide-react'
import clsx from 'clsx'
import { useSpacesStore } from '../../stores/spaces-store'

export function SpacesHierarchyTree(): React.ReactElement {
  const folders = useSpacesStore((s) => s.folders)
  const lists = useSpacesStore((s) => s.lists)
  const activeListId = useSpacesStore((s) => s.activeListId)
  const expandedFolderIds = useSpacesStore((s) => s.expandedFolderIds)
  const setActiveList = useSpacesStore((s) => s.setActiveList)
  const setActiveFolder = useSpacesStore((s) => s.setActiveFolder)
  const toggleFolderExpanded = useSpacesStore((s) => s.toggleFolderExpanded)
  const createFolder = useSpacesStore((s) => s.createFolder)
  const createList = useSpacesStore((s) => s.createList)

  const standaloneLists = lists.filter((l) => !l.folderId)

  return (
    <div className="mt-3 space-y-1 border-t border-surface-border pt-3">
      <p className="px-2 text-[10px] font-semibold uppercase tracking-wide text-ink-muted">In this space</p>

      <TreeRow
        icon={Inbox}
        label="All tasks"
        selected={activeListId === null}
        onClick={() => void setActiveList(null)}
      />

      {folders.map((folder) => {
        const expanded = expandedFolderIds[folder.id] !== false
        const folderLists = lists.filter((l) => l.folderId === folder.id)
        return (
          <div key={folder.id}>
            <div className="flex items-center">
              <button
                type="button"
                onClick={() => toggleFolderExpanded(folder.id)}
                className="shrink-0 rounded p-0.5 text-ink-muted hover:bg-surface-muted"
              >
                {expanded ? <ChevronDown className="h-3 w-3" /> : <ChevronRight className="h-3 w-3" />}
              </button>
              <TreeRow
                icon={Folder}
                label={folder.name}
                selected={false}
                indent={0}
                className="flex-1"
                onClick={() => void setActiveFolder(folder.id)}
              />
            </div>
            {expanded &&
              folderLists.map((list) => (
                <TreeRow
                  key={list.id}
                  icon={List}
                  label={list.name}
                  selected={activeListId === list.id}
                  indent={1}
                  onClick={() => void setActiveList(list.id)}
                />
              ))}
            {expanded && (
              <button
                type="button"
                onClick={() => {
                  const name = window.prompt('List name', 'List')
                  if (name?.trim()) void createList(name.trim(), folder.id)
                }}
                className="ml-7 flex items-center gap-1 py-1 text-[11px] text-ink-muted hover:text-accent"
              >
                <Plus className="h-3 w-3" />
                Add list
              </button>
            )}
          </div>
        )
      })}

      {standaloneLists.length > 0 && folders.length > 0 && (
        <p className="px-2 pt-2 text-[10px] font-semibold uppercase tracking-wide text-ink-muted">Lists</p>
      )}
      {standaloneLists.map((list) => (
        <TreeRow
          key={list.id}
          icon={List}
          label={list.name}
          selected={activeListId === list.id}
          onClick={() => void setActiveList(list.id)}
        />
      ))}

      <div className="flex gap-1 px-2 pt-2">
        <button
          type="button"
          onClick={() => {
            const name = window.prompt('Folder name', 'New Folder')
            if (name?.trim()) void createFolder(name.trim())
          }}
          className="flex-1 rounded border border-dashed border-surface-border py-1 text-[10px] text-ink-muted hover:border-accent/40 hover:text-accent"
        >
          + Folder
        </button>
        <button
          type="button"
          onClick={() => {
            const name = window.prompt('List name', 'List')
            if (name?.trim()) void createList(name.trim(), null)
          }}
          className="flex-1 rounded border border-dashed border-surface-border py-1 text-[10px] text-ink-muted hover:border-accent/40 hover:text-accent"
        >
          + List
        </button>
      </div>
    </div>
  )
}

function TreeRow({
  icon: Icon,
  label,
  selected,
  indent = 0,
  className,
  onClick
}: {
  icon: React.ComponentType<{ className?: string }>
  label: string
  selected: boolean
  indent?: number
  className?: string
  onClick: () => void
}): React.ReactElement {
  return (
    <button
      type="button"
      onClick={onClick}
      className={clsx(
        'flex w-full items-center gap-2 rounded-lg py-1.5 text-left text-xs transition',
        selected ? 'bg-accent-soft font-medium text-accent' : 'text-ink-secondary hover:bg-surface-muted/60',
        className
      )}
      style={{ paddingLeft: 8 + indent * 14 }}
    >
      <Icon className="h-3.5 w-3.5 shrink-0 opacity-70" />
      <span className="truncate">{label}</span>
    </button>
  )
}
