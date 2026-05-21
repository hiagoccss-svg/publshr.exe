import { Bookmark, Tag, MessageSquare, Activity, Sparkles, Link2, FolderKanban } from 'lucide-react'
import { useMonitoringStore } from '@/store/monitoringStore'
import { formatCurrency, formatCompactNumber, formatShortDate } from '@/lib/format'
import { parseKeywordMatches, highlightKeywords } from '@/lib/keywordHighlight'
import clsx from 'clsx'

const SENTIMENT_STYLES = {
  positive: 'text-sentiment-positive',
  negative: 'text-sentiment-negative',
  neutral: 'text-sentiment-neutral',
  mixed: 'text-sentiment-mixed'
} as const

export function ContextPanel() {
  const { results, selectedArticleId } = useMonitoringStore()
  const article = results.find((r) => r.id === selectedArticleId)

  if (!article) {
    return (
      <aside className="w-context bg-surface-panel border-l border-border flex flex-col shrink-0">
        <div className="p-4 text-center text-content-dim text-sm mt-12">
          <p>Select coverage to view metadata, tags, and actions.</p>
        </div>
      </aside>
    )
  }

  const keywords = parseKeywordMatches(article.keyword_matches)

  return (
    <aside className="w-context bg-surface-panel border-l border-border flex flex-col shrink-0 overflow-hidden">
      <div className="px-4 py-3 border-b border-border">
        <h2 className="text-sm font-medium text-content line-clamp-2">{article.title}</h2>
        <p className="text-xs text-content-muted mt-1">{article.publication_name}</p>
      </div>

      <div className="flex-1 overflow-y-auto px-4 py-3 space-y-4 text-sm">
        <section>
          <h3 className="text-2xs uppercase tracking-wide text-content-header mb-2">Metrics</h3>
          <dl className="grid grid-cols-2 gap-2 text-xs">
            <div>
              <dt className="text-content-dim">Reach</dt>
              <dd className="text-content">{formatCompactNumber(article.reach)}</dd>
            </div>
            <div>
              <dt className="text-content-dim">PR value</dt>
              <dd className="text-content">{formatCurrency(article.pr_value)}</dd>
            </div>
            <div>
              <dt className="text-content-dim">Media value</dt>
              <dd className="text-content">{formatCurrency(article.media_value)}</dd>
            </div>
            <div>
              <dt className="text-content-dim">Relevance</dt>
              <dd className="text-content">{Math.round(article.relevance_score)}%</dd>
            </div>
          </dl>
        </section>

        <section>
          <h3 className="text-2xs uppercase tracking-wide text-content-header mb-2">Details</h3>
          <ul className="space-y-1.5 text-xs text-content-muted">
            <li>Published {formatShortDate(article.published_at)}</li>
            <li>
              Sentiment{' '}
              <span className={clsx('capitalize', SENTIMENT_STYLES[article.sentiment])}>
                {article.sentiment}
              </span>
            </li>
            <li>{article.region} · {article.language?.toUpperCase()}</li>
            {article.author && <li>{article.author}</li>}
          </ul>
        </section>

        {keywords.length > 0 && (
          <section>
            <h3 className="text-2xs uppercase tracking-wide text-content-header mb-2">Matches</h3>
            <div className="flex flex-wrap gap-1">
              {keywords.map((k) => (
                <span key={k} className="text-2xs px-1.5 py-0.5 rounded bg-accent/15 text-accent">
                  {k}
                </span>
              ))}
            </div>
          </section>
        )}

        {article.article_text && (
          <section>
            <h3 className="text-2xs uppercase tracking-wide text-content-header mb-2 flex items-center gap-1">
              <Sparkles size={10} /> AI summary
            </h3>
            <p className="text-xs text-content-muted leading-relaxed">
              {highlightKeywords(article.article_text.slice(0, 280) + '…', keywords)}
            </p>
          </section>
        )}

        <section className="space-y-2">
          <ActionRow icon={Bookmark} label="Save coverage" />
          <ActionRow icon={Tag} label="Add tags" />
          <ActionRow icon={Link2} label="Link client / campaign" />
          <ActionRow icon={FolderKanban} label="Add to report" />
          <ActionRow icon={MessageSquare} label="Comments" />
          <ActionRow icon={Activity} label="Activity log" />
        </section>
      </div>

      <div className="p-3 border-t border-border flex gap-2">
        <button
          type="button"
          className="btn-primary flex-1"
          onClick={() => window.publshr.saveCoverage(article.id)}
        >
          Save coverage
        </button>
      </div>
    </aside>
  )
}

function ActionRow({ icon: Icon, label }: { icon: typeof Bookmark; label: string }) {
  return (
    <button type="button" className="w-full flex items-center gap-2 text-xs text-content-muted hover:text-content py-1">
      <Icon size={13} />
      {label}
    </button>
  )
}
