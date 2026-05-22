import type { App } from 'electron'
import { bundledShellVersion, channelReleaseTag, resolveGitHubRepo } from './release-config'
import { UpdateLogger } from './update-logger'
import type { DesktopProductId, DesktopUpdateChannel } from './types'

export interface ShellUpdateResult {
  available: boolean
  version?: string
  message: string
}

/**
 * Native shell updates via electron-updater (full installer replace).
 * Only runs when shell assets change — not for frontend-only releases.
 */
async function importElectronUpdater(): Promise<unknown> {
  const spec = 'electron-updater'
  return import(/* @vite-ignore */ spec)
}

type ElectronAutoUpdater = {
  autoDownload: boolean
  autoInstallOnAppQuit: boolean
  allowDowngrade: boolean
  logger: unknown
  setFeedURL: (config: Record<string, string>) => void
  checkForUpdates: () => Promise<{ updateInfo?: { version?: string } } | null>
  quitAndInstall: (isSilent?: boolean, isForceRunAfter?: boolean) => void
}

export class ShellUpdater {
  private readonly logger: UpdateLogger
  private autoUpdater: ElectronAutoUpdater | null = null

  constructor(
    private readonly electronApp: App,
    private readonly product: DesktopProductId,
    private readonly channel: DesktopUpdateChannel
  ) {
    this.logger = new UpdateLogger(electronApp)
  }

  private async loadAutoUpdater(): Promise<ElectronAutoUpdater | null> {
    if (!this.electronApp.isPackaged) return null
    if (this.autoUpdater) return this.autoUpdater
    try {
      const mod = (await importElectronUpdater()) as { autoUpdater: ElectronAutoUpdater }
      this.autoUpdater = mod.autoUpdater
      return this.autoUpdater
    } catch (err) {
      this.logger.warn(
        `electron-updater unavailable: ${err instanceof Error ? err.message : String(err)}`
      )
      return null
    }
  }

  async checkForShellUpdate(): Promise<ShellUpdateResult> {
    const updater = await this.loadAutoUpdater()
    if (!updater) {
      return { available: false, message: 'Shell updater not available in dev builds' }
    }

    const repo = resolveGitHubRepo()
    const [owner, name] = repo.split('/')
    if (!owner || !name) {
      return { available: false, message: 'Invalid GitHub repository configuration' }
    }

    updater.autoDownload = true
    updater.autoInstallOnAppQuit = true
    updater.allowDowngrade = false
    updater.logger = null

    // electron-updater reads publish config; override channel via release tag
    const tag = channelReleaseTag(this.product, this.channel)
    process.env.ELECTRON_UPDATER_CACHE = this.electronApp.getPath('userData')

    try {
      updater.setFeedURL({
        provider: 'github',
        owner,
        repo: name,
        releaseType: 'release',
        channel: tag
      })
      const result = await updater.checkForUpdates()
      const info = result?.updateInfo
      if (!info?.version) {
        return { available: false, message: 'Shell is up to date' }
      }
      if (info.version === bundledShellVersion()) {
        return { available: false, message: 'Shell is up to date' }
      }
      this.logger.info(`Shell update available: ${info.version}`)
      return { available: true, version: info.version, message: `Shell ${info.version} downloading` }
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err)
      this.logger.warn(`Shell update check: ${msg}`)
      return { available: false, message: msg }
    }
  }

  async quitAndInstall(): Promise<void> {
    const updater = await this.loadAutoUpdater()
    if (!updater?.quitAndInstall) {
      this.electronApp.relaunch()
      this.electronApp.exit(0)
      return
    }
    updater.quitAndInstall(false, true)
  }
}
