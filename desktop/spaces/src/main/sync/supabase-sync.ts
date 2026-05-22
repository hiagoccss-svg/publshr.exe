import { createClient, type RealtimeChannel, type SupabaseClient } from '@supabase/supabase-js'
import type { SpacesDatabase } from '../db/database'
import type { Task, Space } from '../../shared/types'

const SUPABASE_URL = process.env.VITE_SUPABASE_URL ?? process.env.SUPABASE_URL ?? ''
const SUPABASE_ANON_KEY =
  process.env.VITE_SUPABASE_ANON_KEY ?? process.env.SUPABASE_ANON_KEY ?? ''

export class SupabaseSyncService {
  private client: SupabaseClient | null = null
  private channel: RealtimeChannel | null = null
  private enabled = Boolean(SUPABASE_URL && SUPABASE_ANON_KEY)

  constructor(
    private readonly db: SpacesDatabase,
    private readonly onRemoteChange: (payload: { table: string; record: unknown }) => void
  ) {}

  async start(): Promise<void> {
    if (!this.enabled) {
      this.db.setSyncStatus('offline')
      return
    }

    try {
      this.client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
        auth: { persistSession: false }
      })
      this.db.setSyncStatus('syncing')
      await this.flushQueue()
      this.subscribeRealtime()
      this.db.setSyncStatus('online')
    } catch {
      this.db.setSyncStatus('error')
    }
  }

  private subscribeRealtime(): void {
    if (!this.client) return
    this.channel = this.client
      .channel('spaces-realtime')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'tasks' },
        (payload) => {
          this.onRemoteChange({ table: 'tasks', record: payload.new ?? payload.old })
        }
      )
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'spaces' },
        (payload) => {
          this.onRemoteChange({ table: 'spaces', record: payload.new ?? payload.old })
        }
      )
      .subscribe()
  }

  private async flushQueue(): Promise<void> {
    if (!this.client) return
    // Phase 1: queue is local-first; cloud push runs when credentials are configured.
    // Records remain in sync_queue until a successful remote write.
  }

  stop(): void {
    if (this.channel && this.client) {
      this.client.removeChannel(this.channel)
    }
    this.channel = null
    this.client = null
  }

  isEnabled(): boolean {
    return this.enabled
  }

  applyRemoteTask(task: Task): void {
    // Renderer will refresh via IPC broadcast; DB merge in Phase 2.
    void task
  }

  applyRemoteSpace(space: Space): void {
    void space
  }
}
