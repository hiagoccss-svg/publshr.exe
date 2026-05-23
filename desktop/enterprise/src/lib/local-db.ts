import Database from '@tauri-apps/plugin-sql'
import type { SyncQueueEntry } from '@shared/desktop/types'

let db: Database | null = null

export async function getLocalDb(): Promise<Database> {
  if (!db) {
    db = await Database.load('sqlite:enterprise.db')
  }
  return db
}

export async function enqueueSync(entry: Omit<SyncQueueEntry, 'createdAt' | 'attempts'>): Promise<void> {
  const database = await getLocalDb()
  const now = Date.now()
  await database.execute(
    `INSERT INTO sync_queue (id, table_name, record_id, operation, payload, created_at, attempts)
     VALUES ($1, $2, $3, $4, $5, $6, 0)
     ON CONFLICT(id) DO UPDATE SET payload = $5, attempts = 0`,
    [entry.id, entry.tableName, entry.recordId, entry.operation, entry.payload, now]
  )
}

export async function listPendingSync(limit = 100): Promise<SyncQueueEntry[]> {
  const database = await getLocalDb()
  const rows = await database.select<
    Array<{
      id: string
      table_name: string
      record_id: string
      operation: string
      payload: string
      created_at: number
      attempts: number
    }>
  >(
    `SELECT id, table_name, record_id, operation, payload, created_at, attempts
     FROM sync_queue ORDER BY created_at ASC LIMIT $1`,
    [limit]
  )
  return rows.map((r) => ({
    id: r.id,
    tableName: r.table_name,
    recordId: r.record_id,
    operation: r.operation as SyncQueueEntry['operation'],
    payload: r.payload,
    createdAt: r.created_at,
    attempts: r.attempts
  }))
}

export async function getCacheStats(): Promise<{ syncQueuePending: number; kvEntries: number }> {
  const database = await getLocalDb()
  const [syncRow] = await database.select<Array<{ c: number }>>(
    'SELECT COUNT(*) as c FROM sync_queue'
  )
  const [kvRow] = await database.select<Array<{ c: number }>>('SELECT COUNT(*) as c FROM app_kv')
  return {
    syncQueuePending: syncRow?.c ?? 0,
    kvEntries: kvRow?.c ?? 0
  }
}
