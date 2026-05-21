import { contextBridge, ipcRenderer } from 'electron'
import type { SpacesAPI } from '../shared/types'

const api: SpacesAPI = {
  getBootstrap: () => ipcRenderer.invoke('spaces:getBootstrap'),
  listSpaces: () => ipcRenderer.invoke('spaces:listSpaces'),
  getSpace: (id) => ipcRenderer.invoke('spaces:getSpace', id),
  createSpace: (input) => ipcRenderer.invoke('spaces:createSpace', input),
  updateSpace: (id, patch) => ipcRenderer.invoke('spaces:updateSpace', id, patch),
  listTasks: (spaceId) => ipcRenderer.invoke('spaces:listTasks', spaceId),
  createTask: (input) => ipcRenderer.invoke('spaces:createTask', input),
  updateTask: (input) => ipcRenderer.invoke('spaces:updateTask', input),
  deleteTask: (id) => ipcRenderer.invoke('spaces:deleteTask', id),
  listActivity: (spaceId, limit) => ipcRenderer.invoke('spaces:listActivity', spaceId, limit),
  listMembers: (spaceId) => ipcRenderer.invoke('spaces:listMembers', spaceId),
  listApprovals: (spaceId) => ipcRenderer.invoke('spaces:listApprovals', spaceId),
  listDocuments: (spaceId) => ipcRenderer.invoke('spaces:listDocuments', spaceId),
  listFiles: (spaceId) => ipcRenderer.invoke('spaces:listFiles', spaceId),
  search: (query) => ipcRenderer.invoke('spaces:search', query),
  getSyncStatus: () => ipcRenderer.invoke('spaces:getSyncStatus'),
  openDocumentWindow: (documentId, title) =>
    ipcRenderer.send('spaces:openDocumentWindow', documentId, title),
  openSpaceWindow: (spaceId) => ipcRenderer.send('spaces:openSpaceWindow', spaceId)
}

contextBridge.exposeInMainWorld('spaces', api)

ipcRenderer.on('spaces:refresh', () => {
  window.dispatchEvent(new CustomEvent('spaces:refresh'))
})

declare global {
  interface Window {
    spaces: SpacesAPI
  }
}
