#!/usr/bin/env node
/**
 * Smoke test: verify build artifacts and required files exist.
 * (SQLite native module is compiled for Electron, not system Node.)
 */
import { existsSync } from 'fs'
import { join, dirname } from 'path'
import { fileURLToPath } from 'url'

const root = join(dirname(fileURLToPath(import.meta.url)), '..')

const required = [
  'out/main/index.js',
  'out/preload/index.mjs',
  'out/renderer/index.html',
  'electron/main/monitoring/engine.ts',
  'electron/main/supabase/sync-service.ts',
  'src/App.tsx'
]

let ok = true
for (const f of required) {
  const p = join(root, f)
  if (!existsSync(p)) {
    console.error('MISSING:', f)
    ok = false
  }
}

if (!ok) process.exit(1)
console.log('OK —', required.length, 'artifacts verified')
console.log('Run: npm run start  (or npm run dev)')
