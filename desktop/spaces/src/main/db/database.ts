import Database from 'better-sqlite3'
import { app } from 'electron'
import { join } from 'path'
import { existsSync, mkdirSync } from 'fs'
import { SCHEMA_SQL } from './schema'
import { v4 as uuid } from 'uuid'
import type {
  Approval,
  BootstrapPayload,
  CreateTaskInput,
  SearchResult,
  Space,
  SpaceActivity,
  SpaceDocument,
  SpaceFile,
  SpaceMember,
  SyncStatus,
  Task,
  TaskStatus,
  UpdateTaskInput,
  Workspace
} from '../../shared/types'

function now(): string {
  return new Date().toISOString()
}

function parseJson<T>(raw: string, fallback: T): T {
  try {
    return JSON.parse(raw) as T
  } catch {
    return fallback
  }
}

function rowToSpace(row: Record<string, unknown>): Space {
  return {
    id: row.id as string,
    workspaceId: row.workspace_id as string,
    name: row.name as string,
    description: row.description as string,
    type: row.type as Space['type'],
    status: row.status as Space['status'],
    ownerId: row.owner_id as string,
    color: row.color as string,
    isPinned: Boolean(row.is_pinned),
    isFavourite: Boolean(row.is_favourite),
    isArchived: Boolean(row.is_archived),
    clientMode: Boolean(row.client_mode),
    updatedAt: row.updated_at as string,
    createdAt: row.created_at as string
  }
}

function rowToTask(row: Record<string, unknown>): Task {
  return {
    id: row.id as string,
    spaceId: row.space_id as string,
    title: row.title as string,
    description: row.description as string,
    status: row.status as TaskStatus,
    priority: row.priority as Task['priority'],
    assigneeId: (row.assignee_id as string) || null,
    startDate: (row.start_date as string) || null,
    dueDate: (row.due_date as string) || null,
    tags: parseJson<string[]>(row.tags as string, []),
    parentTaskId: (row.parent_task_id as string) || null,
    checklist: parseJson(row.checklist as string, []),
    commentCount: row.comment_count as number,
    attachmentCount: row.attachment_count as number,
    linkedDocIds: parseJson<string[]>(row.linked_doc_ids as string, []),
    order: row.sort_order as number,
    updatedAt: row.updated_at as string,
    createdAt: row.created_at as string
  }
}

export class SpacesDatabase {
  private db: Database.Database
  private syncStatus: SyncStatus = 'online'

  constructor() {
    const dir = join(app.getPath('userData'), 'spaces-cache')
    if (!existsSync(dir)) mkdirSync(dir, { recursive: true })
    const path = join(dir, 'spaces.db')
    this.db = new Database(path)
    this.db.exec(SCHEMA_SQL)
    this.ensureSeed()
  }

  setSyncStatus(status: SyncStatus): void {
    this.syncStatus = status
  }

  getSyncStatus(): SyncStatus {
    return this.syncStatus
  }

  private ensureSeed(): void {
    const count = this.db.prepare('SELECT COUNT(*) as c FROM spaces').get() as { c: number }
    if (count.c > 0) return

    const workspaceId = uuid()
    const userId = uuid()
    const ts = now()

    this.db
      .prepare(
        `INSERT INTO workspaces (id, name, updated_at) VALUES (?, ?, ?)`
      )
      .run(workspaceId, 'Publshr Workspace', ts)

    this.db
      .prepare(`INSERT INTO meta (key, value) VALUES (?, ?), (?, ?)`)
      .run('workspace_id', workspaceId, 'current_user_id', userId)

    this.db
      .prepare(
        `INSERT INTO meta (key, value) VALUES (?, ?)`
      )
      .run('current_user_name', 'You')
  }

  getBootstrap(): BootstrapPayload {
    const meta = Object.fromEntries(
      this.db.prepare('SELECT key, value FROM meta').all().map((r) => {
        const row = r as { key: string; value: string }
        return [row.key, row.value]
      })
    )
    const workspaceRow = this.db
      .prepare('SELECT * FROM workspaces LIMIT 1')
      .get() as Record<string, unknown> | undefined

    const workspace: Workspace = workspaceRow
      ? { id: workspaceRow.id as string, name: workspaceRow.name as string }
      : { id: meta.workspace_id ?? uuid(), name: 'Publshr Workspace' }

    const spaces = this.listSpaces()
    return {
      workspace,
      spaces,
      currentUserId: meta.current_user_id ?? uuid(),
      currentUserName: meta.current_user_name ?? 'You',
      syncStatus: this.syncStatus
    }
  }

