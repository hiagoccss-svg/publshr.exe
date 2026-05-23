import { contextBridge, ipcRenderer } from 'electron'
import type { SpacesAPI } from '../shared/types'

const api: SpacesAPI = {
  getBootstrap: () => ipcRenderer.invoke('spaces:getBootstrap'),
  listSpaces: () => ipcRenderer.invoke('spaces:listSpaces'),
  getSpace: (id) => ipcRenderer.invoke('spaces:getSpace', id),
  createSpace: (input) => ipcRenderer.invoke('spaces:createSpace', input),
  updateSpace: (id, patch) => ipcRenderer.invoke('spaces:updateSpace', id, patch),
  listFolders: (spaceId) => ipcRenderer.invoke('spaces:listFolders', spaceId),
  createFolder: (spaceId, name) => ipcRenderer.invoke('spaces:createFolder', spaceId, name),
  updateFolder: (id, patch) => ipcRenderer.invoke('spaces:updateFolder', id, patch),
  listLists: (spaceId) => ipcRenderer.invoke('spaces:listLists', spaceId),
  createList: (spaceId, name, folderId) =>
    ipcRenderer.invoke('spaces:createList', spaceId, name, folderId),
  updateList: (id, patch) => ipcRenderer.invoke('spaces:updateList', id, patch),
  listTasks: (spaceId, listId) => ipcRenderer.invoke('spaces:listTasks', spaceId, listId),
  listComments: (taskId) => ipcRenderer.invoke('spaces:listComments', taskId),
  createComment: (input) => ipcRenderer.invoke('spaces:createComment', input),
  createTask: (input) => ipcRenderer.invoke('spaces:createTask', input),
  updateTask: (input) => ipcRenderer.invoke('spaces:updateTask', input),
  deleteTask: (id) => ipcRenderer.invoke('spaces:deleteTask', id),
  listActivity: (spaceId, limit) => ipcRenderer.invoke('spaces:listActivity', spaceId, limit),
  listMembers: (spaceId) => ipcRenderer.invoke('spaces:listMembers', spaceId),
  listApprovals: (spaceId) => ipcRenderer.invoke('spaces:listApprovals', spaceId),
  listDocuments: (spaceId) => ipcRenderer.invoke('spaces:listDocuments', spaceId),
  getDocument: (id) => ipcRenderer.invoke('spaces:getDocument', id),
  createDocument: (spaceId, title, content) =>
    ipcRenderer.invoke('spaces:createDocument', spaceId, title, content),
  updateDocument: (id, patch) => ipcRenderer.invoke('spaces:updateDocument', id, patch),
  listFiles: (spaceId) => ipcRenderer.invoke('spaces:listFiles', spaceId),
  createFile: (spaceId, fileName, fileUrl) =>
    ipcRenderer.invoke('spaces:createFile', spaceId, fileName, fileUrl),
  listWorkspaceDocuments: () => ipcRenderer.invoke('spaces:listWorkspaceDocuments'),
  listWorkspaceApprovals: () => ipcRenderer.invoke('spaces:listWorkspaceApprovals'),
  listWorkspaceFiles: () => ipcRenderer.invoke('spaces:listWorkspaceFiles'),
  listWorkspaceTasks: () => ipcRenderer.invoke('spaces:listWorkspaceTasks'),
  listWorkspaceMembers: () => ipcRenderer.invoke('spaces:listWorkspaceMembers'),
  listWorkspaceActivity: (limit) => ipcRenderer.invoke('spaces:listWorkspaceActivity', limit),
  listNotifications: (limit) => ipcRenderer.invoke('spaces:listNotifications', limit),
  getWorkspaceSummary: () => ipcRenderer.invoke('spaces:getWorkspaceSummary'),
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
