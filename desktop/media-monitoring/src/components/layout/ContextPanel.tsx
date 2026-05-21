import { useState, useEffect } from 'react'
import { Bookmark, ExternalLink, Maximize2 } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { useMonitoringStore } from '@/store/monitoringStore'
import { formatCurrency, formatCompactNumber } from '@/lib/format'
import { parseKeywordMatches, highlightKeywords } from '@/lib/keywordHighlight'
import type { MonitorResult, Sentiment } from '@/types'

const SENTIMENTS: Sentiment[] = ['positive', 'neutral', 'negative', 'mixed']

export function ContextPanel() {
  const { results, selectedArticleId, setResults } = useMonitoringStore()
  const navigate = useNavigate()
  const article = results.find((r) => r.id === selectedArticleId)
  const [notes, setNotes] = useState('')
  const [tags, setTags] = useState('')
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    if (!article) return
    const ext = article as MonitorResult & { saved_notes?: string; saved_tags?: string }
    setNotes(ext.saved_notes ?? '')
    if (ext.saved_tags) {
      try {
        setTags(JSON.parse(ext.saved_tags).join(', '))
      } catch {
        setTags('')
      }
    } else {
      setTags('')
    }
  }, [article?.id])

  if (!article) {
    return (
      <aside
        className="flex flex-col shrink-0 border-l"
        style={{ width: 380, backgroundColor: '#181818', borderColor: '#2B2B2B' }}
      >
        <div className="p-4 text-center text-content-dim text-sm mt-12">
          <p>Select coverage to view metadata, tags, and actions.</p>
        </div>
      </aside>
    )
  }

  const keywords = parseKeywordMatches(article.keyword_matches)

  const refreshArticle = async () => {
    const row = await window.publshr.getArticle(article.id)
    if (row) {
      setResults(results.map((r) => (r.id === article.id ? { ...r, ...(row as MonitorResult) } : r)))
    }
  }

  return (
    <aside
      className="flex flex-col shrink-0 border-l overflow-hidden"
      style={{ width: 380, backgroundColor: '#181818', borderColor: '#2B2B2B' }}
    >
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
          <label className="text-2xs uppercase tracking-wide text-content-header block mb-1">
            Sentiment
          </label>
          <select
            className="input-field w-full text-xs"
            value={article.sentiment}
            onChange={async (e) => {
              await window.publshr.updateSentiment(article.id, e.target.value)
              setResults(
                results.map((r) =>
                  r.id === article.id ? { ...r, sentiment: e.target.value as Sentiment } : r
                )
              )
            }}
          >
            {SENTIMENTS.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>
        </section>

        <section>
          <label className="text-2xs uppercase tracking-wide text-content-header block mb-1">
            Notes
          </label>
          <textarea
            className="input-field w-full text-xs min-h-[60px]"
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
          />
        </section>

        <section>
          <label className="text-2xs uppercase tracking-wide text-content-header block mb-1">
            Tags
          </label>
          <input
            className="input-field w-full text-xs"
            value={tags}
            onChange={(e) => setTags(e.target.value)}
            placeholder="campaign, client, priority"
          />
        </section>

        {article.article_text && (
          <section>
            <h3 className="text-2xs uppercase tracking-wide text-content-header mb-2">Preview</h3>
            <p className="text-xs text-content-muted leading-relaxed line-clamp-6">
              {highlightKeywords(article.article_text, keywords)}
            </p>
          </section>
        )}
      </div>

      <div className="p-3 border-t border-border flex flex-col gap-2">
        <button
          type="button"
          className="btn-primary w-full flex items-center justify-center gap-1"
          disabled={saving}
          onClick={async () => {
            setSaving(true)
            const tagList = tags
              .split(',')
              .map((t) => t.trim())
              .filter(Boolean)
            await window.publshr.saveCoverage(article.id, { notes, tags: tagList })
            setResults(results.map((r) => (r.id === article.id ? { ...r, is_saved: 1 } : r)))
            await refreshArticle()
            setSaving(false)
          }}
        >
          <Bookmark size={13} />
          {saving ? 'Saving…' : article.is_saved ? 'Update saved' : 'Save coverage'}
        </button>
        <div className="flex gap-2">
          <button
            type="button"
            className="btn-ghost flex-1 flex items-center justify-center gap-1 text-xs"
            onClick={() => navigate(`/article/${article.id}`)}
          >
            <Maximize2 size={12} /> Detail
          </button>
          {article.url && (
            <button
              type="button"
              className="btn-ghost flex-1 flex items-center justify-center gap-1 text-xs"
              onClick={() => window.publshr.openExternal(article.url!)}
            >
              <ExternalLink size={12} /> Open URL
            </button>
          )}
        </div>
      </div>
    </aside>
  )
}
