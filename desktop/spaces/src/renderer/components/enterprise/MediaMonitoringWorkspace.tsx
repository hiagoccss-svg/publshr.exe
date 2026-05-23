import { format, formatDistanceToNow } from 'date-fns'
import { Bookmark, ExternalLink, Radio, RefreshCw } from 'lucide-react'
import clsx from 'clsx'
import { useMemo, useState } from 'react'
import { useSpacesStore } from '../../stores/spaces-store'
import type { CoverageMention, CoverageSentiment } from '../../../shared/types'

const SENTIMENT_STYLES: Record<CoverageSentiment, string> = {
  positive: 'bg-emerald-50 text-emerald-800',
  negative: 'bg-red-50 text-red-700',
  neutral: 'bg-surface-muted text-ink-secondary',
  mixed: 'bg-amber-50 text-amber-800'
}

function formatReach(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`
  if (n >= 1_000) return `${Math.round(n / 1_000)}K`
  return String(n)
}

function formatPr(n: number): string {
  return new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0
  }).format(n)
}

/** Media Eye–style coverage feed — local SQLite today, Supabase when cloud sync is on. */
export function MediaMonitoringWorkspace(): React.ReactElement {
  const mentions = useSpacesStore((s) => s.coverageMentions)
  const searchQuery = useSpacesStore((s) => s.searchQuery)
  const loadWorkspaceData = useSpacesStore((s) => s.loadWorkspaceData)
  const [selectedId, setSelectedId] = useState<string | null>(null)

  const q = searchQuery.trim().toLowerCase()
  const filtered = useMemo(
    () =>
      mentions.filter(
        (m) =>
          !q ||
          m.headline.toLowerCase().includes(q) ||
          m.publication.toLowerCase().includes(q)
      ),
    [mentions, q]
  )

  const selected = filtered.find((m) => m.id === selectedId) ?? filtered[0] ?? null

  const totals = useMemo(() => {
    return filtered.reduce(
      (acc, m) => {
        acc.mentions += 1
        acc.reach += m.reach
        acc.pr += m.prValue
        return acc
      },
      { mentions: 0, reach: 0, pr: 0 }
    )
  }, [filtered])

  return (
    <div className="flex h-full min-h-0 flex-col">
      <div className="shrink-0 space-y-4 border-b border-surface-border p-6">
        <header className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <h1 className="flex items-center gap-2 text-xl font-semibold text-ink">
              <Radio className="h-5 w-5 text-accent" />
              Media Monitoring
            </h1>
            <p className="mt-1 max-w-2xl text-sm text-ink-secondary">
              Live coverage feed with reach and PR value — inspired by Media Eye and coverage book workflows.
            </p>
          </div>
          <button
            type="button"
            className="inline-flex items-center gap-1 rounded-lg border border-surface-border px-3 py-1.5 text-xs text-ink-secondary hover:bg-surface-muted"
            onClick={() => void loadWorkspaceData()}
          >
            <RefreshCw className="h-3.5 w-3.5" />
            Refresh
          </button>
        </header>
        <div className="library-masonry library-masonry-responsive">
          <Metric label="Mentions" value={String(totals.mentions)} />
          <Metric label="Reach" value={formatReach(totals.reach)} />
          <Metric label="PR value" value={formatPr(totals.pr)} />
        </div>
      </div>

      <div className="grid min-h-0 flex-1 grid-cols-1 lg:grid-cols-[1fr_340px]">
        <ul className="min-h-0 overflow-y-auto border-r border-surface-border p-4">
          {filtered.length === 0 ? (
            <li className="text-sm text-ink-muted">No coverage yet. Data syncs from your workspace database.</li>
          ) : (
            filtered.map((m) => (
              <li key={m.id} className="mb-2">
                <CoverageRow
                  mention={m}
                  active={selected?.id === m.id}
                  onSelect={() => setSelectedId(m.id)}
                />
              </li>
            ))
          )}
        </ul>
        <aside className="min-h-0 overflow-y-auto p-4">
          {selected ? (
            <CoverageDetail mention={selected} />
          ) : (
            <p className="text-sm text-ink-muted">Select a clipping to view detail.</p>
          )}
        </aside>
      </div>
    </div>
  )
}

function CoverageRow({
  mention,
  active,
  onSelect
}: {
  mention: CoverageMention
  active: boolean
  onSelect: () => void
}): React.ReactElement {
  const sentiment = (mention.sentiment in SENTIMENT_STYLES
    ? mention.sentiment
    : 'neutral') as CoverageSentiment

  return (
    <button
      type="button"
      onClick={onSelect}
      className={clsx(
        'flex w-full flex-col gap-1 rounded-lg border px-3 py-2 text-left text-sm transition',
        active
          ? 'border-accent/30 bg-accent-soft/30'
          : 'border-surface-border hover:bg-surface-muted'
      )}
    >
      <div className="flex items-start justify-between gap-2">
        <span className="font-medium text-ink">{mention.headline}</span>
        <span className={clsx('shrink-0 rounded px-1.5 py-0.5 text-[10px] capitalize', SENTIMENT_STYLES[sentiment])}>
          {sentiment}
        </span>
      </div>
      <span className="text-xs text-ink-muted">
        {mention.publication} · {formatDistanceToNow(new Date(mention.publishedAt), { addSuffix: true })}
      </span>
    </button>
  )
}

function CoverageDetail({ mention }: { mention: CoverageMention }): React.ReactElement {
  const sentiment = (mention.sentiment in SENTIMENT_STYLES
    ? mention.sentiment
    : 'neutral') as CoverageSentiment

  return (
    <div className="library-card space-y-4 p-4">
      <div>
        <p className="text-xs font-medium uppercase text-ink-muted">Clipping</p>
        <h2 className="mt-1 text-base font-semibold text-ink">{mention.headline}</h2>
      </div>
      <dl className="space-y-2 text-sm">
        <Row label="Publication" value={mention.publication} />
        <Row label="Published" value={format(new Date(mention.publishedAt), 'PPp')} />
        <Row label="Reach" value={formatReach(mention.reach)} />
        <Row label="PR value" value={formatPr(mention.prValue)} />
        <div className="flex justify-between gap-2">
          <dt className="text-ink-muted">Sentiment</dt>
          <dd>
            <span className={clsx('rounded px-1.5 py-0.5 text-xs capitalize', SENTIMENT_STYLES[sentiment])}>
              {sentiment}
            </span>
          </dd>
        </div>
      </dl>
      {mention.url ? (
        <a
          href={mention.url}
          target="_blank"
          rel="noreferrer"
          className="inline-flex items-center gap-1 text-xs text-accent hover:underline"
        >
          Open source
          <ExternalLink className="h-3 w-3" />
        </a>
      ) : (
        <p className="flex items-center gap-1 text-xs text-ink-muted">
          <Bookmark className="h-3 w-3" />
          Saved to workspace — link when synced from monitoring ingest
        </p>
      )}
    </div>
  )
}

function Metric({ label, value }: { label: string; value: string }): React.ReactElement {
  return (
    <div className="library-card library-masonry-item">
      <span className="text-[11px] font-medium uppercase tracking-wide text-ink-muted">{label}</span>
      <p className="mt-2 text-2xl font-semibold text-ink">{value}</p>
    </div>
  )
}

function Row({ label, value }: { label: string; value: string }): React.ReactElement {
  return (
    <div className="flex justify-between gap-2">
      <dt className="text-ink-muted">{label}</dt>
      <dd className="font-medium text-ink">{value}</dd>
    </div>
  )
}
