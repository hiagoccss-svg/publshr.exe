import { useCallback, useEffect, useMemo, useState } from 'react'
import { Download, RefreshCw } from 'lucide-react'
import type { MonitorResult, Sentiment } from '@/types'
import type { ReportAnalytics } from '@/types'
import { ArticleCard } from '@/components/monitoring/ArticleCard'
import { useMonitoringStore } from '@/store/monitoringStore'
import { formatCurrency, formatCompactNumber } from '@/lib/format'

const PERIODS = [
  { days: 7, label: '7 days' },
  { days: 30, label: '30 days' },
  { days: 90, label: '90 days' },
  { days: 0, label: 'All time' }
] as const

const SENTIMENT_COLORS: Record<Sentiment, string> = {
  positive: 'bg-sentiment-positive',
  negative: 'bg-sentiment-negative',
  neutral: 'bg-sentiment-neutral',
  mixed: 'bg-sentiment-mixed'
}

export function ReportsView() {
  const { searchQuery, filters, setFilters, setResults, setSelectedArticle } = useMonitoringStore()
  const [periodDays, setPeriodDays] = useState(30)
  const [savedOnly, setSavedOnly] = useState(false)
  const [analytics, setAnalytics] = useState<ReportAnalytics | null>(null)
  const [clippings, setClippings] = useState<MonitorResult[]>([])
  const [loading, setLoading] = useState(true)

  const load = useCallback(async () => {
    setLoading(true)
    const [a, rows] = await Promise.all([
      window.publshr.getReportAnalytics({ days: periodDays, savedOnly }),
      window.publshr.getWorkspaceClippings({
        days: periodDays,
        savedOnly,
        sentiment: filters.sentiment || undefined,
        search: searchQuery || undefined,
        sort: filters.sort,
        limit: 250
      })
    ])
    setAnalytics(a as ReportAnalytics)
    const list = rows as MonitorResult[]
    setClippings(list)
    setResults(list)
    if (list.length > 0 && !list.some((r) => r.id === useMonitoringStore.getState().selectedArticleId)) {
      setSelectedArticle(list[0].id)
    }
    setLoading(false)
  }, [periodDays, savedOnly, filters.sentiment, filters.sort, searchQuery, setResults, setSelectedArticle])

  useEffect(() => {
    void load()
  }, [load])

  const sentimentTotal = useMemo(() => {
    if (!analytics) return 0
    return analytics.bySentiment.reduce((s, x) => s + x.count, 0) || 1
  }, [analytics])

  const exportSummary = () => {
    if (!analytics) return
    const lines = [
      '# Publshr Reports — Executive summary',
      '',
      `Period: ${periodDays === 0 ? 'All time' : `Last ${periodDays} days`}`,
      `Scope: ${savedOnly ? 'Saved coverage only' : 'All monitored coverage'}`,
      '',
      `Mentions: ${analytics.totals.mentions}`,
      `Reach: ${formatCompactNumber(analytics.totals.total_reach)}`,
      `PR value: ${formatCurrency(analytics.totals.total_pr_value)}`,
      `Media value: ${formatCurrency(analytics.totals.total_media_value)}`,
      '',
      '## Sentiment',
      ...analytics.bySentiment.map((s) => `- ${s.sentiment}: ${s.count}`),
      '',
      '## Top publications',
      ...analytics.byPublication.map((p) => `- ${p.name}: ${p.count} (${formatCurrency(p.pr_value)} PR)`),
      '',
      `Generated ${new Date().toISOString()}`
    ]
    const blob = new Blob([lines.join('\n')], { type: 'text/markdown' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `publshr-report-${periodDays}d.md`
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="flex-1 flex flex-col min-h-0">
      <div className="px-4 py-3 border-b border-border flex items-start justify-between gap-4 shrink-0">
        <div>
          <h1 className="text-[13px] font-medium text-content">Reports</h1>
          <p className="text-[11px] text-content-dim mt-0.5 max-w-xl">
            Enterprise coverage intelligence — executive summary, sentiment, publications, and
            clippings (similar to Media Eye / PR insights dashboards).
          </p>
        </div>
        <div className="flex items-center gap-2 shrink-0 app-no-drag">
          <button type="button" className="btn-ghost text-[11px] flex items-center gap-1" onClick={() => void load()}>
            <RefreshCw size={12} /> Refresh
          </button>
          <button type="button" className="btn-primary text-[11px] flex items-center gap-1" onClick={exportSummary}>
            <Download size={12} /> Export summary
          </button>
        </div>
      </div>

      <div className="px-4 py-2 border-b border-border flex flex-wrap items-center gap-3 text-[11px] shrink-0">
        <span className="shell-section-header">Period</span>
        {PERIODS.map((p) => (
          <button
            key={p.days}
            type="button"
            className={periodDays === p.days ? 'btn-primary py-0.5 px-2' : 'btn-ghost py-0.5 px-2'}
            onClick={() => setPeriodDays(p.days)}
          >
            {p.label}
          </button>
        ))}
        <label className="flex items-center gap-1.5 text-content-muted ml-2">
          <input
            type="checkbox"
            checked={savedOnly}
            onChange={(e) => setSavedOnly(e.target.checked)}
          />
          Saved coverage only
        </label>
        <select
          className="input-field text-[11px] py-0.5 ml-auto"
          value={filters.sentiment}
          onChange={(e) => setFilters({ sentiment: e.target.value })}
        >
          <option value="">All sentiment</option>
          <option value="positive">Positive</option>
          <option value="neutral">Neutral</option>
          <option value="negative">Negative</option>
          <option value="mixed">Mixed</option>
        </select>
        <select
          className="input-field text-[11px] py-0.5"
          value={filters.sort}
          onChange={(e) => setFilters({ sort: e.target.value })}
        >
          <option value="newest">Newest first</option>
          <option value="oldest">Oldest first</option>
          <option value="reach">Highest reach</option>
          <option value="pr_value">Highest PR value</option>
          <option value="relevance">Relevance</option>
        </select>
      </div>

      {loading && (
        <p className="px-4 py-6 text-[12px] text-content-dim">Loading report data…</p>
      )}

      {!loading && analytics && (
        <>
          <div className="shell-metric-row shrink-0">
            <Metric label="Mentions" value={String(analytics.totals.mentions)} />
            <Metric label="Total reach" value={formatCompactNumber(analytics.totals.total_reach)} />
            <Metric label="PR value" value={formatCurrency(analytics.totals.total_pr_value)} />
            <Metric label="Media value" value={formatCurrency(analytics.totals.total_media_value)} />
            <Metric
              label="Avg relevance"
              value={`${Math.round(analytics.totals.avg_relevance)}%`}
            />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-0 border-b border-border shrink-0 max-h-[220px] overflow-hidden">
            <Panel title="Sentiment">
              <div className="space-y-2">
                {analytics.bySentiment.map((s) => (
                  <div key={s.sentiment} className="flex items-center gap-2 text-[11px]">
                    <span
                      className={`w-2 h-2 rounded-full ${SENTIMENT_COLORS[s.sentiment as Sentiment] ?? 'bg-content-dim'}`}
                    />
                    <span className="capitalize text-content-muted w-16">{s.sentiment}</span>
                    <div className="flex-1 h-1.5 bg-surface-input rounded-sm overflow-hidden">
                      <div
                        className="h-full bg-accent"
                        style={{ width: `${(s.count / sentimentTotal) * 100}%` }}
                      />
                    </div>
                    <span className="text-content tabular-nums w-8 text-right">{s.count}</span>
                  </div>
                ))}
              </div>
            </Panel>
            <Panel title="Top publications">
              <ul className="space-y-1.5 text-[11px]">
                {analytics.byPublication.map((p) => (
                  <li key={p.name} className="flex justify-between gap-2">
                    <span className="text-content truncate">{p.name}</span>
                    <span className="text-content-dim tabular-nums shrink-0">{p.count}</span>
                  </li>
                ))}
              </ul>
            </Panel>
            <Panel title="Media type">
              <ul className="space-y-1.5 text-[11px]">
                {analytics.byMediaType.map((m) => (
                  <li key={m.media_type} className="flex justify-between gap-2">
                    <span className="text-content capitalize">{m.media_type}</span>
                    <span className="text-content-dim tabular-nums">{m.count}</span>
                  </li>
                ))}
              </ul>
              {analytics.byMonitor.length > 0 && (
                <>
                  <p className="shell-section-header mt-3 mb-1.5">By monitor</p>
                  <ul className="space-y-1 text-[10px] text-content-muted">
                    {analytics.byMonitor.map((m) => (
                      <li key={m.name} className="flex justify-between">
                        <span className="truncate">{m.name}</span>
                        <span>{m.count}</span>
                      </li>
                    ))}
                  </ul>
                </>
              )}
            </Panel>
          </div>

          <div className="flex-1 min-h-0 flex flex-col">
            <p className="px-4 py-2 text-[11px] text-content-dim border-b border-border shrink-0">
              {clippings.length} clippings — select a row for full detail in the right panel
            </p>
            <div className="flex-1 overflow-y-auto shell-list">
              {clippings.length === 0 ? (
                <p className="px-4 py-8 text-center text-[12px] text-content-dim">
                  No coverage in this period. Run a monitor or widen the date range.
                </p>
              ) : (
                clippings.map((article, i) => (
                  <ArticleCard key={article.id} article={article} index={i} />
                ))
              )}
            </div>
          </div>
        </>
      )}
    </div>
  )
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="shell-metric-cell">
      <p className="shell-section-header">{label}</p>
      <p className="text-lg font-medium text-content mt-1 tabular-nums">{value}</p>
    </div>
  )
}

function Panel({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="px-4 py-3 border-r border-border last:border-r-0 overflow-y-auto">
      <h2 className="shell-section-header mb-2">{title}</h2>
      {children}
    </section>
  )
}
