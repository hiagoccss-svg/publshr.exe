#!/usr/bin/env node
/**
 * Write desktop-manifest JSON for a product/channel release.
 */
import { readFileSync, writeFileSync, mkdirSync } from 'fs'
import { dirname } from 'path'

const [
  product,
  channel,
  shellVersion,
  appVersion,
  build,
  commit,
  appBundleAsset,
  appMetaPath,
  outPath,
  shellAsset,
  shellMetaPath
] = process.argv.slice(2)

if (!product || !channel || !appBundleAsset || !appMetaPath || !outPath) {
  console.error(
    'Usage: write-desktop-manifest.mjs <product> <channel> <shellVer> <appVer> <build> <commit> <appAsset> <app.meta.json> <out.json> [shellAsset] [shell.meta.json]'
  )
  process.exit(1)
}

const appMeta = JSON.parse(readFileSync(appMetaPath, 'utf8'))
const manifest = {
  product,
  channel,
  shellVersion: shellVersion || appVersion,
  appVersion,
  build: Number(build),
  commit,
  publishedAt: new Date().toISOString(),
  appBundle: {
    assetName: appBundleAsset,
    sha256: appMeta.sha256,
    size: appMeta.size
  }
}

if (shellAsset && shellMetaPath) {
  const shellMeta = JSON.parse(readFileSync(shellMetaPath, 'utf8'))
  manifest.shell = {
    assetName: shellAsset,
    sha256: shellMeta.sha256,
    size: shellMeta.size,
    required: false
  }
}

mkdirSync(dirname(outPath), { recursive: true })
writeFileSync(outPath, JSON.stringify(manifest, null, 2))
console.log(`Wrote ${outPath}`)
