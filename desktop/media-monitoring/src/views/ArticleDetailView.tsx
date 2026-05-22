import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, ExternalLink } from 'lucide-react'
import type { MonitorResult, Sentiment } from '@/types'
import { formatShortDate, formatCurrency, formatCompactNumber } from '@/lib/format'
import { highlightKeywords, parseKeywordMatches } from '@/lib/keywordHighlight'
import { shell } from '@/theme/shellTheme'

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
    return <div className="p-4 text-content-dim text-[12px]">Loading article…</div>
  }

  const keywords = parseKeywordMatches(article.keyword_matches)

  return (
    <div className="h-full flex flex-col overflow-hidden bg-surface-workspace">
      <header className="flex items-center gap-3 px-3 py-2 border-b border-border shrink-0">
        <button type="button" className="btn-ghost p-1" onClick={() => navigate(-1)}>
          <ArrowLeft size={15} />
        </button>
        <div className="flex-1 min-w-0">
          <h1 className="text-[13px] font-medium text-content line-clamp-1">{article.title}</h1>
          <p className="text-[11px] text-content-muted">{article.publication_name}</p>
        </div>
        {article.url && (
          <button
            type="button"
            className="btn-ghost text-[11px]"
            onClick={() => window.publshr.openExternal(article.url!)}
          >
            <ExternalLink size={13} /> Open
          </button>
        )}
      </header>

      <div className="flex-1 flex min-h-0">
        <article className="flex-1 overflow-y-auto px-4 py-4 max-w-3xl">
          <dl className="flex flex-wrap gap-x-6 gap-y-2 text-[11px] mb-5 pb-4 border-b border-border">
            <Meta label="Published" value={formatShortDate(article.published_at)} />
            <Meta label="Author" value={article.author ?? '—'} />
            <Meta label="Reach" value={formatCompactNumber(article.reach)} />
            <Meta label="PR value" value={formatCurrency(article.pr_value)} />
            <Meta label="Media value" value={formatCurrency(article.media_value)} />
            <Meta label="Relevance" value={`${Math.round(article.relevance_score)}%`} />
          </dl>

          <p className="text-[13px] text-content leading-relaxed whitespace-pre-wrap">
            {highlightKeywords(article.article_text ?? '', keywords)}
          </p>
        </article>

        <aside
          className="w-72 border-l border-border px-3 py-3 space-y-4 shrink-0 overflow-y-auto"
          style={{ backgroundColor: shell.panel }}
        >
          <label className="block text-[11px]">
            <span className="shell-section-header">Sentiment</span>
            <select
              className="input-field mt-1.5 w-full"
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
          <label className="block text-[11px]">
            <span className="shell-section-header">Notes</span>
            <textarea
              className="input-field mt-1.5 w-full min-h-[72px]"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
            />
          </label>
          <label className="block text-[11px]">
            <span className="shell-section-header">Tags</span>
            <input
              className="input-field mt-1.5 w-full"
              value={tags}
              onChange={(e) => setTags(e.target.value)}
              placeholder="comma-separated"
            />
          </label>
          <button
            type="button"
            className="btn-primary w-full text-[11px]"
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
      <dd className="text-content mt-0.5 tabular-nums">{value}</dd>
    </div>
  )
}
