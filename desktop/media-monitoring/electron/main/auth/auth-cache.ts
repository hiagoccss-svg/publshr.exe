import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'fs'
import { join } from 'path'
import { app } from 'electron'
import type { UserProfile } from '../supabase/sync-service'

export interface AuthOfflineCache {
  userId: string
  email: string
  workspaceId: string
  workspaceName: string
  profile: UserProfile | null
  savedAt: string
}

const file = () => join(app.getPath('userData'), 'auth-offline-cache.json')

export function saveAuthCache(cache: AuthOfflineCache): void {
  const dir = app.getPath('userData')
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true })
  writeFileSync(file(), JSON.stringify(cache, null, 0))
}

export function loadAuthCache(): AuthOfflineCache | null {
  try {
    if (!existsSync(file())) return null
    return JSON.parse(readFileSync(file(), 'utf-8')) as AuthOfflineCache
  } catch {
    return null
  }
}

export function clearAuthCache(): void {
  if (existsSync(file())) writeFileSync(file(), '')
}
