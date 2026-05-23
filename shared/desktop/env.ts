/**
 * Canonical Supabase env names for desktop apps.
 * Renderer reads VITE_*; Tauri/Rust reads the same at build time via import.meta.env.
 */
export const SUPABASE_ENV = {
  url: 'VITE_SUPABASE_URL',
  anonKey: 'VITE_SUPABASE_ANON_KEY'
} as const

export function isSupabaseConfigured(
  env: Record<string, string | undefined>
): boolean {
  return Boolean(env[SUPABASE_ENV.url] && env[SUPABASE_ENV.anonKey])
}
