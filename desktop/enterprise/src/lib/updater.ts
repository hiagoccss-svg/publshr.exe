import { check } from '@tauri-apps/plugin-updater'
import { relaunch } from '@tauri-apps/plugin-process'

export interface UpdateCheckResult {
  available: boolean
  version: string | null
  message: string
}

export async function checkForAppUpdate(): Promise<UpdateCheckResult> {
  try {
    const update = await check()
    if (!update) {
      return { available: false, version: null, message: 'You are on the latest version.' }
    }
    return {
      available: true,
      version: update.version,
      message: `Update ${update.version} is available.`
    }
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'Update check failed'
    return { available: false, version: null, message: msg }
  }
}

export async function installUpdateAndRestart(): Promise<void> {
  const update = await check()
  if (!update) return
  await update.downloadAndInstall()
  await relaunch()
}
