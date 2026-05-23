/**
 * In-browser Spaces API (Vite preview / dev without Tauri).
 * Persists to localStorage so modules work when `window.__TAURI__` is unavailable.
 */
import { v4 as uuid } from 'uuid'
import type {
  Approval,
  BootstrapPayload,
  CoverageMention,
  CoverageSentiment,
  CreateTaskInput,
  NotificationItem,
  SearchResult,
  Space,
  SpaceActivity,
  SpaceDocumentDetail,
  SpaceFile,
  SpaceFolder,
  SpaceList,
  SpaceMember,
  SpacesAPI,
  SyncStatus,
  Task,
  UpdateTaskInput,
  Workspace,
  WorkspaceMember,
  WorkspaceSummary,
  WorkspaceTask
} from '../../shared/types'

const STORAGE_KEY = 'publshr.spaces.local-api.v1'

interface Store {
  workspace: Workspace
  currentUserId: string
  currentUserName: string
  syncStatus: SyncStatus
  spaces: Space[]
  folders: SpaceFolder[]
  lists: SpaceList[]
  tasks: Task[]
  members: SpaceMember[]
  activity: SpaceActivity[]
  documents: SpaceDocumentDetail[]
  files: SpaceFile[]
  approvals: Approval[]
  notifications: NotificationItem[]
  coverage: CoverageMention[]
}

function now(): string {
  return new Date().toISOString()
}

function seedStore(): Store {
  const workspaceId = uuid()
  const userId = uuid()
  const ts = now()
  const editorialId = uuid()
  const space: Space = {
    id: editorialId,
    workspaceId,
    name: 'Editorial Ops',
    description: 'Local dev workspace',
    type: 'general',
    status: 'active',
    ownerId: userId,
    color: '#3d5a80',
    isPinned: true,
    isFavourite: false,
    isArchived: false,
    clientMode: false,
    updatedAt: ts,
    createdAt: ts
  }
  const listId = uuid()
  const taskId = uuid()
  return {
    workspace: { id: workspaceId, name: 'Publshr Workspace (local)' },
    currentUserId: userId,
    currentUserName: 'You',
    syncStatus: 'offline',
    spaces: [space],
    folders: [],
    lists: [{ id: listId, spaceId: editorialId, folderId: null, name: 'List', sortOrder: 0, isArchived: false, updatedAt: ts }],
    tasks: [
      {
        id: taskId,
        spaceId: editorialId,
        listId,
        title: 'Review launch brief',
        description: '',
        status: 'in_progress',
        priority: 'high',
        assigneeId: userId,
        startDate: null,
        dueDate: now(),
        tags: [],
        parentTaskId: null,
        checklist: [],
        commentCount: 0,
        attachmentCount: 0,
        linkedDocIds: [],
        order: 0,
        updatedAt: ts,
        createdAt: ts
      }
    ],
    members: [
      {
        id: uuid(),
        spaceId: editorialId,
        userId,
        role: 'owner',
        name: 'You',
        email: 'you@local',
        avatarColor: '#22863A',
        isOnline: true
      }
    ],
    activity: [],
    documents: [],
    files: [],
    approvals: [],
    notifications: [
      {
        id: uuid(),
        spaceId: editorialId,
        title: 'Welcome',
        body: 'Running in local browser mode — use `npm run dev` in desktop/enterprise for full Tauri + SQLite.',
        kind: 'info',
        read: false,
        createdAt: ts
      }
    ],
    coverage: [
      {
        id: uuid(),
        spaceId: editorialId,
        headline: 'Local coverage sample for Media Monitoring',
        publication: 'Reuters',
        sentiment: 'positive' as CoverageSentiment,
        reach: 1_200_000,
        prValue: 4200,
        url: '',
        saved: false,
        publishedAt: ts
      }
    ]
  }
}

function loadStore(): Store {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return seedStore()
    return JSON.parse(raw) as Store
  } catch {
    return seedStore()
  }
}

function saveStore(store: Store): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(store))
  } catch {
    /* quota */
  }
}

let store = loadStore()

