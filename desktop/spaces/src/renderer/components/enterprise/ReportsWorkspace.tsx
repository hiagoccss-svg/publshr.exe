import clsx from 'clsx'
import { useMemo } from 'react'
import { useSpacesStore } from '../../stores/spaces-store'
import type { CoverageSentiment } from '../../../shared/types'

const SENTIMENT_COLORS: Record<CoverageSentiment, string> = {
  positive: 'bg-emerald-500',
  negative: 'bg-red-500',
  neutral: 'bg-slate-400',
  mixed: 'bg-amber-500'
}

/** Coverage book / PR insights dashboard from workspace + monitoring data. */
export function ReportsWorkspace(): React.ReactElement {
  const summary = useSpacesStore((s) => s.workspaceSummary)
  const tasks = useSpacesStore((s) => s.workspaceTasks)
  const coverage = useSpacesStore((s) => s.coverageMentions)
  const approvals = useSpacesStore((s) => s.workspaceApprovals)

  const byStatus = useMemo(() => {
    return tasks.reduce<Record<string, number>>((acc, t) => {
      acc[t.status] = (acc[t.status] ?? 0) + 1
      return acc
    }, {})
  }, [tasks])

  const bySentiment = useMemo(() => {
    return coverage.reduce<Record<string, number>>((acc, m) => {
      const key = m.sentiment in SENTIMENT_COLORS ? m.sentiment : 'neutral'
      acc[key] = (acc[key] ?? 0) + 1
      return acc
    }, {})
  }, [coverage])

  const sentimentTotal = Object.values(bySentiment).reduce((a, b) => a + b, 0) || 1
  const pendingApprovals = approvals.filter((a) =>
    ['requested', 'in_review'].includes(a.status)
  ).length

  return (
    <div className="space-y-6 p-6">
      <header>
        <h1 className="text-xl font-semibold text-ink">Reports</h1>
        <p className="mt-1 text-sm text-ink-secondary">
          Executive summary across Spaces, coverage, and approvals — ready for Supabase-backed exports.
        </p>
      </header>

      {summary && (
        <div className="library-masonry library-masonry-responsive">
          <Metric label="Spaces" value={summary.spaceCount} />
          <Metric label="Open tasks" value={summary.openTasks} warn={summary.overdueTasks > 0} />
          <Metric label="Coverage" value={coverage.length} />
          <Metric label="Pending approvals" value={pendingApprovals} />
        </div>
      )}

      <div className="grid gap-4 lg:grid-cols-2">
        <section className="library-card p-4">
          <h2 className="mb-3 text-xs font-semibold uppercase tracking-wide text-ink-muted">
            Coverage sentiment
          </h2>
          {coverage.length === 0 ? (
            <p className="text-xs text-ink-muted">Open Media Monitoring to ingest coverage.</p>
          ) : (
            <ul className="space-y-2">
              {Object.entries(bySentiment).map(([sentiment, count]) => (
                <li key={sentiment}>
                  <div className="mb-1 flex justify-between text-xs">
                    <span className="capitalize text-ink-secondary">{sentiment}</span>
                    <span className="font-medium text-ink">{count}</span>
                  </div>
                  <div className="h-2 overflow-hidden rounded-full bg-surface-muted">
                    <div
                      className={clsx(
                        'h-full rounded-full',
                        SENTIMENT_COLORS[sentiment as CoverageSentiment] ?? 'bg-slate-400'
                      )}
                      style={{ width: `${(count / sentimentTotal) * 100}%` }}
                    />
                  </div>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section className="library-card p-4">
          <h2 className="mb-3 text-xs font-semibold uppercase tracking-wide text-ink-muted">
            Tasks by status
          </h2>
          {Object.keys(byStatus).length === 0 ? (
            <p className="text-xs text-ink-muted">No task data.</p>
          ) : (
            <ul className="space-y-1">
              {Object.entries(byStatus).map(([status, count]) => (
                <li key={status} className="flex justify-between text-xs">
                  <span className="capitalize text-ink-secondary">{status.replace(/_/g, ' ')}</span>
                  <span className="font-medium text-ink">{count}</span>
                </li>
              ))}
            </ul>
          )}
        </section>
      </div>
    </div>
  )
}

function Metric({
  label,
  value,
  warn
}: {
  label: string
  value: number
  warn?: boolean
}): React.ReactElement {
  return (
    <div className="library-card library-masonry-item">
      <span className="text-[11px] font-medium uppercase tracking-wide text-ink-muted">{label}</span>
      <p className={clsx('mt-2 text-2xl font-semibold', warn ? 'text-status-blocked' : 'text-ink')}>
        {value}
      </p>
    </div>
  )
}
