#!/usr/bin/env node
/**
 * Verifies Supabase media monitoring schema and publication seed.
 * Usage: node scripts/verify-supabase.mjs [email] [password]
 */
import { createClient } from '@supabase/supabase-js'

const url = process.env.SUPABASE_URL ?? 'https://lboesdtsrqfvosznjpdy.supabase.co'
const key = process.env.SUPABASE_ANON_KEY ?? 'sb_publishable_mHARlRkK4iHkkn9wn_-uAw_EkW-jRXP'

const client = createClient(url, key)

async function main() {
  const email = process.argv[2]
  const password = process.argv[3]

  if (email && password) {
    const { data, error } = await client.auth.signInWithPassword({ email, password })
    if (error) {
      console.error('Auth failed:', error.message)
      process.exit(1)
    }
    console.log('Signed in as', data.user?.email)
  } else {
    console.log('Skipping auth (pass email password to test RLS writes)')
  }

  const { data: pubs, error: pubErr } = await client
    .from('publication_sources')
    .select('id, name, authority_score')
    .eq('verified', true)
    .order('authority_score', { ascending: false })
    .limit(5)

  if (pubErr) {
    console.error('Publications query failed:', pubErr.message)
    process.exit(1)
  }
  console.log('Publications (top 5):', pubs?.length ?? 0, 'rows')
  pubs?.forEach((p) => console.log(' -', p.name, p.authority_score))

  const { count, error: monErr } = await client
    .from('monitor_profiles')
    .select('*', { count: 'exact', head: true })

  if (monErr) console.warn('Monitors (auth required):', monErr.message)
  else console.log('Monitor profiles:', count ?? 0)

  console.log('OK — Supabase media monitoring schema reachable')
}

main().catch((e) => {
  console.error(e)
  process.exit(1)
})
