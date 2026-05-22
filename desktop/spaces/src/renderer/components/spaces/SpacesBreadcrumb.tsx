import { ChevronRight } from 'lucide-react'
import { useSpacesStore } from '../../stores/spaces-store'

export function SpacesBreadcrumb(): React.ReactElement {
  const spaces = useSpacesStore((s) => s.spaces)
  const folders = useSpacesStore((s) => s.folders)
  const lists = useSpacesStore((s) => s.lists)
  const activeSpaceId = useSpacesStore((s) => s.activeSpaceId)
  const activeListId = useSpacesStore((s) => s.activeListId)
  const setActiveList = useSpacesStore((s) => s.setActiveList)
  const setActiveFolder = useSpacesStore((s) => s.setActiveFolder)

  const space = spaces.find((s) => s.id === activeSpaceId)
  const list = lists.find((l) => l.id === activeListId)
  const folder = list?.folderId ? folders.find((f) => f.id === list.folderId) : null

  if (!space) return <span className="text-sm text-ink-muted">Spaces</span>

  const crumbs: { label: string; onClick?: () => void }[] = [{ label: space.name }]
  if (folder) crumbs.push({ label: folder.name, onClick: () => void setActiveFolder(folder.id) })
  if (list) crumbs.push({ label: list.name, onClick: () => void setActiveList(list.id) })
  else if (!list && activeListId === null) crumbs.push({ label: 'All tasks' })

  return (
    <nav className="flex min-w-0 flex-wrap items-center gap-1 text-sm">
      {crumbs.map((c, i) => (
        <span key={`${c.label}-${i}`} className="flex items-center gap-1">
          {i > 0 && <ChevronRight className="h-3.5 w-3.5 shrink-0 text-ink-muted" />}
          {c.onClick && i < crumbs.length - 1 ? (
            <button type="button" onClick={c.onClick} className="truncate text-ink-secondary hover:text-accent">
              {c.label}
            </button>
          ) : (
            <span className={i === crumbs.length - 1 ? 'truncate font-medium text-ink' : 'truncate text-ink-secondary'}>
              {c.label}
            </span>
          )}
        </span>
      ))}
    </nav>
  )
}
