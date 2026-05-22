export type TaskStatus =
  | 'todo'
  | 'in_progress'
  | 'review'
  | 'blocked'
  | 'approved'
  | 'completed'
  | 'archived'

export type TaskPriority = 'none' | 'low' | 'normal' | 'high' | 'urgent'

export type SpaceType =
  | 'client'
  | 'campaign'
  | 'launch'
  | 'editorial'
  | 'department'
  | 'initiative'
  | 'event'
  | 'retainer'
  | 'publication'
  | 'operation'
  | 'general'

export type SpaceStatus = 'active' | 'planning' | 'on_hold' | 'completed' | 'archived'

export type SpaceMemberRole =
  | 'owner'
  | 'manager'
  | 'editor'
  | 'contributor'
  | 'viewer'
  | 'client'

export type TaskViewMode =
  | 'overview'
  | 'list'
  | 'board'
  | 'timeline'
  | 'calendar'
  | 'workload'
  | 'priority'
  | 'document'

export type SidebarSection =
  | 'dashboard'
  | 'spaces'
  | 'planner'
  | 'chat'
  | 'documents'
  | 'approvals'
  | 'reports'
  | 'clients'
  | 'campaigns'
  | 'team'
  | 'media'
  | 'files'
  | 'settings'

export type SyncStatus = 'online' | 'syncing' | 'offline' | 'error'

export interface Workspace {
  id: string
  name: string
  logoUrl?: string
}

export interface Space {
  id: string
  workspaceId: string
  name: string
  description: string
  type: SpaceType
  status: SpaceStatus
  ownerId: string
  color: string
  isPinned: boolean
  isFavourite: boolean
  isArchived: boolean
  clientMode: boolean
  updatedAt: string
  createdAt: string
}

export interface SpaceFolder {
  id: string
  spaceId: string
  name: string
  sortOrder: number
  isArchived: boolean
  updatedAt: string
}

export interface SpaceList {
  id: string
  spaceId: string
  folderId: string | null
  name: string
  sortOrder: number
  isArchived: boolean
  updatedAt: string
}

export interface SpaceMember {
  id: string
  spaceId: string
  userId: string
  role: SpaceMemberRole
  name: string
  email: string
  avatarColor: string
  isOnline: boolean
}

export interface Task {
  id: string
  spaceId: string
  listId: string | null
  title: string
  description: string
  status: TaskStatus
  priority: TaskPriority
  assigneeId: string | null
  startDate: string | null
  dueDate: string | null
  tags: string[]
  parentTaskId: string | null
  checklist: ChecklistItem[]
  commentCount: number
  attachmentCount: number
  linkedDocIds: string[]
  order: number
  updatedAt: string
  createdAt: string
}

export interface ChecklistItem {
  id: string
  title: string
  done: boolean
}

export interface TaskDependency {
  id: string
  taskId: string
  dependsOnTaskId: string
  type: 'blocked_by' | 'waiting_on' | 'related_to' | 'duplicate_of' | 'parent'
}

export interface SpaceActivity {
  id: string
  spaceId: string
  userId: string
  userName: string
  action: string
  entityType: string
  entityId: string
  createdAt: string
}

export interface SpaceComment {
  id: string
  spaceId: string
  taskId: string | null
  documentId: string | null
  userId: string
  userName: string
  body: string
  createdAt: string
}

export interface SpaceDocument {
  id: string
  spaceId: string
  title: string
  docType: string
  updatedAt: string
}

export interface Approval {
  id: string
  spaceId: string
  taskId: string | null
  documentId: string | null
  status: 'requested' | 'in_review' | 'changes_requested' | 'approved' | 'rejected'
  title: string
  updatedAt: string
}

export interface SpaceFile {
  id: string
  spaceId: string
  fileName: string
  fileUrl: string
  mimeType: string
  updatedAt: string
}

export interface NotificationItem {
  id: string
  spaceId: string | null
  title: string
  body: string
  kind: string
  read: boolean
  createdAt: string
}

export interface SearchResult {
  id: string
  type: 'task' | 'doc' | 'file' | 'comment' | 'approval' | 'space' | 'user'
  title: string
  subtitle: string
  spaceId?: string
}

export interface CreateTaskInput {
  spaceId: string
  listId?: string | null
  title: string
  status?: TaskStatus
  priority?: TaskPriority
  assigneeId?: string | null
  dueDate?: string | null
}

export interface UpdateTaskInput {
  id: string
  title?: string
  description?: string
  status?: TaskStatus
  priority?: TaskPriority
  assigneeId?: string | null
  listId?: string | null
  startDate?: string | null
  dueDate?: string | null
  tags?: string[]
  checklist?: ChecklistItem[]
  order?: number
}

export interface SpacesAPI {
  getBootstrap: () => Promise<BootstrapPayload>
  listSpaces: () => Promise<Space[]>
  getSpace: (id: string) => Promise<Space | null>
  createSpace: (input: Partial<Space> & { name: string }) => Promise<Space>
  updateSpace: (id: string, patch: Partial<Space>) => Promise<Space>
  listFolders: (spaceId: string) => Promise<SpaceFolder[]>
  createFolder: (spaceId: string, name: string) => Promise<SpaceFolder>
  updateFolder: (id: string, patch: { name?: string }) => Promise<SpaceFolder>
  listLists: (spaceId: string) => Promise<SpaceList[]>
  createList: (spaceId: string, name: string, folderId?: string | null) => Promise<SpaceList>
  updateList: (id: string, patch: { name?: string }) => Promise<SpaceList>
  listTasks: (spaceId: string, listId?: string | null) => Promise<Task[]>
  createTask: (input: CreateTaskInput) => Promise<Task>
  listComments: (taskId: string) => Promise<SpaceComment[]>
  createComment: (input: {
    spaceId: string
    taskId: string
    body: string
  }) => Promise<SpaceComment>
  updateTask: (input: UpdateTaskInput) => Promise<Task>
  deleteTask: (id: string) => Promise<void>
  listActivity: (spaceId: string, limit?: number) => Promise<SpaceActivity[]>
  listMembers: (spaceId: string) => Promise<SpaceMember[]>
  listApprovals: (spaceId: string) => Promise<Approval[]>
  listDocuments: (spaceId: string) => Promise<SpaceDocument[]>
  listFiles: (spaceId: string) => Promise<SpaceFile[]>
  search: (query: string) => Promise<SearchResult[]>
  getSyncStatus: () => Promise<SyncStatus>
  openDocumentWindow: (documentId: string, title: string) => void
  openSpaceWindow: (spaceId: string) => void
}

export interface BootstrapPayload {
  workspace: Workspace
  spaces: Space[]
  currentUserId: string
  currentUserName: string
  syncStatus: SyncStatus
}

export const TASK_STATUS_LABELS: Record<TaskStatus, string> = {
  todo: 'To Do',
  in_progress: 'In Progress',
  review: 'Review',
  blocked: 'Blocked',
  approved: 'Approved',
  completed: 'Completed',
  archived: 'Archived'
}

export const BOARD_COLUMNS: TaskStatus[] = [
  'todo',
  'in_progress',
  'review',
  'approved',
  'completed'
]
