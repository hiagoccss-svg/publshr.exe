import { createHash } from 'crypto'
import {
  createWriteStream,
  existsSync,
  mkdirSync,
  readFileSync,
  renameSync,
  rmSync,
  writeFileSync
} from 'fs'
import { join } from 'path'
import { Readable } from 'stream'
import { pipeline } from 'stream/promises'
import { execFileSync } from 'child_process'
import type { App } from 'electron'
import {
  bundledAppVersion,
  channelReleaseTag,
  manifestDownloadUrl,
  releaseAssetUrl,
  resolveUpdateChannel
} from './release-config'
import { UpdateLogger } from './update-logger'
import type {
  ActiveAppBundlePointer,
  DesktopProductId,
  DesktopUpdateChannel,
  DesktopUpdateManifest,
  UpdateStatusSnapshot
} from './types'

function parseBuild(version: string): number {
  const parts = version.split('.')
  const last = parts[parts.length - 1]
  const n = Number.parseInt(last ?? '', 10)
  return Number.isFinite(n) ? n : 0
}

function extractZipArchive(zipPath: string, destDir: string): void {
  if (process.platform === 'win32') {
    const cmd = `Expand-Archive -LiteralPath '${zipPath.replace(/'/g, "''")}' -DestinationPath '${destDir.replace(/'/g, "''")}' -Force`
    execFileSync('powershell.exe', ['-NoProfile', '-Command', cmd], { stdio: 'pipe' })
    return
  }
  execFileSync('unzip', ['-oq', zipPath, '-d', destDir], { stdio: 'pipe' })
}

function compareVersion(a: string, b: string): number {
  const pa = a.split('.').map((x) => Number.parseInt(x, 10) || 0)
  const pb = b.split('.').map((x) => Number.parseInt(x, 10) || 0)
  const len = Math.max(pa.length, pb.length)
  for (let i = 0; i < len; i++) {
    const da = pa[i] ?? 0
    const db = pb[i] ?? 0
    if (da !== db) return da > db ? 1 : -1
  }
  return 0
}

async function sha256File(path: string): Promise<string> {
  const hash = createHash('sha256')
  hash.update(readFileSync(path))
  return hash.digest('hex')
}

export class AppBundleUpdater {
  private readonly product: DesktopProductId
  private readonly logger: UpdateLogger
  private readonly bundlesRoot: string
  private readonly pointerPath: string
  private status: UpdateStatusSnapshot

  constructor(
    private readonly electronApp: App,
    product: DesktopProductId
  ) {
    this.product = product
    this.logger = new UpdateLogger(electronApp)
    this.bundlesRoot = join(electronApp.getPath('userData'), 'app-bundles')
    this.pointerPath = join(this.bundlesRoot, 'active.json')
    const channel = resolveUpdateChannel(product, electronApp.isPackaged ? 'staging' : 'dev')
    this.status = {
      phase: 'idle',
      channel,
      message: 'Ready',
      appVersion: bundledAppVersion(),
      shellVersion: null,
      pendingRestart: false,
      lastError: null,
      lastCheckAt: null
    }
    if (!existsSync(this.bundlesRoot)) mkdirSync(this.bundlesRoot, { recursive: true })
  }

  getStatus(): UpdateStatusSnapshot {
    return { ...this.status }
  }

  getActiveBundle(): ActiveAppBundlePointer | null {
    if (!existsSync(this.pointerPath)) return null
    try {
      return JSON.parse(readFileSync(this.pointerPath, 'utf8')) as ActiveAppBundlePointer
    } catch {
      return null
    }
  }

  /** Path to index.html for renderer — bundled `out` or downloaded app bundle. */
  resolveRendererIndex(): { indexPath: string; hashPrefix: string } {
    const active = this.getActiveBundle()
    if (active?.path && existsSync(join(active.path, 'index.html'))) {
      return { indexPath: join(active.path, 'index.html'), hashPrefix: '' }
    }
    return {
      indexPath: join(__dirname, '../renderer/index.html'),
      hashPrefix: ''
    }
  }

  setChannel(channel: DesktopUpdateChannel): void {
    this.status = { ...this.status, channel }
  }

