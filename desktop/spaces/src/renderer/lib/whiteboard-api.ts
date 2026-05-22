import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import type { Whiteboard } from '../../shared/types'

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined
const key = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined

let client: SupabaseClient | null = null

function getClient(): SupabaseClient | null {
  if (!url || !key) return null
  if (!client) {
    client = createClient(url, key, { auth: { persistSession: false } })
  }
  return client
}

function mapRow(row: Record<string, unknown>): Whiteboard {
  return {
    id: String(row.id),
    workspaceId: String(row.workspace_id),
    spaceId: String(row.space_id),
    listId: row.list_id ? String(row.list_id) : null,
    plannerProjectId: row.planner_project_id ? String(row.planner_project_id) : null,
    name: String(row.name ?? 'Whiteboard'),
    description: String(row.description ?? ''),
    snapshot: (row.snapshot as Record<string, unknown>) ?? {},
    isArchived: Boolean(row.is_archived),
    isPinned: Boolean(row.is_pinned),
    createdBy: String(row.created_by),
    updatedAt: String(row.updated_at),
    createdAt: String(row.created_at)
  }
}

export function whiteboardApiEnabled(): boolean {
  return Boolean(url && key)
}

export async function listWhiteboards(spaceId: string): Promise<Whiteboard[]> {
  const c = getClient()
  if (!c) return []
  const { data, error } = await c
    .from('whiteboards')
    .select('*')
    .eq('space_id', spaceId)
    .eq('is_archived', false)
    .order('updated_at', { ascending: false })
  if (error) throw error
  return (data ?? []).map((row) => mapRow(row as Record<string, unknown>))
}

export async function createWhiteboard(input: {
  workspaceId: string
  spaceId: string
  name: string
  createdBy: string
  listId?: string | null
}): Promise<Whiteboard> {
  const c = getClient()
  if (!c) throw new Error('Supabase not configured — add VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY')
  const { data, error } = await c
    .from('whiteboards')
    .insert({
      workspace_id: input.workspaceId,
      space_id: input.spaceId,
      list_id: input.listId ?? null,
      name: input.name,
      created_by: input.createdBy,
      snapshot: {}
    })
    .select('*')
    .single()
  if (error) throw error
  return mapRow(data as Record<string, unknown>)
}

export async function saveWhiteboardSnapshot(
  id: string,
  snapshot: Record<string, unknown>,
  updatedBy: string
): Promise<void> {
  const c = getClient()
  if (!c) throw new Error('Supabase not configured')
  const { error } = await c
    .from('whiteboards')
    .update({
      snapshot,
      updated_by: updatedBy,
      updated_at: new Date().toISOString()
    })
    .eq('id', id)
  if (error) throw error
}
