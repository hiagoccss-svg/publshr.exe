import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'fs'
import { join } from 'path'
import { app } from 'electron'
import type { Session } from '@supabase/supabase-js'

const FILE = () => join(app.getPath('userData'), 'supabase-session.json')

export function loadSession(): Session | null {
  try {
    if (!existsSync(FILE())) return null
    const raw = readFileSync(FILE(), 'utf-8')
    if (!raw.trim()) return null
    return JSON.parse(raw) as Session
  } catch {
    return null
  }
}

export function saveSession(session: Session | null): void {
  const dir = app.getPath('userData')
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true })
  if (!session) {
    if (existsSync(FILE())) writeFileSync(FILE(), '')
    return
  }
  writeFileSync(FILE(), JSON.stringify(session))
}
