import { useMonitoringStore } from '@/store/monitoringStore'
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
  const { filters, setFilters } = useMonitoringStore()

  return (
    <div className="flex flex-wrap items-center gap-2 px-4 py-2 border-b border-border bg-surface-editor shrink-0">
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
