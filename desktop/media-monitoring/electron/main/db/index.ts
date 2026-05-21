import Database from 'better-sqlite3'
import { join } from 'path'
import { app } from 'electron'
import { SCHEMA_SQL } from './schema'
import { seedPublications } from './seed-publications'

let db: Database.Database | null = null

export function getDbPath(): string {
  return join(app.getPath('userData'), 'media-monitoring.db')
}

export function initDatabase(): Database.Database {
  if (db) return db

  db = new Database(getDbPath())
  db.exec(SCHEMA_SQL)
  seedPublications(db)
  return db
}

export function getDatabase(): Database.Database {
  if (!db) throw new Error('Database not initialized')
  return db
}

export function closeDatabase(): void {
  if (db) {
    db.close()
    db = null
  }
}
