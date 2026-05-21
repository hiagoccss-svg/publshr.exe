import { ipcMain, BrowserWindow } from 'electron'
import type { SpacesDatabase } from '../db/database'
import { createDocumentWindow, createSpaceWindow } from '../windows'

export function registerIpcHandlers(db: SpacesDatabase): void {
  ipcMain.handle('spaces:getBootstrap', () => db.getBootstrap())
  ipcMain.handle('spaces:listSpaces', () => db.listSpaces())
  ipcMain.handle('spaces:getSpace', (_e, id: string) => db.getSpace(id))
  ipcMain.handle('spaces:createSpace', (_e, input) => db.createSpace(input))
  ipcMain.handle('spaces:updateSpace', (_e, id: string, patch) => db.updateSpace(id, patch))
  ipcMain.handle('spaces:listTasks', (_e, spaceId: string) => db.listTasks(spaceId))
  ipcMain.handle('spaces:createTask', (_e, input) => db.createTask(input))
  ipcMain.handle('spaces:updateTask', (_e, input) => db.updateTask(input))
  ipcMain.handle('spaces:deleteTask', (_e, id: string) => db.deleteTask(id))
  ipcMain.handle('spaces:listActivity', (_e, spaceId: string, limit?: number) =>
    db.listActivity(spaceId, limit)
  )
  ipcMain.handle('spaces:listMembers', (_e, spaceId: string) => db.listMembers(spaceId))
  ipcMain.handle('spaces:listApprovals', (_e, spaceId: string) => db.listApprovals(spaceId))
  ipcMain.handle('spaces:listDocuments', (_e, spaceId: string) => db.listDocuments(spaceId))
  ipcMain.handle('spaces:listFiles', (_e, spaceId: string) => db.listFiles(spaceId))
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
