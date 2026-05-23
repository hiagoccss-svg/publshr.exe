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
  SpaceComment,
  SpaceDocument,
  SpaceDocumentDetail,
  SpaceFile,
  WorkspaceActivity,
  WorkspaceMember,
  WorkspaceSummary,
  WorkspaceTask,
  NotificationItem,
  SpaceFolder,
  SpaceList,
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

function rowToFolder(row: Record<string, unknown>): SpaceFolder {
  return {
    id: row.id as string,
    spaceId: row.space_id as string,
    name: row.name as string,
    sortOrder: row.sort_order as number,
    isArchived: Boolean(row.is_archived),
    updatedAt: row.updated_at as string
  }
}

function rowToList(row: Record<string, unknown>): SpaceList {
  return {
    id: row.id as string,
    spaceId: row.space_id as string,
    folderId: (row.folder_id as string) || null,
    name: row.name as string,
    sortOrder: row.sort_order as number,
    isArchived: Boolean(row.is_archived),
    updatedAt: row.updated_at as string
  }
}

function rowToTask(row: Record<string, unknown>): Task {
  return {
    id: row.id as string,
    spaceId: row.space_id as string,
    listId: (row.list_id as string) || null,
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
    this.runMigrations()
    this.ensureSeed()
  }

  private runMigrations(): void {
    const versionRow = this.db.prepare(`SELECT value FROM meta WHERE key = 'schema_version'`).get() as
      | { value: string }
      | undefined
    const version = Number(versionRow?.value ?? 0)

    if (version < 2) {
      const taskCols = this.db.prepare(`PRAGMA table_info(tasks)`).all() as Array<{ name: string }>
      if (!taskCols.some((c) => c.name === 'list_id')) {
        this.db.exec(`ALTER TABLE tasks ADD COLUMN list_id TEXT REFERENCES space_lists(id) ON DELETE SET NULL`)
      }
      this.db.exec(`
        CREATE TABLE IF NOT EXISTS space_folders (
          id TEXT PRIMARY KEY,
          space_id TEXT NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          sort_order REAL NOT NULL DEFAULT 0,
          is_archived INTEGER NOT NULL DEFAULT 0,
          updated_at TEXT NOT NULL,
          sync_pending INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS space_lists (
          id TEXT PRIMARY KEY,
          space_id TEXT NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
          folder_id TEXT REFERENCES space_folders(id) ON DELETE SET NULL,
          name TEXT NOT NULL,
          sort_order REAL NOT NULL DEFAULT 0,
          is_archived INTEGER NOT NULL DEFAULT 0,
          updated_at TEXT NOT NULL,
          sync_pending INTEGER NOT NULL DEFAULT 0
        );
        CREATE INDEX IF NOT EXISTS idx_tasks_list ON tasks(list_id);
        CREATE INDEX IF NOT EXISTS idx_folders_space ON space_folders(space_id);
        CREATE INDEX IF NOT EXISTS idx_lists_space ON space_lists(space_id);
      `)
      this.ensureDefaultListsForExistingSpaces()
      this.db
        .prepare(
          `INSERT INTO meta (key, value) VALUES ('schema_version', '2')
           ON CONFLICT(key) DO UPDATE SET value = excluded.value`
        )
        .run()
    }
  }

  private ensureDefaultListsForExistingSpaces(): void {
    const spaces = this.db.prepare(`SELECT id FROM spaces WHERE is_archived = 0`).all() as Array<{
      id: string
    }>
    for (const { id: spaceId } of spaces) {
      const listCount = this.db
        .prepare(`SELECT COUNT(*) as c FROM space_lists WHERE space_id = ? AND is_archived = 0`)
        .get(spaceId) as { c: number }
      if (listCount.c === 0) {
        this.createList(spaceId, 'List', null)
      }
    }
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
    this.createList(space.id, 'List', null)
    return space
  }

  listFolders(spaceId: string): SpaceFolder[] {
    const rows = this.db
      .prepare(
        `SELECT * FROM space_folders WHERE space_id = ? AND is_archived = 0 ORDER BY sort_order ASC, name ASC`
      )
      .all(spaceId)
    return rows.map((r) => rowToFolder(r as Record<string, unknown>))
  }

  createFolder(spaceId: string, name: string): SpaceFolder {
    const id = uuid()
    const ts = now()
    const maxOrder = this.db
      .prepare(`SELECT COALESCE(MAX(sort_order), 0) as m FROM space_folders WHERE space_id = ?`)
      .get(spaceId) as { m: number }
    const folder: SpaceFolder = {
      id,
      spaceId,
      name,
      sortOrder: maxOrder.m + 1,
      isArchived: false,
      updatedAt: ts
    }
    this.db
      .prepare(
        `INSERT INTO space_folders (id, space_id, name, sort_order, is_archived, updated_at, sync_pending)
         VALUES (?, ?, ?, ?, 0, ?, 1)`
      )
      .run(folder.id, folder.spaceId, folder.name, folder.sortOrder, folder.updatedAt)
    this.createList(spaceId, 'List', folder.id)
    this.logActivity(spaceId, '', 'You', `created folder "${name}"`, 'folder', folder.id)
    this.enqueueSync('space_folders', folder.id, 'insert', folder)
    return folder
  }

  updateFolder(id: string, patch: { name?: string }): SpaceFolder {
    const row = this.db.prepare('SELECT * FROM space_folders WHERE id = ?').get(id)
    if (!row) throw new Error('Folder not found')
    const current = rowToFolder(row as Record<string, unknown>)
    const next = { ...current, name: patch.name ?? current.name, updatedAt: now() }
    this.db
      .prepare(`UPDATE space_folders SET name = ?, updated_at = ?, sync_pending = 1 WHERE id = ?`)
      .run(next.name, next.updatedAt, id)
    this.enqueueSync('space_folders', id, 'update', next)
    return next
  }

  listLists(spaceId: string): SpaceList[] {
    const rows = this.db
      .prepare(
        `SELECT * FROM space_lists WHERE space_id = ? AND is_archived = 0 ORDER BY sort_order ASC, name ASC`
      )
      .all(spaceId)
    return rows.map((r) => rowToList(r as Record<string, unknown>))
  }

  createList(spaceId: string, name: string, folderId: string | null = null): SpaceList {
    const id = uuid()
    const ts = now()
    const maxOrder = this.db
      .prepare(
        `SELECT COALESCE(MAX(sort_order), 0) as m FROM space_lists WHERE space_id = ? AND COALESCE(folder_id, '') = COALESCE(?, '')`
      )
      .get(spaceId, folderId) as { m: number }
    const list: SpaceList = {
      id,
      spaceId,
      folderId,
      name,
      sortOrder: maxOrder.m + 1,
      isArchived: false,
      updatedAt: ts
    }
    this.db
      .prepare(
        `INSERT INTO space_lists (id, space_id, folder_id, name, sort_order, is_archived, updated_at, sync_pending)
         VALUES (?, ?, ?, ?, ?, 0, ?, 1)`
      )
      .run(list.id, list.spaceId, list.folderId, list.name, list.sortOrder, list.updatedAt)
    this.logActivity(spaceId, '', 'You', `created list "${name}"`, 'list', list.id)
    this.enqueueSync('space_lists', list.id, 'insert', list)
    return list
  }

  updateList(id: string, patch: { name?: string }): SpaceList {
    const row = this.db.prepare('SELECT * FROM space_lists WHERE id = ?').get(id)
    if (!row) throw new Error('List not found')
    const current = rowToList(row as Record<string, unknown>)
    const next = { ...current, name: patch.name ?? current.name, updatedAt: now() }
    this.db
      .prepare(`UPDATE space_lists SET name = ?, updated_at = ?, sync_pending = 1 WHERE id = ?`)
      .run(next.name, next.updatedAt, id)
    this.enqueueSync('space_lists', id, 'update', next)
    return next
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

  listTasks(spaceId: string, listId?: string | null): Task[] {
    const rows = listId
      ? this.db
          .prepare(
            `SELECT * FROM tasks WHERE space_id = ? AND list_id = ? AND status != 'archived'
             ORDER BY sort_order ASC, updated_at DESC`
          )
          .all(spaceId, listId)
      : this.db
          .prepare(
            `SELECT * FROM tasks WHERE space_id = ? AND status != 'archived'
             ORDER BY sort_order ASC, updated_at DESC`
          )
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
      listId: input.listId ?? null,
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
          id, space_id, list_id, title, description, status, priority, assignee_id,
          start_date, due_date, tags, parent_task_id, checklist, comment_count,
          attachment_count, linked_doc_ids, sort_order, updated_at, created_at, sync_pending
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, '[]', NULL, '[]', 0, 0, '[]', ?, ?, ?, 1)`
      )
      .run(
        task.id,
        task.spaceId,
        task.listId,
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
      listId: input.listId !== undefined ? input.listId : current.listId,
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
          title = ?, description = ?, status = ?, priority = ?, assignee_id = ?, list_id = ?,
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
        next.listId,
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
    return rows.map((r) => this.rowToDocument(r as Record<string, unknown>))
  }

  private rowToDocument(row: Record<string, unknown>, spaceName?: string): SpaceDocument {
    return {
      id: row.id as string,
      spaceId: row.space_id as string,
      title: row.title as string,
      docType: row.doc_type as string,
      updatedAt: row.updated_at as string,
      ...(spaceName ? { spaceName } : {})
    }
  }

  getDocument(id: string): SpaceDocumentDetail | null {
    const row = this.db
      .prepare(
        `SELECT d.*, s.name as space_name FROM documents d
         JOIN spaces s ON s.id = d.space_id WHERE d.id = ?`
      )
      .get(id) as Record<string, unknown> | undefined
    if (!row) return null
    return {
      ...this.rowToDocument(row, row.space_name as string),
      content: (row.content as string) ?? ''
    }
  }

  createDocument(spaceId: string, title: string, content = ''): SpaceDocumentDetail {
    const meta = Object.fromEntries(
      this.db.prepare('SELECT key, value FROM meta').all().map((r) => {
        const row = r as { key: string; value: string }
        return [row.key, row.value]
      })
    )
    const id = uuid()
    const ts = now()
    this.db
      .prepare(
        `INSERT INTO documents (id, space_id, title, doc_type, content, updated_at, sync_pending)
         VALUES (?, ?, ?, 'brief', ?, ?, 1)`
      )
      .run(id, spaceId, title, content, ts)
    const userId = meta.current_user_id ?? uuid()
    const userName = meta.current_user_name ?? 'You'
    this.logActivity(spaceId, userId, userName, 'created document', 'document', id)
    this.indexSearch('doc', id, spaceId, title, content)
    const doc = this.getDocument(id)!
    this.enqueueSync('documents', id, 'insert', doc)
    return doc
  }

  updateDocument(id: string, patch: { title?: string; content?: string }): SpaceDocumentDetail {
    const existing = this.getDocument(id)
    if (!existing) throw new Error('Document not found')
    const title = patch.title ?? existing.title
    const content = patch.content ?? existing.content
    const ts = now()
    this.db
      .prepare(`UPDATE documents SET title = ?, content = ?, updated_at = ?, sync_pending = 1 WHERE id = ?`)
      .run(title, content, ts, id)
    this.indexSearch('doc', id, existing.spaceId, title, content)
    const doc = this.getDocument(id)!
    this.enqueueSync('documents', id, 'update', doc)
    return doc
  }

  listWorkspaceDocuments(): SpaceDocument[] {
    const rows = this.db
      .prepare(
        `SELECT d.*, s.name as space_name FROM documents d
         JOIN spaces s ON s.id = d.space_id
         WHERE s.is_archived = 0
         ORDER BY d.updated_at DESC`
      )
      .all()
    return rows.map((r) => this.rowToDocument(r as Record<string, unknown>, (r as Record<string, unknown>).space_name as string))
  }

  listWorkspaceApprovals(): Approval[] {
    const rows = this.db
      .prepare(
        `SELECT a.* FROM approvals a
         JOIN spaces s ON s.id = a.space_id
         WHERE s.is_archived = 0
         ORDER BY a.updated_at DESC`
      )
      .all()
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

  listWorkspaceFiles(): SpaceFile[] {
    const rows = this.db
      .prepare(
        `SELECT f.* FROM space_files f
         JOIN spaces s ON s.id = f.space_id
         WHERE s.is_archived = 0
         ORDER BY f.updated_at DESC`
      )
      .all()
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

  createFile(spaceId: string, fileName: string, fileUrl: string): SpaceFile {
    const id = uuid()
    const ts = now()
    this.db
      .prepare(
        `INSERT INTO space_files (id, space_id, file_name, file_url, mime_type, updated_at)
         VALUES (?, ?, ?, ?, 'application/octet-stream', ?)`
      )
      .run(id, spaceId, fileName, fileUrl, ts)
    const meta = Object.fromEntries(
      this.db.prepare('SELECT key, value FROM meta').all().map((r) => {
        const row = r as { key: string; value: string }
        return [row.key, row.value]
      })
    )
    this.logActivity(
      spaceId,
      meta.current_user_id ?? uuid(),
      meta.current_user_name ?? 'You',
      'added file',
      'file',
      id
    )
    return {
      id,
      spaceId,
      fileName,
      fileUrl,
      mimeType: 'application/octet-stream',
      updatedAt: ts
    }
  }

  listWorkspaceTasks(): WorkspaceTask[] {
    const rows = this.db
      .prepare(
        `SELECT t.*, s.name as space_name FROM tasks t
         JOIN spaces s ON s.id = t.space_id
         WHERE s.is_archived = 0 AND t.status NOT IN ('archived')
         ORDER BY t.updated_at DESC LIMIT 500`
      )
      .all()
    return rows.map((r) => {
      const row = r as Record<string, unknown>
      return { ...rowToTask(row), spaceName: row.space_name as string }
    })
  }

  listWorkspaceMembers(): WorkspaceMember[] {
    const rows = this.db
      .prepare(
        `SELECT user_id, name, email, role, avatar_color,
                MAX(is_online) as is_online,
                COUNT(DISTINCT space_id) as space_count
         FROM space_members
         GROUP BY user_id, name, email, role, avatar_color
         ORDER BY name ASC`
      )
      .all()
    return rows.map((r) => {
      const row = r as Record<string, unknown>
      return {
        id: row.user_id as string,
        spaceId: '',
        userId: row.user_id as string,
        role: row.role as SpaceMember['role'],
        name: row.name as string,
        email: row.email as string,
        avatarColor: row.avatar_color as string,
        isOnline: Boolean(row.is_online),
        spaceCount: row.space_count as number
      }
    })
  }

  listWorkspaceActivity(limit = 40): WorkspaceActivity[] {
    const rows = this.db
      .prepare(
        `SELECT a.*, s.name as space_name FROM space_activity a
         JOIN spaces s ON s.id = a.space_id
         WHERE s.is_archived = 0
         ORDER BY a.created_at DESC LIMIT ?`
      )
      .all(limit)
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
        createdAt: row.created_at as string,
        spaceName: row.space_name as string
      }
    })
  }

  listCoverage(limit = 100): import('../../shared/types').CoverageMention[] {
    const rows = this.db
      .prepare(`SELECT * FROM coverage_mentions ORDER BY published_at DESC LIMIT ?`)
      .all(limit)
    return rows.map((r) => {
      const row = r as Record<string, unknown>
      return {
        id: row.id as string,
        spaceId: (row.space_id as string) || null,
        headline: row.headline as string,
        publication: row.publication as string,
        sentiment: row.sentiment as import('../../shared/types').CoverageSentiment,
        reach: Number(row.reach),
        prValue: Number(row.pr_value),
        url: (row.url as string) || '',
        saved: Boolean(row.saved),
        publishedAt: row.published_at as string
      }
    })
  }

  listNotifications(limit = 30): NotificationItem[] {
    const rows = this.db
      .prepare(`SELECT * FROM notifications ORDER BY created_at DESC LIMIT ?`)
      .all(limit)
    return rows.map((r) => {
      const row = r as Record<string, unknown>
      return {
        id: row.id as string,
        spaceId: (row.space_id as string) || null,
        title: row.title as string,
        body: row.body as string,
        kind: row.kind as string,
        read: Boolean(row.read),
        createdAt: row.created_at as string
      }
    })
  }

  getWorkspaceSummary(): WorkspaceSummary {
    const spaceCount = (
      this.db.prepare(`SELECT COUNT(*) as c FROM spaces WHERE is_archived = 0`).get() as { c: number }
    ).c
    const openTasks = (
      this.db
        .prepare(
          `SELECT COUNT(*) as c FROM tasks t
           JOIN spaces s ON s.id = t.space_id
           WHERE s.is_archived = 0 AND t.status NOT IN ('completed', 'archived')`
        )
        .get() as { c: number }
    ).c
    const overdueTasks = (
      this.db
        .prepare(
          `SELECT COUNT(*) as c FROM tasks t
           JOIN spaces s ON s.id = t.space_id
           WHERE s.is_archived = 0 AND t.due_date IS NOT NULL AND t.due_date < ?
           AND t.status NOT IN ('completed', 'archived')`
        )
        .get(now()) as { c: number }
    ).c
    const pendingApprovals = (
      this.db
        .prepare(
          `SELECT COUNT(*) as c FROM approvals a
           JOIN spaces s ON s.id = a.space_id
           WHERE s.is_archived = 0 AND a.status IN ('requested', 'in_review')`
        )
        .get() as { c: number }
    ).c
    const documentCount = (
      this.db
        .prepare(
          `SELECT COUNT(*) as c FROM documents d JOIN spaces s ON s.id = d.space_id WHERE s.is_archived = 0`
        )
        .get() as { c: number }
    ).c
    const fileCount = (
      this.db
        .prepare(
          `SELECT COUNT(*) as c FROM space_files f JOIN spaces s ON s.id = f.space_id WHERE s.is_archived = 0`
        )
        .get() as { c: number }
    ).c
    const onlineMembers = (
      this.db.prepare(`SELECT COUNT(DISTINCT user_id) as c FROM space_members WHERE is_online = 1`).get() as {
        c: number
      }
    ).c
    return {
      spaceCount,
      openTasks,
      overdueTasks,
      pendingApprovals,
      documentCount,
      fileCount,
      onlineMembers
    }
  }

  listComments(taskId: string): SpaceComment[] {
    const rows = this.db
      .prepare(
        `SELECT * FROM space_comments WHERE task_id = ? ORDER BY created_at ASC`
      )
      .all(taskId)
    return rows.map((r) => {
      const row = r as Record<string, unknown>
      return {
        id: row.id as string,
        spaceId: row.space_id as string,
        taskId: (row.task_id as string) || null,
        documentId: (row.document_id as string) || null,
        userId: row.user_id as string,
        userName: row.user_name as string,
        body: row.body as string,
        createdAt: row.created_at as string
      }
    })
  }

  createComment(input: { spaceId: string; taskId: string; body: string }): SpaceComment {
    const meta = Object.fromEntries(
      this.db.prepare('SELECT key, value FROM meta').all().map((r) => {
        const row = r as { key: string; value: string }
        return [row.key, row.value]
      })
    )
    const id = uuid()
    const ts = now()
    const comment: SpaceComment = {
      id,
      spaceId: input.spaceId,
      taskId: input.taskId,
      documentId: null,
      userId: meta.current_user_id ?? uuid(),
      userName: meta.current_user_name ?? 'You',
      body: input.body,
      createdAt: ts
    }
    this.db
      .prepare(
        `INSERT INTO space_comments (id, space_id, task_id, document_id, user_id, user_name, body, created_at, sync_pending)
         VALUES (?, ?, ?, NULL, ?, ?, ?, ?, 1)`
      )
      .run(
        comment.id,
        comment.spaceId,
        comment.taskId,
        comment.userId,
        comment.userName,
        comment.body,
        comment.createdAt
      )
    this.db
      .prepare(`UPDATE tasks SET comment_count = comment_count + 1, updated_at = ? WHERE id = ?`)
      .run(ts, input.taskId)
    this.logActivity(input.spaceId, comment.userId, comment.userName, 'commented on task', 'task', input.taskId)
    this.enqueueSync('space_comments', comment.id, 'insert', comment)
    return comment
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

  listSyncQueue(limit = 100): Array<{
    id: string
    tableName: string
    recordId: string
    operation: string
    payload: string
  }> {
    const rows = this.db
      .prepare(
        `SELECT id, table_name, record_id, operation, payload FROM sync_queue ORDER BY created_at ASC LIMIT ?`
      )
      .all(limit) as Array<{
      id: string
      table_name: string
      record_id: string
      operation: string
      payload: string
    }>
    return rows.map((r) => ({
      id: r.id,
      tableName: r.table_name,
      recordId: r.record_id,
      operation: r.operation,
      payload: r.payload
    }))
  }

  removeSyncQueueItem(id: string): void {
    this.db.prepare(`DELETE FROM sync_queue WHERE id = ?`).run(id)
  }

  close(): void {
    this.db.close()
  }
}
