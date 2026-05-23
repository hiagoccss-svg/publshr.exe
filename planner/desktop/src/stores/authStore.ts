import { create } from 'zustand'
import type { Session, User } from '@supabase/supabase-js'
import { getSupabase } from '@/lib/supabase'

interface AuthState {
  user: User | null
  session: Session | null
  loading: boolean
  error: string | null
  initialize: () => Promise<void>
  signIn: (email: string, password: string) => Promise<void>
  signUp: (email: string, password: string, displayName?: string) => Promise<void>
  signOut: () => Promise<void>
}

async function loadSessionFromMain(): Promise<Session | null> {
  return window.planner.getAuthSession()
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  session: null,
  loading: true,
  error: null,

  initialize: async () => {
    try {
      const session = await loadSessionFromMain()
      if (session) {
        const supabase = getSupabase()
        await supabase.auth.setSession({
          access_token: session.access_token,
          refresh_token: session.refresh_token
        })
        set({ session, user: session.user, loading: false })
        supabase.auth.onAuthStateChange(async (_event, next) => {
          if (next) await window.planner.setAuthSession(next)
          else await window.planner.clearAuthSession()
          set({ session: next, user: next?.user ?? null })
        })
      } else {
        set({ loading: false })
      }
    } catch (e) {
      set({ loading: false, error: e instanceof Error ? e.message : 'Auth init failed' })
    }
  },

  signIn: async (email, password) => {
    set({ error: null, loading: true })
    try {
      const session = await window.planner.signIn(email, password)
      const supabase = getSupabase()
      await supabase.auth.setSession({
        access_token: session.access_token,
        refresh_token: session.refresh_token
      })
      set({ session, user: session.user, loading: false })
    } catch (e) {
      set({
        error: e instanceof Error ? e.message : 'Sign in failed',
        loading: false
      })
    }
  },

  signUp: async (email, password, displayName) => {
    set({ error: null, loading: true })
    try {
      const session = await window.planner.signUp(email, password, displayName)
      if (session) {
        const supabase = getSupabase()
        await supabase.auth.setSession({
          access_token: session.access_token,
          refresh_token: session.refresh_token
        })
        set({ session, user: session.user, loading: false })
      } else {
        set({ loading: false })
      }
    } catch (e) {
      set({
        error: e instanceof Error ? e.message : 'Sign up failed',
        loading: false
      })
    }
  },

  signOut: async () => {
    await window.planner.signOut()
    await getSupabase().auth.signOut()
    set({ user: null, session: null })
  }
}))
