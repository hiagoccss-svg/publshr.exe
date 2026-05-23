/** Unified desktop product identifiers (Tauri + legacy Electron). */
export type DesktopProductId =
  | 'enterprise'
  | 'spaces'
  | 'media-monitoring'
  | 'planner'

export type DesktopUpdateChannel = 'dev' | 'staging' | 'production'

export interface DesktopAuthUser {
  id: string
  email: string
  displayName: string | null
}

export interface DesktopAuthSnapshot {
  user: DesktopAuthUser | null
  accessToken: string | null
  refreshToken: string | null
  expiresAt: number | null
  workspaceId: string | null
  cloudValidated: boolean
  biometricEnabled: boolean
}

export interface SyncQueueEntry {
  id: string
  tableName: string
  recordId: string
  operation: 'insert' | 'update' | 'delete'
  payload: string
  createdAt: number
  attempts: number
}

export interface WindowStateSnapshot {
  label: string
  x: number | null
  y: number | null
  width: number
  height: number
  maximized: boolean
  fullscreen: boolean
}

export interface DesktopPlatformInfo {
  os: string
  arch: string
  appVersion: string
  dataDir: string
}

export interface CacheStats {
  syncQueuePending: number
  kvEntries: number
}
