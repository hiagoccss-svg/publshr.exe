import {
  appendFileSync,
  existsSync,
  mkdirSync,
  readFileSync,
  statSync,
  writeFileSync
} from 'fs'
import { join } from 'path'
import type { App } from 'electron'

const MAX_LOG_BYTES = 512_000

export class UpdateLogger {
  private readonly logPath: string

  constructor(app: App) {
    const dir = join(app.getPath('userData'), 'updates')
    if (!existsSync(dir)) mkdirSync(dir, { recursive: true })
    this.logPath = join(dir, 'last-update.log')
  }

  info(message: string): void {
    this.write('INFO', message)
  }

  warn(message: string): void {
    this.write('WARN', message)
  }

  error(message: string): void {
    this.write('ERROR', message)
  }

  private write(level: string, message: string): void {
    const line = `${new Date().toISOString()} [${level}] ${message}\n`
    try {
      appendFileSync(this.logPath, line, 'utf8')
      this.trimIfNeeded()
    } catch {
      // logging must never break updates
    }
    const prefix = level === 'ERROR' ? 'Update error:' : 'Update:'
    if (level === 'ERROR') console.error(prefix, message)
    else console.log(prefix, message)
  }

  private trimIfNeeded(): void {
    try {
      const size = statSync(this.logPath).size
      if (size <= MAX_LOG_BYTES) return
      const raw = readFileSync(this.logPath, 'utf8')
      const tail = raw.slice(-Math.floor(MAX_LOG_BYTES * 0.75))
      writeFileSync(this.logPath, `--- log trimmed ---\n${tail}`, 'utf8')
    } catch {
      // ignore
    }
  }

  getPath(): string {
    return this.logPath
  }
}
