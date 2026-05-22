import { useEffect, useState } from 'react'
import { Command } from 'cmdk'
import { usePlannerStore } from '@/stores/plannerStore'
import type { PlannerView } from '@/types/planner'

const COMMANDS: { id: string; label: string; action: (setView: (v: PlannerView) => void, openCreate: () => void) => void }[] = [
  { id: 'create', label: 'Create planner item', action: (_, open) => open() },
  { id: 'timeline', label: 'Open timeline view', action: (setView) => setView('timeline') },
  { id: 'calendar', label: 'Open calendar view', action: (setView) => setView('calendar') },
  { id: 'board', label: 'Open board view', action: (setView) => setView('board') },
  { id: 'approvals', label: 'Open approvals view', action: (setView) => setView('approvals') },
  { id: 'overdue', label: 'Show overdue items', action: () => usePlannerStore.getState().setFilters({ overdueOnly: true }) },
  { id: 'today', label: 'Go to today', action: () => {} }
]

export default function CommandPalette() {
  const [open, setOpen] = useState(false)
  const setView = usePlannerStore((s) => s.setView)
  const setCreatePanelOpen = usePlannerStore((s) => s.setCreatePanelOpen)

  useEffect(() => {
    const handler = () => setOpen(true)
    window.addEventListener('planner:command-palette', handler)
    return () => window.removeEventListener('planner:command-palette', handler)
  }, [])

  if (!open) return null

  return (
    <div className="fixed inset-0 z-[100] flex items-start justify-center bg-ink/15 pt-[15vh] backdrop-blur-[3px]">
      <Command
        className="dt-glass-overlay w-full max-w-lg overflow-hidden rounded-xl"
        onKeyDown={(e) => e.key === 'Escape' && setOpen(false)}
      >
        <Command.Input
          placeholder="Search or run a command…"
          className="w-full border-b border-surface-border bg-transparent px-4 py-3 text-sm outline-none"
          autoFocus
        />
        <Command.List className="max-h-72 overflow-y-auto p-2">
          <Command.Empty className="px-3 py-6 text-center text-xs text-ink-muted">No results.</Command.Empty>
          <Command.Group heading="Commands" className="text-[10px] font-semibold uppercase tracking-wider text-ink-muted px-2 py-1">
            {COMMANDS.map((cmd) => (
              <Command.Item
                key={cmd.id}
                value={cmd.label}
                onSelect={() => {
                  cmd.action(setView, () => setCreatePanelOpen(true))
                  setOpen(false)
                }}
                className="cursor-pointer rounded-lg px-3 py-2 text-sm text-ink aria-selected:bg-accent-soft aria-selected:text-accent"
              >
                {cmd.label}
              </Command.Item>
            ))}
          </Command.Group>
        </Command.List>
      </Command>
      <button type="button" className="fixed inset-0 -z-10" onClick={() => setOpen(false)} aria-label="Close" />
    </div>
  )
}
