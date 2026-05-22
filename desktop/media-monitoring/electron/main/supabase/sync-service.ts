import { createClient, type SupabaseClient, type Session, type RealtimeChannel } from '@supabase/supabase-js'
import type Database from 'better-sqlite3'
import { BrowserWindow } from 'electron'
import WebSocket from 'ws'
import { SUPABASE_URL, SUPABASE_ANON_KEY, LOCAL_WORKSPACE_ID, LOCAL_WORKSPACE_NAME } from '../config'
import { clearAuthCache, loadAuthCache, saveAuthCache } from '../auth/auth-cache'
import { isNetworkReachable } from '../auth/network'
import { loadSession, saveSession } from './session-store'

function createSupabaseClient(): SupabaseClient {
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: true },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    realtime: { transport: WebSocket as any }
  })
}

export type SyncStatus = 'offline' | 'syncing' | 'synced' | 'error'

export interface UserProfile {
  id: string
  email: string
  display_name: string | null
  avatar_url: string | null
}

export interface AuthState {
  session: Session | null
  email: string | null
  userId: string | null
  workspaceId: string | null
  workspaceName: string | null
  displayName: string | null
  profile: UserProfile | null
}

export class SyncService {
  private client: SupabaseClient
  private session: Session | null = null
  private workspaceId: string | null = null
  private workspaceName: string | null = null
  private status: SyncStatus = 'offline'
  private lastError: string | null = null
  private realtimeChannel: RealtimeChannel | null = null
  private profile: UserProfile | null = null
  private cloudValidated = false

  constructor(private db: Database.Database) {
    this.client = createSupabaseClient()
    this.session = loadSession()
    if (this.session) {
      void this.restoreSession().catch((err) => {
        console.error('Failed to restore session on startup:', err)
        const stored = loadSession()
        if (stored) {
          this.applySessionOffline(stored)
        } else {
          this.setStatus('offline', err instanceof Error ? err.message : 'Session restore failed')
        }
      })
    } else {
      this.setStatus('offline')
    }
  }

  isAuthenticated(): boolean {
    return this.session !== null && this.workspaceId !== null
  }

  getAuthState(): AuthState {
    const cloud = this.isAuthenticated()
    return {
      session: this.session,
      email: this.session?.user?.email ?? this.profile?.email ?? null,
      userId: this.session?.user?.id ?? null,
      workspaceId: cloud ? this.workspaceId : LOCAL_WORKSPACE_ID,
      workspaceName: cloud ? this.workspaceName : LOCAL_WORKSPACE_NAME,
      displayName:
        this.profile?.display_name ??
        (this.session?.user?.user_metadata?.display_name as string | undefined) ??
        null,
      profile: this.profile
    }
  }

  getStatus(): { status: SyncStatus; error: string | null } {
    return { status: this.status, error: this.lastError }
  }

  private setStatus(status: SyncStatus, error: string | null = null): void {
    this.status = status
    this.lastError = error
    this.broadcastSync()
  }

  private broadcastSync(): void {
    const payload = { ...this.getStatus(), auth: this.getAuthState() }
    for (const win of BrowserWindow.getAllWindows()) {
      win.webContents.send('sync:status', payload)
    }
  }

  private persistAuthCache(): void {
    if (!this.session?.user?.id || !this.workspaceId) return
    saveAuthCache({
      userId: this.session.user.id,
      email: this.session.user.email ?? '',
      workspaceId: this.workspaceId,
      workspaceName: this.workspaceName ?? 'Workspace',
      profile: this.profile,
      savedAt: new Date().toISOString()
    })
  }

  private applySessionOffline(session: Session): AuthState {
    this.session = session
    this.client = createSupabaseClient()
    void this.client.auth.setSession({
      access_token: session.access_token,
      refresh_token: session.refresh_token
    })
    saveSession(session)
    const cache = loadAuthCache()
    if (cache) {
      this.workspaceId = cache.workspaceId
      this.workspaceName = cache.workspaceName
      this.profile = cache.profile
    }
    this.cloudValidated = false
    this.setStatus('offline', 'Cached session — reconnect to refresh permissions')
    return this.getAuthState()
  }

