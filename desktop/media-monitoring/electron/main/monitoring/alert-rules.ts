export interface AlertSettings {
  desktop?: boolean
  min_relevance?: number
  sentiment?: string[]
}

export function parseAlertSettings(raw: unknown): AlertSettings {
  if (!raw) return { desktop: true, min_relevance: 0, sentiment: [] }
  try {
    const v = typeof raw === 'string' ? JSON.parse(raw) : raw
    if (!v || typeof v !== 'object') return { desktop: true, min_relevance: 0, sentiment: [] }
    return {
      desktop: (v as AlertSettings).desktop !== false,
      min_relevance:
        typeof (v as AlertSettings).min_relevance === 'number' ? (v as AlertSettings).min_relevance : 0,
      sentiment: Array.isArray((v as AlertSettings).sentiment) ? (v as AlertSettings).sentiment : []
    }
  } catch {
    return { desktop: true, min_relevance: 0, sentiment: [] }
  }
}

export function shouldNotifyForArticle(
  settings: AlertSettings,
  article: { relevance_score?: number; sentiment?: string }
): boolean {
  if (settings.desktop === false) return false
  const min = settings.min_relevance ?? 0
  const score = Number(article.relevance_score ?? 0)
  if (score < min) return false
  const filter = settings.sentiment ?? []
  if (filter.length === 0) return true
  const sentiment = String(article.sentiment ?? 'neutral').toLowerCase()
  return filter.map((s) => s.toLowerCase()).includes(sentiment)
}
