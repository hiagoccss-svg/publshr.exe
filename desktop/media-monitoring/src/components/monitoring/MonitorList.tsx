import clsx from 'clsx'
import { Play, Square, Trash2 } from 'lucide-react'
import { useMonitoringStore } from '@/store/monitoringStore'
import { useActiveMonitor } from '@/hooks/useMonitoring'
import { shell } from '@/theme/shellTheme'

export function MonitorList() {
  const { monitors, activeMonitorId, isMonitoring } = useMonitoringStore()
  const { selectMonitor, startLive, stopLive } = useActiveMonitor()

  if (monitors.length === 0) return null

  return (
    <div className="flex-1 overflow-y-auto min-h-0">
      <p className="shell-section-header px-3 pt-2 pb-1">Monitors</p>
      {monitors.map((m) => {
        const selected = activeMonitorId === m.id
        return (
          <div
            key={m.id}
            className={clsx(
              'flex items-center gap-0.5 px-2 py-1 text-[12px] group mx-1 rounded-sm',
              selected ? 'shell-list-row-selected' : 'text-content-muted hover:bg-surface-highlight/50'
            )}
            style={selected ? { backgroundColor: shell.highlight } : undefined}
          >
            <button type="button" className="flex-1 text-left truncate min-w-0" onClick={() => void selectMonitor(m.id)}>
              <span className="flex items-center gap-1.5 text-content">
                {m.is_active ? (
                  <span className="w-1.5 h-1.5 rounded-full bg-sentiment-positive shrink-0" />
                ) : (
                  <span className="w-1.5 h-1.5 rounded-full bg-content-dim shrink-0" />
                )}
                <span className={clsx('truncate', selected && 'text-content')}>{m.name}</span>
              </span>
              <span className="text-[10px] text-content-dim truncate block pl-3">{m.keywords}</span>
            </button>
            {selected && (
              <button
                type="button"
                className="p-1 opacity-0 group-hover:opacity-100 text-content-muted hover:text-accent shrink-0"
                onClick={() => (isMonitoring ? stopLive() : startLive())}
                aria-label={isMonitoring ? 'Stop' : 'Start'}
              >
                {isMonitoring ? <Square size={11} /> : <Play size={11} />}
              </button>
            )}
            <button
              type="button"
              className="p-1 opacity-0 group-hover:opacity-100 text-content-muted hover:text-sentiment-negative shrink-0"
              onClick={async () => {
                await window.publshr.deleteMonitor(m.id)
                const next = monitors.filter((x) => x.id !== m.id)
                useMonitoringStore.getState().setMonitors(next)
              }}
              aria-label="Delete"
            >
              <Trash2 size={11} />
            </button>
          </div>
        )
      })}
    </div>
  )
}