  private async applySession(session: Session): Promise<void> {
    this.session = session
    this.client = createSupabaseClient()
    await this.client.auth.setSession({
      access_token: session.access_token,
      refresh_token: session.refresh_token
    })
    saveSession(session)
    await this.loadProfile()
    await this.ensureWorkspace()
    await this.pullAll()
    this.subscribeRealtime()
    this.persistAuthCache()
    this.cloudValidated = true
    this.setStatus('synced')
  }

  async reconcileCloudSession(): Promise<AuthState> {
    if (!this.session) return this.getAuthState()
    if (!(await isNetworkReachable())) return this.getAuthState()
    try {
      this.setStatus('syncing')
      await this.client.auth.setSession({
        access_token: this.session.access_token,
        refresh_token: this.session.refresh_token
      })
      const { data, error } = await this.client.auth.refreshSession()
      if (error || !data.session) throw error ?? new Error('Could not refresh session')
      await this.applySession(data.session)
    } catch (e) {
      const stored = loadSession()
      if (stored) return this.applySessionOffline(stored)
      this.setStatus('error', e instanceof Error ? e.message : 'Reconnect failed')
    }
    return this.getAuthState()
  }

  async signIn(email: string, password: string): Promise<AuthState> {
    this.setStatus('syncing')
    const { data, error } = await this.client.auth.signInWithPassword({ email, password })
    if (error) {
      this.setStatus('error', error.message)
      throw error
    }
    if (!data.session) throw new Error('No session returned')
    await this.applySession(data.session)
    return this.getAuthState()
  }

  async signUp(
    email: string,
    password: string,
    displayName: string
  ): Promise<{ needsConfirmation: boolean }> {
    const { data, error } = await this.client.auth.signUp({
      email: email.trim(),
      password,
      options: {
        data: {
          display_name: displayName.trim() || email.split('@')[0]
        }
      }
    })
    if (error) throw error
    if (data.session) {
      await this.applySession(data.session)
      return { needsConfirmation: false }
    }
    return { needsConfirmation: true }
  }

  async verifyEmailOtp(email: string, token: string): Promise<AuthState> {
    const { data, error } = await this.client.auth.verifyOtp({
      email: email.trim(),
      token: token.trim(),
      type: 'signup'
    })
    if (error) throw error
    if (!data.session) throw new Error('Verification succeeded but no session was returned')
    await this.applySession(data.session)
    return this.getAuthState()
  }

  async resendSignupOtp(email: string): Promise<void> {
    const { error } = await this.client.auth.resend({
      type: 'signup',
      email: email.trim()
    })
    if (error) throw error
  }

  async loadProfile(): Promise<UserProfile | null> {
    if (!this.session) return null
    const { data, error } = await this.client
      .from('profiles')
      .select('id, email, display_name, avatar_url')
      .eq('id', this.session.user.id)
      .maybeSingle()
    if (error || !data) {
      this.profile = {
        id: this.session.user.id,
        email: this.session.user.email ?? '',
        display_name: (this.session.user.user_metadata?.display_name as string) ?? null,
        avatar_url: null
      }
      return this.profile
    }
    this.profile = data as UserProfile
    return this.profile
  }

  async refreshSessionFromToken(refreshToken: string): Promise<AuthState> {
    const online = await isNetworkReachable()
    if (!online) {
      const stored = loadSession()
      if (stored) return this.applySessionOffline(stored)
      throw new Error('Offline — no cached session on this Mac')
    }
    try {
      const { data, error } = await this.client.auth.refreshSession({ refresh_token: refreshToken })
      if (error || !data.session) throw error ?? new Error('Could not refresh session')
      await this.applySession(data.session)
      return this.getAuthState()
    } catch (e) {
      const stored = loadSession()
      if (stored) return this.applySessionOffline(stored)
      throw e
    }
  }

