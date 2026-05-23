import { ipcMain, BrowserWindow } from 'electron'
import type { SpacesDatabase } from '../db/database'
import { createDocumentWindow, createSpaceWindow } from '../windows'

export function registerIpcHandlers(db: SpacesDatabase): void {
  ipcMain.handle('spaces:getBootstrap', () => db.getBootstrap())
  ipcMain.handle('spaces:listSpaces', () => db.listSpaces())
  ipcMain.handle('spaces:getSpace', (_e, id: string) => db.getSpace(id))
  ipcMain.handle('spaces:createSpace', (_e, input) => db.createSpace(input))
  ipcMain.handle('spaces:updateSpace', (_e, id: string, patch) => db.updateSpace(id, patch))
  ipcMain.handle('spaces:listFolders', (_e, spaceId: string) => db.listFolders(spaceId))
  ipcMain.handle('spaces:createFolder', (_e, spaceId: string, name: string) =>
    db.createFolder(spaceId, name)
  )
  ipcMain.handle('spaces:updateFolder', (_e, id: string, patch) => db.updateFolder(id, patch))
  ipcMain.handle('spaces:listLists', (_e, spaceId: string) => db.listLists(spaceId))
  ipcMain.handle('spaces:createList', (_e, spaceId: string, name: string, folderId?: string | null) =>
    db.createList(spaceId, name, folderId ?? null)
  )
  ipcMain.handle('spaces:updateList', (_e, id: string, patch) => db.updateList(id, patch))
  ipcMain.handle('spaces:listTasks', (_e, spaceId: string, listId?: string | null) =>
    db.listTasks(spaceId, listId)
  )
  ipcMain.handle('spaces:listComments', (_e, taskId: string) => db.listComments(taskId))
  ipcMain.handle('spaces:createComment', (_e, input) => db.createComment(input))
  ipcMain.handle('spaces:createTask', (_e, input) => db.createTask(input))
  ipcMain.handle('spaces:updateTask', (_e, input) => db.updateTask(input))
  ipcMain.handle('spaces:deleteTask', (_e, id: string) => db.deleteTask(id))
  ipcMain.handle('spaces:listActivity', (_e, spaceId: string, limit?: number) =>
    db.listActivity(spaceId, limit)
  )
  ipcMain.handle('spaces:listMembers', (_e, spaceId: string) => db.listMembers(spaceId))
  ipcMain.handle('spaces:listApprovals', (_e, spaceId: string) => db.listApprovals(spaceId))
  ipcMain.handle('spaces:listDocuments', (_e, spaceId: string) => db.listDocuments(spaceId))
  ipcMain.handle('spaces:getDocument', (_e, id: string) => db.getDocument(id))
  ipcMain.handle('spaces:createDocument', (_e, spaceId: string, title: string, content?: string) =>
    db.createDocument(spaceId, title, content)
  )
  ipcMain.handle('spaces:updateDocument', (_e, id: string, patch: { title?: string; content?: string }) =>
    db.updateDocument(id, patch)
  )
  ipcMain.handle('spaces:listFiles', (_e, spaceId: string) => db.listFiles(spaceId))
  ipcMain.handle('spaces:createFile', (_e, spaceId: string, fileName: string, fileUrl: string) =>
    db.createFile(spaceId, fileName, fileUrl)
  )
  ipcMain.handle('spaces:listWorkspaceDocuments', () => db.listWorkspaceDocuments())
  ipcMain.handle('spaces:listWorkspaceApprovals', () => db.listWorkspaceApprovals())
  ipcMain.handle('spaces:listWorkspaceFiles', () => db.listWorkspaceFiles())
  ipcMain.handle('spaces:listWorkspaceTasks', () => db.listWorkspaceTasks())
  ipcMain.handle('spaces:listWorkspaceMembers', () => db.listWorkspaceMembers())
  ipcMain.handle('spaces:listWorkspaceActivity', (_e, limit?: number) =>
    db.listWorkspaceActivity(limit)
  )
  ipcMain.handle('spaces:listNotifications', (_e, limit?: number) => db.listNotifications(limit))
  ipcMain.handle('spaces:getWorkspaceSummary', () => db.getWorkspaceSummary())
  ipcMain.handle('spaces:search', (_e, query: string) => db.search(query))
  ipcMain.handle('spaces:getSyncStatus', () => db.getSyncStatus())

  ipcMain.on('spaces:openDocumentWindow', (_e, documentId: string, title: string) => {
    createDocumentWindow(documentId, title)
  })

  ipcMain.on('spaces:openSpaceWindow', (_e, spaceId: string) => {
    createSpaceWindow(spaceId)
  })

  ipcMain.on('spaces:broadcastRefresh', () => {
    for (const win of BrowserWindow.getAllWindows()) {
      if (!win.isDestroyed()) {
        win.webContents.send('spaces:refresh')
      }
    }
  })
}
