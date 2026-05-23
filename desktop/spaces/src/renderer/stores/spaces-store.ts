import type { CanonicalSpaceType } from '@spaces-enterprise/hierarchy'
import type { SpacesHomeLayout } from '@spaces-enterprise/spaces-home'
import { create } from 'zustand'
import { getSpacesAPI } from '../lib/api'
import type { CloudWorkspaceSnapshot } from '../lib/cloud-live-sync'
import type {
  Approval,
  BootstrapPayload,
  CoverageMention,
  NotificationItem,
  SidebarSection,
  Space,
  SpaceActivity,
  SpaceComment,
  SpaceDocument,
  SpaceFile,
  SpaceFolder,
  SpaceList,
  SpaceMember,
  SyncStatus,
  Task,
  TaskViewMode,
  WorkspaceActivity,
  WorkspaceMember,
  WorkspaceSummary,
  WorkspaceTask
} from '../../shared/types'

interface SpacesState {
  ready: boolean
  bootstrapError: string | null
  workspace: BootstrapPayload['workspace'] | null
  spaces: Space[]
  folders: SpaceFolder[]
  lists: SpaceList[]
  activeSpaceId: string | null
  activeFolderId: string | null
  activeListId: string | null
  expandedFolderIds: Record<string, boolean>
  activeSection: SidebarSection
  taskView: TaskViewMode
  tasks: Task[]
  members: SpaceMember[]
  activity: SpaceActivity[]
  documents: SpaceDocument[]
  files: SpaceFile[]
  approvals: Approval[]
  workspaceSummary: WorkspaceSummary | null
  workspaceDocuments: SpaceDocument[]
  workspaceApprovals: Approval[]
  workspaceFiles: SpaceFile[]
  workspaceTasks: WorkspaceTask[]
  workspaceMembers: WorkspaceMember[]
  workspaceActivity: WorkspaceActivity[]
  notifications: NotificationItem[]
  coverageMentions: CoverageMention[]
  taskComments: SpaceComment[]
  currentUserId: string
  currentUserName: string
  syncStatus: SyncStatus
  sidebarCollapsed: boolean
  contextPanelOpen: boolean
  selectedTaskId: string | null
  commandOpen: boolean
  notificationsOpen: boolean
  searchQuery: string
  newSpaceModalOpen: boolean
  spaceSettingsId: string | null
  spacesHomeOpen: boolean
  spacesHomeQuery: string
  spacesHomeTypeFilter: CanonicalSpaceType | 'all'
  spacesHomeShowArchived: boolean
  spacesHomeLayout: SpacesHomeLayout
  loadBootstrap: () => Promise<void>
  clearBootstrapError: () => void
  loadWorkspaceData: () => Promise<void>
  applyCloudSnapshot: (snapshot: CloudWorkspaceSnapshot, userId: string, userName: string) => void
  refreshActiveSpace: () => Promise<void>
  refreshHierarchy: () => Promise<void>
  setActiveSpace: (id: string | null) => Promise<void>
  setActiveList: (listId: string | null) => Promise<void>
  setActiveFolder: (folderId: string | null) => Promise<void>
  toggleFolderExpanded: (folderId: string) => void
  setActiveSection: (section: SidebarSection) => void
  selectEnterpriseNav: (id: SidebarSection | 'whiteboard') => void
  setTaskView: (view: TaskViewMode) => void
  setSelectedTask: (id: string | null) => Promise<void>
  setSidebarCollapsed: (v: boolean) => void
  setContextPanelOpen: (v: boolean) => void
  setCommandOpen: (v: boolean) => void
  setNotificationsOpen: (v: boolean) => void
  setSearchQuery: (q: string) => void
  setNewSpaceModalOpen: (v: boolean) => void
  setSpaceSettingsId: (id: string | null) => void
  openSpaceSettings: (id: string) => void
  setSpacesHomeOpen: (v: boolean) => void
  setSpacesHomeQuery: (q: string) => void
  setSpacesHomeTypeFilter: (t: CanonicalSpaceType | 'all') => void
  setSpacesHomeShowArchived: (v: boolean) => void
  setSpacesHomeLayout: (layout: SpacesHomeLayout) => void
  getDefaultViewForSpace: (spaceId: string) => TaskViewMode
  setDefaultViewForSpace: (spaceId: string, view: TaskViewMode) => void
  updateSpace: (id: string, patch: Partial<Space>) => Promise<void>
  createSpace: (input: { name: string; description?: string; type?: Space['type'] }) => Promise<Space>
  createFolder: (name: string) => Promise<void>
  createList: (name: string, folderId?: string | null) => Promise<void>
  createTask: (title: string) => Promise<void>
  updateTaskStatus: (taskId: string, status: Task['status']) => Promise<void>
  loadTaskComments: (taskId: string) => Promise<void>
  postComment: (body: string) => Promise<void>
  createDocument: (title: string, spaceId?: string) => Promise<void>
  createFileLink: (fileName: string, fileUrl: string, spaceId?: string) => Promise<void>
}

