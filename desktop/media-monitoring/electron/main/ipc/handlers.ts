import { ipcMain, BrowserWindow, Notification, app, shell } from 'electron'
import { join } from 'path'
import { v4 as uuidv4 } from 'uuid'
import type { MonitoringEngine } from '../monitoring/engine'
import type { SyncService } from '../supabase/sync-service'
import { getDatabase, getDbPath } from '../db'

export function registerIpcHandlers(engine: MonitoringEngine, sync: SyncService): void {
  const db = () => getDatabase()

  // Auth & sync
  ipcMain.handle('auth:restore', () => sync.restoreSession())
  ipcMain.handle('auth:sign-in', (_, email: string, password: string) => sync.signIn(email, password))
  ipcMain.handle('auth:sign-out', () => sync.signOut())
  ipcMain.handle('auth:get-state', () => sync.getAuthState())
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
    const auth = sync.getAuthState()
    const workspaceId = auth.workspaceId ?? 'local-offline'
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
      created_by: auth.userId ?? 'local-user'
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
    const auth = sync.getAuthState()
    const workspaceId = auth.workspaceId ?? 'local-offline'
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
    try {
      await sync.updateResultSentiment(resultId, sentiment)
    } catch (e) {
      console.error('Sentiment sync failed:', e)
    }
    return { ok: true }
  })

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
    const win = new BrowserWindow({
      width: 1100,
      height: 780,
      minWidth: 800,
      minHeight: 600,
      backgroundColor: '#1E1E1E',
      titleBarStyle: 'hiddenInset',
      webPreferences: {
        preload: join(__dirname, '../preload/index.mjs'),
        contextIsolation: true,
        nodeIntegration: false
      }
    })
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
        const article = event.article as { title?: string; publication_name?: string }
        new Notification({
          title: 'New coverage found',
          body: `${article.publication_name ?? 'Publication'}: ${article.title ?? 'Article'}`
        }).show()
      }
    }
  })
}
