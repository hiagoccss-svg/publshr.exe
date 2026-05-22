import { create } from 'zustand'
import { getSpacesAPI } from '../lib/api'
import type {
  Approval,
  BootstrapPayload,
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
  TaskViewMode
} from '../../shared/types'

interface SpacesState {
  ready: boolean
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
  taskComments: SpaceComment[]
  currentUserId: string
  currentUserName: string
  syncStatus: SyncStatus
  sidebarCollapsed: boolean
  contextPanelOpen: boolean
  selectedTaskId: string | null
  commandOpen: boolean
  searchQuery: string
  newSpaceModalOpen: boolean
  loadBootstrap: () => Promise<void>
  refreshActiveSpace: () => Promise<void>
  refreshHierarchy: () => Promise<void>
  setActiveSpace: (id: string | null) => Promise<void>
  setActiveList: (listId: string | null) => Promise<void>
  setActiveFolder: (folderId: string | null) => Promise<void>
  toggleFolderExpanded: (folderId: string) => void
  setActiveSection: (section: SidebarSection) => void
  setTaskView: (view: TaskViewMode) => void
  setSelectedTask: (id: string | null) => Promise<void>
  setSidebarCollapsed: (v: boolean) => void
  setContextPanelOpen: (v: boolean) => void
  setCommandOpen: (v: boolean) => void
  setSearchQuery: (q: string) => void
  setNewSpaceModalOpen: (v: boolean) => void
  createSpace: (input: { name: string; description?: string; type?: Space['type'] }) => Promise<Space>
  createFolder: (name: string) => Promise<void>
  createList: (name: string, folderId?: string | null) => Promise<void>
  createTask: (title: string) => Promise<void>
  updateTaskStatus: (taskId: string, status: Task['status']) => Promise<void>
  loadTaskComments: (taskId: string) => Promise<void>
  postComment: (body: string) => Promise<void>
}

export const useSpacesStore = create<SpacesState>((set, get) => ({
  ready: false,
  workspace: null,
  spaces: [],
  folders: [],
  lists: [],
  activeSpaceId: null,
  activeFolderId: null,
  activeListId: null,
  expandedFolderIds: {},
  activeSection: 'spaces',
  taskView: 'overview',
  tasks: [],
  members: [],
  activity: [],
  documents: [],
  files: [],
  approvals: [],
  taskComments: [],
  currentUserId: '',
  currentUserName: 'You',
  syncStatus: 'offline',
  sidebarCollapsed: false,
  contextPanelOpen: true,
  selectedTaskId: null,
  commandOpen: false,
  searchQuery: '',
  newSpaceModalOpen: false,

  loadBootstrap: async () => {
    const api = getSpacesAPI()
    const data: BootstrapPayload = await api.getBootstrap()
    const spaces = data.spaces
    set({
      ready: true,
      workspace: data.workspace,
      spaces,
      activeSpaceId: spaces[0]?.id ?? null,
      currentUserId: data.currentUserId,
      currentUserName: data.currentUserName,
      syncStatus: data.syncStatus
    })
    if (spaces[0]) await get().setActiveSpace(spaces[0].id)
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
    set({
      activeSpaceId: id,
      activeSection: 'spaces',
      taskView: 'overview',
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

  setActiveSection: (section) => set({ activeSection: section }),
  setTaskView: (view) => set({ taskView: view }),
  setSelectedTask: async (id) => {
    set({ selectedTaskId: id, contextPanelOpen: true })
    if (id) await get().loadTaskComments(id)
    else set({ taskComments: [] })
  },
  setSidebarCollapsed: (v) => set({ sidebarCollapsed: v }),
  setContextPanelOpen: (v) => set({ contextPanelOpen: v }),
  setCommandOpen: (v) => set({ commandOpen: v }),
  setSearchQuery: (q) => set({ searchQuery: q }),
  setNewSpaceModalOpen: (v) => set({ newSpaceModalOpen: v }),

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
  }
}))
