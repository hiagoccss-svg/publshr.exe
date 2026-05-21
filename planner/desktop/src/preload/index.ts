import { contextBridge, ipcRenderer } from 'electron'

export type PlannerAPI = {
  getPreference: (key: string) => Promise<string | null>
  setPreference: (key: string, value: string) => Promise<boolean>
  getPlannerItemsCache: (workspaceId: string) => Promise<unknown[]>
  upsertPlannerItemCache: (item: Record<string, unknown>) => Promise<boolean>
  deletePlannerItemCache: (id: string) => Promise<boolean>
  getWorkspacesCache: () => Promise<unknown[]>
  upsertWorkspaceCache: (workspace: Record<string, unknown>) => Promise<boolean>
  enqueueSync: (entry: {
    id: string
    tableName: string
    recordId: string
    operation: string
    payload: string
  }) => Promise<boolean>
  getSyncQueue: () => Promise<unknown[]>
  dequeueSync: (id: string) => Promise<boolean>
  openEditorWindow: (documentId: string, plannerItemId: string) => Promise<boolean>
  getEditorDraftCache: (documentId: string) => Promise<unknown | null>
  upsertEditorDraftCache: (draft: Record<string, unknown>) => Promise<boolean>
  openExternal: (url: string) => Promise<void>
  showNotification: (payload: { title: string; body: string }) => Promise<void>
  platform: NodeJS.Platform
  isEditorWindow: boolean
  editorDocumentId: string | null
  plannerItemId: string | null
}

function getArg(name: string): string | null {
  const prefix = `--${name}=`
  const arg = process.argv.find((a) => a.startsWith(prefix))
  return arg ? arg.slice(prefix.length) : null
}

const editorDocumentId = getArg('editor-document-id')
const plannerItemId = getArg('planner-item-id')

const api: PlannerAPI = {
  getPreference: (key) => ipcRenderer.invoke('db:getPreference', key),
  setPreference: (key, value) => ipcRenderer.invoke('db:setPreference', key, value),
  getPlannerItemsCache: (workspaceId) => ipcRenderer.invoke('cache:getPlannerItems', workspaceId),
  upsertPlannerItemCache: (item) => ipcRenderer.invoke('cache:upsertPlannerItem', item),
  deletePlannerItemCache: (id) => ipcRenderer.invoke('cache:deletePlannerItem', id),
  getWorkspacesCache: () => ipcRenderer.invoke('cache:getWorkspaces'),
  upsertWorkspaceCache: (workspace) => ipcRenderer.invoke('cache:upsertWorkspace', workspace),
  enqueueSync: (entry) => ipcRenderer.invoke('sync:enqueue', entry),
  getSyncQueue: () => ipcRenderer.invoke('sync:getQueue'),
  dequeueSync: (id) => ipcRenderer.invoke('sync:dequeue', id),
  openEditorWindow: (documentId, itemId) =>
    ipcRenderer.invoke('editor:openWindow', documentId, itemId),
  getEditorDraftCache: (documentId) => ipcRenderer.invoke('cache:getEditorDraft', documentId),
  upsertEditorDraftCache: (draft) => ipcRenderer.invoke('cache:upsertEditorDraft', draft),
  openExternal: (url) => ipcRenderer.invoke('shell:openExternal', url),
  showNotification: (payload) => ipcRenderer.invoke('notification:show', payload),
  platform: process.platform,
  isEditorWindow: Boolean(editorDocumentId),
  editorDocumentId,
  plannerItemId
}

contextBridge.exposeInMainWorld('planner', api)
