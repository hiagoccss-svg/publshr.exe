#!/usr/bin/env node
/**
 * Zip renderer-only output for lightweight GitHub app-bundle updates.
 * Usage: node desktop/scripts/package-app-bundle.mjs <product> <out-renderer-dir> <output-zip>
 */
import { createHash } from 'crypto'
import { createReadStream, existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs'
import { dirname, join, resolve } from 'path'
import { pipeline } from 'stream/promises'
import { execFileSync } from 'child_process'

const [product, rendererDir, outZip] = process.argv.slice(2)
if (!product || !rendererDir || !outZip) {
  console.error(
    'Usage: package-app-bundle.mjs <spaces|media-monitoring|planner> <renderer-dir> <out.zip>'
  )
  process.exit(1)
}

const rendererRoot = resolve(rendererDir)
const indexHtml = join(rendererRoot, 'index.html')
if (!existsSync(indexHtml)) {
  console.error(`Missing index.html in ${rendererRoot}`)
  process.exit(1)
}

const zipPath = resolve(outZip)
mkdirSync(dirname(zipPath), { recursive: true })
if (existsSync(zipPath)) {
  execFileSync('rm', ['-f', zipPath])
}
execFileSync('zip', ['-rq', zipPath, '.'], { cwd: rendererRoot, stdio: 'inherit' })

async function sha256(path) {
  const hash = createHash('sha256')
  await pipeline(createReadStream(path), hash)
  return hash.digest('hex')
}

const digest = await sha256(zipPath)
const metaPath = zipPath.replace(/\.zip$/, '.meta.json')
writeFileSync(
  metaPath,
  JSON.stringify(
    {
      product,
      sha256: digest,
      size: readFileSync(zipPath).length
    },
    null,
    2
  )
)
console.log(`Packaged ${zipPath} sha256=${digest}`)
