import type { App, BrowserWindow } from 'electron'
import { AppBundleUpdater } from './app-bundle-updater'
import { resolveUpdateChannel } from './release-config'
import { ShellUpdater } from './shell-updater'
import type { DesktopProductId, DesktopUpdateChannel, UpdateStatusSnapshot } from './types'
import { UpdateLogger } from './update-logger'

const DEFAULT_CHECK_MS = 10 * 60 * 1000

export class DesktopUpdateService {
  readonly appBundle: AppBundleUpdater
  private readonly shell: ShellUpdater
  private readonly logger: UpdateLogger
  private timer: ReturnType<typeof setInterval> | null = null
  private started = false

  constructor(
    private readonly electronApp: App,
    product: DesktopProductId
  ) {
    const channel = resolveUpdateChannel(
      product,
      electronApp.isPackaged ? 'staging' : 'dev'
    )
    this.appBundle = new AppBundleUpdater(electronApp, product)
    this.appBundle.setChannel(channel)
    this.shell = new ShellUpdater(electronApp, product, channel)
    this.logger = new UpdateLogger(electronApp)
  }

  get channel(): DesktopUpdateChannel {
    return this.appBundle.getStatus().channel
  }

  getStatus(): UpdateStatusSnapshot {
    return this.appBundle.getStatus()
  }

  /** Call once after app.whenReady — does not block window creation. */
  start(options?: { intervalMs?: number; checkOnStart?: boolean }): void {
    if (this.started) return
    this.started = true
    const intervalMs = options?.intervalMs ?? DEFAULT_CHECK_MS
    if (options?.checkOnStart !== false) {
      void this.runUpdateCycle()
    }
    this.timer = setInterval(() => void this.runUpdateCycle(), intervalMs)
    this.electronApp.on('before-quit', () => this.stop())
  }

  stop(): void {
    if (this.timer) clearInterval(this.timer)
    this.timer = null
  }

  async runUpdateCycle(): Promise<void> {
    try {
      await this.shell.checkForShellUpdate()
      const updated = await this.appBundle.checkAndApply({ autoInstall: true })
      if (updated && this.appBundle.getStatus().pendingRestart) {
        this.logger.info('App bundle updated; restart when convenient')
      }
    } catch (err) {
      this.logger.error(err instanceof Error ? err.message : String(err))
    }
  }

  async applyPendingAndRestart(windows: BrowserWindow[]): Promise<void> {
    for (const win of windows) {
      if (!win.isDestroyed()) win.close()
    }
    if (this.appBundle.getStatus().pendingRestart) {
      this.electronApp.relaunch()
      this.electronApp.exit(0)
      return
    }
    await this.shell.quitAndInstall()
  }

  rollbackAppBundle(): void {
    this.appBundle.rollbackToBundled()
  }
}
