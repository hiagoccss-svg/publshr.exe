/** Publshr.exe Supabase project — legacy anon JWT has widest client compatibility */
export const SUPABASE_URL =
  process.env.SUPABASE_URL ?? 'https://lboesdtsrqfvosznjpdy.supabase.co'

export const SUPABASE_ANON_KEY =
  process.env.SUPABASE_ANON_KEY ??
  process.env.SUPABASE_PUBLISHABLE_KEY ??
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxib2VzZHRzcnFmdm9zem5qcGR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzNTMyMjUsImV4cCI6MjA5NDkyOTIyNX0._xpTUrBAkURJUH_Dl1Wyt10c4lvyoAvhvRGW_oFu17Y'

/** Local-first workspace when not signed in — full monitoring still works */
export const LOCAL_WORKSPACE_ID = '00000000-0000-4000-8000-000000000001'
export const LOCAL_WORKSPACE_NAME = 'Local Workspace'
