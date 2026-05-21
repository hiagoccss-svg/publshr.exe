import { useEffect, useState } from 'react'
import { Command } from 'cmdk'
import { useSpacesStore } from '../../stores/spaces-store'
import { getSpacesAPI } from '../../lib/api'
import type { SearchResult, TaskViewMode } from '../../../shared/types'

export function CommandPalette(): React.ReactElement {
  const open = useSpacesStore((s) => s.commandOpen)
  const setCommandOpen = useSpacesStore((s) => s.setCommandOpen)
  const searchQuery = useSpacesStore((s) => s.searchQuery)
  const setSearchQuery = useSpacesStore((s) => s.setSearchQuery)
  const setTaskView = useSpacesStore((s) => s.setTaskView)
  const createTask = useSpacesStore((s) => s.createTask)
  const createSpace = useSpacesStore((s) => s.createSpace)
  const spaces = useSpacesStore((s) => s.spaces)
  const setActiveSpace = useSpacesStore((s) => s.setActiveSpace)
  const [results, setResults] = useState<SearchResult[]>([])

  useEffect(() => {
    if (!open) return
    const q = searchQuery.trim()
    if (!q) {
      setResults([])
      return
    }
    const t = setTimeout(() => {
      void getSpacesAPI()
        .search(q)
        .then(setResults)
    }, 120)
    return () => clearTimeout(t)
  }, [open, searchQuery])

  if (!open) return <></>

  const run = (fn: () => void): void => {
    fn()
    setCommandOpen(false)
    setSearchQuery('')
  }

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center bg-ink/20 pt-[12vh] backdrop-blur-[2px]">
      <Command
        className="w-full max-w-lg overflow-hidden rounded-xl border border-surface-border bg-surface-raised shadow-panel"
        label="Command palette"
      >
        <Command.Input
          value={searchQuery}
          onValueChange={setSearchQuery}
          placeholder="Search or run a command…"
          className="w-full border-b border-surface-border bg-transparent px-4 py-3 text-sm text-ink outline-none placeholder:text-ink-muted"
          autoFocus
        />
        <Command.List className="max-h-80 overflow-y-auto p-2">
          <Command.Empty className="px-3 py-6 text-center text-xs text-ink-muted">
            No results.
          </Command.Empty>

          <Command.Group heading="Actions" className="text-[10px] font-semibold uppercase text-ink-muted">
            <CommandItem onSelect={() => run(() => void createTask('New task'))}>Create task</CommandItem>
            <CommandItem onSelect={() => run(() => void createSpace('New Space'))}>Create Space</CommandItem>
            <CommandItem onSelect={() => run(() => setTaskView('board'))}>Open board view</CommandItem>
            <CommandItem onSelect={() => run(() => setTaskView('list'))}>Open list view</CommandItem>
            <CommandItem onSelect={() => run(() => setTaskView('timeline' as TaskViewMode))}>
              Open timeline
            </CommandItem>
          </Command.Group>

          {spaces.length > 0 && (
            <Command.Group heading="Spaces" className="text-[10px] font-semibold uppercase text-ink-muted">
              {spaces.map((s) => (
                <CommandItem key={s.id} onSelect={() => run(() => void setActiveSpace(s.id))}>
                  {s.name}
                </CommandItem>
              ))}
            </Command.Group>
          )}

          {results.length > 0 && (
            <Command.Group heading="Search" className="text-[10px] font-semibold uppercase text-ink-muted">
              {results.map((r) => (
                <CommandItem key={`${r.type}-${r.id}`} onSelect={() => setCommandOpen(false)}>
                  <span className="font-medium">{r.title}</span>
                  <span className="ml-2 text-ink-muted">{r.type}</span>
                </CommandItem>
              ))}
            </Command.Group>
          )}
        </Command.List>
      </Command>
      <button
        type="button"
        className="fixed inset-0 -z-10"
        aria-label="Close"
        onClick={() => setCommandOpen(false)}
      />
    </div>
  )
}

function CommandItem({
  children,
  onSelect
}: {
  children: React.ReactNode
  onSelect: () => void
}): React.ReactElement {
  return (
    <Command.Item
      onSelect={onSelect}
      className="cursor-pointer rounded-lg px-3 py-2 text-sm text-ink aria-selected:bg-accent-soft aria-selected:text-accent"
    >
      {children}
    </Command.Item>
  )
}
