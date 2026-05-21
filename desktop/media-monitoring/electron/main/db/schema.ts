export const SCHEMA_SQL = `
PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS publication_sources (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  logo_url TEXT,
  website TEXT,
  region TEXT,
  country TEXT,
  language TEXT DEFAULT 'en',
  category TEXT,
  publication_type TEXT,
  authority_score REAL DEFAULT 50,
  estimated_traffic INTEGER DEFAULT 0,
  verified INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS monitor_profiles (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL DEFAULT 'default',
  name TEXT NOT NULL,
  keywords TEXT NOT NULL,
  exclusions TEXT,
  regions TEXT,
  publication_filters TEXT,
  language_filters TEXT,
  alert_settings TEXT,
  linked_client TEXT,
  linked_campaign TEXT,
  is_active INTEGER DEFAULT 0,
  created_by TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS monitor_results (
  id TEXT PRIMARY KEY,
  monitor_profile_id TEXT NOT NULL,
  publication_id TEXT,
  title TEXT NOT NULL,
  url TEXT,
  author TEXT,
  published_at TEXT,
  article_text TEXT,
  sentiment TEXT DEFAULT 'neutral',
  reach INTEGER DEFAULT 0,
  media_value REAL DEFAULT 0,
  pr_value REAL DEFAULT 0,
  relevance_score REAL DEFAULT 0,
  screenshot_path TEXT,
  language TEXT DEFAULT 'en',
  region TEXT,
  country TEXT,
  coverage_type TEXT,
  keyword_matches TEXT,
  duplicate_group_id TEXT,
  is_saved INTEGER DEFAULT 0,
  cached_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (monitor_profile_id) REFERENCES monitor_profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (publication_id) REFERENCES publication_sources(id)
);

CREATE TABLE IF NOT EXISTS saved_coverage (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL DEFAULT 'default',
  monitor_result_id TEXT NOT NULL UNIQUE,
  project_id TEXT,
  campaign_id TEXT,
  report_id TEXT,
  notes TEXT,
  tags TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (monitor_result_id) REFERENCES monitor_results(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS monitoring_sessions (
  id TEXT PRIMARY KEY,
  monitor_profile_id TEXT NOT NULL,
  status TEXT DEFAULT 'idle',
  articles_found INTEGER DEFAULT 0,
  started_at TEXT,
  last_activity_at TEXT,
  FOREIGN KEY (monitor_profile_id) REFERENCES monitor_profiles(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_monitor_results_profile ON monitor_results(monitor_profile_id);
CREATE INDEX IF NOT EXISTS idx_monitor_results_published ON monitor_results(published_at DESC);
CREATE TABLE IF NOT EXISTS coverage_activity_local (
  id TEXT PRIMARY KEY,
  monitor_result_id TEXT NOT NULL,
  action TEXT NOT NULL,
  metadata TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (monitor_result_id) REFERENCES monitor_results(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_publication_region ON publication_sources(region);
CREATE INDEX IF NOT EXISTS idx_monitor_results_saved ON monitor_results(is_saved);
`;