  listSpaces(): Space[] {
    const rows = this.db
      .prepare(
        `SELECT * FROM spaces WHERE is_archived = 0 ORDER BY is_pinned DESC, is_favourite DESC, updated_at DESC`
      )
      .all()
    return rows.map((r) => rowToSpace(r as Record<string, unknown>))
  }

  getSpace(id: string): Space | null {
    const row = this.db.prepare('SELECT * FROM spaces WHERE id = ?').get(id)
    return row ? rowToSpace(row as Record<string, unknown>) : null
  }

  createSpace(input: { name: string; type?: Space['type']; description?: string }): Space {
    const meta = Object.fromEntries(
      this.db.prepare('SELECT key, value FROM meta').all().map((r) => {
        const row = r as { key: string; value: string }
        return [row.key, row.value]
      })
    )
    const id = uuid()
    const ts = now()
    const space: Space = {
      id,
      workspaceId: meta.workspace_id ?? uuid(),
      name: input.name,
      description: input.description ?? '',
      type: input.type ?? 'general',
      status: 'active',
      ownerId: meta.current_user_id ?? uuid(),
      color: '#3d5a80',
      isPinned: false,
      isFavourite: false,
      isArchived: false,
      clientMode: false,
      updatedAt: ts,
      createdAt: ts
    }

    this.db
      .prepare(
        `INSERT INTO spaces (
          id, workspace_id, name, description, type, status, owner_id, color,
          is_pinned, is_favourite, is_archived, client_mode, updated_at, created_at, sync_pending
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0, 0, ?, ?, 1)`
      )
      .run(
        space.id,
        space.workspaceId,
        space.name,
        space.description,
        space.type,
        space.status,
        space.ownerId,
        space.color,
        space.updatedAt,
        space.createdAt
      )

    this.indexSearch('space', space.id, space.id, space.name, space.description)
    this.logActivity(space.id, space.ownerId, 'You', 'created space', 'space', space.id)
    this.enqueueSync('spaces', space.id, 'insert', space)
    return space
  }

  updateSpace(id: string, patch: Partial<Space>): Space {
    const current = this.getSpace(id)
    if (!current) throw new Error('Space not found')
    const next = { ...current, ...patch, updatedAt: now() }
    this.db
      .prepare(
        `UPDATE spaces SET
          name = ?, description = ?, type = ?, status = ?, color = ?,
          is_pinned = ?, is_favourite = ?, is_archived = ?, client_mode = ?, updated_at = ?, sync_pending = 1
         WHERE id = ?`
      )
      .run(
        next.name,
        next.description,
        next.type,
        next.status,
        next.color,
        next.isPinned ? 1 : 0,
        next.isFavourite ? 1 : 0,
        next.isArchived ? 1 : 0,
        next.clientMode ? 1 : 0,
        next.updatedAt,
        id
      )
    this.enqueueSync('spaces', id, 'update', next)
    return next
  }

  listTasks(spaceId: string): Task[] {
    const rows = this.db
      .prepare('SELECT * FROM tasks WHERE space_id = ? ORDER BY sort_order ASC, updated_at DESC')
      .all(spaceId)
    return rows.map((r) => rowToTask(r as Record<string, unknown>))
  }

