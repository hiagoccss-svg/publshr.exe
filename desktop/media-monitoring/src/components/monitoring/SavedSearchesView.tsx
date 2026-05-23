import { useMonitoringStore } from '@/store/monitoringStore'
import { useActiveMonitor } from '@/hooks/useMonitoring'
import { format } from 'date-fns'

export function SavedSearchesView() {
  const { monitors, setSection } = useMonitoringStore()
  const { selectMonitor } = useActiveMonitor()

  if (monitors.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full text-center px-8">
        <p className="text-content text-[13px] font-medium">No saved searches</p>
        <p className="text-content-dim text-[11px] mt-2 max-w-sm">
          Create a monitor with keywords to save a search. Each monitor tracks mentions over time.
        </p>
        <button
          type="button"
          className="mt-4 rounded-sm px-3 py-1.5 text-[12px] text-white"
          style={{ backgroundColor: 'var(--shell-button, #0e639c)' }}
          onClick={() => {
            setSection('monitoring')
            useMonitoringStore.getState().setShowCreatePanel(true)
          }}
        >
          New monitor
        </button>
      </div>
    )
  }

  return (
    <div className="flex-1 overflow-hidden flex flex-col">
      <div className="px-4 py-2 border-b border-border shrink-0">
        <p className="text-[11px] text-content-muted">{monitors.length} saved searches (monitors)</p>
      </div>
      <div className="flex-1 overflow-y-auto p-2 space-y-1">
        {monitors.map((m) => (
          <button
            key={m.id}
            type="button"
            onClick={() => {
              void selectMonitor(m.id)
              setSection('monitoring')
            }}
            className="w-full text-left rounded-md border border-border/60 px-3 py-2 hover:bg-white/5 transition-colors"
          >
            <p className="text-[13px] font-medium text-content">{m.name}</p>
            <p className="text-[11px] text-content-dim mt-0.5 truncate">{m.keywords}</p>
            <p className="text-[10px] text-content-muted mt-1">
              {m.is_active ? 'Active' : 'Paused'}
              {m.updated_at ? ` · Updated ${format(new Date(m.updated_at), 'MMM d')}` : ''}
            </p>
          </button>
        ))}
      </div>
    </div>
  )
}
