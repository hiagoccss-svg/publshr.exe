#!/usr/bin/env node
/**
 * Zip renderer-only output for lightweight GitHub app-bundle updates.
 * Usage: node desktop/scripts/package-app-bundle.mjs <product> <out-renderer-dir> <output-zip>
 */
import { createHash } from 'crypto'
import { createReadStream, existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs'
import { dirname, join } from 'path'
import { pipeline } from 'stream/promises'
import { execFileSync } from 'child_process'

const [product, rendererDir, outZip] = process.argv.slice(2)
if (!product || !rendererDir || !outZip) {
  console.error(
    'Usage: package-app-bundle.mjs <spaces|media-monitoring|planner> <renderer-dir> <out.zip>'
  )
  process.exit(1)
}

if (!existsSync(join(rendererDir, 'index.html'))) {
  console.error(`Missing index.html in ${rendererDir}`)
  process.exit(1)
}

mkdirSync(dirname(outZip), { recursive: true })
if (existsSync(outZip)) {
  execFileSync('rm', ['-f', outZip])
}
execFileSync('zip', ['-rq', outZip, '.'], { cwd: rendererDir, stdio: 'inherit' })

async function sha256(path) {
  const hash = createHash('sha256')
  await pipeline(createReadStream(path), hash)
  return hash.digest('hex')
}

const digest = await sha256(outZip)
const metaPath = outZip.replace(/\.zip$/, '.meta.json')
writeFileSync(
  metaPath,
  JSON.stringify(
    {
      product,
      sha256: digest,
      size: readFileSync(outZip).length
    },
    null,
    2
  )
)
console.log(`Packaged ${outZip} sha256=${digest}`)
