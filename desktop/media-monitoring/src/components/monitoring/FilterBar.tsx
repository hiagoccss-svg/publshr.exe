import { RefreshCw } from 'lucide-react'
import clsx from 'clsx'
import { useMonitoringStore } from '@/store/monitoringStore'
import { useActiveMonitor } from '@/hooks/useMonitoring'
import type { Sentiment } from '@/types'
import { shell } from '@/theme/shellTheme'

const SENTIMENTS: { value: Sentiment | ''; label: string }[] = [
  { value: '', label: 'All sentiment' },
  { value: 'positive', label: 'Positive' },
  { value: 'neutral', label: 'Neutral' },
  { value: 'negative', label: 'Negative' },
  { value: 'mixed', label: 'Mixed' }
]

const SORTS = [
  { value: 'newest', label: 'Newest' },
  { value: 'oldest', label: 'Oldest' },
  { value: 'reach', label: 'Highest reach' },
  { value: 'pr_value', label: 'Highest PR value' },
  { value: 'relevance', label: 'Most relevant' }
]

export function FilterBar() {
  const { filters, setFilters, isMonitoring, activeMonitorId } = useMonitoringStore()
  const { startLive, stopLive } = useActiveMonitor()

  return (
    <div
      className="flex flex-wrap items-center gap-2 px-3 py-1.5 border-b shrink-0"
      style={{ backgroundColor: shell.workspace, borderColor: shell.border }}
    >
      <button
        type="button"
        className={clsx(
          'flex items-center gap-1 text-[11px] px-2 py-1 rounded border app-no-drag',
          isMonitoring ? 'text-accent border-accent/40' : 'text-content-muted border-border'
        )}
        disabled={!activeMonitorId}
        onClick={() => (isMonitoring ? stopLive() : startLive())}
      >
        <RefreshCw size={12} className={clsx(isMonitoring && 'animate-spin')} />
        {isMonitoring ? 'Stop live' : 'Start live'}
      </button>
      <select
        className="input-field w-auto text-xs py-1"
        value={filters.sentiment}
        onChange={(e) => setFilters({ sentiment: e.target.value })}
      >
        {SENTIMENTS.map((s) => (
          <option key={s.value} value={s.value}>
            {s.label}
          </option>
        ))}
      </select>
      <select
        className="input-field w-auto text-xs py-1"
        value={filters.sort}
        onChange={(e) => setFilters({ sort: e.target.value })}
      >
        {SORTS.map((s) => (
          <option key={s.value} value={s.value}>
            {s.label}
          </option>
        ))}
      </select>
      <label className="flex items-center gap-1.5 text-xs text-content-muted cursor-pointer">
        <input
          type="checkbox"
          checked={filters.savedOnly}
          onChange={(e) => setFilters({ savedOnly: e.target.checked })}
          className="rounded border-border-subtle"
        />
        Saved only
      </label>
    </div>
  )
}
