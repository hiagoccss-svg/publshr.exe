import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, ExternalLink } from 'lucide-react'
import type { MonitorResult, Sentiment } from '@/types'
import { formatShortDate, formatCurrency, formatCompactNumber } from '@/lib/format'
import { highlightKeywords, parseKeywordMatches } from '@/lib/keywordHighlight'

const SENTIMENTS: Sentiment[] = ['positive', 'neutral', 'negative', 'mixed']

export function ArticleDetailView() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [article, setArticle] = useState<MonitorResult | null>(null)
  const [notes, setNotes] = useState('')
  const [tags, setTags] = useState('')

  useEffect(() => {
    if (!id) return
    window.publshr.getArticle(id).then((row) => {
      const a = row as MonitorResult
      setArticle(a)
      setNotes((a as MonitorResult & { saved_notes?: string }).saved_notes ?? '')
      const raw = (a as MonitorResult & { saved_tags?: string }).saved_tags
      if (raw) {
        try {
          setTags(JSON.parse(raw).join(', '))
        } catch {
          setTags('')
        }
      }
    })
  }, [id])

  if (!article) {
    return <div className="p-8 text-content-dim text-sm">Loading article…</div>
  }

  const keywords = parseKeywordMatches(article.keyword_matches)

  return (
    <div className="h-full flex flex-col bg-surface-workspace overflow-hidden">
      <header className="flex items-center gap-3 px-4 py-3 border-b border-border shrink-0">
        <button type="button" className="btn-ghost p-1" onClick={() => navigate(-1)}>
          <ArrowLeft size={16} />
        </button>
        <div className="flex-1 min-w-0">
          <h1 className="text-sm font-medium text-content line-clamp-1">{article.title}</h1>
          <p className="text-xs text-content-muted">{article.publication_name}</p>
        </div>
        {article.url && (
          <button
            type="button"
            className="btn-ghost"
            onClick={() => window.publshr.openExternal(article.url!)}
          >
            <ExternalLink size={14} /> Open
          </button>
        )}
      </header>

      <div className="flex-1 flex min-h-0">
        <article className="flex-1 overflow-y-auto p-6 max-w-3xl">
          <dl className="grid grid-cols-2 gap-3 text-xs mb-6">
            <Meta label="Published" value={formatShortDate(article.published_at)} />
            <Meta label="Author" value={article.author ?? '—'} />
            <Meta label="Reach" value={formatCompactNumber(article.reach)} />
            <Meta label="PR value" value={formatCurrency(article.pr_value)} />
            <Meta label="Media value" value={formatCurrency(article.media_value)} />
            <Meta label="Relevance" value={`${Math.round(article.relevance_score)}%`} />
          </dl>

          <div className="prose prose-invert max-w-none">
            <p className="text-sm text-content leading-relaxed whitespace-pre-wrap">
              {highlightKeywords(article.article_text ?? '', keywords)}
            </p>
          </div>
        </article>

        <aside className="w-80 border-l border-border p-4 space-y-4 shrink-0 overflow-y-auto">
          <label className="block text-xs">
            <span className="text-content-muted">Sentiment</span>
            <select
              className="input-field mt-1 w-full"
              value={article.sentiment}
              onChange={async (e) => {
                const s = e.target.value as Sentiment
                await window.publshr.updateSentiment(article.id, s)
                setArticle({ ...article, sentiment: s })
              }}
            >
              {SENTIMENTS.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
          </label>
          <label className="block text-xs">
            <span className="text-content-muted">Notes</span>
            <textarea
              className="input-field mt-1 w-full min-h-[80px]"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
            />
          </label>
          <label className="block text-xs">
            <span className="text-content-muted">Tags (comma-separated)</span>
            <input
              className="input-field mt-1 w-full"
              value={tags}
              onChange={(e) => setTags(e.target.value)}
            />
          </label>
          <button
            type="button"
            className="btn-primary w-full"
            onClick={async () => {
              const tagList = tags
                .split(',')
                .map((t) => t.trim())
                .filter(Boolean)
              await window.publshr.saveCoverage(article.id, { notes, tags: tagList })
            }}
          >
            Save coverage
          </button>
        </aside>
      </div>
    </div>
  )
}

function Meta({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-content-dim">{label}</dt>
      <dd className="text-content mt-0.5">{value}</dd>
    </div>
  )
}