  async signOut(): Promise<void> {
    await this.client.auth.signOut()
    this.realtimeChannel?.unsubscribe()
    this.realtimeChannel = null
    this.session = null
    this.profile = null
    this.workspaceId = null
    this.workspaceName = null
    this.cloudValidated = false
    saveSession(null)
    clearAuthCache()
    this.setStatus('offline')
  }

  async restoreSession(): Promise<AuthState> {
    const stored = loadSession()
    if (!stored) {
      this.setStatus('offline')
      return this.getAuthState()
    }
    if (!(await isNetworkReachable())) {
      return this.applySessionOffline(stored)
    }
    try {
      this.setStatus('syncing')
      const { data, error } = await this.client.auth.setSession({
        access_token: stored.access_token,
        refresh_token: stored.refresh_token
      })
      if (error || !data.session) {
        return this.applySessionOffline(stored)
      }
      await this.applySession(data.session)
      return this.getAuthState()
    } catch (e) {
      return this.applySessionOffline(stored)
    }
  }

  private async ensureWorkspace(): Promise<void> {
    const userId = this.session?.user?.id
    if (!userId) return

    const { data: owned } = await this.client
      .from('workspaces')
      .select('id, name')
      .eq('owner_id', userId)
      .limit(1)
      .maybeSingle()

    if (owned) {
      this.workspaceId = owned.id
      this.workspaceName = owned.name
      return
    }

    const { data: member } = await this.client
      .from('workspace_members')
      .select('workspace_id')
      .eq('user_id', userId)
      .limit(1)
      .maybeSingle()

    if (member?.workspace_id) {
      const { data: ws } = await this.client
        .from('workspaces')
        .select('id, name')
        .eq('id', member.workspace_id)
        .single()
      this.workspaceId = member.workspace_id
      this.workspaceName = ws?.name ?? 'Workspace'
      return
    }

    const slug = `media-${userId.slice(0, 8)}`
    const { data: rpcId, error: rpcErr } = await this.client.rpc('create_workspace', {
      p_name: 'Media Monitoring',
      p_slug: slug
    })

    if (!rpcErr && rpcId) {
      this.workspaceId = rpcId as string
      this.workspaceName = 'Media Monitoring'
      return
    }

    const { data: created, error } = await this.client
      .from('workspaces')
      .insert({
        name: 'Media Monitoring',
        slug: `${slug}-${Date.now()}`,
        owner_id: userId,
        plan_id: 'free'
      })
      .select('id, name')
      .single()

    if (error) throw new Error(rpcErr?.message ?? error.message)

    this.workspaceId = created.id
    this.workspaceName = created.name
  }

  getWorkspaceId(): string {
    if (!this.workspaceId) throw new Error('Not signed in or workspace not ready')
    return this.workspaceId
  }

  async pullAll(): Promise<void> {
    if (!this.session || !this.workspaceId) return
    await this.pullPublications()
    await this.pullMonitors()
  }

  async pullPublications(): Promise<void> {
    const { data, error } = await this.client
      .from('publication_sources')
      .select('*')
      .eq('verified', true)
      .order('authority_score', { ascending: false })

    if (error) throw error
    if (!data?.length) return

    const upsert = this.db.prepare(`
      INSERT INTO publication_sources (
        id, name, logo_url, website, region, country, language, category,
        publication_type, authority_score, estimated_traffic, verified
      ) VALUES (
        @id, @name, @logo_url, @website, @region, @country, @language, @category,
        @publication_type, @authority_score, @estimated_traffic, @verified
      )
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        website = excluded.website,
        region = excluded.region,
        authority_score = excluded.authority_score,
        estimated_traffic = excluded.estimated_traffic
    `)

    const tx = this.db.transaction(() => {
      for (const row of data) {
        upsert.run({
          id: row.id,
          name: row.name,
          logo_url: row.logo_url,
          website: row.website,
          region: row.region,
          country: row.country,
          language: row.language ?? 'en',
          category: row.category,
          publication_type: row.publication_type,
          authority_score: Number(row.authority_score),
          estimated_traffic: Number(row.estimated_traffic),
          verified: row.verified ? 1 : 0
        })
      }
    })
    tx()
  }

