import { EventEmitter } from 'events'
import { v4 as uuidv4 } from 'uuid'
import type Database from 'better-sqlite3'
import { calculateMediaValue } from './media-value'

export interface MonitorProfileRow {
  id: string
  workspace_id: string
  name: string
  keywords: string
  exclusions: string | null
  regions: string | null
  publication_filters: string | null
  language_filters: string | null
  is_active: number
}

export interface PublicationRow {
  id: string
  name: string
  website: string
  region: string
  country: string
  language: string
  category: string
  authority_score: number
  estimated_traffic: number
}

export interface ArticleStreamEvent {
  type: 'article' | 'complete' | 'status'
  monitorId: string
  article?: Record<string, unknown>
  totalFound?: number
  status?: string
}

const HEADLINE_TEMPLATES = [
  '{brand} announces strategic partnership in {region}',
  'Industry analysts weigh in on {brand} market position',
  '{brand} CEO discusses growth strategy at summit',
  'How {brand} is reshaping the communications landscape',
  '{brand} launches new initiative amid sector shift',
  'Coverage spike: {brand} featured in major {category} outlet',
  'Competitive landscape shifts as {brand} gains visibility',
  '{brand} campaign drives measurable media attention'
]

const BODY_SNIPPETS = [
  'In a move that signals continued momentum, {brand} has captured attention across professional media channels.',
  'Communications teams are tracking heightened visibility as coverage expands across approved publications.',
  'The mention aligns with ongoing monitoring of brand presence, campaign reach, and competitive positioning.',
  'Analysts note the article places significant emphasis on market narrative and executive visibility.',
  'Stakeholders monitoring {brand} will want to review sentiment and publication authority for reporting.'
]

function parseKeywords(raw: string): string[] {
  return raw
    .split(/\s+(?:AND|OR)\s+|\s*,\s*/i)
    .map((k) => k.replace(/^NOT\s+/i, '').trim())
    .filter((k) => k.length > 1 && !/^(AND|OR|NOT)$/i.test(k))
}

function matchesQuery(text: string, keywords: string[], exclusions: string[]): boolean {
  const lower = text.toLowerCase()
  const hasKeyword = keywords.some((k) => lower.includes(k.toLowerCase()))
  if (!hasKeyword) return false
  return !exclusions.some((e) => lower.includes(e.toLowerCase()))
}

function highlightMatches(text: string, keywords: string[]): string[] {
  const found: string[] = []
  const lower = text.toLowerCase()
  for (const k of keywords) {
    if (lower.includes(k.toLowerCase())) found.push(k)
  }
  return found
}

function pick<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)]
}

export class MonitoringEngine extends EventEmitter {
  private activeRuns = new Map<string, NodeJS.Timeout[]>()

  constructor(private db: Database.Database) {
    super()
  }

