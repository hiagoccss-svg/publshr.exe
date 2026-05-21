import { ExternalLink, Bookmark, FilePlus2, MoreHorizontal } from 'lucide-react'
import clsx from 'clsx'
import type { MonitorResult } from '@/types'
import { formatRelativeDate, formatCurrency, formatCompactNumber, publicationInitials } from '@/lib/format'
import { highlightKeywords, parseKeywordMatches } from '@/lib/keywordHighlight'
import { useMonitoringStore } from '@/store/monitoringStore'

const SENTIMENT_DOT = {
  positive: 'bg-sentiment-positive',
  negative: 'bg-sentiment-negative',
  neutral: 'bg-sentiment-neutral',
  mixed: 'bg-sentiment-mixed'
} as const

interface Props {
  article: MonitorResult
  index: number
}

export function ArticleCard({ article, index }: Props) {
  const { selectedArticleId, setSelectedArticle } = useMonitoringStore()
  const keywords = parseKeywordMatches(article.keyword_matches)
  const selected = selectedArticleId === article.id

  return (
    <article
      role="button"
      tabIndex={0}
      onClick={() => setSelectedArticle(article.id)}
      onKeyDown={(e) => e.key === 'Enter' && setSelectedArticle(article.id)}
      className={clsx(
        'group animate-slide-up rounded-lg border transition-all cursor-pointer',
        selected
          ? 'border-accent/50 bg-surface-highlight'
          : 'border-border/80 bg-surface-editor hover:border-border-subtle hover:bg-surface-highlight/60'
      )}
      style={{ animationDelay: `${Math.min(index, 8) * 40}ms` }}
    >
      <div className="flex gap-3 p-3">
        <div className="w-10 h-10 rounded-md bg-surface-tabInactive flex items-center justify-center text-xs font-semibold text-content-muted shrink-0">
          {publicationInitials(article.publication_name ?? '?')}
        </div>

        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between gap-2">
            <div className="min-w-0">
              <p className="text-xs text-content-muted flex items-center gap-2">
                <span className="font-medium text-content">{article.publication_name}</span>
                <span className="text-content-dim">·</span>
                <span>{formatRelativeDate(article.published_at)}</span>
                <span
                  className={clsx('w-1.5 h-1.5 rounded-full', SENTIMENT_DOT[article.sentiment])}
                  title={article.sentiment}
                />
              </p>
              <h3 className="text-sm font-medium text-content mt-0.5 line-clamp-2 group-hover:text-white transition-colors">
                {highlightKeywords(article.title, keywords)}
              </h3>
            </div>
            <div className="opacity-0 group-hover:opacity-100 flex items-center gap-0.5 transition-opacity shrink-0">
              <IconBtn icon={ExternalLink} label="Open" onClick={(e) => { e.stopPropagation(); article.url && window.open(article.url) }} />
              <IconBtn icon={Bookmark} label="Save" onClick={(e) => { e.stopPropagation(); void window.publshr.saveCoverage(article.id) }} />
              <IconBtn icon={FilePlus2} label="Report" onClick={(e) => e.stopPropagation()} />
              <IconBtn icon={MoreHorizontal} label="More" onClick={(e) => e.stopPropagation()} />
            </div>
          </div>

          {article.article_text && (
            <p className="text-xs text-content-dim mt-1.5 line-clamp-2 leading-relaxed">
              {highlightKeywords(article.article_text, keywords)}
            </p>
          )}

          <div className="flex flex-wrap items-center gap-x-3 gap-y-1 mt-2 text-2xs text-content-muted">
            {article.author && <span>{article.author}</span>}
            <span>Reach {formatCompactNumber(article.reach)}</span>
            <span>PR {formatCurrency(article.pr_value)}</span>
            <span>MV {formatCurrency(article.media_value)}</span>
            <span>{article.region}</span>
            {article.is_saved ? (
              <span className="text-accent">Saved</span>
            ) : null}
          </div>
        </div>

        <div className="w-20 h-14 rounded bg-surface-tabInactive/80 shrink-0 hidden sm:block" aria-hidden />
      </div>
    </article>
  )
}

function IconBtn({
  icon: Icon,
  label,
  onClick
}: {
  icon: typeof ExternalLink
  label: string
  onClick: (e: React.MouseEvent) => void
}) {
  return (
    <button
      type="button"
      className="p-1 rounded hover:bg-surface-input text-content-muted hover:text-content"
      aria-label={label}
      onClick={onClick}
    >
      <Icon size={13} />
    </button>
  )
}
