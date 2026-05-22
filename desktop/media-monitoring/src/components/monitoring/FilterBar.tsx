import { RefreshCw } from 'lucide-react'
import clsx from 'clsx'
import { useMonitoringStore } from '@/store/monitoringStore'
import { useActiveMonitor } from '@/hooks/useMonitoring'
import type { Sentiment } from '@/types'

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
    <div className="shell-toolbar">
      <button
        type="button"
        className={clsx(
          'shell-toolbar-btn',
          isMonitoring && 'shell-toolbar-btn-active'
        )}
        disabled={!activeMonitorId}
        onClick={() => (isMonitoring ? stopLive() : startLive())}
      >
        <RefreshCw size={12} className={clsx(isMonitoring && 'animate-spin')} />
        {isMonitoring ? 'Stop live' : 'Start live'}
      </button>

      <span className="w-px h-4 bg-border mx-0.5" aria-hidden />

      <select
        className="input-field-compact text-[11px] max-w-[120px]"
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
        className="input-field-compact text-[11px] max-w-[130px]"
        value={filters.sort}
        onChange={(e) => setFilters({ sort: e.target.value })}
      >
        {SORTS.map((s) => (
          <option key={s.value} value={s.value}>
            {s.label}
          </option>
        ))}
      </select>

      <label className="flex items-center gap-1.5 text-[11px] text-content-muted cursor-pointer ml-1 app-no-drag">
        <input
          type="checkbox"
          checked={filters.savedOnly}
          onChange={(e) => setFilters({ savedOnly: e.target.checked })}
          className="rounded-sm border-border-subtle"
        />
        Saved only
      </label>
    </div>
  )
}