  startMonitoring(monitorId: string): void {
    this.stopMonitoring(monitorId)

    const profile = this.db
      .prepare('SELECT * FROM monitor_profiles WHERE id = ?')
      .get(monitorId) as MonitorProfileRow | undefined

    if (!profile) return

    this.db
      .prepare(
        `INSERT OR REPLACE INTO monitoring_sessions (id, monitor_profile_id, status, articles_found, started_at, last_activity_at)
         VALUES (?, ?, 'running', 0, datetime('now'), datetime('now'))`
      )
      .run(uuidv4(), monitorId)

    this.db.prepare('UPDATE monitor_profiles SET is_active = 1, updated_at = datetime(\'now\') WHERE id = ?').run(monitorId)

    this.emitEvent({ type: 'status', monitorId, status: 'running' })

    const keywords = parseKeywords(profile.keywords)
    const exclusions = profile.exclusions
      ? parseKeywords(profile.exclusions.replace(/\bNOT\s+/gi, ''))
      : []

    let pubs = this.db.prepare('SELECT * FROM publication_sources WHERE verified = 1').all() as PublicationRow[]

    if (profile.regions) {
      try {
        const regions = JSON.parse(profile.regions) as string[]
        if (regions.length) {
          pubs = pubs.filter((p) => regions.some((r) => p.region.toLowerCase().includes(r.toLowerCase())))
        }
      } catch {
        /* ignore */
      }
    }

    if (profile.language_filters) {
      try {
        const langs = JSON.parse(profile.language_filters) as string[]
        if (langs.length) pubs = pubs.filter((p) => langs.includes(p.language))
      } catch {
        /* ignore */
      }
    }

    const brand = keywords[0] ?? profile.name
    const timers: NodeJS.Timeout[] = []
    let found = 0
    const maxArticles = Math.min(12, Math.max(4, pubs.length))

    const shuffled = [...pubs].sort(() => Math.random() - 0.5).slice(0, maxArticles)

    shuffled.forEach((pub, index) => {
      const delay = 400 + index * 350 + Math.random() * 200
      const timer = setTimeout(() => {
        const headline = pick(HEADLINE_TEMPLATES)
          .replace(/\{brand\}/g, brand)
          .replace(/\{region\}/g, pub.region)
          .replace(/\{category\}/g, pub.category)

        const body = pick(BODY_SNIPPETS)
          .replace(/\{brand\}/g, brand)
          .concat(' ', pick(BODY_SNIPPETS).replace(/\{brand\}/g, brand))

        if (!matchesQuery(headline + ' ' + body, keywords, exclusions)) return

        const articleId = uuidv4()
        const publishedAt = new Date(Date.now() - Math.random() * 72 * 3600000).toISOString()
        const values = calculateMediaValue({
          authorityScore: pub.authority_score,
          estimatedTraffic: pub.estimated_traffic,
          articleLength: body.length
        })

        const relevance = Math.min(
          100,
          40 +
            keywords.filter((k) => headline.toLowerCase().includes(k.toLowerCase())).length * 15 +
            pub.authority_score * 0.3
        )

        const matches = highlightMatches(headline + ' ' + body, keywords)
        const sentiments = ['positive', 'neutral', 'negative', 'mixed'] as const
        const sentiment = pick([...sentiments])

        this.db
          .prepare(
            `INSERT INTO monitor_results (
              id, monitor_profile_id, publication_id, title, url, author, published_at,
              article_text, sentiment, reach, media_value, pr_value, relevance_score,
              language, region, country, coverage_type, keyword_matches
            ) VALUES (
              @id, @monitor_profile_id, @publication_id, @title, @url, @author, @published_at,
              @article_text, @sentiment, @reach, @media_value, @pr_value, @relevance_score,
              @language, @region, @country, @coverage_type, @keyword_matches
            )`
          )
          .run({
            id: articleId,
            monitor_profile_id: monitorId,
            publication_id: pub.id,
            title: headline,
            url: `https://${pub.website}/article/${articleId.slice(0, 8)}`,
            author: pick(['Sarah Mitchell', 'James Chen', 'Elena Vasquez', 'Omar Al-Rashid', 'Priya Kapoor']),
            published_at: publishedAt,
            article_text: body,
            sentiment,
            reach: values.reach,
            media_value: values.mediaValue,
            pr_value: values.prValue,
            relevance_score: relevance,
            language: pub.language,
            region: pub.region,
            country: pub.country,
            coverage_type: 'online',
            keyword_matches: JSON.stringify(matches)
          })

        found++
        this.db
          .prepare(
            `UPDATE monitoring_sessions SET articles_found = ?, last_activity_at = datetime('now')
             WHERE monitor_profile_id = ?`
          )
          .run(found, monitorId)

        const row = this.db
          .prepare(
            `SELECT mr.*, ps.name as publication_name, ps.logo_url, ps.website, ps.category,
                    ps.authority_score, ps.estimated_traffic
             FROM monitor_results mr
             LEFT JOIN publication_sources ps ON mr.publication_id = ps.id
             WHERE mr.id = ?`
          )
          .get(articleId)

        this.emitEvent({ type: 'article', monitorId, article: row as Record<string, unknown>, totalFound: found })
      }, delay)

      timers.push(timer)
    })

    const completeTimer = setTimeout(() => {
      this.db
        .prepare(
          `UPDATE monitoring_sessions SET status = 'complete', last_activity_at = datetime('now')
           WHERE monitor_profile_id = ?`
        )
        .run(monitorId)
      this.emitEvent({ type: 'complete', monitorId, totalFound: found, status: 'complete' })
    }, 400 + maxArticles * 600 + 500)

    timers.push(completeTimer)
    this.activeRuns.set(monitorId, timers)
  }

  stopMonitoring(monitorId: string): void {
    const timers = this.activeRuns.get(monitorId)
    if (timers) {
      timers.forEach(clearTimeout)
      this.activeRuns.delete(monitorId)
    }
    this.db.prepare('UPDATE monitor_profiles SET is_active = 0 WHERE id = ?').run(monitorId)
    this.emitEvent({ type: 'status', monitorId, status: 'idle' })
  }

  private emitEvent(event: ArticleStreamEvent): void {
    this.emit('stream', event)
  }
}