export function createLocalSpacesAPI(): SpacesAPI {
  return {
    getBootstrap: async () => {
      const payload: BootstrapPayload = {
        workspace: store.workspace,
        spaces: store.spaces.filter((s) => !s.isArchived),
        currentUserId: store.currentUserId,
        currentUserName: store.currentUserName,
        syncStatus: store.syncStatus
      }
      return payload
    },
    listSpaces: async () => store.spaces.filter((s) => !s.isArchived),
    getSpace: async (id) => store.spaces.find((s) => s.id === id) ?? null,
    createSpace: async (input) => {
      const ts = now()
      const space: Space = {
        id: uuid(),
        workspaceId: store.workspace.id,
        name: input.name,
        description: input.description ?? '',
        type: input.type ?? 'general',
        status: 'active',
        ownerId: store.currentUserId,
        color: '#3d5a80',
        isPinned: false,
        isFavourite: false,
        isArchived: false,
        clientMode: false,
        updatedAt: ts,
        createdAt: ts
      }
      store.spaces.push(space)
      saveStore(store)
      return space
    },
    updateSpace: async (id, patch) => {
      const s = store.spaces.find((x) => x.id === id)
      if (!s) throw new Error('Space not found')
      Object.assign(s, patch, { updatedAt: now() })
      saveStore(store)
      return s
    },
    listFolders: async (spaceId) => store.folders.filter((f) => f.spaceId === spaceId && !f.isArchived),
    createFolder: async (spaceId, name) => {
      const folder: SpaceFolder = {
        id: uuid(),
        spaceId,
        name,
        sortOrder: 0,
        isArchived: false,
        updatedAt: now()
      }
      store.folders.push(folder)
      saveStore(store)
      return folder
    },
    updateFolder: async (id, patch) => {
      const f = store.folders.find((x) => x.id === id)
      if (!f) throw new Error('Folder not found')
      if (patch.name) f.name = patch.name
      f.updatedAt = now()
      saveStore(store)
      return f
    },
    listLists: async (spaceId) => store.lists.filter((l) => l.spaceId === spaceId && !l.isArchived),
    createList: async (spaceId, name, folderId) => {
      const list: SpaceList = {
        id: uuid(),
        spaceId,
        folderId: folderId ?? null,
        name,
        sortOrder: 0,
        isArchived: false,
        updatedAt: now()
      }
      store.lists.push(list)
      saveStore(store)
      return list
    },
    updateList: async (id, patch) => {
      const l = store.lists.find((x) => x.id === id)
      if (!l) throw new Error('List not found')
      if (patch.name) l.name = patch.name
      l.updatedAt = now()
      saveStore(store)
      return l
    },
    listTasks: async (spaceId, listId) =>
      store.tasks.filter(
        (t) => t.spaceId === spaceId && (listId == null || t.listId === listId)
      ),
    createTask: async (input: CreateTaskInput) => {
      const ts = now()
      const task: Task = {
        id: uuid(),
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
        order: 0,
        updatedAt: ts,
        createdAt: ts
      }
      store.tasks.push(task)
      saveStore(store)
      return task
    },
    listComments: async () => [],
    createComment: async (input) => ({
      id: uuid(),
      spaceId: input.spaceId,
      taskId: input.taskId,
      documentId: null,
      userId: store.currentUserId,
      userName: store.currentUserName,
      body: input.body,
      createdAt: now()
    }),
    updateTask: async (input: UpdateTaskInput) => {
      const t = store.tasks.find((x) => x.id === input.id)
      if (!t) throw new Error('Task not found')
      Object.assign(t, input, { updatedAt: now() })
      saveStore(store)
      return t
    },
    deleteTask: async (id) => {
      store.tasks = store.tasks.filter((t) => t.id !== id)
      saveStore(store)
    },
    listActivity: async (spaceId, limit = 20) =>
      store.activity.filter((a) => a.spaceId === spaceId).slice(0, limit),
    listMembers: async (spaceId) => store.members.filter((m) => m.spaceId === spaceId),
    listApprovals: async (spaceId) => store.approvals.filter((a) => a.spaceId === spaceId),
    listDocuments: async (spaceId) =>
      store.documents
        .filter((d) => d.spaceId === spaceId)
        .map((d) => ({ id: d.id, spaceId: d.spaceId, title: d.title, docType: d.docType, updatedAt: d.updatedAt })),
    getDocument: async (id) => store.documents.find((d) => d.id === id) ?? null,
    createDocument: async (spaceId, title, content = '') => {
      const ts = now()
      const doc: SpaceDocumentDetail = {
        id: uuid(),
        spaceId,
        title,
        docType: 'brief',
        content,
        updatedAt: ts
      }
      store.documents.push(doc)
      saveStore(store)
      return doc
    },
    updateDocument: async (id, patch) => {
      const d = store.documents.find((x) => x.id === id)
      if (!d) throw new Error('Document not found')
      if (patch.title) d.title = patch.title
      if (patch.content != null) d.content = patch.content
      d.updatedAt = now()
      saveStore(store)
      return d
    },
    listFiles: async (spaceId) => store.files.filter((f) => f.spaceId === spaceId),
    createFile: async (spaceId, fileName, fileUrl) => {
      const file: SpaceFile = {
        id: uuid(),
        spaceId,
        fileName,
        fileUrl,
        mimeType: 'application/octet-stream',
        updatedAt: now()
      }
      store.files.push(file)
      saveStore(store)
      return file
    },
    listWorkspaceDocuments: async () =>
      store.documents.map((d) => ({
        id: d.id,
        spaceId: d.spaceId,
        title: d.title,
        docType: d.docType,
        updatedAt: d.updatedAt,
        spaceName: store.spaces.find((s) => s.id === d.spaceId)?.name ?? ''
      })),
    listWorkspaceApprovals: async () =>
      store.approvals.map((a) => ({
        ...a,
        spaceName: store.spaces.find((s) => s.id === a.spaceId)?.name ?? ''
      })),
    listWorkspaceFiles: async () =>
      store.files.map((f) => ({
        ...f,
        spaceName: store.spaces.find((s) => s.id === f.spaceId)?.name ?? ''
      })),
    listWorkspaceTasks: async () =>
      store.tasks.map((t) => ({
        ...t,
        spaceName: store.spaces.find((s) => s.id === t.spaceId)?.name ?? ''
      })),
    listWorkspaceMembers: async () => {
      const byUser = new Map<string, WorkspaceMember>()
      for (const m of store.members) {
        const existing = byUser.get(m.userId)
        if (existing) existing.spaceCount += 1
        else
          byUser.set(m.userId, {
            ...m,
            spaceCount: 1
          })
      }
      return [...byUser.values()]
    },
    listWorkspaceActivity: async (limit = 40) =>
      store.activity.slice(0, limit).map((a) => ({
        ...a,
        spaceName: store.spaces.find((s) => s.id === a.spaceId)?.name ?? ''
      })),
    listNotifications: async (limit = 30) => store.notifications.slice(0, limit),
    listCoverage: async (limit = 100) => store.coverage.slice(0, limit),
    getWorkspaceSummary: async (): Promise<WorkspaceSummary> => ({
      spaceCount: store.spaces.filter((s) => !s.isArchived).length,
      openTasks: store.tasks.filter((t) => !['completed', 'archived'].includes(t.status)).length,
      overdueTasks: 0,
      pendingApprovals: store.approvals.filter((a) =>
        ['requested', 'in_review'].includes(a.status)
      ).length,
      documentCount: store.documents.length,
      fileCount: store.files.length,
      onlineMembers: store.members.filter((m) => m.isOnline).length
    }),
    search: async (query): Promise<SearchResult[]> => {
      const q = query.toLowerCase()
      return store.tasks
        .filter((t) => t.title.toLowerCase().includes(q))
        .map((t) => ({
          id: t.id,
          type: 'task' as const,
          title: t.title,
          subtitle: store.spaces.find((s) => s.id === t.spaceId)?.name ?? '',
          spaceId: t.spaceId
        }))
    },
    getSyncStatus: async () => store.syncStatus,
    openDocumentWindow: () => {},
    openSpaceWindow: () => {}
  }
}

/** Apply cloud snapshot into local browser store (after live sync). */
export function applyCloudToLocalStore(snapshot: {
  workspaceId: string
  workspaceName: string
  spaces: Space[]
  workspaceTasks: WorkspaceTask[]
  syncStatus: SyncStatus
}): void {
  store = loadStore()
  store.workspace = { id: snapshot.workspaceId, name: snapshot.workspaceName }
  store.spaces = snapshot.spaces
  store.tasks = snapshot.workspaceTasks.map((t) => ({ ...t, listId: t.listId ?? null }))
  store.syncStatus = snapshot.syncStatus
  saveStore(store)
}
