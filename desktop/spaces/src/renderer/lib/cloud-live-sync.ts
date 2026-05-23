import type { SupabaseClient } from '@supabase/supabase-js'
import type { Space, SpaceType, TaskStatus, TaskPriority, WorkspaceTask } from '../../shared/types'
import type { ChatChannel, ChatMessage } from '../stores/chat-store'

export interface CloudWorkspaceSnapshot {
  workspaceId: string
  workspaceName: string
  spaces: Space[]
  workspaceTasks: WorkspaceTask[]
  channels: ChatChannel[]
  messages: ChatMessage[]
}

function mapSpace(row: Record<string, unknown>, workspaceId: string, ownerId: string): Space {
  const now = new Date().toISOString()
  return {
    id: String(row.id),
    workspaceId,
    name: String(row.name ?? 'Space'),
    description: String(row.description ?? ''),
    type: (row.type as SpaceType) ?? 'general',
    status: (row.status as Space['status']) ?? 'active',
    ownerId: String(row.owner_id ?? ownerId),
    color: String(row.color ?? '#3d5a80'),
    isPinned: Boolean(row.is_pinned),
    isFavourite: Boolean(row.is_favourite),
    isArchived: Boolean(row.is_archived),
    clientMode: Boolean(row.client_mode),
    updatedAt: String(row.updated_at ?? now),
    createdAt: String(row.created_at ?? now)
  }
}

function mapTask(row: Record<string, unknown>, spaceName: string): WorkspaceTask {
  const now = new Date().toISOString()
  return {
    id: String(row.id),
    spaceId: String(row.space_id),
    listId: null,
    title: String(row.title ?? 'Task'),
    description: String(row.description ?? ''),
    status: (row.status as TaskStatus) ?? 'todo',
    priority: (row.priority as TaskPriority) ?? 'normal',
    assigneeId: row.assignee_id ? String(row.assignee_id) : null,
    startDate: row.start_date ? String(row.start_date) : null,
    dueDate: row.due_date ? String(row.due_date) : null,
    tags: Array.isArray(row.tags) ? (row.tags as string[]) : [],
    parentTaskId: row.parent_task_id ? String(row.parent_task_id) : null,
    checklist: [],
    commentCount: 0,
    attachmentCount: 0,
    linkedDocIds: [],
    order: Number(row.sort_order ?? 0),
    updatedAt: String(row.updated_at ?? now),
    createdAt: String(row.created_at ?? now),
    spaceName
  }
}

/** Pull workspace, spaces, tasks, and chat from Supabase (live cloud). */
export async function fetchCloudWorkspaceSnapshot(
  supabase: SupabaseClient,
  userId: string,
  displayName: string
): Promise<CloudWorkspaceSnapshot | null> {
  const { data: memberships, error: memErr } = await supabase
    .from('workspace_members')
    .select('workspace_id, role')
    .eq('user_id', userId)
    .limit(1)

  if (memErr || !memberships?.length) {
    const { data: created, error: createErr } = await supabase.rpc('create_workspace', {
      p_name: 'Publshr Workspace'
    })
    if (createErr || !created) return null
    const ws = created as { id: string; name?: string }
    return pullForWorkspace(supabase, ws.id, ws.name ?? 'Publshr Workspace', userId, displayName)
  }

  const workspaceId = memberships[0].workspace_id as string
  const { data: workspace } = await supabase
    .from('workspaces')
    .select('id, name')
    .eq('id', workspaceId)
    .maybeSingle()

  return pullForWorkspace(
    supabase,
    workspaceId,
    (workspace?.name as string) ?? 'Publshr Workspace',
    userId,
    displayName
  )
}

async function pullForWorkspace(
  supabase: SupabaseClient,
  workspaceId: string,
  workspaceName: string,
  userId: string,
  displayName: string
): Promise<CloudWorkspaceSnapshot> {
  const { data: spaceRows } = await supabase
    .from('spaces')
    .select('*')
    .eq('workspace_id', workspaceId)
    .eq('is_archived', false)
    .order('updated_at', { ascending: false })
    .limit(100)

  const spaces = (spaceRows ?? []).map((r) =>
    mapSpace(r as Record<string, unknown>, workspaceId, userId)
  )
  const spaceNames = Object.fromEntries(spaces.map((s) => [s.id, s.name]))

  const spaceIds = spaces.map((s) => s.id)
  let workspaceTasks: WorkspaceTask[] = []
  if (spaceIds.length > 0) {
    const { data: taskRows } = await supabase
      .from('tasks')
      .select('*')
      .in('space_id', spaceIds)
      .order('updated_at', { ascending: false })
      .limit(200)
    workspaceTasks = (taskRows ?? []).map((r) =>
      mapTask(r as Record<string, unknown>, spaceNames[String((r as { space_id: string }).space_id)] ?? '')
    )
  }

  const { data: channelRows } = await supabase
    .from('chat_channels')
    .select('id, name, description, kind, is_archived')
    .eq('workspace_id', workspaceId)
    .eq('is_archived', false)
    .order('name')
    .limit(50)

  const channels: ChatChannel[] = (channelRows ?? []).map((c) => ({
    id: String(c.id),
    name: String(c.name),
    description: String(c.description ?? ''),
    isDm: c.kind === 'dm',
    unread: 0
  }))

  const channelIds = channels.map((c) => c.id)
  let messages: ChatMessage[] = []
  if (channelIds.length > 0) {
    const { data: msgRows } = await supabase
      .from('chat_messages')
      .select('id, channel_id, user_id, body, created_at')
      .in('channel_id', channelIds)
      .eq('is_deleted', false)
      .order('created_at', { ascending: true })
      .limit(200)

    const { data: profiles } = await supabase
      .from('profiles')
      .select('id, display_name, email')

    const profileMap = Object.fromEntries(
      (profiles ?? []).map((p) => [
        String(p.id),
        String(p.display_name ?? p.email ?? 'Member')
      ])
    )

    messages = (msgRows ?? []).map((m) => ({
      id: String(m.id),
      channelId: String(m.channel_id),
      authorId: String(m.user_id),
      authorName:
        m.user_id === userId
          ? displayName
          : (profileMap[String(m.user_id)] ?? 'Member'),
      body: String(m.body ?? ''),
      createdAt: String(m.created_at)
    }))
  }

  return {
    workspaceId,
    workspaceName,
    spaces,
    workspaceTasks,
    channels: channels.length > 0 ? channels : [{ id: 'general', name: 'general', description: 'Workspace', isDm: false, unread: 0 }],
    messages
  }
}
