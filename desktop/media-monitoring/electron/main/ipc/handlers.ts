import { ipcMain, BrowserWindow, Notification, app } from 'electron'
import { join } from 'path'
import { v4 as uuidv4 } from 'uuid'
import type { MonitoringEngine } from '../monitoring/engine'
import { getDatabase, getDbPath } from '../db'

export function registerIpcHandlers(engine: MonitoringEngine): void {
  const db = () => getDatabase()

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

  ipcMain.handle('db:create-monitor', (_, input: Record<string, unknown>) => {
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
      workspace_id: input.workspace_id ?? 'default',
      name: input.name,
      keywords: input.keywords,
      exclusions: input.exclusions ?? null,
      regions: input.regions ? JSON.stringify(input.regions) : null,
      publication_filters: input.publication_filters ? JSON.stringify(input.publication_filters) : null,
      language_filters: input.language_filters ? JSON.stringify(input.language_filters) : null,
      alert_settings: input.alert_settings ? JSON.stringify(input.alert_settings) : null,
      linked_client: input.linked_client ?? null,
      linked_campaign: input.linked_campaign ?? null,
      created_by: input.created_by ?? 'local-user'
    })
    return db().prepare('SELECT * FROM monitor_profiles WHERE id = ?').get(id)
  })

  ipcMain.handle('db:update-monitor', (_, id: string, updates: Record<string, unknown>) => {
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
    return db().prepare('SELECT * FROM monitor_profiles WHERE id = ?').get(id)
  })

  ipcMain.handle('db:delete-monitor', (_, id: string) => {
    engine.stopMonitoring(id)
    db().prepare('DELETE FROM monitor_profiles WHERE id = ?').run(id)
    return { ok: true }
  })

  ipcMain.handle('db:get-results', (_, monitorId: string, options?: { limit?: number; offset?: number }) => {
    const limit = options?.limit ?? 100
    const offset = options?.offset ?? 0
    return db()
      .prepare(
        `SELECT mr.*, ps.name as publication_name, ps.logo_url, ps.website, ps.category,
                ps.authority_score, ps.estimated_traffic
         FROM monitor_results mr
         LEFT JOIN publication_sources ps ON mr.publication_id = ps.id
         WHERE mr.monitor_profile_id = ?
         ORDER BY mr.published_at DESC
         LIMIT ? OFFSET ?`
      )
      .all(monitorId, limit, offset)
  })

  ipcMain.handle('db:save-coverage', (_, resultId: string, data?: { notes?: string; tags?: string[] }) => {
    const existing = db().prepare('SELECT id FROM saved_coverage WHERE monitor_result_id = ?').get(resultId)
    if (existing) {
      db()
        .prepare('UPDATE saved_coverage SET notes = ?, tags = ? WHERE monitor_result_id = ?')
        .run(data?.notes ?? null, data?.tags ? JSON.stringify(data.tags) : null, resultId)
    } else {
      db()
        .prepare(
          `INSERT INTO saved_coverage (id, monitor_result_id, notes, tags) VALUES (?, ?, ?, ?)`
        )
        .run(uuidv4(), resultId, data?.notes ?? null, data?.tags ? JSON.stringify(data.tags) : null)
    }
    db().prepare('UPDATE monitor_results SET is_saved = 1 WHERE id = ?').run(resultId)
    return { ok: true }
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

  engine.on('stream', (event) => {
    const windows = BrowserWindow.getAllWindows()
    for (const win of windows) {
      win.webContents.send('monitoring:stream', event)
    }

    if (event.type === 'article' && Notification.isSupported()) {
      const article = event.article as { title?: string; publication_name?: string }
      new Notification({
        title: 'New coverage found',
        body: `${article.publication_name ?? 'Publication'}: ${article.title ?? 'Article'}`
      }).show()
    }
  })
}
