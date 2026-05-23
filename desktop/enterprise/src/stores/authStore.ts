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
import { runEnterpriseLiveSync } from '@/lib/live-sync'
import { isTauriDesktop } from '@shared/desktop/platform'

interface AuthStore {
  snapshot: DesktopAuthSnapshot | null
  loading: boolean
  error: string | null
  cloudConfigured: boolean
  initialize: () => Promise<void>
  signIn: (email: string, password: string) => Promise<void>
  signOut: () => Promise<void>
  continueOffline: () => void
}

export const useAuthStore = create<AuthStore>((set, get) => ({
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

      if (snapshot.user?.id && snapshot.user.id !== 'local-user' && isCloudConfigured()) {
        await runEnterpriseLiveSync(
          snapshot.user.id,
          snapshot.user.displayName ?? snapshot.user.email ?? 'You'
        )
      } else if (isTauriDesktop() && !snapshot.user) {
        set({
          snapshot: {
            user: {
              id: 'local-user',
              email: 'local@workspace',
              displayName: 'Local workspace'
            },
            accessToken: null,
            refreshToken: null,
            expiresAt: null,
            workspaceId: null,
            cloudValidated: false,
            biometricEnabled: false
          },
          loading: false
        })
      }
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
      if (snapshot.user) {
        const sync = await runEnterpriseLiveSync(
          snapshot.user.id,
          snapshot.user.displayName ?? snapshot.user.email ?? email
        )
        if (!sync.ok) {
          set({ error: sync.error ?? 'Signed in, but cloud sync failed. Local data still available.' })
        }
      }
    } catch (e) {
      set({
        loading: false,
        error: e instanceof Error ? e.message : 'Sign in failed'
      })
    }
  },

  signOut: async () => {
    const isLocalOnly = get().snapshot?.user?.id === 'local-user'
    if (isCloudConfigured() && !isLocalOnly) {
      await supabaseSignOut()
      set({ snapshot: await getAuthState() })
    } else {
      set({ snapshot: null, loading: false })
    }
  },

  continueOffline: () => {
    set({
      loading: false,
      error: null,
      snapshot: {
        user: {
          id: 'local-user',
          email: 'local@workspace',
          displayName: 'Local workspace'
        },
        accessToken: null,
        refreshToken: null,
        expiresAt: null,
        workspaceId: null,
        cloudValidated: false,
        biometricEnabled: false
      }
    })
  }
}))