  async pullMonitors(): Promise<void> {
    const { data, error } = await this.client
      .from('monitor_profiles')
      .select('*')
      .eq('workspace_id', this.workspaceId!)
      .order('updated_at', { ascending: false })

    if (error) throw error

    const upsert = this.db.prepare(`
      INSERT INTO monitor_profiles (
        id, workspace_id, name, keywords, exclusions, regions, publication_filters,
        language_filters, alert_settings, linked_client, linked_campaign, is_active, created_by, updated_at
      ) VALUES (
        @id, @workspace_id, @name, @keywords, @exclusions, @regions, @publication_filters,
        @language_filters, @alert_settings, @linked_client, @linked_campaign, @is_active, @created_by, @updated_at
      )
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        keywords = excluded.keywords,
        is_active = excluded.is_active,
        updated_at = excluded.updated_at
    `)

    const tx = this.db.transaction(() => {
      for (const m of data ?? []) {
        upsert.run({
          id: m.id,
          workspace_id: m.workspace_id,
          name: m.name,
          keywords: m.keywords,
          exclusions: m.exclusions,
          regions: m.regions ? JSON.stringify(m.regions) : null,
          publication_filters: m.publication_filters ? JSON.stringify(m.publication_filters) : null,
          language_filters: m.language_filters ? JSON.stringify(m.language_filters) : null,
          alert_settings: m.alert_settings ? JSON.stringify(m.alert_settings) : null,
          linked_client: m.linked_client,
          linked_campaign: m.linked_campaign,
          is_active: m.is_active ? 1 : 0,
          created_by: m.created_by,
          updated_at: m.updated_at
        })
      }
    })
    tx()

    for (const m of data ?? []) {
      await this.pullResults(m.id)
    }
  }

  async pullResults(monitorId: string): Promise<void> {
    const { data, error } = await this.client
      .from('monitor_results')
      .select('*')
      .eq('monitor_profile_id', monitorId)
      .order('published_at', { ascending: false })
      .limit(200)

    if (error) throw error

    const insert = this.db.prepare(`
      INSERT INTO monitor_results (
        id, monitor_profile_id, publication_id, title, url, author, published_at,
        article_text, sentiment, reach, media_value, pr_value, relevance_score,
        language, region, country, coverage_type, keyword_matches
      ) VALUES (
        @id, @monitor_profile_id, @publication_id, @title, @url, @author, @published_at,
        @article_text, @sentiment, @reach, @media_value, @pr_value, @relevance_score,
        @language, @region, @country, @coverage_type, @keyword_matches
      )
      ON CONFLICT(id) DO NOTHING
    `)

    const tx = this.db.transaction(() => {
      for (const r of data ?? []) {
        insert.run({
          id: r.id,
          monitor_profile_id: r.monitor_profile_id,
          publication_id: r.publication_id,
          title: r.title,
          url: r.url,
          author: r.author,
          published_at: r.published_at,
          article_text: r.article_text,
          sentiment: r.sentiment,
          reach: r.reach,
          media_value: r.media_value,
          pr_value: r.pr_value,
          relevance_score: r.relevance_score,
          language: r.language,
          region: r.region,
          country: r.country,
          coverage_type: r.coverage_type,
          keyword_matches: r.keyword_matches ? JSON.stringify(r.keyword_matches) : null
        })
      }
    })
    tx()
  }

