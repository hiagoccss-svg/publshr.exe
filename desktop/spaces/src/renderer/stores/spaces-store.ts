import { create } from 'zustand'
import { getSpacesAPI } from '../lib/api'
import type {
  Approval,
  BootstrapPayload,
  SidebarSection,
  Space,
  SpaceActivity,
  SpaceDocument,
  SpaceFile,
  SpaceMember,
  SyncStatus,
  Task,
  TaskViewMode,
  Workspace
} from '../../shared/types'

interface SpacesState {
  ready: boolean
  workspace: Workspace | null
  spaces: Space[]
  activeSpaceId: string | null
  activeSection: SidebarSection
  taskView: TaskViewMode
  tasks: Task[]
  members: SpaceMember[]
  activity: SpaceActivity[]
  approvals: Approval[]
  documents: SpaceDocument[]
  files: SpaceFile[]
  currentUserId: string
  currentUserName: string
  syncStatus: SyncStatus
  sidebarCollapsed: boolean
  contextPanelOpen: boolean
  selectedTaskId: string | null
  commandOpen: boolean
  searchQuery: string
  loadBootstrap: () => Promise<void>
  refreshActiveSpace: () => Promise<void>
  setActiveSpace: (id: string | null) => Promise<void>
  setActiveSection: (section: SidebarSection) => void
  setTaskView: (view: TaskViewMode) => void
  setSelectedTask: (id: string | null) => void
  setSidebarCollapsed: (v: boolean) => void
  setContextPanelOpen: (v: boolean) => void
  setCommandOpen: (v: boolean) => void
  setSearchQuery: (q: string) => void
  createSpace: (name: string) => Promise<Space>
  createTask: (title: string) => Promise<void>
  updateTaskStatus: (taskId: string, status: Task['status']) => Promise<void>
}

export const useSpacesStore = create<SpacesState>((set, get) => ({
  ready: false,
  workspace: null,
  spaces: [],
  activeSpaceId: null,
  activeSection: 'spaces',
  taskView: 'overview',
  tasks: [],
  members: [],
  activity: [],
  approvals: [],
  documents: [],
  files: [],
  currentUserId: '',
  currentUserName: 'You',
  syncStatus: 'offline',
  sidebarCollapsed: false,
  contextPanelOpen: true,
  selectedTaskId: null,
  commandOpen: false,
  searchQuery: '',

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

  refreshActiveSpace: async () => {
    const { activeSpaceId } = get()
    if (!activeSpaceId) return
    const api = getSpacesAPI()
    const [tasks, members, activity, approvals, documents, files, syncStatus] =
      await Promise.all([
        api.listTasks(activeSpaceId),
        api.listMembers(activeSpaceId),
        api.listActivity(activeSpaceId),
        api.listApprovals(activeSpaceId),
        api.listDocuments(activeSpaceId),
        api.listFiles(activeSpaceId),
        api.getSyncStatus()
      ])
    set({ tasks, members, activity, approvals, documents, files, syncStatus })
  },

  setActiveSpace: async (id) => {
    set({
      activeSpaceId: id,
      activeSection: 'spaces',
      taskView: 'overview',
      selectedTaskId: null
    })
    if (id) await get().refreshActiveSpace()
  },

  setActiveSection: (section) => set({ activeSection: section }),
  setTaskView: (view) => set({ taskView: view }),
  setSelectedTask: (id) => set({ selectedTaskId: id, contextPanelOpen: true }),
  setSidebarCollapsed: (v) => set({ sidebarCollapsed: v }),
  setContextPanelOpen: (v) => set({ contextPanelOpen: v }),
  setCommandOpen: (v) => set({ commandOpen: v }),
  setSearchQuery: (q) => set({ searchQuery: q }),

  createSpace: async (name) => {
    const api = getSpacesAPI()
    const space = await api.createSpace({ name })
    const spaces = await api.listSpaces()
    set({ spaces })
    await get().setActiveSpace(space.id)
    return space
  },

  createTask: async (title) => {
    const { activeSpaceId } = get()
    if (!activeSpaceId) return
    const api = getSpacesAPI()
    await api.createTask({ spaceId: activeSpaceId, title })
    await get().refreshActiveSpace()
  },

  updateTaskStatus: async (taskId, status) => {
    const api = getSpacesAPI()
    await api.updateTask({ id: taskId, status })
    await get().refreshActiveSpace()
  }
}))