export const useSpacesStore = create<SpacesState>((set, get) => ({
  ready: false,
  bootstrapError: null,
  workspace: null,
  spaces: [],
  folders: [],
  lists: [],
  activeSpaceId: null,
  activeFolderId: null,
  activeListId: null,
  expandedFolderIds: {},
  activeSection: 'chat',
  taskView: 'overview',
  tasks: [],
  members: [],
  activity: [],
  documents: [],
  files: [],
  approvals: [],
  workspaceSummary: null,
  workspaceDocuments: [],
  workspaceApprovals: [],
  workspaceFiles: [],
  workspaceTasks: [],
  workspaceMembers: [],
  workspaceActivity: [],
  notifications: [],
  coverageMentions: [],
  taskComments: [],
  currentUserId: '',
  currentUserName: 'You',
  syncStatus: 'offline',
  sidebarCollapsed: false,
  contextPanelOpen: true,
  selectedTaskId: null,
  commandOpen: false,
  notificationsOpen: false,
  searchQuery: '',
  newSpaceModalOpen: false,
  spaceSettingsId: null,
  spacesHomeOpen: false,
  spacesHomeQuery: '',
  spacesHomeTypeFilter: 'all',
  spacesHomeShowArchived: false,
  spacesHomeLayout: 'grid',

  loadBootstrap: async () => {
    set({ bootstrapError: null })
    try {
      const api = getSpacesAPI()
      const data: BootstrapPayload = await api.getBootstrap()
      const spaces = data.spaces
      set({
        ready: true,
        bootstrapError: null,
        workspace: data.workspace,
        spaces,
        activeSpaceId: spaces[0]?.id ?? null,
        activeSection: 'chat',
        spacesHomeOpen: false,
        currentUserId: data.currentUserId,
        currentUserName: data.currentUserName,
        syncStatus: data.syncStatus
      })
      await get().loadWorkspaceData()
    } catch (e) {
      set({
        ready: false,
        bootstrapError: e instanceof Error ? e.message : 'Failed to load workspace'
      })
    }
  },

  clearBootstrapError: () => set({ bootstrapError: null }),

  applyCloudSnapshot: (snapshot, userId, userName) => {
    set({
      ready: true,
      bootstrapError: null,
      workspace: { id: snapshot.workspaceId, name: snapshot.workspaceName },
      spaces: snapshot.spaces,
      workspaceTasks: snapshot.workspaceTasks,
      activeSpaceId: snapshot.spaces[0]?.id ?? null,
      currentUserId: userId,
      currentUserName: userName,
      syncStatus: 'online'
    })
    if (snapshot.spaces[0]) {
      void get().setActiveSpace(snapshot.spaces[0].id)
    }
    void get().loadWorkspaceData()
  },

  loadWorkspaceData: async () => {
    const api = getSpacesAPI()
    const [
      workspaceSummary,
      workspaceDocuments,
      workspaceApprovals,
      workspaceFiles,
      workspaceTasks,
      workspaceMembers,
      workspaceActivity,
      notifications,
      coverageMentions,
      syncStatus
    ] = await Promise.all([
      api.getWorkspaceSummary(),
      api.listWorkspaceDocuments(),
      api.listWorkspaceApprovals(),
      api.listWorkspaceFiles(),
      api.listWorkspaceTasks(),
      api.listWorkspaceMembers(),
      api.listWorkspaceActivity(50),
      api.listNotifications(30),
      api.listCoverage(100).catch(() => [] as CoverageMention[]),
      api.getSyncStatus()
    ])
    set({
      workspaceSummary,
      workspaceDocuments,
      workspaceApprovals,
      workspaceFiles,
      workspaceTasks,
      workspaceMembers,
      workspaceActivity,
      notifications,
      coverageMentions,
      syncStatus
    })
  },

  refreshHierarchy: async () => {
    const { activeSpaceId } = get()
    if (!activeSpaceId) return
    const api = getSpacesAPI()
    const [folders, lists] = await Promise.all([
      api.listFolders(activeSpaceId),
      api.listLists(activeSpaceId)
    ])
    const expanded: Record<string, boolean> = { ...get().expandedFolderIds }
    for (const f of folders) {
      if (expanded[f.id] === undefined) expanded[f.id] = true
    }
    set({ folders, lists, expandedFolderIds: expanded })
  },

  refreshActiveSpace: async () => {
    const { activeSpaceId, activeListId } = get()
    if (!activeSpaceId) return
    const api = getSpacesAPI()
    const [tasks, members, activity, approvals, documents, files, syncStatus] = await Promise.all([
      api.listTasks(activeSpaceId, activeListId ?? undefined),
      api.listMembers(activeSpaceId),
      api.listActivity(activeSpaceId),
      api.listApprovals(activeSpaceId),
      api.listDocuments(activeSpaceId),
      api.listFiles(activeSpaceId),
      api.getSyncStatus()
    ])
    set({ tasks, members, activity, approvals, documents, files, syncStatus })
    const { selectedTaskId } = get()
    if (selectedTaskId) await get().loadTaskComments(selectedTaskId)
  },

  setActiveSpace: async (id) => {
    const defaultView = id ? get().getDefaultViewForSpace(id) : 'overview'
    set({
      activeSpaceId: id,
      activeSection: 'spaces',
      spacesHomeOpen: false,
      taskView: defaultView,
      selectedTaskId: null,
      activeFolderId: null,
      activeListId: null,
      taskComments: []
    })
    if (id) {
      await get().refreshHierarchy()
      await get().refreshActiveSpace()
    } else {
      set({ folders: [], lists: [], tasks: [] })
    }
  },

  setActiveList: async (listId) => {
    const list = get().lists.find((l) => l.id === listId)
    set({
      activeListId: listId,
      activeFolderId: list?.folderId ?? null,
      selectedTaskId: null,
      taskComments: []
    })
    await get().refreshActiveSpace()
  },

  setActiveFolder: async (folderId) => {
    const lists = get().lists.filter((l) => l.folderId === folderId)
    set({
      activeFolderId: folderId,
      activeListId: lists[0]?.id ?? null,
      selectedTaskId: null,
      taskComments: []
    })
    if (folderId) {
      const expanded = { ...get().expandedFolderIds, [folderId]: true }
      set({ expandedFolderIds: expanded })
    }
    await get().refreshActiveSpace()
  },

  toggleFolderExpanded: (folderId) => {
    const expanded = { ...get().expandedFolderIds }
    expanded[folderId] = !expanded[folderId]
    set({ expandedFolderIds: expanded })
  },

  setActiveSection: (section) => {
    const resolved = section === 'dashboard' ? 'chat' : section
    set({ activeSection: resolved })
    if (resolved !== 'spaces') void get().loadWorkspaceData()
  },
  selectEnterpriseNav: (id) => {
    if (id === 'dashboard') {
      set({ activeSection: 'chat', spacesHomeOpen: false })
      return
    }
    if (id === 'whiteboard') {
      set({ activeSection: 'spaces', spacesHomeOpen: false, taskView: 'whiteboard' })
      const spaceId = get().activeSpaceId ?? get().spaces[0]?.id ?? null
      if (spaceId) void get().setActiveSpace(spaceId)
      return
    }
    if (id === 'planner') {
      set({ activeSection: 'planner', spacesHomeOpen: false })
      void get().loadWorkspaceData()
      return
    }
    if (id === 'spaces') {
      set({ activeSection: 'spaces', activeSpaceId: null, spacesHomeOpen: true })
      return
    }
    if (id === 'chat') {
      set({ activeSection: 'chat', spacesHomeOpen: false })
      void get().loadWorkspaceData()
      return
    }
    get().setActiveSection(id)
  },
  setTaskView: (view) => set({ taskView: view }),
  setSelectedTask: async (id) => {
    set({ selectedTaskId: id, contextPanelOpen: true })
    if (id) await get().loadTaskComments(id)
    else set({ taskComments: [] })
  },
  setSidebarCollapsed: (v) => set({ sidebarCollapsed: v }),
  setContextPanelOpen: (v) => set({ contextPanelOpen: v }),
  setCommandOpen: (v) => set({ commandOpen: v }),
  setNotificationsOpen: (v) => set({ notificationsOpen: v }),
  setSearchQuery: (q) => set({ searchQuery: q }),
  setNewSpaceModalOpen: (v) => set({ newSpaceModalOpen: v }),
  setSpaceSettingsId: (id) => set({ spaceSettingsId: id }),
  openSpaceSettings: (id) => set({ spaceSettingsId: id }),
  setSpacesHomeOpen: (v) => {
    if (v) {
      set({
        spacesHomeOpen: true,
        activeSpaceId: null,
        selectedTaskId: null,
        activeFolderId: null,
        activeListId: null,
        folders: [],
        lists: [],
        tasks: [],
        taskComments: []
      })
    } else {
      set({ spacesHomeOpen: false })
    }
  },

  setSpacesHomeQuery: (q) => set({ spacesHomeQuery: q }),
  setSpacesHomeTypeFilter: (t) => set({ spacesHomeTypeFilter: t }),
  setSpacesHomeShowArchived: (v) => set({ spacesHomeShowArchived: v }),
  setSpacesHomeLayout: (layout) => set({ spacesHomeLayout: layout }),

  getDefaultViewForSpace: (spaceId) => {
    try {
      const raw = localStorage.getItem(`spaces:defaultView:${spaceId}`)
      if (raw && isTaskViewMode(raw)) return raw
    } catch {
      /* ignore */
    }
    return 'overview'
  },

  setDefaultViewForSpace: (spaceId, view) => {
    try {
      localStorage.setItem(`spaces:defaultView:${spaceId}`, view)
    } catch {
      /* ignore */
    }
  },

  updateSpace: async (id, patch) => {
    const api = getSpacesAPI()
    await api.updateSpace(id, patch)
    const spaces = await api.listSpaces()
    set({ spaces })
    if (patch.isArchived && get().activeSpaceId === id) {
      const next = spaces.find((s) => !s.isArchived)
      if (next) await get().setActiveSpace(next.id)
      else set({ activeSpaceId: null, spacesHomeOpen: true, folders: [], lists: [], tasks: [] })
    }
  },

  createSpace: async (input) => {
    const api = getSpacesAPI()
    const space = await api.createSpace({
      name: input.name,
      description: input.description,
      type: input.type
    })
    const spaces = await api.listSpaces()
    set({ spaces, newSpaceModalOpen: false })
    await get().setActiveSpace(space.id)
    return space
  },

  createFolder: async (name) => {
    const { activeSpaceId } = get()
    if (!activeSpaceId) return
    const api = getSpacesAPI()
    const folder = await api.createFolder(activeSpaceId, name)
    await get().refreshHierarchy()
    const list = get().lists.find((l) => l.folderId === folder.id)
    if (list) await get().setActiveList(list.id)
  },

  createList: async (name, folderId = null) => {
    const { activeSpaceId } = get()
    if (!activeSpaceId) return
    const api = getSpacesAPI()
    const list = await api.createList(activeSpaceId, name, folderId)
    await get().refreshHierarchy()
    await get().setActiveList(list.id)
  },

  createTask: async (title) => {
    const { activeSpaceId, activeListId } = get()
    if (!activeSpaceId) return
    const api = getSpacesAPI()
    await api.createTask({ spaceId: activeSpaceId, listId: activeListId, title })
    await get().refreshActiveSpace()
  },

  updateTaskStatus: async (taskId, status) => {
    const api = getSpacesAPI()
    await api.updateTask({ id: taskId, status })
    await get().refreshActiveSpace()
  },

  loadTaskComments: async (taskId) => {
    const api = getSpacesAPI()
    const taskComments = await api.listComments(taskId)
    set({ taskComments })
  },

  postComment: async (body) => {
    const { activeSpaceId, selectedTaskId } = get()
    if (!activeSpaceId || !selectedTaskId || !body.trim()) return
    const api = getSpacesAPI()
    await api.createComment({ spaceId: activeSpaceId, taskId: selectedTaskId, body: body.trim() })
    await get().loadTaskComments(selectedTaskId)
    await get().refreshActiveSpace()
  },

  createDocument: async (title, spaceId) => {
    const targetSpaceId = spaceId ?? get().activeSpaceId ?? get().spaces[0]?.id
    if (!targetSpaceId || !title.trim()) return
    const api = getSpacesAPI()
    const doc = await api.createDocument(targetSpaceId, title.trim())
    await get().loadWorkspaceData()
    if (get().activeSpaceId === targetSpaceId) await get().refreshActiveSpace()
    getSpacesAPI().openDocumentWindow(doc.id, doc.title)
  },

  createFileLink: async (fileName, fileUrl, spaceId) => {
    const targetSpaceId = spaceId ?? get().activeSpaceId ?? get().spaces[0]?.id
    if (!targetSpaceId || !fileName.trim() || !fileUrl.trim()) return
    const api = getSpacesAPI()
    await api.createFile(targetSpaceId, fileName.trim(), fileUrl.trim())
    await get().loadWorkspaceData()
    if (get().activeSpaceId === targetSpaceId) await get().refreshActiveSpace()
  }
}))

function isTaskViewMode(v: string): v is TaskViewMode {
  return [
    'overview',
    'list',
    'board',
    'timeline',
    'calendar',
    'workload',
    'priority',
    'document'
  ].includes(v)
}
