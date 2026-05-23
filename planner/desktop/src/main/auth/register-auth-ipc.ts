import { ipcMain } from 'electron'
import { createClient, type Session } from '@supabase/supabase-js'
import { loadSession, saveSession } from './session-store'

const url = process.env.VITE_SUPABASE_URL ?? process.env.SUPABASE_URL
const key =
  process.env.VITE_SUPABASE_PUBLISHABLE_KEY ??
  process.env.VITE_SUPABASE_ANON_KEY ??
  process.env.SUPABASE_ANON_KEY

function createAuthClient() {
  if (!url || !key) {
    throw new Error('Supabase not configured in main process env')
  }
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: true, detectSessionInUrl: false }
  })
}

export function registerAuthIpc(): void {
  ipcMain.handle('auth:getSession', () => loadSession())

  ipcMain.handle('auth:signIn', async (_, email: string, password: string) => {
    const client = createAuthClient()
    const { data, error } = await client.auth.signInWithPassword({ email, password })
    if (error) throw error
    if (!data.session) throw new Error('No session returned')
    saveSession(data.session)
    return data.session
  })

  ipcMain.handle('auth:signUp', async (_, email: string, password: string, displayName?: string) => {
    const client = createAuthClient()
    const { data, error } = await client.auth.signUp({
      email,
      password,
      options: { data: { display_name: displayName ?? email.split('@')[0] } }
    })
    if (error) throw error
    if (data.session) saveSession(data.session)
    return data.session
  })

  ipcMain.handle('auth:signOut', async () => {
    const existing = loadSession()
    if (existing?.access_token) {
      try {
        const client = createAuthClient()
        await client.auth.setSession({
          access_token: existing.access_token,
          refresh_token: existing.refresh_token
        })
        await client.auth.signOut()
      } catch {
        /* offline sign-out still clears local session */
      }
    }
    saveSession(null)
    return true
  })

  ipcMain.handle('auth:setSession', async (_, session: Session | null) => {
    saveSession(session)
    return true
  })

  ipcMain.handle('auth:clearSession', async () => {
    saveSession(null)
    return true
  })

  ipcMain.handle('auth:refreshSession', async () => {
    const existing = loadSession()
    if (!existing?.refresh_token) return null
    const client = createAuthClient()
    const { data, error } = await client.auth.setSession({
      access_token: existing.access_token,
      refresh_token: existing.refresh_token
    })
    if (error) throw error
    const { data: refreshed, error: refreshError } = await client.auth.refreshSession()
    if (refreshError) throw refreshError
    if (refreshed.session) saveSession(refreshed.session)
    return refreshed.session
  })
}