  async pushMonitor(profile: Record<string, unknown>): Promise<void> {
    if (!this.session || !this.workspaceId) return
    const payload = {
      id: profile.id,
      workspace_id: this.workspaceId,
      name: profile.name,
      keywords: profile.keywords,
      exclusions: profile.exclusions ?? null,
      regions: profile.regions ? JSON.parse(profile.regions as string) : null,
      publication_filters: profile.publication_filters
        ? JSON.parse(profile.publication_filters as string)
        : null,
      language_filters: profile.language_filters
        ? JSON.parse(profile.language_filters as string)
        : null,
      alert_settings: profile.alert_settings ? JSON.parse(profile.alert_settings as string) : null,
      linked_client: profile.linked_client ?? null,
      linked_campaign: profile.linked_campaign ?? null,
      is_active: Boolean(profile.is_active),
      created_by: this.session.user.id
    }

    const { error } = await this.client.from('monitor_profiles').upsert(payload)
    if (error) throw error
  }

  async pushResult(result: Record<string, unknown>): Promise<void> {
    if (!this.session) return

    const payload = {
      id: result.id,
      monitor_profile_id: result.monitor_profile_id,
      publication_id: result.publication_id ?? null,
      title: result.title,
      url: result.url ?? null,
      author: result.author ?? null,
      published_at: result.published_at ?? null,
      article_text: result.article_text ?? null,
      sentiment: result.sentiment ?? 'neutral',
      reach: result.reach ?? 0,
      media_value: result.media_value ?? 0,
      pr_value: result.pr_value ?? 0,
      relevance_score: result.relevance_score ?? 0,
      language: result.language ?? 'en',
      region: result.region ?? null,
      country: result.country ?? null,
      coverage_type: result.coverage_type ?? 'online',
      keyword_matches: result.keyword_matches
        ? JSON.parse(result.keyword_matches as string)
        : null
    }

    const { error } = await this.client.from('monitor_results').upsert(payload)
    if (error) throw error

    await this.logActivity(result.id as string, 'discovered', { title: result.title })
  }

  async pushSavedCoverage(
    resultId: string,
    data?: { notes?: string; tags?: string[] }
  ): Promise<void> {
    if (!this.session || !this.workspaceId) return

    const { error } = await this.client.from('saved_coverage').upsert({
      workspace_id: this.workspaceId,
      monitor_result_id: resultId,
      notes: data?.notes ?? null,
      tags: data?.tags ?? null
    })
    if (error) throw error

    await this.logActivity(resultId, 'saved', data ?? {})
  }

  async updateResultSentiment(resultId: string, sentiment: string): Promise<void> {
    this.db.prepare('UPDATE monitor_results SET sentiment = ? WHERE id = ?').run(sentiment, resultId)
    if (!this.session) return
    const { error } = await this.client
      .from('monitor_results')
      .update({ sentiment })
      .eq('id', resultId)
    if (error) throw error
    await this.logActivity(resultId, 'sentiment_override', { sentiment })
  }

  async updateResultNotes(resultId: string, notes: string, tags: string[]): Promise<void> {
    await this.pushSavedCoverage(resultId, { notes, tags })
    this.db.prepare('UPDATE monitor_results SET is_saved = 1 WHERE id = ?').run(resultId)
  }

  async deleteMonitor(id: string): Promise<void> {
    if (!this.session) return
    const { error } = await this.client.from('monitor_profiles').delete().eq('id', id)
    if (error) throw error
  }

  private async logActivity(
    monitorResultId: string,
    action: string,
    metadata: Record<string, unknown>
  ): Promise<void> {
    if (!this.session) return
    await this.client.from('coverage_activity').insert({
      monitor_result_id: monitorResultId,
      user_id: this.session.user.id,
      action,
      metadata
    })
  }

  private subscribeRealtime(): void {
    if (!this.workspaceId) return
    this.realtimeChannel?.unsubscribe()

    this.realtimeChannel = this.client
      .channel('monitor-results')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'monitor_results' },
        async (payload) => {
          const row = payload.new as Record<string, unknown>
          await this.pullResults(row.monitor_profile_id as string)
          for (const win of BrowserWindow.getAllWindows()) {
            win.webContents.send('sync:remote-article', row)
          }
        }
      )
      .subscribe()
  }
}
