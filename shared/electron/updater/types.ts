/** GitHub release channel for installed desktop apps. */
export type DesktopUpdateChannel = 'dev' | 'staging' | 'production'

export type DesktopProductId = 'spaces' | 'media-monitoring' | 'planner'

export interface AppBundleManifestEntry {
  assetName: string
  sha256: string
  size: number
}

export interface ShellManifestEntry {
  assetName: string
  sha256?: string
  size?: number
  /** When true, installed shell must update before loading a newer app bundle. */
  required?: boolean
}

/** Published at releases/download/{channelTag}/manifest.json per product. */
export interface DesktopUpdateManifest {
  product: DesktopProductId
  channel: DesktopUpdateChannel
  shellVersion: string
  appVersion: string
  build: number
  commit: string
  publishedAt: string
  appBundle: AppBundleManifestEntry
  shell?: ShellManifestEntry
}

export interface ActiveAppBundlePointer {
  version: string
  build: number
  path: string
  installedAt: string
}

export type UpdatePhase =
  | 'idle'
  | 'checking'
  | 'downloading-app'
  | 'downloading-shell'
  | 'ready'
  | 'installing'
  | 'error'

export interface UpdateStatusSnapshot {
  phase: UpdatePhase
  channel: DesktopUpdateChannel
  message: string
  appVersion: string | null
  shellVersion: string | null
  pendingRestart: boolean
  lastError: string | null
  lastCheckAt: string | null
}
