import { createClient } from '@supabase/supabase-js'

/**
 * Cloud sync client — wire when VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY are set.
 * Local SQLite remains source for offline/fast access; Supabase is source of truth when online.
 */
const url = import.meta.env.VITE_SUPABASE_URL as string | undefined
const key = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined

export const supabase =
  url && key
    ? createClient(url, key, {
        realtime: { params: { eventsPerSecond: 10 } }
      })
    : null

export const isCloudEnabled = Boolean(supabase)
