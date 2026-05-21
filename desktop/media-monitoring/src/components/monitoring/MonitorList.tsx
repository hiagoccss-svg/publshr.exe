import clsx from 'clsx'
import { Play, Square, Trash2 } from 'lucide-react'
import { useMonitoringStore } from '@/store/monitoringStore'
import { useActiveMonitor } from '@/hooks/useMonitoring'

export function MonitorList() {
  const { monitors, activeMonitorId, isMonitoring } = useMonitoringStore()
  const { selectMonitor, startLive, stopLive } = useActiveMonitor()

  if (monitors.length === 0) return null

  return (
    <div className="border-b border-border px-3 py-2 space-y-1 shrink-0 max-h-40 overflow-y-auto">
      <p className="text-2xs uppercase tracking-wide text-content-header px-1">Active monitors</p>
      {monitors.map((m) => (
        <div
          key={m.id}
          className={clsx(
            'flex items-center gap-1 rounded px-2 py-1 text-sm group',
            activeMonitorId === m.id ? 'bg-surface-highlight text-content' : 'text-content-muted hover:bg-surface-highlight/50'
          )}
        >
          <button type="button" className="flex-1 text-left truncate" onClick={() => void selectMonitor(m.id)}>
            <span className="flex items-center gap-1.5">
              {m.is_active ? (
                <span className="w-1.5 h-1.5 rounded-full bg-sentiment-positive shrink-0" />
              ) : (
                <span className="w-1.5 h-1.5 rounded-full bg-content-dim shrink-0" />
              )}
              {m.name}
            </span>
            <span className="text-2xs text-content-dim">{m.keywords}</span>
          </button>
          {activeMonitorId === m.id && (
            <button
              type="button"
              className="p-1 opacity-0 group-hover:opacity-100 text-content-muted hover:text-accent"
              onClick={() => (isMonitoring ? stopLive() : startLive())}
              aria-label={isMonitoring ? 'Stop' : 'Start'}
            >
              {isMonitoring ? <Square size={12} /> : <Play size={12} />}
            </button>
          )}
          <button
            type="button"
            className="p-1 opacity-0 group-hover:opacity-100 text-content-muted hover:text-sentiment-negative"
            onClick={async () => {
              await window.publshr.deleteMonitor(m.id)
              const next = monitors.filter((x) => x.id !== m.id)
              useMonitoringStore.getState().setMonitors(next)
            }}
            aria-label="Delete"
          >
            <Trash2 size={12} />
          </button>
        </div>
      ))}
    </div>
  )
}
