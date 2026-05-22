import { useEffect } from 'react'
import Sidebar from './Sidebar'
import TopBar from './TopBar'
import ContextPanel from './ContextPanel'
import CreateItemPanel from '../planner/CreateItemPanel'
import CommandPalette from '../command/CommandPalette'
import { usePlannerStore } from '@/stores/plannerStore'
import TimelineView from '../views/TimelineView'
import CalendarView from '../views/CalendarView'
import BoardView from '../views/BoardView'
import EditorialGridView from '../views/EditorialGridView'
import ApprovalsView from '../views/ApprovalsView'
import WorkloadView from '../views/WorkloadView'
import ClientView from '../views/ClientView'
import EmptyState from '../planner/EmptyState'

function PlannerWorkspace() {
  const view = usePlannerStore((s) => s.view)
  const items = usePlannerStore((s) => s.items)
  const loading = usePlannerStore((s) => s.loading)

  if (!loading && items.length === 0) {
    return <EmptyState />
  }

  switch (view) {
    case 'timeline':
      return <TimelineView />
    case 'calendar':
      return <CalendarView />
    case 'board':
      return <BoardView />
    case 'editorial_grid':
      return <EditorialGridView />
    case 'approvals':
      return <ApprovalsView />
    case 'workload':
      return <WorkloadView />
    case 'client':
      return <ClientView />
    default:
      return <TimelineView />
  }
}

export default function PlannerShell() {
  const createPanelOpen = usePlannerStore((s) => s.createPanelOpen)
  const contextPanelOpen = usePlannerStore((s) => s.contextPanelOpen)
  const selectedId = usePlannerStore((s) => s.selectedId)

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault()
        window.dispatchEvent(new CustomEvent('planner:command-palette'))
      }
      if ((e.metaKey || e.ctrlKey) && e.key === 'n') {
        e.preventDefault()
        usePlannerStore.getState().setCreatePanelOpen(true)
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  return (
    <div className="glass-shell flex h-screen flex-col">
      <TopBar />
      <div className="flex min-h-0 flex-1">
        <Sidebar />
        <main className="glass-workspace relative min-w-0 flex-1 overflow-hidden">
          <PlannerWorkspace />
        </main>
        {contextPanelOpen && selectedId && <ContextPanel />}
      </div>
      {createPanelOpen && <CreateItemPanel />}
      <CommandPalette />
    </div>
  )
}
