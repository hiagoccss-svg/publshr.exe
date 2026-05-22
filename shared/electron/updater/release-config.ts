import type { DesktopProductId, DesktopUpdateChannel } from './types'

const DEFAULT_REPO = 'hiagoccss-svg/publshr.exe'

export function resolveGitHubRepo(): string {
  return (
    process.env.PUBLSHR_GITHUB_REPO?.trim() ||
    process.env.GITHUB_REPOSITORY?.trim() ||
    DEFAULT_REPO
  )
}

/** Release tag on GitHub, e.g. `spaces-staging`. */
export function channelReleaseTag(product: DesktopProductId, channel: DesktopUpdateChannel): string {
  return `${product}-${channel}`
}

export function manifestAssetName(product: DesktopProductId): string {
  return `${product}-desktop-manifest.json`
}

export function manifestDownloadUrl(
  product: DesktopProductId,
  channel: DesktopUpdateChannel,
  repo = resolveGitHubRepo()
): string {
  const tag = channelReleaseTag(product, channel)
  const asset = manifestAssetName(product)
  return `https://github.com/${repo}/releases/download/${tag}/${asset}`
}

export function releaseAssetUrl(
  tag: string,
  assetName: string,
  repo = resolveGitHubRepo()
): string {
  return `https://github.com/${repo}/releases/download/${tag}/${assetName}`
}

export function resolveUpdateChannel(
  product: DesktopProductId,
  fallback: DesktopUpdateChannel = 'staging'
): DesktopUpdateChannel {
  const raw = (
    process.env.PUBLSHR_UPDATE_CHANNEL ||
    process.env[`PUBLSHR_${product.toUpperCase().replace(/-/g, '_')}_UPDATE_CHANNEL`] ||
    ''
  )
    .trim()
    .toLowerCase()
  if (raw === 'dev' || raw === 'staging' || raw === 'production') return raw
  if (!process.env.NODE_ENV || process.env.NODE_ENV === 'development') return 'dev'
  return fallback
}

export function bundledShellVersion(): string {
  return process.env.PUBLSHR_SHELL_VERSION?.trim() || '0.1.0'
}

export function bundledAppVersion(): string {
  return process.env.PUBLSHR_APP_VERSION?.trim() || bundledShellVersion()
}
