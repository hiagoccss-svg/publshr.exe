import { create } from 'zustand'
import { getSupabase } from '@/lib/supabase'
import type { User, Session } from '@supabase/supabase-js'

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

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  session: null,
  loading: true,
  error: null,

  initialize: async () => {
    try {
      const supabase = getSupabase()
      const { data } = await supabase.auth.getSession()
      set({ session: data.session, user: data.session?.user ?? null, loading: false })
      supabase.auth.onAuthStateChange((_event, session) => {
        set({ session, user: session?.user ?? null })
      })
    } catch (e) {
      set({ loading: false, error: e instanceof Error ? e.message : 'Auth init failed' })
    }
  },

  signIn: async (email, password) => {
    set({ error: null, loading: true })
    const { error } = await getSupabase().auth.signInWithPassword({ email, password })
    if (error) set({ error: error.message, loading: false })
    else set({ loading: false })
  },

  signUp: async (email, password, displayName) => {
    set({ error: null, loading: true })
    const { error } = await getSupabase().auth.signUp({
      email,
      password,
      options: { data: { display_name: displayName ?? email.split('@')[0] } }
    })
    if (error) set({ error: error.message, loading: false })
    else set({ loading: false })
  },

  signOut: async () => {
    await getSupabase().auth.signOut()
    set({ user: null, session: null })
  }
}))
