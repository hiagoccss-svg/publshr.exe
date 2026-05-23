import { invoke } from '@tauri-apps/api/core'
import type { DesktopAuthSnapshot } from '@shared/desktop/types'

export interface StoredSessionInput {
  accessToken: string
  refreshToken: string
  expiresAt: number | null
  user: {
    id: string
    email: string
    displayName: string | null
  }
}

export async function getAuthState(): Promise<DesktopAuthSnapshot> {
  return invoke<DesktopAuthSnapshot>('auth_get_state')
}

export async function saveAuthSession(
  session: StoredSessionInput,
  workspaceId?: string
): Promise<DesktopAuthSnapshot> {
  return invoke<DesktopAuthSnapshot>('auth_save_session', { session, workspaceId })
}

export async function clearAuthSession(): Promise<DesktopAuthSnapshot> {
  return invoke<DesktopAuthSnapshot>('auth_clear_session')
}

export async function setWorkspace(workspaceId: string): Promise<DesktopAuthSnapshot> {
  return invoke<DesktopAuthSnapshot>('auth_set_workspace', { workspaceId })
}

export async function setBiometricEnabled(enabled: boolean): Promise<DesktopAuthSnapshot> {
  return invoke<DesktopAuthSnapshot>('auth_set_biometric_enabled', { enabled })
}