  createTask(input: CreateTaskInput): Task {
    const id = uuid()
    const ts = now()
    const maxOrder = this.db
      .prepare('SELECT COALESCE(MAX(sort_order), 0) as m FROM tasks WHERE space_id = ?')
      .get(input.spaceId) as { m: number }

    const task: Task = {
      id,
      spaceId: input.spaceId,
      title: input.title,
      description: '',
      status: input.status ?? 'todo',
      priority: input.priority ?? 'normal',
      assigneeId: input.assigneeId ?? null,
      startDate: null,
      dueDate: input.dueDate ?? null,
      tags: [],
      parentTaskId: null,
      checklist: [],
      commentCount: 0,
      attachmentCount: 0,
      linkedDocIds: [],
      order: maxOrder.m + 1,
      updatedAt: ts,
      createdAt: ts
    }

    this.db
      .prepare(
        `INSERT INTO tasks (
          id, space_id, title, description, status, priority, assignee_id,
          start_date, due_date, tags, parent_task_id, checklist, comment_count,
          attachment_count, linked_doc_ids, sort_order, updated_at, created_at, sync_pending
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, '[]', NULL, '[]', 0, 0, '[]', ?, ?, ?, 1)`
      )
      .run(
        task.id,
        task.spaceId,
        task.title,
        task.description,
        task.status,
        task.priority,
        task.assigneeId,
        task.startDate,
        task.dueDate,
        task.order,
        task.updatedAt,
        task.createdAt
      )

    this.indexSearch('task', task.id, task.spaceId, task.title, task.description)
    this.logActivity(task.spaceId, '', 'You', `created task "${task.title}"`, 'task', task.id)
    this.enqueueSync('tasks', task.id, 'insert', task)
    return task
  }

  updateTask(input: UpdateTaskInput): Task {
    const row = this.db.prepare('SELECT * FROM tasks WHERE id = ?').get(input.id)
    if (!row) throw new Error('Task not found')
    const current = rowToTask(row as Record<string, unknown>)
    const next: Task = {
      ...current,
      title: input.title ?? current.title,
      description: input.description ?? current.description,
      status: input.status ?? current.status,
      priority: input.priority ?? current.priority,
      assigneeId: input.assigneeId !== undefined ? input.assigneeId : current.assigneeId,
      startDate: input.startDate !== undefined ? input.startDate : current.startDate,
      dueDate: input.dueDate !== undefined ? input.dueDate : current.dueDate,
      tags: input.tags ?? current.tags,
      checklist: input.checklist ?? current.checklist,
      order: input.order ?? current.order,
      updatedAt: now()
    }

    this.db
      .prepare(
        `UPDATE tasks SET
          title = ?, description = ?, status = ?, priority = ?, assignee_id = ?,
          start_date = ?, due_date = ?, tags = ?, checklist = ?, sort_order = ?,
          updated_at = ?, sync_pending = 1
         WHERE id = ?`
      )
      .run(
        next.title,
        next.description,
        next.status,
        next.priority,
        next.assigneeId,
        next.startDate,
        next.dueDate,
        JSON.stringify(next.tags),
        JSON.stringify(next.checklist),
        next.order,
        next.updatedAt,
        input.id
      )

    if (input.status && input.status !== current.status) {
      this.logActivity(
        next.spaceId,
        '',
        'You',
        `changed status to ${next.status.replace('_', ' ')}`,
        'task',
        next.id
      )
    }

    this.indexSearch('task', next.id, next.spaceId, next.title, next.description)
    this.enqueueSync('tasks', next.id, 'update', next)
    return next
  }

  deleteTask(id: string): void {
    const row = this.db.prepare('SELECT space_id FROM tasks WHERE id = ?').get(id) as
      | { space_id: string }
      | undefined
    this.db.prepare('DELETE FROM tasks WHERE id = ?').run(id)
    this.db.prepare('DELETE FROM search_index WHERE entity_id = ?').run(id)
    if (row) {
      this.enqueueSync('tasks', id, 'delete', { id, spaceId: row.space_id })
    }
  }

  listActivity(spaceId: string, limit = 30): SpaceActivity[] {
    const rows = this.db
      .prepare(
        `SELECT * FROM space_activity WHERE space_id = ? ORDER BY created_at DESC LIMIT ?`
      )
      .all(spaceId, limit)
    return rows.map((r) => {
      const row = r as Record<string, unknown>
      return {
        id: row.id as string,
        spaceId: row.space_id as string,
        userId: row.user_id as string,
        userName: row.user_name as string,
        action: row.action as string,
        entityType: row.entity_type as string,
        entityId: row.entity_id as string,
        createdAt: row.created_at as string
      }
    })
  }

