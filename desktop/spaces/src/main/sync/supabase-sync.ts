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
    const rows = this.db.listSyncQueue(200)
    for (const row of rows) {
      try {
        const payload = JSON.parse(row.payload) as Record<string, unknown>
        if (row.tableName === 'spaces') {
          if (row.operation === 'delete') {
            await this.client.from('spaces').delete().eq('id', row.recordId)
          } else {
            await this.client.from('spaces').upsert(this.mapSpace(payload))
          }
        } else if (row.tableName === 'tasks') {
          if (row.operation === 'delete') {
            await this.client.from('tasks').delete().eq('id', row.recordId)
          } else {
            await this.client.from('tasks').upsert(this.mapTask(payload))
          }
        }
        this.db.removeSyncQueueItem(row.id)
      } catch {
        // Keep in queue for next flush
      }
    }
  }

  /** Production `space_type` enum: project | folder | list | board | channel */
  private mapSpaceTypeForCloud(type: unknown): string {
    const t = String(type ?? 'general')
    if (['project', 'folder', 'list', 'board', 'channel'].includes(t)) return t
    return 'project'
  }

  private mapSpace(p: Record<string, unknown>) {
    return {
      id: p.id,
      workspace_id: p.workspaceId,
      name: p.name,
      description: p.description ?? '',
      type: this.mapSpaceTypeForCloud(p.type),
      status: p.status ?? 'active',
      owner_id: p.ownerId,
      color: p.color ?? '#3d5a80',
      is_pinned: Boolean(p.isPinned),
      is_favourite: Boolean(p.isFavourite),
      is_archived: Boolean(p.isArchived),
      client_mode: Boolean(p.clientMode)
    }
  }

  private mapTask(p: Record<string, unknown>) {
    return {
      id: p.id,
      space_id: p.spaceId,
      title: p.title,
      description: p.description ?? '',
      status: p.status ?? 'todo',
      priority: p.priority ?? 'normal',
      assignee_id: p.assigneeId ?? null,
      start_date: p.startDate ?? null,
      due_date: p.dueDate ?? null,
      tags: p.tags ?? [],
      parent_task_id: p.parentTaskId ?? null,
      checklist: p.checklist ?? [],
      sort_order: p.order ?? 0
    }
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
