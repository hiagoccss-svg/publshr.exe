import { app, type BrowserWindow } from 'electron'
import { join } from 'path'
import type { AppBundleUpdater } from './app-bundle-updater'

export interface WindowLoadTarget {
  /** Hash route, e.g. `/` or `/space/uuid` — omit leading # */
  hash?: string
}

/**
 * Loads renderer into a native BrowserWindow:
 * - Dev: Vite HMR via ELECTRON_RENDERER_URL
 * - Installed: downloaded app bundle in userData (if newer)
 * - Fallback: bundled out/renderer from last shell build
 */
export function loadRendererWindow(
  win: BrowserWindow,
  bundledRendererIndex: string,
  bundleUpdater: AppBundleUpdater | null,
  target: WindowLoadTarget = {}
): void {
  const hash = target.hash?.replace(/^#/, '') ?? ''
  const hashSuffix = hash ? `#${hash}` : ''

  if (!app.isPackaged && process.env['ELECTRON_RENDERER_URL']) {
    win.loadURL(`${process.env['ELECTRON_RENDERER_URL']}${hashSuffix}`)
    return
  }

  const active = bundleUpdater?.getActiveBundle()
  if (active?.path) {
    const indexPath = join(active.path, 'index.html')
    win.loadFile(indexPath, hash ? { hash } : undefined)
    return
  }

  win.loadFile(bundledRendererIndex, hash ? { hash } : undefined)
}
