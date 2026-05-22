export type Sentiment = 'positive' | 'neutral' | 'negative' | 'mixed'

export interface Publication {
  id: string
  name: string
  logo_url?: string
  website: string
  region: string
  country: string
  language: string
  category: string
  publication_type?: string
  authority_score: number
  estimated_traffic: number
  verified?: number
}

export interface MonitorProfile {
  id: string
  workspace_id: string
  name: string
  keywords: string
  exclusions?: string | null
  regions?: string | null
  publication_filters?: string | null
  language_filters?: string | null
  alert_settings?: string | null
  linked_client?: string | null
  linked_campaign?: string | null
  is_active: number
  result_count?: number
  created_at?: string
  updated_at?: string
}

export interface MonitorResult {
  id: string
  monitor_profile_id: string
  publication_id?: string
  publication_name?: string
  logo_url?: string
  website?: string
  category?: string
  authority_score?: number
  title: string
  url?: string
  author?: string
  published_at?: string
  article_text?: string
  sentiment: Sentiment
  reach: number
  media_value: number
  pr_value: number
  relevance_score: number
  language?: string
  region?: string
  country?: string
  coverage_type?: string
  keyword_matches?: string
  is_saved?: number
}

export type SidebarSection =
  | 'dashboard'
  | 'monitoring'
  | 'saved-searches'
  | 'brands'
  | 'competitors'
  | 'coverage'
  | 'reports'
  | 'alerts'
  | 'publications'
  | 'journalists'
  | 'clients'
  | 'exports'
  | 'settings'

export type TopBarMode = 'live' | 'search' | 'report' | 'default'

export interface StreamEvent {
  type: 'article' | 'complete' | 'status'
  monitorId: string
  article?: MonitorResult
  totalFound?: number
  status?: string
}

export interface ReportAnalytics {
  periodDays: number
  savedOnly: boolean
  totals: {
    mentions: number
    total_reach: number
    total_pr_value: number
    total_media_value: number
    avg_relevance: number
  }
  bySentiment: { sentiment: string; count: number }[]
  byPublication: { name: string; count: number; pr_value: number; reach: number }[]
  byMediaType: { media_type: string; count: number }[]
  byMonitor: { name: string; count: number }[]
}

export interface CoverageActivity {
  action: string
  metadata?: string
  created_at: string
}
