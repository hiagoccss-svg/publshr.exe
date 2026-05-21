-- Media Monitoring module — cloud source of truth (syncs with desktop SQLite cache)

-- Publication database
CREATE TABLE IF NOT EXISTS publication_sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID,
  name TEXT NOT NULL,
  logo_url TEXT,
  website TEXT,
  region TEXT,
  country TEXT,
  language TEXT DEFAULT 'en',
  category TEXT,
  publication_type TEXT,
  authority_score NUMERIC DEFAULT 50,
  estimated_traffic BIGINT DEFAULT 0,
  verified BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS monitor_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL,
  name TEXT NOT NULL,
  keywords TEXT NOT NULL,
  exclusions TEXT,
  regions JSONB,
  publication_filters JSONB,
  language_filters JSONB,
  alert_settings JSONB,
  linked_client TEXT,
  linked_campaign TEXT,
  is_active BOOLEAN DEFAULT false,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS monitor_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  monitor_profile_id UUID NOT NULL REFERENCES monitor_profiles(id) ON DELETE CASCADE,
  publication_id UUID REFERENCES publication_sources(id),
  title TEXT NOT NULL,
  url TEXT,
  author TEXT,
  published_at TIMESTAMPTZ,
  article_text TEXT,
  sentiment TEXT DEFAULT 'neutral' CHECK (sentiment IN ('positive', 'neutral', 'negative', 'mixed')),
  reach BIGINT DEFAULT 0,
  media_value NUMERIC DEFAULT 0,
  pr_value NUMERIC DEFAULT 0,
  relevance_score NUMERIC DEFAULT 0,
  screenshot_url TEXT,
  language TEXT DEFAULT 'en',
  region TEXT,
  country TEXT,
  coverage_type TEXT,
  keyword_matches JSONB,
  duplicate_group_id UUID,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS saved_coverage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL,
  monitor_result_id UUID NOT NULL UNIQUE REFERENCES monitor_results(id) ON DELETE CASCADE,
  project_id UUID,
  campaign_id UUID,
  report_id UUID,
  notes TEXT,
  tags JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS coverage_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  monitor_result_id UUID NOT NULL REFERENCES monitor_results(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  comment TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS coverage_activity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  monitor_result_id UUID NOT NULL REFERENCES monitor_results(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_monitor_results_profile ON monitor_results(monitor_profile_id);
CREATE INDEX IF NOT EXISTS idx_monitor_results_published ON monitor_results(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_publication_workspace ON publication_sources(workspace_id);

-- RLS (workspace-scoped — enable per deployment)
ALTER TABLE monitor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE monitor_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_coverage ENABLE ROW LEVEL SECURITY;
ALTER TABLE publication_sources ENABLE ROW LEVEL SECURITY;

-- Role-based permissions scaffold (Owner, Admin, Analyst, Editor, Viewer, Client)
COMMENT ON TABLE monitor_profiles IS 'Media monitoring profiles — keywords, filters, alerts';
COMMENT ON TABLE monitor_results IS 'Collected coverage articles from approved publications';
COMMENT ON TABLE saved_coverage IS 'User-saved coverage for reports and client exports';
