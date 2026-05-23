import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import { isSupabaseConfigured, SUPABASE_ENV } from '@shared/desktop/env'
import { getAuthState, saveAuthSession, clearAuthSession } from './tauri-auth'

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

let client: SupabaseClient | null = null

export function getSupabase(): SupabaseClient {
  if (!url || !anonKey) {
    throw new Error(
      `Missing ${SUPABASE_ENV.url} or ${SUPABASE_ENV.anonKey}. Copy .env.example to .env`
    )
  }
  if (!client) {
    client = createClient(url, anonKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: true,
        detectSessionInUrl: false
      }
    })
  }
  return client
}

export function isCloudConfigured(): boolean {
  return isSupabaseConfigured(import.meta.env as Record<string, string | undefined>)
}

/** Restore session from OS keychain via Rust, then attach to Supabase client. */
export async function hydrateSessionFromNative(): Promise<boolean> {
  const snapshot = await getAuthState()
  if (!snapshot.accessToken || !snapshot.refreshToken || !snapshot.user) return false

  const supabase = getSupabase()
  const { data, error } = await supabase.auth.setSession({
    access_token: snapshot.accessToken,
    refresh_token: snapshot.refreshToken
  })
  if (error || !data.session) return false
  return true
}

export async function signInWithPassword(email: string, password: string): Promise<void> {
  const supabase = getSupabase()
  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  if (error) throw error
  if (!data.session?.user) throw new Error('No session returned')

  await saveAuthSession({
    accessToken: data.session.access_token,
    refreshToken: data.session.refresh_token,
    expiresAt: data.session.expires_at ?? null,
    user: {
      id: data.session.user.id,
      email: data.session.user.email ?? email,
      displayName:
        (data.session.user.user_metadata?.display_name as string | undefined) ?? null
    }
  })
}

/** Call once at app startup after Supabase client exists. */
export function bindAuthPersistence(supabase: SupabaseClient): void {
  supabase.auth.onAuthStateChange(async (event, session) => {
    if (event === 'TOKEN_REFRESHED' && session?.user) {
      await saveAuthSession({
        accessToken: session.access_token,
        refreshToken: session.refresh_token,
        expiresAt: session.expires_at ?? null,
        user: {
          id: session.user.id,
          email: session.user.email ?? '',
          displayName: (session.user.user_metadata?.display_name as string | undefined) ?? null
        }
      })
    }
    if (event === 'SIGNED_OUT') {
      await clearAuthSession()
    }
  })
}

export async function signOut(): Promise<void> {
  const supabase = getSupabase()
  await supabase.auth.signOut()
  await clearAuthSession()
}
