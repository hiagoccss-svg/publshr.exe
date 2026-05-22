import { SUPABASE_URL } from '../config'

export async function isNetworkReachable(): Promise<boolean> {
  const targets = [SUPABASE_URL, 'https://github.com']
  for (const base of targets) {
    try {
      const url = new URL(base)
      const res = await fetch(url.origin, { method: 'HEAD', signal: AbortSignal.timeout(8000) })
      if (res.status >= 200 && res.status < 500) return true
    } catch {
      /* try next */
    }
  }
  return false
}
