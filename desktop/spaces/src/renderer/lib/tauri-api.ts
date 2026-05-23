import { invoke } from '@tauri-apps/api/core'
import { listen } from '@tauri-apps/api/event'
import { isTauriDesktop } from '@desktop/platform'
import type { SpacesAPI } from '../../shared/types'

function cmd<T>(name: string, args?: Record<string, unknown>): Promise<T> {
  return invoke<T>(name, args)
}

export function createTauriSpacesAPI(): SpacesAPI {
  return {
    getBootstrap: () => cmd('spaces_get_bootstrap'),
    listSpaces: () => cmd('spaces_list_spaces'),
    getSpace: (id) => cmd('spaces_get_space', { id }),
    createSpace: (input) => cmd('spaces_create_space', { input }),
    updateSpace: (id, patch) => cmd('spaces_update_space', { id, patch }),
    listFolders: (spaceId) => cmd('spaces_list_folders', { spaceId }),
    createFolder: (spaceId, name) => cmd('spaces_create_folder', { spaceId, name }),
    updateFolder: (id, patch) => cmd('spaces_update_folder', { id, patch }),
    listLists: (spaceId) => cmd('spaces_list_lists', { spaceId }),
    createList: (spaceId, name, folderId) =>
      cmd('spaces_create_list', { spaceId, name, folderId: folderId ?? null }),
    updateList: (id, patch) => cmd('spaces_update_list', { id, patch }),
    listTasks: (spaceId, listId) => cmd('spaces_list_tasks', { spaceId, listId: listId ?? null }),
    createTask: (input) => cmd('spaces_create_task', { input }),
    listComments: (taskId) => cmd('spaces_list_comments', { taskId }),
    createComment: (input) => cmd('spaces_create_comment', { input }),
    updateTask: (input) => cmd('spaces_update_task', { input }),
    deleteTask: (id) => cmd('spaces_delete_task', { id }),
    listActivity: (spaceId, limit) => cmd('spaces_list_activity', { spaceId, limit }),
    listMembers: (spaceId) => cmd('spaces_list_members', { spaceId }),
    listApprovals: (spaceId) => cmd('spaces_list_approvals', { spaceId }),
    listDocuments: (spaceId) => cmd('spaces_list_documents', { spaceId }),
    getDocument: (id) => cmd('spaces_get_document', { id }),
    createDocument: (spaceId, title, content) =>
      cmd('spaces_create_document', { spaceId, title, content: content ?? '' }),
    updateDocument: (id, patch) => cmd('spaces_update_document', { id, patch }),
    listFiles: (spaceId) => cmd('spaces_list_files', { spaceId }),
    createFile: (spaceId, fileName, fileUrl) =>
      cmd('spaces_create_file', { spaceId, fileName, fileUrl }),
    listWorkspaceDocuments: () => cmd('spaces_list_workspace_documents'),
    listWorkspaceApprovals: () => cmd('spaces_list_workspace_approvals'),
    listWorkspaceFiles: () => cmd('spaces_list_workspace_files'),
    listWorkspaceTasks: () => cmd('spaces_list_workspace_tasks'),
    listWorkspaceMembers: () => cmd('spaces_list_workspace_members'),
    listWorkspaceActivity: (limit) => cmd('spaces_list_workspace_activity', { limit }),
    listNotifications: (limit) => cmd('spaces_list_notifications', { limit }),
    getWorkspaceSummary: () => cmd('spaces_get_workspace_summary'),
    search: (query) => cmd('spaces_search', { query }),
    getSyncStatus: () => cmd('spaces_get_sync_status'),
    openDocumentWindow: (documentId, title) => {
      void cmd('spaces_open_document_window', { documentId, title })
    },
    openSpaceWindow: (spaceId) => {
      void cmd('spaces_open_space_window', { spaceId })
    }
  }
}

export function bindTauriSpacesRefresh(onRefresh: () => void): () => void {
  let unlisten: (() => void) | undefined
  void listen('spaces:refresh', () => onRefresh()).then((fn) => {
    unlisten = fn
  })
  return () => unlisten?.()
}

export function resolveSpacesAPI(): SpacesAPI {
  if (isTauriDesktop()) return createTauriSpacesAPI()
  if (window.spaces) return window.spaces
  throw new Error(
    'Spaces API unavailable — run with `npm run tauri:dev` (Tauri) or `npm run dev:electron` (legacy)'
  )
}
