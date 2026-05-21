import { ipcMain, type BrowserWindow } from 'electron'
import { getDb } from './database'

type Handlers = {
  getMainWindow: () => BrowserWindow | null
  openEditorWindow: (documentId: string, plannerItemId: string) => BrowserWindow
}

export function registerIpcHandlers({ openEditorWindow }: Handlers): void {
  ipcMain.handle('db:getPreference', (_, key: string) => {
    const row = getDb().prepare('SELECT value FROM user_preferences WHERE key = ?').get(key) as
      | { value: string }
      | undefined
    return row?.value ?? null
  })

  ipcMain.handle('db:setPreference', (_, key: string, value: string) => {
    getDb()
      .prepare(
        'INSERT INTO user_preferences (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value'
      )
      .run(key, value)
    return true
  })

  ipcMain.handle('cache:getPlannerItems', (_, workspaceId: string) => {
    const rows = getDb()
      .prepare(
        'SELECT payload FROM planner_items_cache WHERE workspace_id = ? ORDER BY updated_at DESC'
      )
      .all(workspaceId) as { payload: string }[]
    return rows.map((r) => JSON.parse(r.payload))
  })

  ipcMain.handle('cache:upsertPlannerItem', (_, item: Record<string, unknown>) => {
    const id = item.id as string
    const workspaceId = item.workspace_id as string
    getDb()
      .prepare(
        `INSERT INTO planner_items_cache (id, workspace_id, payload, updated_at, sync_status)
         VALUES (?, ?, ?, ?, ?)
         ON CONFLICT(id) DO UPDATE SET
           payload = excluded.payload,
           updated_at = excluded.updated_at,
           sync_status = excluded.sync_status`
      )
      .run(id, workspaceId, JSON.stringify(item), Date.now(), item._syncStatus ?? 'pending')
    return true
  })

  ipcMain.handle('cache:deletePlannerItem', (_, id: string) => {
    getDb().prepare('DELETE FROM planner_items_cache WHERE id = ?').run(id)
    return true
  })

  ipcMain.handle('cache:getWorkspaces', () => {
    const rows = getDb().prepare('SELECT payload FROM workspaces_cache').all() as {
      payload: string
    }[]
    return rows.map((r) => JSON.parse(r.payload))
  })

  ipcMain.handle('cache:upsertWorkspace', (_, workspace: Record<string, unknown>) => {
    getDb()
      .prepare(
        `INSERT INTO workspaces_cache (id, payload, updated_at)
         VALUES (?, ?, ?)
         ON CONFLICT(id) DO UPDATE SET payload = excluded.payload, updated_at = excluded.updated_at`
      )
      .run(workspace.id as string, JSON.stringify(workspace), Date.now())
    return true
  })

  ipcMain.handle('sync:enqueue', (_, entry: { id: string; tableName: string; recordId: string; operation: string; payload: string }) => {
    getDb()
      .prepare(
        `INSERT INTO sync_queue (id, table_name, record_id, operation, payload, created_at)
         VALUES (?, ?, ?, ?, ?, ?)
         ON CONFLICT(id) DO UPDATE SET payload = excluded.payload, attempts = 0`
      )
      .run(entry.id, entry.tableName, entry.recordId, entry.operation, entry.payload, Date.now())
    return true
  })

  ipcMain.handle('sync:getQueue', () => {
    return getDb()
      .prepare('SELECT * FROM sync_queue ORDER BY created_at ASC LIMIT 100')
      .all()
  })

  ipcMain.handle('sync:dequeue', (_, id: string) => {
    getDb().prepare('DELETE FROM sync_queue WHERE id = ?').run(id)
    return true
  })

  ipcMain.handle('editor:openWindow', (_, documentId: string, plannerItemId: string) => {
    openEditorWindow(documentId, plannerItemId)
    return true
  })

  ipcMain.handle('cache:getEditorDraft', (_, documentId: string) => {
    const row = getDb()
      .prepare('SELECT payload FROM editor_drafts_cache WHERE id = ?')
      .get(documentId) as { payload: string } | undefined
    return row ? JSON.parse(row.payload) : null
  })

  ipcMain.handle('cache:upsertEditorDraft', (_, draft: Record<string, unknown>) => {
    getDb()
      .prepare(
        `INSERT INTO editor_drafts_cache (id, planner_item_id, payload, updated_at, sync_status)
         VALUES (?, ?, ?, ?, ?)
         ON CONFLICT(id) DO UPDATE SET
           payload = excluded.payload,
           updated_at = excluded.updated_at,
           sync_status = excluded.sync_status`
      )
      .run(
        draft.id as string,
        (draft.planner_item_id as string) ?? null,
        JSON.stringify(draft),
        Date.now(),
        draft._syncStatus ?? 'pending'
      )
    return true
  })
}
