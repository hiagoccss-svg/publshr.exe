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
        'group cursor-list-row animate-fade-in',
        selected && 'cursor-list-row-selected'
      )}
      style={{ animationDelay: `${Math.min(index, 8) * 30}ms` }}
    >
      <div className="w-8 h-8 rounded-sm bg-surface-tabInactive flex items-center justify-center text-[10px] font-semibold text-content-muted shrink-0">
        {publicationInitials(article.publication_name ?? '?')}
      </div>

      <div className="flex-1 min-w-0">
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0">
            <p className="text-[11px] text-content-muted flex items-center gap-1.5">
              <span className="font-medium text-content">{article.publication_name}</span>
              <span className="text-content-dim">·</span>
              <span>{formatRelativeDate(article.published_at)}</span>
              <span
                className={clsx('w-1.5 h-1.5 rounded-full', SENTIMENT_DOT[article.sentiment])}
                title={article.sentiment}
              />
            </p>
            <h3 className="text-[13px] font-medium text-content mt-0.5 line-clamp-2 group-hover:text-white transition-colors">
              {highlightKeywords(article.title, keywords)}
            </h3>
          </div>
          <div className="opacity-0 group-hover:opacity-100 flex items-center gap-0.5 transition-opacity shrink-0">
            <IconBtn icon={ExternalLink} label="Open" onClick={(e) => { e.stopPropagation(); article.url && void window.publshr.openExternal(article.url) }} />
            <IconBtn icon={Bookmark} label="Save" onClick={(e) => { e.stopPropagation(); void window.publshr.saveCoverage(article.id) }} />
            <IconBtn icon={FilePlus2} label="Report" onClick={(e) => e.stopPropagation()} />
            <IconBtn icon={MoreHorizontal} label="More" onClick={(e) => e.stopPropagation()} />
          </div>
        </div>

        {article.article_text && (
          <p className="text-[11px] text-content-dim mt-1 line-clamp-2 leading-relaxed">
            {highlightKeywords(article.article_text, keywords)}
          </p>
        )}

        <div className="flex flex-wrap items-center gap-x-2.5 gap-y-0.5 mt-1.5 text-[10px] text-content-muted">
          {article.author && <span>{article.author}</span>}
          <span>Reach {formatCompactNumber(article.reach)}</span>
          <span>PR {formatCurrency(article.pr_value)}</span>
          <span>MV {formatCurrency(article.media_value)}</span>
          <span>{article.region}</span>
          {article.is_saved ? <span className="text-accent">Saved</span> : null}
        </div>
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
      className="p-1 rounded-sm hover:bg-surface-input text-content-muted hover:text-content"
      aria-label={label}
      onClick={onClick}
    >
      <Icon size={13} />
    </button>
  )
}
