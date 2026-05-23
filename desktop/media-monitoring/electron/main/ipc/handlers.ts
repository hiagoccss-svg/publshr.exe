import { ipcMain, BrowserWindow, Notification, app, shell } from 'electron'
import { join } from 'path'
import {
  configureGlassWindow,
  glassWindowOptions
} from '../../../../../shared/electron/glass-window'
import { v4 as uuidv4 } from 'uuid'
import type { MonitoringEngine } from '../monitoring/engine'
import type { SyncService } from '../supabase/sync-service'
import { getDatabase, getDbPath } from '../db'
import { LOCAL_WORKSPACE_ID } from '../config'
import {
  getBiometricStatus,
  promptBiometric,
  storeBiometricSession,
  loadBiometricRefreshToken,
  clearBiometricSession
} from '../auth/biometric'
import { parseAlertSettings, shouldNotifyForArticle } from '../monitoring/alert-rules'

export function registerIpcHandlers(engine: MonitoringEngine, sync: SyncService): void {
  const db = () => getDatabase()

  // Auth & sync
  ipcMain.handle('auth:restore', () => sync.restoreSession())
  ipcMain.handle('auth:reconcile-cloud', () => sync.reconcileCloudSession())
  ipcMain.handle('auth:sign-in', (_, email: string, password: string) => sync.signIn(email, password))
  ipcMain.handle('auth:sign-up', (_, email: string, password: string, displayName: string) =>
    sync.signUp(email, password, displayName)
  )
  ipcMain.handle('auth:verify-otp', (_, email: string, token: string) => sync.verifyEmailOtp(email, token))
  ipcMain.handle('auth:resend-otp', (_, email: string) => sync.resendSignupOtp(email))
  ipcMain.handle('auth:sign-out', async () => {
    clearBiometricSession()
    await sync.signOut()
  })
  ipcMain.handle('auth:get-state', () => sync.getAuthState())
  ipcMain.handle('auth:get-profile', () => sync.loadProfile())
  ipcMain.handle('auth:biometric-status', () => getBiometricStatus())
  ipcMain.handle('auth:biometric-enable', async () => {
    const state = sync.getAuthState()
    const refresh = state.session?.refresh_token
    if (!refresh) throw new Error('Sign in with password first')
    const ok = await promptBiometric('Enable Touch ID for Publshr Media Monitoring')
    if (!ok) throw new Error('Biometric verification cancelled')
    if (!storeBiometricSession(refresh)) throw new Error('Secure storage unavailable')
    return { ok: true }
  })
  ipcMain.handle('auth:biometric-unlock', async () => {
    const status = getBiometricStatus()
    if (!status.enabled) throw new Error('Biometric unlock is not enabled')
    const ok = await promptBiometric('Unlock Publshr Media Monitoring')
    if (!ok) throw new Error('Biometric verification failed')
    const refresh = loadBiometricRefreshToken()
    if (!refresh) throw new Error('No stored session')
    return sync.refreshSessionFromToken(refresh)
  })
  ipcMain.handle('auth:biometric-disable', () => {
    clearBiometricSession()
    return { ok: true }
  })
  ipcMain.handle('sync:pull', () => sync.pullAll())
  ipcMain.handle('sync:status', () => sync.getStatus())

  ipcMain.handle('db:get-publications', (_, filters?: { region?: string; language?: string }) => {
    let sql = 'SELECT * FROM publication_sources WHERE verified = 1'
    const params: Record<string, string> = {}
    if (filters?.region) {
      sql += ' AND region = @region'
      params.region = filters.region
    }
    if (filters?.language) {
      sql += ' AND language = @language'
      params.language = filters.language
    }
    sql += ' ORDER BY authority_score DESC'
    return db().prepare(sql).all(params)
  })

  ipcMain.handle('db:get-monitors', () => {
    return db()
      .prepare(
        `SELECT mp.*,
          (SELECT COUNT(*) FROM monitor_results mr WHERE mr.monitor_profile_id = mp.id) as result_count
         FROM monitor_profiles mp
         ORDER BY mp.updated_at DESC`
      )
      .all()
  })

  ipcMain.handle('db:create-monitor', async (_, input: Record<string, unknown>) => {
    const workspaceId = sync.isAuthenticated()
      ? sync.getAuthState().workspaceId!
      : LOCAL_WORKSPACE_ID
    const id = uuidv4()
    const stmt = db().prepare(`
      INSERT INTO monitor_profiles (
        id, workspace_id, name, keywords, exclusions, regions, publication_filters,
        language_filters, alert_settings, linked_client, linked_campaign, created_by
      ) VALUES (
        @id, @workspace_id, @name, @keywords, @exclusions, @regions, @publication_filters,
        @language_filters, @alert_settings, @linked_client, @linked_campaign, @created_by
      )
    `)
    stmt.run({
      id,
      workspace_id: workspaceId,
      name: input.name,
      keywords: input.keywords,
      exclusions: input.exclusions ?? null,
      regions: input.regions ? JSON.stringify(input.regions) : null,
      publication_filters: input.publication_filters ? JSON.stringify(input.publication_filters) : null,
      language_filters: input.language_filters ? JSON.stringify(input.language_filters) : null,
      alert_settings: input.alert_settings ? JSON.stringify(input.alert_settings) : null,
      linked_client: input.linked_client ?? null,
      linked_campaign: input.linked_campaign ?? null,
      created_by: sync.getAuthState().userId ?? 'local-user'
    })
    const profile = db().prepare('SELECT * FROM monitor_profiles WHERE id = ?').get(id) as Record<
      string,
      unknown
    >
    try {
      await sync.pushMonitor(profile)
    } catch (e) {
      console.error('Supabase push monitor failed:', e)
    }
    return profile
  })

  ipcMain.handle('db:update-monitor', async (_, id: string, updates: Record<string, unknown>) => {
    const fields: string[] = []
    const params: Record<string, unknown> = { id }
    for (const [key, value] of Object.entries(updates)) {
      if (['regions', 'language_filters', 'publication_filters', 'alert_settings'].includes(key)) {
        fields.push(`${key} = @${key}`)
        params[key] = JSON.stringify(value)
      } else {
        fields.push(`${key} = @${key}`)
        params[key] = value
      }
    }
    fields.push("updated_at = datetime('now')")
    db()
      .prepare(`UPDATE monitor_profiles SET ${fields.join(', ')} WHERE id = @id`)
      .run(params)
    const profile = db().prepare('SELECT * FROM monitor_profiles WHERE id = ?').get(id) as Record<
      string,
      unknown
    >
    try {
      await sync.pushMonitor(profile)
    } catch (e) {
      console.error('Supabase update monitor failed:', e)
    }
    return profile
  })

  ipcMain.handle('db:delete-monitor', async (_, id: string) => {
    engine.stopMonitoring(id)
    db().prepare('DELETE FROM monitor_profiles WHERE id = ?').run(id)
    try {
      await sync.deleteMonitor(id)
    } catch (e) {
      console.error('Supabase delete monitor failed:', e)
    }
    return { ok: true }
  })

  ipcMain.handle('db:get-results', (_, monitorId: string, options?: Record<string, unknown>) => {
    const limit = (options?.limit as number) ?? 100
    const offset = (options?.offset as number) ?? 0
    let sql = `
      SELECT mr.*, ps.name as publication_name, ps.logo_url, ps.website, ps.category,
             ps.authority_score, ps.estimated_traffic,
             sc.notes as saved_notes, sc.tags as saved_tags
      FROM monitor_results mr
      LEFT JOIN publication_sources ps ON mr.publication_id = ps.id
      LEFT JOIN saved_coverage sc ON sc.monitor_result_id = mr.id
      WHERE mr.monitor_profile_id = ?
    `
    const params: unknown[] = [monitorId]

    if (options?.sentiment) {
      sql += ' AND mr.sentiment = ?'
      params.push(options.sentiment)
    }
    if (options?.savedOnly) {
      sql += ' AND mr.is_saved = 1'
    }
    if (options?.search) {
      sql += ' AND (mr.title LIKE ? OR mr.article_text LIKE ?)'
      const q = `%${options.search}%`
      params.push(q, q)
    }

    const sort = (options?.sort as string) ?? 'newest'
    if (sort === 'oldest') sql += ' ORDER BY mr.published_at ASC'
    else if (sort === 'reach') sql += ' ORDER BY mr.reach DESC'
    else if (sort === 'pr_value') sql += ' ORDER BY mr.pr_value DESC'
    else if (sort === 'relevance') sql += ' ORDER BY mr.relevance_score DESC'
    else sql += ' ORDER BY mr.published_at DESC'

    sql += ' LIMIT ? OFFSET ?'
    params.push(limit, offset)
    return db().prepare(sql).all(...params)
  })

  ipcMain.handle('db:get-saved-coverage', () => {
    return db()
      .prepare(
        `SELECT mr.*, ps.name as publication_name, ps.website, sc.notes as saved_notes, sc.tags as saved_tags
         FROM saved_coverage sc
         JOIN monitor_results mr ON mr.id = sc.monitor_result_id
         LEFT JOIN publication_sources ps ON mr.publication_id = ps.id
         ORDER BY sc.created_at DESC`
      )
      .all()
  })

  ipcMain.handle('db:get-article', (_, id: string) => {
    return db()
      .prepare(
        `SELECT mr.*, ps.name as publication_name, ps.logo_url, ps.website, ps.category,
                sc.notes as saved_notes, sc.tags as saved_tags
         FROM monitor_results mr
         LEFT JOIN publication_sources ps ON mr.publication_id = ps.id
         LEFT JOIN saved_coverage sc ON sc.monitor_result_id = mr.id
         WHERE mr.id = ?`
      )
      .get(id)
  })

  ipcMain.handle('db:save-coverage', async (_, resultId: string, data?: { notes?: string; tags?: string[] }) => {
    const workspaceId = sync.isAuthenticated()
      ? sync.getAuthState().workspaceId!
      : LOCAL_WORKSPACE_ID
    const existing = db().prepare('SELECT id FROM saved_coverage WHERE monitor_result_id = ?').get(resultId)
    if (existing) {
      db()
        .prepare('UPDATE saved_coverage SET notes = ?, tags = ? WHERE monitor_result_id = ?')
        .run(data?.notes ?? null, data?.tags ? JSON.stringify(data.tags) : null, resultId)
    } else {
      db()
        .prepare(
          `INSERT INTO saved_coverage (id, workspace_id, monitor_result_id, notes, tags) VALUES (?, ?, ?, ?, ?)`
        )
        .run(uuidv4(), workspaceId, resultId, data?.notes ?? null, data?.tags ? JSON.stringify(data.tags) : null)
    }
    db().prepare('UPDATE monitor_results SET is_saved = 1 WHERE id = ?').run(resultId)
    try {
      await sync.pushSavedCoverage(resultId, data)
    } catch (e) {
      console.error('Supabase save coverage failed:', e)
    }
    return { ok: true }
  })

  ipcMain.handle('db:update-sentiment', async (_, resultId: string, sentiment: string) => {
    db().prepare('UPDATE monitor_results SET sentiment = ? WHERE id = ?').run(sentiment, resultId)
    try {
      await sync.updateResultSentiment(resultId, sentiment)
    } catch (e) {
      console.error('Sentiment sync failed:', e)
    }
    return { ok: true }
  })

  ipcMain.handle(
    'db:get-report-analytics',
    (_, options?: { days?: number; savedOnly?: boolean }) => {
      const days = (options?.days as number) ?? 30
      const savedOnly = Boolean(options?.savedOnly)
      const since =
        days > 0
          ? new Date(Date.now() - days * 86400000).toISOString()
          : null

      let where = '1=1'
      const params: unknown[] = []
      if (since) {
        where += ' AND (mr.published_at IS NULL OR mr.published_at >= ?)'
        params.push(since)
      }
      if (savedOnly) {
        where += ' AND mr.is_saved = 1'
      }

      const totals = db()
        .prepare(
          `SELECT COUNT(*) as mentions,
            COALESCE(SUM(mr.reach), 0) as total_reach,
            COALESCE(SUM(mr.pr_value), 0) as total_pr_value,
            COALESCE(SUM(mr.media_value), 0) as total_media_value,
            COALESCE(AVG(mr.relevance_score), 0) as avg_relevance
           FROM monitor_results mr
           WHERE ${where}`
        )
        .get(...params) as Record<string, number>

      const bySentiment = db()
        .prepare(
          `SELECT mr.sentiment as sentiment, COUNT(*) as count
           FROM monitor_results mr
           WHERE ${where}
           GROUP BY mr.sentiment`
        )
        .all(...params) as { sentiment: string; count: number }[]

      const byPublication = db()
        .prepare(
          `SELECT COALESCE(ps.name, 'Unknown') as name,
            COUNT(*) as count,
            COALESCE(SUM(mr.pr_value), 0) as pr_value,
            COALESCE(SUM(mr.reach), 0) as reach
           FROM monitor_results mr
           LEFT JOIN publication_sources ps ON mr.publication_id = ps.id
           WHERE ${where}
           GROUP BY ps.id, ps.name
           ORDER BY count DESC
           LIMIT 12`
        )
        .all(...params) as { name: string; count: number; pr_value: number; reach: number }[]

      const byMediaType = db()
        .prepare(
          `SELECT COALESCE(ps.publication_type, mr.coverage_type, 'online') as media_type,
            COUNT(*) as count
           FROM monitor_results mr
           LEFT JOIN publication_sources ps ON mr.publication_id = ps.id
           WHERE ${where}
           GROUP BY media_type
           ORDER BY count DESC`
        )
        .all(...params) as { media_type: string; count: number }[]

      const byMonitor = db()
        .prepare(
          `SELECT mp.name as name, COUNT(*) as count
           FROM monitor_results mr
           JOIN monitor_profiles mp ON mp.id = mr.monitor_profile_id
           WHERE ${where}
           GROUP BY mp.id, mp.name
           ORDER BY count DESC
           LIMIT 8`
        )
        .all(...params) as { name: string; count: number }[]

      return {
        periodDays: days,
        savedOnly,
        totals,
        bySentiment,
        byPublication,
        byMediaType,
        byMonitor
      }
    }
  )

  ipcMain.handle(
    'db:get-workspace-clippings',
    (_, options?: {
      days?: number
      savedOnly?: boolean
      sentiment?: string
      search?: string
      sort?: string
      limit?: number
    }) => {
      const days = (options?.days as number) ?? 30
      const limit = (options?.limit as number) ?? 200
      const since =
        days > 0
          ? new Date(Date.now() - days * 86400000).toISOString()
          : null

      let sql = `
        SELECT mr.*, ps.name as publication_name, ps.logo_url, ps.website, ps.category,
               ps.publication_type, ps.country, ps.authority_score,
               mp.name as monitor_name,
               sc.notes as saved_notes, sc.tags as saved_tags
        FROM monitor_results mr
        LEFT JOIN publication_sources ps ON mr.publication_id = ps.id
        LEFT JOIN monitor_profiles mp ON mp.id = mr.monitor_profile_id
        LEFT JOIN saved_coverage sc ON sc.monitor_result_id = mr.id
        WHERE 1=1
      `
      const params: unknown[] = []

      if (since) {
        sql += ' AND (mr.published_at IS NULL OR mr.published_at >= ?)'
        params.push(since)
      }
      if (options?.savedOnly) {
        sql += ' AND mr.is_saved = 1'
      }
      if (options?.sentiment) {
        sql += ' AND mr.sentiment = ?'
        params.push(options.sentiment)
      }
      if (options?.search) {
        sql += ' AND (mr.title LIKE ? OR mr.article_text LIKE ? OR ps.name LIKE ?)'
        const q = `%${options.search}%`
        params.push(q, q, q)
      }

      const sort = (options?.sort as string) ?? 'newest'
      if (sort === 'oldest') sql += ' ORDER BY mr.published_at ASC'
      else if (sort === 'reach') sql += ' ORDER BY mr.reach DESC'
      else if (sort === 'pr_value') sql += ' ORDER BY mr.pr_value DESC'
      else sql += ' ORDER BY mr.published_at DESC'

      sql += ' LIMIT ?'
      params.push(limit)
      return db().prepare(sql).all(...params)
    }
  )

  ipcMain.handle('db:get-activity', (_, resultId: string) => {
    return db()
      .prepare(
        `SELECT action, metadata, created_at FROM coverage_activity_local WHERE monitor_result_id = ? ORDER BY created_at DESC LIMIT 20`
      )
      .all(resultId)
  })

  ipcMain.handle('db:get-stats', () => {
    const monitors = db().prepare('SELECT COUNT(*) as c FROM monitor_profiles').get() as { c: number }
    const articles = db().prepare('SELECT COUNT(*) as c FROM monitor_results').get() as { c: number }
    const saved = db().prepare('SELECT COUNT(*) as c FROM saved_coverage').get() as { c: number }
    const prValue = db()
      .prepare('SELECT COALESCE(SUM(pr_value), 0) as total FROM monitor_results')
      .get() as { total: number }
    return { monitors: monitors.c, articles: articles.c, saved: saved.c, totalPrValue: prValue.total }
  })

  ipcMain.handle('monitoring:start', (_, monitorId: string) => {
    engine.startMonitoring(monitorId)
    return { ok: true }
  })

  ipcMain.handle('monitoring:stop', (_, monitorId: string) => {
    engine.stopMonitoring(monitorId)
    return { ok: true }
  })

  ipcMain.handle('monitoring:session', (_, monitorId: string) => {
    return db()
      .prepare('SELECT * FROM monitoring_sessions WHERE monitor_profile_id = ? ORDER BY started_at DESC LIMIT 1')
      .get(monitorId)
  })

  ipcMain.handle('app:get-paths', () => ({
    userData: app.getPath('userData'),
    dbPath: getDbPath()
  }))

  ipcMain.handle('app:open-external', (_, url: string) => {
    if (url.startsWith('http')) shell.openExternal(url)
  })

  ipcMain.handle('window:open-article', (_, articleId: string) => {
    const win = new BrowserWindow(
      glassWindowOptions('dark', {
        width: 1100,
        height: 780,
        minWidth: 800,
        minHeight: 600,
        webPreferences: {
          preload: join(__dirname, '../preload/index.mjs'),
          contextIsolation: true,
          nodeIntegration: false
        }
      })
    )
    configureGlassWindow(win, 'dark')
    const base = process.env.ELECTRON_RENDERER_URL
    if (base) {
      win.loadURL(`${base}#/article/${articleId}`)
    } else {
      win.loadFile(join(__dirname, '../../renderer/index.html'), {
        hash: `/article/${articleId}`
      })
    }
  })

  engine.on('stream', async (event) => {
    const windows = BrowserWindow.getAllWindows()
    for (const win of windows) {
      win.webContents.send('monitoring:stream', event)
    }

    if (event.type === 'article' && event.article) {
      try {
        await sync.pushResult(event.article as Record<string, unknown>)
      } catch (e) {
        console.error('Supabase push result failed:', e)
      }

      if (Notification.isSupported()) {
        const profile = db()
          .prepare('SELECT alert_settings FROM monitor_profiles WHERE id = ?')
          .get(event.monitorId) as { alert_settings?: string } | undefined
        const rules = parseAlertSettings(profile?.alert_settings)
        const article = event.article as {
          title?: string
          publication_name?: string
          relevance_score?: number
          sentiment?: string
        }
        if (shouldNotifyForArticle(rules, article)) {
          new Notification({
            title: 'New coverage found',
            body: `${article.publication_name ?? 'Publication'}: ${article.title ?? 'Article'}`
          }).show()
        }
      }
    }
  })
}
