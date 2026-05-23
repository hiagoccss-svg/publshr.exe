import { create } from 'zustand'
import type { DesktopAuthSnapshot } from '@shared/desktop/types'
import { getAuthState } from '@/lib/tauri-auth'
import {
  bindAuthPersistence,
  hydrateSessionFromNative,
  isCloudConfigured,
  signInWithPassword,
  signOut as supabaseSignOut,
  getSupabase
} from '@/lib/supabase'

interface AuthStore {
  snapshot: DesktopAuthSnapshot | null
  loading: boolean
  error: string | null
  cloudConfigured: boolean
  initialize: () => Promise<void>
  signIn: (email: string, password: string) => Promise<void>
  signOut: () => Promise<void>
}

export const useAuthStore = create<AuthStore>((set) => ({
  snapshot: null,
  loading: true,
  error: null,
  cloudConfigured: isCloudConfigured(),

  initialize: async () => {
    try {
      const snapshot = await getAuthState()
      if (isCloudConfigured()) {
        const supabase = getSupabase()
        bindAuthPersistence(supabase)
        if (snapshot.accessToken) {
          await hydrateSessionFromNative()
        }
        supabase.auth.onAuthStateChange(async () => {
          set({ snapshot: await getAuthState() })
        })
      }
      set({ snapshot, loading: false })
    } catch (e) {
      set({
        loading: false,
        error: e instanceof Error ? e.message : 'Failed to restore session'
      })
    }
  },

  signIn: async (email, password) => {
    set({ error: null, loading: true })
    try {
      await signInWithPassword(email, password)
      const snapshot = await getAuthState()
      set({ snapshot, loading: false })
    } catch (e) {
      set({
        loading: false,
        error: e instanceof Error ? e.message : 'Sign in failed'
      })
    }
  },

  signOut: async () => {
    await supabaseSignOut()
    set({ snapshot: await getAuthState() })
  }
}))