  async checkAndApply(options?: { autoInstall?: boolean }): Promise<boolean> {
    if (process.env.PUBLSHR_SKIP_UPDATES === '1') return false
    if (!this.electronApp.isPackaged && process.env.PUBLSHR_FORCE_UPDATES !== '1') {
      this.logger.info('Skipping update check in unpackaged dev mode')
      return false
    }

    const channel = this.status.channel
    this.status = { ...this.status, phase: 'checking', message: 'Checking for updates…', lastError: null }

    try {
      const manifest = await this.fetchManifest(channel)
      this.status = {
        ...this.status,
        shellVersion: manifest.shellVersion,
        lastCheckAt: new Date().toISOString()
      }

      const current = this.getActiveBundle()
      const bundled = bundledAppVersion()
      const currentVersion = current?.version ?? bundled
      const currentBuild = current?.build ?? parseBuild(bundled)
      const needsApp =
        compareVersion(manifest.appVersion, currentVersion) > 0 ||
        manifest.build > currentBuild

      if (!needsApp) {
        this.status = { ...this.status, phase: 'idle', message: 'App is up to date' }
        this.logger.info(`App bundle up to date (${currentVersion})`)
        return false
      }

      if (options?.autoInstall === false) {
        this.status = {
          ...this.status,
          phase: 'ready',
          message: `Update ${manifest.appVersion} available`,
          appVersion: manifest.appVersion,
          pendingRestart: true
        }
        return true
      }

      this.status = { ...this.status, phase: 'downloading-app', message: 'Downloading app update…' }
      await this.downloadAndInstallBundle(manifest, channel)
      this.status = {
        ...this.status,
        phase: 'ready',
        message: `Installed app ${manifest.appVersion}. Restart to apply.`,
        appVersion: manifest.appVersion,
        pendingRestart: true
      }
      this.logger.info(`App bundle ${manifest.appVersion} (build ${manifest.build}) ready`)
      return true
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err)
      this.status = { ...this.status, phase: 'error', message: msg, lastError: msg }
      this.logger.error(msg)
      return false
    }
  }

  private async fetchManifest(channel: DesktopUpdateChannel): Promise<DesktopUpdateManifest> {
    const url = manifestDownloadUrl(this.product, channel)
    const res = await fetch(url, {
      headers: { Accept: 'application/json', 'User-Agent': 'Publshr-Desktop/1.0' },
      cache: 'no-store'
    })
    if (!res.ok) throw new Error(`Manifest unavailable (${res.status})`)
    return (await res.json()) as DesktopUpdateManifest
  }

  private async downloadAndInstallBundle(
    manifest: DesktopUpdateManifest,
    channel: DesktopUpdateChannel
  ): Promise<void> {
    const tag = channelReleaseTag(this.product, channel)
    const url = releaseAssetUrl(tag, manifest.appBundle.assetName)
    const tmpZip = join(this.bundlesRoot, `_download-${manifest.build}.zip`)
    const stagingDir = join(this.bundlesRoot, `_staging-${manifest.build}`)
    const finalDir = join(this.bundlesRoot, `${manifest.appVersion}-${manifest.build}`)

    if (existsSync(tmpZip)) rmSync(tmpZip, { force: true })
    if (existsSync(stagingDir)) rmSync(stagingDir, { recursive: true, force: true })

    const res = await fetch(url, {
      headers: { Accept: 'application/octet-stream', 'User-Agent': 'Publshr-Desktop/1.0' },
      cache: 'no-store'
    })
    if (!res.ok || !res.body) throw new Error(`App bundle download failed (${res.status})`)

    const body = res.body
    if (!body) throw new Error('Empty download response')
    const nodeStream =
      typeof (Readable as { fromWeb?: (s: ReadableStream) => Readable }).fromWeb === 'function'
        ? Readable.fromWeb(body as ReadableStream)
        : Readable.from(body as AsyncIterable<Uint8Array>)
    await pipeline(nodeStream, createWriteStream(tmpZip))

    const digest = await sha256File(tmpZip)
    if (digest !== manifest.appBundle.sha256) {
      rmSync(tmpZip, { force: true })
      throw new Error('App bundle checksum mismatch')
    }

    mkdirSync(stagingDir, { recursive: true })
    extractZipArchive(tmpZip, stagingDir)

    const indexCandidates = [
      join(stagingDir, 'index.html'),
      join(stagingDir, 'renderer', 'index.html')
    ]
    const indexPath = indexCandidates.find((p) => existsSync(p))
    if (!indexPath) {
      rmSync(stagingDir, { recursive: true, force: true })
      rmSync(tmpZip, { force: true })
      throw new Error('Downloaded bundle missing index.html')
    }

    const bundleRoot =
      indexPath === join(stagingDir, 'index.html')
        ? stagingDir
        : join(stagingDir, 'renderer')

    if (existsSync(finalDir)) rmSync(finalDir, { recursive: true, force: true })
    renameSync(bundleRoot, finalDir)
    rmSync(stagingDir, { recursive: true, force: true })
    rmSync(tmpZip, { force: true })

    const previous = this.getActiveBundle()
    const pointer: ActiveAppBundlePointer = {
      version: manifest.appVersion,
      build: manifest.build,
      path: finalDir,
      installedAt: new Date().toISOString()
    }
    writeFileSync(this.pointerPath, JSON.stringify(pointer, null, 2), 'utf8')

    if (previous?.path && previous.path !== finalDir && existsSync(previous.path)) {
      try {
        rmSync(previous.path, { recursive: true, force: true })
      } catch {
        this.logger.warn(`Could not remove previous bundle at ${previous.path}`)
      }
    }
  }

  rollbackToBundled(): void {
    if (existsSync(this.pointerPath)) rmSync(this.pointerPath, { force: true })
    this.status = {
      ...this.status,
      phase: 'idle',
      message: 'Using bundled app',
      pendingRestart: false,
      appVersion: bundledAppVersion()
    }
    this.logger.warn('Rolled back to bundled renderer')
  }
}