  listMembers(spaceId: string): SpaceMember[] {
    const rows = this.db.prepare('SELECT * FROM space_members WHERE space_id = ?').all(spaceId)
    if (rows.length === 0) {
      const meta = Object.fromEntries(
        this.db.prepare('SELECT key, value FROM meta').all().map((r) => {
          const row = r as { key: string; value: string }
          return [row.key, row.value]
        })
      )
      return [
        {
          id: uuid(),
          spaceId,
          userId: meta.current_user_id ?? uuid(),
          role: 'owner',
          name: meta.current_user_name ?? 'You',
          email: '',
          avatarColor: '#3d5a80',
          isOnline: true
        }
      ]
    }
    return rows.map((r) => {
      const row = r as Record<string, unknown>
      return {
        id: row.id as string,
        spaceId: row.space_id as string,
        userId: row.user_id as string,
        role: row.role as SpaceMember['role'],
        name: row.name as string,
        email: row.email as string,
        avatarColor: row.avatar_color as string,
        isOnline: Boolean(row.is_online)
      }
    })
  }

  listApprovals(spaceId: string): Approval[] {
    const rows = this.db.prepare('SELECT * FROM approvals WHERE space_id = ?').all(spaceId)
    return rows.map((r) => {
      const row = r as Record<string, unknown>
      return {
        id: row.id as string,
        spaceId: row.space_id as string,
        taskId: (row.task_id as string) || null,
        documentId: (row.document_id as string) || null,
        status: row.status as Approval['status'],
        title: row.title as string,
        updatedAt: row.updated_at as string
      }
    })
  }

  listDocuments(spaceId: string): SpaceDocument[] {
    const rows = this.db.prepare('SELECT * FROM documents WHERE space_id = ?').all(spaceId)
    return rows.map((r) => {
      const row = r as Record<string, unknown>
      return {
        id: row.id as string,
        spaceId: row.space_id as string,
        title: row.title as string,
        docType: row.doc_type as string,
        updatedAt: row.updated_at as string
      }
    })
  }

  listFiles(spaceId: string): SpaceFile[] {
    const rows = this.db.prepare('SELECT * FROM space_files WHERE space_id = ?').all(spaceId)
    return rows.map((r) => {
      const row = r as Record<string, unknown>
      return {
        id: row.id as string,
        spaceId: row.space_id as string,
        fileName: row.file_name as string,
        fileUrl: row.file_url as string,
        mimeType: row.mime_type as string,
        updatedAt: row.updated_at as string
      }
    })
  }

  search(query: string): SearchResult[] {
    const q = `%${query.trim().toLowerCase()}%`
    if (!query.trim()) return []
    const rows = this.db
      .prepare(
        `SELECT * FROM search_index
         WHERE lower(title) LIKE ? OR lower(body) LIKE ?
         ORDER BY updated_at DESC LIMIT 40`
      )
      .all(q, q)
    return rows.map((r) => {
      const row = r as Record<string, unknown>
      return {
        id: row.entity_id as string,
        type: row.entity_type as SearchResult['type'],
        title: row.title as string,
        subtitle: (row.body as string).slice(0, 80),
        spaceId: (row.space_id as string) || undefined
      }
    })
  }

  private indexSearch(
    entityType: string,
    entityId: string,
    spaceId: string | null,
    title: string,
    body: string
  ): void {
    const id = `${entityType}:${entityId}`
    this.db
      .prepare(
        `INSERT INTO search_index (id, entity_type, entity_id, space_id, title, body, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(id) DO UPDATE SET title = excluded.title, body = excluded.body, updated_at = excluded.updated_at`
      )
      .run(id, entityType, entityId, spaceId, title, body, now())
  }

  private logActivity(
    spaceId: string,
    userId: string,
    userName: string,
    action: string,
    entityType: string,
    entityId: string
  ): void {
    this.db
      .prepare(
        `INSERT INTO space_activity (id, space_id, user_id, user_name, action, entity_type, entity_id, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
      )
      .run(uuid(), spaceId, userId, userName, action, entityType, entityId, now())
  }

  private enqueueSync(tableName: string, recordId: string, operation: string, payload: unknown): void {
    this.db
      .prepare(
        `INSERT INTO sync_queue (id, table_name, record_id, operation, payload, created_at)
         VALUES (?, ?, ?, ?, ?, ?)`
      )
      .run(uuid(), tableName, recordId, operation, JSON.stringify(payload), now())
  }

  close(): void {
    this.db.close()
  }
}
