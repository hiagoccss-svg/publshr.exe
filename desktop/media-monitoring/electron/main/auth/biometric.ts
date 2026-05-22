import { safeStorage, systemPreferences } from 'electron'
import { readFileSync, writeFileSync, existsSync, unlinkSync } from 'fs'
import { join } from 'path'
import { app } from 'electron'

const FLAG_FILE = () => join(app.getPath('userData'), 'biometric-enabled.json')
const TOKEN_FILE = () => join(app.getPath('userData'), 'biometric-session.bin')

export interface BiometricStatus {
  available: boolean
  enabled: boolean
  platform: string
}

export function getBiometricStatus(): BiometricStatus {
  const available =
    process.platform === 'darwin' &&
    typeof systemPreferences.canPromptTouchID === 'function' &&
    systemPreferences.canPromptTouchID() &&
    safeStorage.isEncryptionAvailable()

  let enabled = false
  if (existsSync(FLAG_FILE())) {
    try {
      enabled = JSON.parse(readFileSync(FLAG_FILE(), 'utf-8')).enabled === true
    } catch {
      enabled = false
    }
  }

  return { available, enabled, platform: process.platform }
}

export async function promptBiometric(reason: string): Promise<boolean> {
  if (process.platform !== 'darwin') return false
  if (!systemPreferences.canPromptTouchID?.()) return false
  try {
    await systemPreferences.promptTouchID(reason)
    return true
  } catch {
    return false
  }
}

export function storeBiometricSession(refreshToken: string): boolean {
  if (!safeStorage.isEncryptionAvailable()) return false
  const encrypted = safeStorage.encryptString(refreshToken)
  writeFileSync(TOKEN_FILE(), encrypted)
  writeFileSync(FLAG_FILE(), JSON.stringify({ enabled: true, at: new Date().toISOString() }))
  return true
}

export function loadBiometricRefreshToken(): string | null {
  if (!existsSync(TOKEN_FILE()) || !safeStorage.isEncryptionAvailable()) return null
  try {
    const encrypted = readFileSync(TOKEN_FILE())
    return safeStorage.decryptString(encrypted)
  } catch {
    return null
  }
}

export function clearBiometricSession(): void {
  if (existsSync(TOKEN_FILE())) unlinkSync(TOKEN_FILE())
  if (existsSync(FLAG_FILE())) unlinkSync(FLAG_FILE())
}
